pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var stats
    required property var theme
    required property var lockController
    required property var notifications
    required property var network
    required property var brightness
    required property var power
    required property var media
    required property var profile

    property bool idleInhibited: false
    readonly property date clockDate: clock.date
    readonly property var hyprMonitor: root.screen ? Hyprland.monitorFor(root.screen) : null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: root.sink ? root.sink.audio : null
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryVisible: root.battery.ready && root.battery.isLaptopBattery
    readonly property int batteryPercent: Math.round(root.battery.percentage * 100)
    readonly property var mediaPlayer: media.player
    readonly property var trayItems: SystemTray.items.values.filter(item => item.id !== "nm-applet")

    function openMusic() {
        centerPopup.toggleTab("music");
    }

    function openQuickPanel(panelMode, item) {
        const centerX = item.mapToItem(barCanvas, item.width / 2, 0).x;
        settingsPopup.openFor(panelMode, centerX);
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 0
        left: 8
        right: 8
    }

    // Surface starts at the physical edge; pills retain their original 4 px inset.
    implicitHeight: root.theme.barHeight + root.theme.spaceTiny
    exclusiveZone: implicitHeight
    color: "transparent"

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    IdleInhibitor {
        window: root
        enabled: root.idleInhibited
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PanelCoordinator {
        controlCenter: centerPopup
        calendar: calendarPopup
        quickSettings: settingsPopup
        lockController: root.lockController
    }

    Item {
        id: barCanvas
        anchors.fill: parent
        anchors.topMargin: root.theme.spaceTiny

        Row {
            id: leftSection

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            spacing: root.theme.spaceSmall

            BarWorkspaces { theme: root.theme; hyprMonitor: root.hyprMonitor }

            BarActiveWindow { theme: root.theme; hyprMonitor: root.hyprMonitor }
        }

        BarPill {
            id: clockPill
            visible: !centerPopup.visible && !calendarPopup.visible

            anchors.centerIn: parent
            theme: root.theme
            interactive: true
            width: 200
            height: root.theme.barHeight

            ClockLabel {
                anchors.centerIn: parent
                theme: root.theme
                date: root.clockDate
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    calendarPopup.toggle();
                }
            }
        }

        Row {
            id: rightSection

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: root.theme.spaceSmall

            BarMedia { theme: root.theme; mediaPlayer: root.mediaPlayer; onOpenRequested: root.openMusic() }

            BarMetrics {
                theme: root.theme
                stats: root.stats
                barWindow: root
                lockController: root.lockController
            }

            BarPill {
                id: systemPill
                width: 184
                height: root.theme.barHeight
                theme: root.theme
                interactive: true

                Row {
                    id: systemRow
                    anchors.centerIn: parent
                    spacing: root.theme.spaceLarge

                    BarAudio {
                        id: audioItem
                        theme: root.theme
                        sinkAudio: root.sinkAudio
                        onOpenRequested: root.openQuickPanel("audio", audioItem)
                    }

                    BarBrightness {
                        id: brightnessItem
                        theme: root.theme
                        brightness: root.brightness
                        onOpenRequested: root.openQuickPanel("brightness", brightnessItem)
                    }

                    BarWifi {
                        id: wifiItem
                        theme: root.theme
                        network: root.network
                        onOpenRequested: root.openQuickPanel("wifi", wifiItem)
                    }

                    BarBluetooth {
                        id: bluetoothItem
                        theme: root.theme
                        network: root.network
                        onOpenRequested: root.openQuickPanel("bluetooth", bluetoothItem)
                    }
                }
            }

            BarTray { theme: root.theme; trayItems: root.trayItems; barWindow: root }

            BarBattery { theme: root.theme; batteryVisible: root.batteryVisible; batteryPercent: root.batteryPercent; battery: root.battery }

            IconButton {
                id: controlButton
                theme: root.theme
                icon: "󰣇"
                iconOffsetY: 1
                accessibleName: "Central de controle"
                active: centerPopup.opened || root.idleInhibited
                width: root.theme.iconButtonSize
                height: root.theme.barHeight
                onClicked: {
                    centerPopup.toggleTab("controls");
                }
                onRightClicked: Quickshell.execDetached(["hyprlauncher"])
            }
        }
    }

    CalendarPopup {
        id: calendarPopup
        barWindow: root
        theme: root.theme
    }

    QuickSettingsPopup {
        id: settingsPopup
        barWindow: root
        theme: root.theme
        sinkAudio: root.sinkAudio
        network: root.network
        brightness: root.brightness
    }

    // Edge-attached central takes over the clock while open.
    ControlCenter {
        id: centerPopup
        profile: root.profile
        network: root.network
        brightness: root.brightness
        power: root.power
        barWindow: root
        theme: root.theme
        stats: root.stats
        sinkAudio: root.sinkAudio
        battery: root.battery
        batteryPercent: root.batteryPercent
        notifications: root.notifications
        media: root.media
        idleInhibited: root.idleInhibited
        lockController: root.lockController
        onIdleToggleRequested: root.idleInhibited = !root.idleInhibited
        onCalendarRequested: calendarPopup.toggle()
    }
}
