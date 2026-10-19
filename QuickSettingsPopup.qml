pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "DesktopUi.js" as Display
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

AnimatedPopup {
    id: root

    panelItem: panel
    required property var sinkAudio
    required property var network
    required property var brightness
    readonly property var wifiDevice: network.wifiDevice
    readonly property var bluetoothAdapter: network.bluetoothAdapter
    readonly property string scanOwner: barWindow.screen ? barWindow.screen.name : "unknown"

    property string mode: "audio"
    property real anchorCenterX: 0
    property var selectedWifi: null
    property string wifiPassword: ""

    readonly property bool compactMode: mode === "audio" || mode === "brightness"
    readonly property string panelTitle: mode === "audio" ? "Volume"
        : mode === "brightness" ? "Brilho"
        : mode === "wifi" ? "Redes Wi-Fi"
        : "Dispositivos Bluetooth"

    function openFor(newMode, centerX) {
        if (root.opened && root.mode === newMode) {
            root.opened = false;
            return;
        }

        root.mode = newMode;
        root.anchorCenterX = centerX;
        root.selectedWifi = null;
        root.wifiPassword = "";
        root.opened = true;
        root.updateScanning();
    }

    function updateScanning() {
        root.network.setScanning(root.scanOwner, root.opened ? root.mode : "");
    }

    function wifiIcon(network) {
        return Display.wifiIcon(true, true, network.signalStrength, false);
    }

    function activateWifi(network) {
        if (!root.network.activateWifi(network)) {
            root.selectedWifi = network;
            root.wifiPassword = "";
            Qt.callLater(function() { passwordInput.forceActiveFocus(); });
        }
    }



    edgeAttached: true
    revealOriginX: Math.max(0, Math.min(panel.width, (root.anchorCenterX - root.anchor.rect.x) / root.layoutScale))
    anchor.window: barWindow
    anchor.rect.x: Math.max(0, Math.min(barWindow.width - root.implicitWidth,
        root.anchorCenterX - root.implicitWidth / 2))
    anchor.rect.y: edgeAnchorY
    preferredWidth: root.compactMode ? theme.quickCompactWidth : theme.quickNetworkWidth
    preferredHeight: (root.compactMode ? theme.quickCompactHeight : theme.quickNetworkHeight) + edgeHeaderHeight
    color: "transparent"

    onOpenedChanged: {
        if (!opened) {
            selectedWifi = null;
            wifiPassword = "";
        }
        updateScanning();
    }
    onModeChanged: updateScanning()
    Component.onCompleted: updateScanning()
    Component.onDestruction: if (root.network) root.network.setScanning(root.scanOwner, "")



    DockFrame {
        id: panel
        theme: root.theme
        width: root.preferredWidth
        height: root.preferredHeight
        focus: true
        Keys.onEscapePressed: root.opened = false


        ColumnLayout {
            anchors {
                fill: parent
                margins: root.theme.panelPadding
                topMargin: root.theme.panelPadding + root.edgeHeaderHeight
            }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: root.theme.spaceMedium

                Text {
                    Layout.fillWidth: true
                    text: root.panelTitle
                    color: root.theme.text
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1; bold: true }
                }

                IconButton {
                    visible: root.mode === "audio"
                    theme: root.theme
                    icon: root.sinkAudio && root.sinkAudio.muted ? "󰝟" : "󰕾"
                    active: root.sinkAudio && root.sinkAudio.muted
                    onClicked: {
                        if (root.sinkAudio)
                            root.sinkAudio.muted = !root.sinkAudio.muted;
                    }
                }

                IconButton {
                    visible: root.mode === "wifi"
                    theme: root.theme
                    icon: root.network.wifiEnabled ? "󰖩" : "󰖪"
                    active: root.network.wifiEnabled
                    onClicked: root.network.toggleWifi()
                }

                IconButton {
                    visible: root.mode === "bluetooth"
                    theme: root.theme
                    icon: "󰂯"
                    active: root.bluetoothAdapter && root.bluetoothAdapter.enabled
                    onClicked: {
                        if (root.bluetoothAdapter)
                            root.network.toggleBluetooth();
                    }
                }

                IconButton {
                    theme: root.theme
                    icon: "󰅖"
                    onClicked: root.opened = false
                }
            }

            ValueSlider {
                visible: root.mode === "audio"
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 68 : 0
                theme: root.theme
                icon: root.sinkAudio && root.sinkAudio.muted ? "󰝟" : "󰕾"
                label: "Volume do sistema"
                value: root.sinkAudio ? Math.min(1, root.sinkAudio.volume) : 0
                valueText: Math.round(value * 100) + "%"
                onMoved: function(value) {
                    if (root.sinkAudio) {
                        root.sinkAudio.muted = false;
                        root.sinkAudio.volume = value;
                    }
                }
            }

            ValueSlider {
                visible: root.mode === "brightness"
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 68 : 0
                theme: root.theme
                icon: "󰃠"
                label: root.brightness.error ? "Brilho indisponível" : "Brilho da tela"
                value: root.brightness.percent / 100
                valueText: root.brightness.percent + "%"
                onMoved: function(value) {
                    root.brightness.setPercent(value * 100);
                }
            }

            Rectangle {
                visible: root.mode === "wifi" && root.selectedWifi !== null
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 58 : 0
                radius: root.theme.radiusLarge
                color: root.theme.surface
                border.color: root.theme.borderSubtle
                border.width: root.theme.borderThin

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 8
                    }
                    spacing: root.theme.spaceMedium

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: root.theme.radiusMedium
                        color: root.theme.surfaceAlt

                        TextInput {
                            id: passwordInput
                            anchors {
                                fill: parent
                                leftMargin: 10
                                rightMargin: 10
                            }
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.wifiPassword
                            onTextChanged: root.wifiPassword = text
                            echoMode: TextInput.Password
                            color: root.theme.text
                            selectionColor: root.theme.accent
                            selectedTextColor: root.theme.background
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                        }

                        Text {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 10
                            }
                            visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                            text: root.selectedWifi ? "Senha de " + root.selectedWifi.name : "Senha"
                            color: root.theme.textMuted
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 2 }
                        }
                    }

                    IconButton {
                        theme: root.theme
                        icon: "󰌷"
                        active: root.wifiPassword.length > 0
                        onClicked: {
                            if (root.selectedWifi && root.wifiPassword.length > 0) {
                                root.network.connectWithPassword(root.selectedWifi, root.wifiPassword);
                                root.selectedWifi = null;
                                root.wifiPassword = "";
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.mode === "wifi"
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: root.theme.radiusLarge
                color: root.theme.surface
                border.color: root.theme.borderSubtle
                border.width: root.theme.borderThin
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: !root.network.wifiEnabled || wifiModel.values.length === 0
                    text: !root.network.wifiEnabled ? "Wi-Fi desligado" : "Procurando redes…"
                    color: root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }

                ListView {
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    visible: root.network.wifiEnabled && wifiModel.values.length > 0
                    clip: true
                    spacing: root.theme.spaceTiny
                    model: wifiModel
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: wifiRow
                        required property var modelData
                        width: ListView.view.width
                        height: 54
                        radius: root.theme.radiusMedium
                        color: wifiMouse.containsMouse ? root.theme.surfaceAlt : wifiRow.modelData.connected ? root.theme.accentSoft : "transparent"
                        border.color: wifiRow.modelData.connected ? root.theme.accent : "transparent"
                        border.width: root.theme.borderThin

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 10
                            }
                            spacing: 10

                            Text {
                                text: root.wifiIcon(wifiRow.modelData)
                                color: wifiRow.modelData.connected ? root.theme.accent : root.theme.textAlt
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 3 }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: wifiRow.modelData.name
                                    elide: Text.ElideRight
                                    color: root.theme.text
                                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize; bold: wifiRow.modelData.connected }
                                }

                                Text {
                                    text: wifiRow.modelData.stateChanging ? "Conectando…"
                                        : wifiRow.modelData.connected ? "Conectado"
                                        : wifiRow.modelData.known ? "Rede salva"
                                        : wifiRow.modelData.security === WifiSecurityType.Open ? "Rede aberta" : "Senha necessária"
                                    color: root.theme.textMuted
                                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 3 }
                                }
                            }

                            Text {
                                text: wifiRow.modelData.security === WifiSecurityType.Open ? "" : "󰌾"
                                color: root.theme.textMuted
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                            }

                            Text {
                                text: wifiRow.modelData.connected ? "󰅖" : "󰐕"
                                color: wifiRow.modelData.connected ? root.theme.error : root.theme.accent
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize }
                            }
                        }

                        MouseArea {
                            id: wifiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !wifiRow.modelData.stateChanging
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activateWifi(wifiRow.modelData)
                        }

                        Behavior on color { ColorAnimation { duration: root.theme.motionFast } }
                    }
                }
            }

            Rectangle {
                visible: root.mode === "bluetooth"
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: root.theme.radiusLarge
                color: root.theme.surface
                border.color: root.theme.borderSubtle
                border.width: root.theme.borderThin
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: !root.bluetoothAdapter || !root.bluetoothAdapter.enabled || bluetoothModel.values.length === 0
                    text: !root.bluetoothAdapter || !root.bluetoothAdapter.enabled ? "Bluetooth desligado" : "Procurando dispositivos…"
                    color: root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }

                ListView {
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    visible: root.bluetoothAdapter && root.bluetoothAdapter.enabled && bluetoothModel.values.length > 0
                    clip: true
                    spacing: root.theme.spaceTiny
                    model: bluetoothModel
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: bluetoothRow
                        required property var modelData
                        width: ListView.view.width
                        height: 54
                        radius: root.theme.radiusMedium
                        color: bluetoothMouse.containsMouse ? root.theme.surfaceAlt : bluetoothRow.modelData.connected ? root.theme.accentSoft : "transparent"
                        border.color: bluetoothRow.modelData.connected ? root.theme.accent : "transparent"
                        border.width: root.theme.borderThin

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 10
                            }
                            spacing: 10

                            Text {
                                text: "󰂯"
                                color: bluetoothRow.modelData.connected ? root.theme.accent : root.theme.textAlt
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 3 }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: bluetoothRow.modelData.name || bluetoothRow.modelData.deviceName || bluetoothRow.modelData.address
                                    elide: Text.ElideRight
                                    color: root.theme.text
                                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize; bold: bluetoothRow.modelData.connected }
                                }

                                Text {
                                    text: bluetoothRow.modelData.state === BluetoothDeviceState.Connecting ? "Conectando…"
                                        : bluetoothRow.modelData.state === BluetoothDeviceState.Disconnecting ? "Desconectando…"
                                        : bluetoothRow.modelData.connected ? "Conectado"
                                        : bluetoothRow.modelData.pairing ? "Pareando…"
                                        : bluetoothRow.modelData.paired ? "Pareado" : "Disponível"
                                    color: root.theme.textMuted
                                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 3 }
                                }
                            }

                            Text {
                                visible: bluetoothRow.modelData.batteryAvailable
                                text: Math.round(bluetoothRow.modelData.battery * 100) + "%"
                                color: root.theme.textMuted
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 2 }
                            }

                            Text {
                                text: bluetoothRow.modelData.connected ? "󰅖" : "󰐕"
                                color: bluetoothRow.modelData.connected ? root.theme.error : root.theme.accent
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize }
                            }
                        }

                        MouseArea {
                            id: bluetoothMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: bluetoothRow.modelData.state !== BluetoothDeviceState.Connecting
                                && bluetoothRow.modelData.state !== BluetoothDeviceState.Disconnecting
                                && !bluetoothRow.modelData.pairing
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.network.activateBluetooth(bluetoothRow.modelData)
                        }

                        Behavior on color { ColorAnimation { duration: root.theme.motionFast } }
                    }
                }
            }
        }
    }

    DockHeader {
        width: root.width; height: root.edgeHeaderHeight * root.layoutScale
        theme: root.theme
        title: "Archblato · " + root.panelTitle
    }

    ScriptModel {
        id: wifiModel
        values: {
            if (!root.wifiDevice)
                return [];
            return root.wifiDevice.networks.values.slice().sort(function(left, right) {
                if (left.connected !== right.connected)
                    return left.connected ? -1 : 1;
                return right.signalStrength - left.signalStrength;
            });
        }
    }

    ScriptModel {
        id: bluetoothModel
        values: {
            if (!root.bluetoothAdapter)
                return [];
            return root.bluetoothAdapter.devices.values.slice().sort(function(left, right) {
                if (left.connected !== right.connected)
                    return left.connected ? -1 : 1;
                if (left.paired !== right.paired)
                    return left.paired ? -1 : 1;
                return (left.name || left.deviceName).localeCompare(right.name || right.deviceName);
            });
        }
    }
}
