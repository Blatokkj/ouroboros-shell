import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root
    required property var theme
    required property var network
    required property var brightness
    required property var power
    required property var stats
    required property var sinkAudio
    required property var battery
    required property int batteryPercent
    required property bool idleInhibited
    signal idleToggleRequested

    property bool powerConfirmation: false
    readonly property real naturalHeight: panelContent.implicitHeight
    function formatDuration(seconds) {
        if (!seconds || seconds <= 0)
            return "calculando";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "min" : minutes + "min";
    }

    function batteryDetail() {
        if (!battery || !battery.ready)
            return "Bateria indisponível";
        if (battery.state === UPowerDeviceState.Charging)
            return "Carrega em " + formatDuration(battery.timeToFull);
        if (UPower.onBattery)
            return "Restante: " + formatDuration(battery.timeToEmpty);
        return "Conectado à energia";
    }

    ColumnLayout {
        id: panelContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        spacing: root.theme.spaceSmall
        enabled: !root.powerConfirmation
        ModuleCard {
            theme: root.theme
            Layout.fillWidth: true
            Layout.preferredHeight: 54

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }

                Text {
                    text: root.batteryPercent >= 95 ? "󰁹" : root.batteryPercent >= 60 ? "󰁿" : root.batteryPercent >= 30 ? "󰁼" : "󰁺"
                    color: root.theme.accent
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 22
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.batteryPercent + "%"
                        color: root.theme.text
                        font {
                            family: root.theme.fontFamily
                            pixelSize: root.theme.fontSize + 3
                            bold: true
                        }
                    }

                    Text {
                        text: root.batteryDetail()
                        color: root.theme.textMuted
                        font {
                            family: root.theme.fontFamily
                            pixelSize: root.theme.fontSize - 2
                        }
                    }
                }

                Text {
                    text: " " + root.stats.cpuUsage + "%    " + root.stats.memoryUsage + "%    " + root.stats.temperature + "°"
                    color: root.theme.textAlt
                    font {
                        family: root.theme.fontFamily
                        pixelSize: root.theme.fontCaption
                    }
                }
            }
        }

        ModuleCard {
            theme: root.theme
            Layout.fillWidth: true
            implicitHeight: sliders.implicitHeight + root.theme.spaceMedium * 2
            ColumnLayout {
                id: sliders
                anchors { fill: parent; margins: root.theme.spaceMedium }
                spacing: root.theme.spaceSmall
                ValueSlider {
                    compact: true
                    Layout.fillWidth: true
                    theme: root.theme
                    icon: root.sinkAudio && root.sinkAudio.muted ? "󰝟" : "󰕾"
                    label: "Volume"
                    value: root.sinkAudio ? Math.min(1, root.sinkAudio.volume) : 0
                    valueText: Math.round(value * 100) + "%"
                    onMoved: function (value) {
                        if (root.sinkAudio)
                            root.sinkAudio.volume = value;
                    }
                }
        
                ValueSlider {
                    compact: true
                    Layout.fillWidth: true
                    theme: root.theme
                    icon: "󰃠"
                    label: root.brightness.error ? "Brilho indisponível" : "Brilho"
                    value: root.brightness.percent / 100
                    valueText: root.brightness.percent + "%"
                    onMoved: function (value) {
                        root.brightness.setPercent(value * 100);
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 6

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: root.network.icon
                title: "Wi-Fi"
                subtitle: root.network.wifiNetwork ? Math.round(root.network.wifiNetwork.signalStrength * 100) + "% · " + root.network.wifiNetwork.name : root.network.wifiEnabled ? "Disponível" : "Desligado"
                active: root.network.wifiEnabled
                onClicked: root.network.toggleWifi()
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: "󰂯"
                title: "Bluetooth"
                subtitle: root.network.bluetoothAdapter ? root.network.bluetoothAdapter.enabled ? "Ligado" : "Desligado" : "Indisponível"
                active: root.network.bluetoothAdapter ? root.network.bluetoothAdapter.enabled : false
                available: root.network.bluetoothAdapter !== null
                onClicked: root.network.toggleBluetooth()
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: "󰈈"
                title: "Manter ativo"
                subtitle: root.idleInhibited ? "Suspensão bloqueada" : "Suspensão normal"
                active: root.idleInhibited
                onClicked: root.idleToggleRequested()
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: root.power.profileIcon
                checkable: false
                title: root.power.profileLabel
                subtitle: "Perfil de energia"
                active: root.power.performance
                onClicked: root.power.cycleProfile()
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: "󰀝"
                title: "Modo avião"
                subtitle: root.network.airplaneMode ? "Rádios desligados" : "Rádios ativos"
                active: root.network.airplaneMode
                onClicked: root.network.toggleAirplane()
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: "󰤨"
                navigates: true
                title: "Conexões"
                subtitle: "Configurações de rede"
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: root.powerConfirmation
        radius: root.theme.radiusLarge
        onVisibleChanged: if (visible) cancelPower.forceActiveFocus()
        Keys.onEscapePressed: root.powerConfirmation = false
        color: root.theme.panelBackground
        border.color: root.theme.error
        MouseArea {
            anchors.fill: parent
        }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 18
            Text {
                text: "Desligar o computador?"
                color: root.theme.text
                font {
                    family: root.theme.fontFamily
                    pixelSize: 14
                    bold: true
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                PanelButton {
                    theme: root.theme
                    id: cancelPower
                    text: "Cancelar"
                    onClicked: root.powerConfirmation = false
                }
                PanelButton {
                    theme: root.theme
                    text: "Desligar"
                    onClicked: root.power.powerOff()
                }
            }
        }
    }
}
