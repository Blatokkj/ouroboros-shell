import QtQuick
import QtQuick.Layouts
import "DesktopUi.js" as Display
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

PopupWindow {
    id: root

    required property var barWindow
    required property var theme
    required property var stats
    required property var sinkAudio
    required property var wifiDevice
    required property var bluetoothAdapter

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
        if (root.visible && root.mode === newMode) {
            root.visible = false;
            return;
        }

        root.mode = newMode;
        root.anchorCenterX = centerX;
        root.selectedWifi = null;
        root.wifiPassword = "";
        root.visible = true;
        root.updateScanning();
    }

    function updateScanning() {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = root.visible && root.mode === "wifi" && Networking.wifiEnabled;
        if (root.bluetoothAdapter)
            root.bluetoothAdapter.discovering = root.visible && root.mode === "bluetooth" && root.bluetoothAdapter.enabled;
    }

    function wifiIcon(network) {
        return Display.wifiIcon(true, true, network.signalStrength, false);
    }

    function activateWifi(network) {
        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) {
            network.connect();
        } else {
            root.selectedWifi = network;
            root.wifiPassword = "";
            Qt.callLater(function() { passwordInput.forceActiveFocus(); });
        }
    }

    function activateBluetooth(device) {
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }

    anchor.window: barWindow
    anchor.rect.x: Math.max(0, Math.min(barWindow.width - root.implicitWidth,
        root.anchorCenterX - root.implicitWidth / 2))
    anchor.rect.y: barWindow.height + 6
    implicitWidth: root.compactMode ? 300 : 390
    implicitHeight: root.compactMode ? 142 : 430
    color: "transparent"
    grabFocus: root.selectedWifi !== null
    visible: false

    onVisibleChanged: {
        if (!visible) {
            selectedWifi = null;
            wifiPassword = "";
        }
        updateScanning();
    }
    onModeChanged: updateScanning()
    Component.onCompleted: updateScanning()
    Component.onDestruction: {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = false;
        if (root.bluetoothAdapter)
            root.bluetoothAdapter.discovering = false;
    }

    Connections {
        target: root.bluetoothAdapter
        function onEnabledChanged() { root.updateScanning(); }
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: root.theme.panelBackground
        border.color: root.theme.borderStrong
        border.width: 1
        scale: root.visible ? 1 : 0.97
        opacity: root.visible ? 1 : 0

        Behavior on scale {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: 8

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
                    icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
                    active: Networking.wifiEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }

                IconButton {
                    visible: root.mode === "bluetooth"
                    theme: root.theme
                    icon: "󰂯"
                    active: root.bluetoothAdapter && root.bluetoothAdapter.enabled
                    onClicked: {
                        if (root.bluetoothAdapter)
                            root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled;
                    }
                }

                IconButton {
                    theme: root.theme
                    icon: "󰅖"
                    onClicked: root.visible = false
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
                label: "Brilho da tela"
                value: root.stats.brightness / 100
                valueText: root.stats.brightness + "%"
                onMoved: function(value) {
                    Quickshell.execDetached(["brightnessctl", "set", Math.round(value * 100) + "%"]);
                }
            }

            Rectangle {
                visible: root.mode === "wifi" && root.selectedWifi !== null
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 58 : 0
                radius: 16
                color: root.theme.surface
                border.color: root.theme.borderSubtle
                border.width: 1

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 8
                    }
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 12
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
                                root.selectedWifi.connectWithPsk(root.wifiPassword);
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
                radius: 16
                color: root.theme.surface
                border.color: root.theme.borderSubtle
                border.width: 1
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: !Networking.wifiEnabled || wifiModel.values.length === 0
                    text: !Networking.wifiEnabled ? "Wi-Fi desligado" : "Procurando redes…"
                    color: root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }

                ListView {
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    visible: Networking.wifiEnabled && wifiModel.values.length > 0
                    clip: true
                    spacing: 4
                    model: wifiModel
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: wifiRow
                        required property var modelData
                        width: ListView.view.width
                        height: 54
                        radius: 13
                        color: wifiMouse.containsMouse ? root.theme.surfaceAlt : wifiRow.modelData.connected ? root.theme.accentSoft : "transparent"
                        border.color: wifiRow.modelData.connected ? root.theme.accent : "transparent"
                        border.width: 1

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

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            Rectangle {
                visible: root.mode === "bluetooth"
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: root.theme.surface
                border.color: root.theme.borderSubtle
                border.width: 1
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
                    spacing: 4
                    model: bluetoothModel
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: bluetoothRow
                        required property var modelData
                        width: ListView.view.width
                        height: 54
                        radius: 13
                        color: bluetoothMouse.containsMouse ? root.theme.surfaceAlt : bluetoothRow.modelData.connected ? root.theme.accentSoft : "transparent"
                        border.color: bluetoothRow.modelData.connected ? root.theme.accent : "transparent"
                        border.width: 1

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
                            onClicked: root.activateBluetooth(bluetoothRow.modelData)
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
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
