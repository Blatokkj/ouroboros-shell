import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "DesktopUi.js" as Display

Item {
    id: root
    required property var theme
    required property var stats
    required property var sinkAudio
    required property var battery
    required property int batteryPercent
    required property bool idleInhibited
    signal idleToggleRequested

    property bool powerConfirmation: false
    readonly property real naturalHeight: panelContent.implicitHeight
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var wifiDevice: {
        const devices = Networking.devices.values;
        for (let index = 0; index < devices.length; index++) {
            if (devices[index].type === DeviceType.Wifi)
                return devices[index];
        }
        return null;
    }
    readonly property var wifiNetwork: {
        if (!wifiDevice)
            return null;
        const networks = wifiDevice.networks.values;
        for (let index = 0; index < networks.length; index++) {
            if (networks[index].connected)
                return networks[index];
        }
        return null;
    }
    readonly property bool airplaneMode: !Networking.wifiEnabled && (!bluetoothAdapter || !bluetoothAdapter.enabled)

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

    function profileLabel() {
        if (PowerProfiles.profile === PowerProfile.Performance)
            return "Performance";
        if (PowerProfiles.profile === PowerProfile.PowerSaver)
            return "Economia";
        return "Balanceado";
    }

    function cycleProfile() {
        if (PowerProfiles.profile === PowerProfile.PowerSaver)
            PowerProfiles.profile = PowerProfile.Balanced;
        else if (PowerProfiles.profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile)
            PowerProfiles.profile = PowerProfile.Performance;
        else
            PowerProfiles.profile = PowerProfile.PowerSaver;
    }

    ColumnLayout {
        id: panelContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        spacing: 6
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            radius: 22
            color: root.theme.surface
            border.color: root.theme.borderSubtle
            border.width: 1

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
                        pixelSize: 10
                    }
                }
            }
        }

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
            label: "Brilho"
            value: root.stats.brightness / 100
            valueText: root.stats.brightness + "%"
            onMoved: function (value) {
                Quickshell.execDetached(["brightnessctl", "set", Math.round(value * 100) + "%"]);
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
                icon: Display.wifiIcon(Networking.wifiEnabled, root.wifiNetwork !== null, root.wifiNetwork ? root.wifiNetwork.signalStrength : 0, false)
                title: "Wi-Fi"
                subtitle: root.wifiNetwork ? Math.round(root.wifiNetwork.signalStrength * 100) + "% · " + root.wifiNetwork.name : Networking.wifiEnabled ? "Disponível" : "Desligado"
                active: Networking.wifiEnabled
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: "󰂯"
                title: "Bluetooth"
                subtitle: root.bluetoothAdapter ? root.bluetoothAdapter.enabled ? "Ligado" : "Desligado" : "Indisponível"
                active: root.bluetoothAdapter ? root.bluetoothAdapter.enabled : false
                available: root.bluetoothAdapter !== null
                onClicked: root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled
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
                icon: PowerProfiles.profile === PowerProfile.Performance ? "󱐋" : PowerProfiles.profile === PowerProfile.PowerSaver ? "󰌪" : "󰾆"
                title: root.profileLabel()
                subtitle: "Perfil de energia"
                active: PowerProfiles.profile === PowerProfile.Performance
                onClicked: root.cycleProfile()
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: "󰀝"
                title: "Modo avião"
                subtitle: root.airplaneMode ? "Rádios desligados" : "Rádios ativos"
                active: root.airplaneMode
                onClicked: {
                    const enable = root.airplaneMode;
                    Networking.wifiEnabled = enable;
                    if (root.bluetoothAdapter)
                        root.bluetoothAdapter.enabled = enable;
                }
            }

            QuickToggle {
                compact: true
                Layout.fillWidth: true
                theme: root.theme
                icon: "󰤨"
                title: "Conexões"
                subtitle: "Configurações de rede"
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: root.powerConfirmation
        radius: 14
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
                    text: "Cancelar"
                    onClicked: root.powerConfirmation = false
                }
                PanelButton {
                    theme: root.theme
                    text: "Desligar"
                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }
}
