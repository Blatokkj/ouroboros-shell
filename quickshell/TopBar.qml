pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "DesktopUi.js" as Display
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    required property var stats
    required property var theme
    required property var lockController
    required property var notifications
    required property var media

    property bool idleInhibited: false
    readonly property var hyprMonitor: root.screen ? Hyprland.monitorFor(root.screen) : null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: root.sink ? root.sink.audio : null
    readonly property int volumePercent: root.sinkAudio ? Math.round(root.sinkAudio.volume * 100) : 0
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryVisible: root.battery.ready && root.battery.isLaptopBattery
    readonly property int batteryPercent: Math.round(root.battery.percentage * 100)
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
    readonly property var mediaPlayer: media.player
    readonly property var trayItems: SystemTray.items.values.filter(item => item.id !== "nm-applet")
    readonly property bool wiredConnected: Networking.devices.values.some(device => device.type === DeviceType.Wired && device.connected)
    readonly property string networkIcon: Display.wifiIcon(Networking.wifiEnabled, wifiNetwork !== null,
        wifiNetwork ? wifiNetwork.signalStrength : 0, wiredConnected)
    readonly property bool networkLimited: (wifiNetwork !== null || wiredConnected) && Networking.canCheckConnectivity
        && Networking.connectivityCheckEnabled && Networking.connectivity !== NetworkConnectivity.Full

    function openMusic() {
        calendarPopup.visible = false;
        quickSettings.visible = false;
        controlCenter.toggleTab("music");
    }

    function audioIcon() {
        if (!root.sinkAudio || root.sinkAudio.muted)
            return "󰝟";
        if (root.volumePercent < 34)
            return "󰕿";
        if (root.volumePercent < 67)
            return "󰖀";
        return "󰕾";
    }

    function batteryIcon() {
        if (root.battery.state === UPowerDeviceState.Charging)
            return "󰂄";
        if (root.batteryPercent < 15)
            return "󰁺";
        if (root.batteryPercent < 35)
            return "󰁼";
        if (root.batteryPercent < 60)
            return "󰁾";
        if (root.batteryPercent < 85)
            return "󰂀";
        return "󰁹";
    }

    function openQuickPanel(panelMode, item) {
        notifications.closeCenter();
        controlCenter.visible = false;
        calendarPopup.visible = false;
        const centerX = rightSection.x + systemPill.x + systemRow.x + item.x + item.width / 2;
        quickSettings.openFor(panelMode, centerX);
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 4
        left: 8
        right: 8
    }

    implicitHeight: 34
    exclusiveZone: 34
    color: "transparent"

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    IdleInhibitor {
        window: root
        enabled: root.idleInhibited
    }

    ScriptModel {
        id: workspaceModel

        values: Hyprland.workspaces.values.filter(function(workspace) {
            return workspace.id > 0 && workspace.monitor === root.hyprMonitor;
        })
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Connections {
        target: controlCenter
        function onVisibleChanged() {
            if (controlCenter.visible) {
                calendarPopup.visible = false;
                quickSettings.visible = false;
            }
        }
    }

    Connections {
        target: root.notifications
        function onCenterScreenNameChanged() {
            if (root.notifications.centerOpen) {
                calendarPopup.visible = false;
                quickSettings.visible = false;
            }
        }
    }

    Connections {
        target: root.lockController
        function onLockedChanged() {
            if (root.lockController.locked) {
                calendarPopup.visible = false;
                controlCenter.visible = false;
                quickSettings.visible = false;
            }
        }
    }

    Item {
        id: barCanvas
        anchors.fill: parent

        Row {
            id: leftSection

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            spacing: 6

            BarPill {
                id: workspacesPill

                theme: root.theme
                interactive: true
                width: workspaceRow.implicitWidth + 16
                height: 34

                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: workspaceModel

                        delegate: Item {
                            id: workspaceButton

                            required property var modelData

                            width: modelData.focused ? 30 : 16
                            height: 22

                            Rectangle {
                                anchors.centerIn: parent
                                width: workspaceButton.modelData.focused ? 26 : 7
                                height: workspaceButton.modelData.focused ? 18 : 7
                                radius: height / 2
                                color: workspaceButton.modelData.urgent ? root.theme.error : workspaceButton.modelData.focused ? root.theme.accent : root.theme.textMuted

                                Behavior on width {
                                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                }
                                Behavior on height {
                                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: workspaceButton.modelData.focused
                                text: workspaceButton.modelData.name
                                color: root.theme.background
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 2; bold: true }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: workspaceButton.modelData.activate()
                                onWheel: function(wheel) {
                                    Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1");
                                }
                            }

                            Behavior on width {
                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }

            BarPill {
                id: activeWindowPill

                readonly property var toplevel: Hyprland.activeToplevel
                readonly property bool belongsToScreen: {
                    if (!toplevel || !root.hyprMonitor)
                        return false;
                    if (Hyprland.monitors.values.length === 1)
                        return true;
                    if (toplevel.monitor === root.hyprMonitor)
                        return true;
                    const state = toplevel.lastIpcObject;
                    return state && state.monitor === root.hyprMonitor.id;
                }

                theme: root.theme
                interactive: true
                visible: belongsToScreen && toplevel.title.length > 0
                width: visible ? Math.min(340, Math.max(140, activeTitle.implicitWidth + 44)) : 0
                height: 34

                Row {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 9

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖯"
                        color: root.theme.accent
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize }
                    }

                    Text {
                        id: activeTitle
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(292, implicitWidth)
                        text: activeWindowPill.toplevel ? activeWindowPill.toplevel.title : ""
                        elide: Text.ElideRight
                        color: root.theme.textAlt
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                    }
                }
            }
        }

        BarPill {
            id: clockPill

            anchors.centerIn: parent
            theme: root.theme
            interactive: true
            width: 200
            height: 34

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clock.date.toLocaleString(Qt.locale("pt_BR"), "ddd, dd MMM")
                    color: root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 18
                    color: root.theme.borderStrong
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: root.theme.text
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1; bold: true }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.notifications.closeCenter();
                    controlCenter.visible = false;
                    quickSettings.visible = false;
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
            spacing: 6

            BarPill {
                visible: root.mediaPlayer !== null
                width: visible ? 210 : 0
                height: 34
                theme: root.theme
                interactive: true

                RowLayout {
                    anchors { fill: parent; leftMargin: 13; rightMargin: 11 }
                    spacing: 8

                    Text {
                        text: "󰎈"
                        color: root.theme.accent
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 2 }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.mediaPlayer ? (root.mediaPlayer.trackTitle || root.mediaPlayer.identity) : ""
                        elide: Text.ElideRight
                        color: root.theme.textAlt
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                    }

                    Text {
                        text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰏤" : "󰐊"
                        color: root.theme.text
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (!root.mediaPlayer)
                            return;
                        if (mouse.button === Qt.LeftButton)
                            root.openMusic();
                        else if (mouse.button === Qt.RightButton && root.mediaPlayer.canRaise)
                            root.mediaPlayer.raise();
                        else if (mouse.button === Qt.MiddleButton && root.mediaPlayer.canTogglePlaying)
                            root.mediaPlayer.togglePlaying();
                    }
                    onWheel: function(wheel) {
                        if (!root.mediaPlayer)
                            return;
                        if (wheel.angleDelta.y > 0 && root.mediaPlayer.canGoPrevious)
                            root.mediaPlayer.previous();
                        else if (wheel.angleDelta.y < 0 && root.mediaPlayer.canGoNext)
                            root.mediaPlayer.next();
                    }
                }
            }

            BarPill {
                id: metricsPill
                width: 164
                height: 34
                theme: root.theme
                interactive: true

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Item {
                        width: cpuText.implicitWidth
                        height: metricsPill.height

                        Text {
                            id: cpuText
                            anchors.centerIn: parent
                            text: " " + root.stats.cpuUsage + "%"
                            color: cpuHover.containsMouse ? root.theme.accent : root.theme.textAlt
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }

                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        MouseArea {
                            id: cpuHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }

                    Item {
                        width: memoryText.implicitWidth
                        height: metricsPill.height

                        Text {
                            id: memoryText
                            anchors.centerIn: parent
                            text: " " + root.stats.memoryUsage + "%"
                            color: memoryHover.containsMouse ? root.theme.accent : root.theme.textAlt
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }

                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        MouseArea {
                            id: memoryHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: " " + root.stats.temperature + "°"
                        color: root.stats.temperature >= 80 ? root.theme.error : root.theme.textAlt
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                    }
                }
            }

            BarPill {
                id: systemPill
                width: 184
                height: 34
                theme: root.theme
                interactive: true

                Row {
                    id: systemRow
                    anchors.centerIn: parent
                    spacing: 12

                    Item {
                        id: audioItem
                        width: audioText.implicitWidth
                        height: systemPill.height

                        Text {
                            id: audioText
                            anchors.centerIn: parent
                            text: root.audioIcon() + " " + root.volumePercent + "%"
                            color: root.sinkAudio && root.sinkAudio.muted ? root.theme.textMuted : root.theme.textAlt
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    root.openQuickPanel("audio", audioItem);
                                } else if (mouse.button === Qt.MiddleButton && root.sinkAudio) {
                                    root.sinkAudio.muted = !root.sinkAudio.muted;
                                } else if (mouse.button === Qt.RightButton) {
                                    Quickshell.execDetached(["pavucontrol"]);
                                }
                            }
                            onWheel: function(wheel) {
                                if (!root.sinkAudio)
                                    return;
                                const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                root.sinkAudio.volume = Math.max(0, Math.min(1, root.sinkAudio.volume + step));
                            }
                        }
                    }

                    Item {
                        id: brightnessItem
                        width: brightnessText.implicitWidth
                        height: systemPill.height

                        Text {
                            id: brightnessText
                            anchors.centerIn: parent
                            text: "󰃠 " + root.stats.brightness + "%"
                            color: root.theme.textAlt
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openQuickPanel("brightness", brightnessItem)
                            onWheel: function(wheel) {
                                const change = wheel.angleDelta.y > 0 ? "+5%" : "5%-";
                                Quickshell.execDetached(["brightnessctl", "set", change]);
                            }
                        }
                    }

                    Item {
                        id: wifiItem
                        width: wifiText.implicitWidth
                        height: systemPill.height

                        Text {
                            id: wifiText
                            anchors.centerIn: parent
                            text: root.networkIcon
                            color: root.networkLimited ? root.theme.warning : root.wifiNetwork || root.wiredConnected ? root.theme.accent : root.theme.textMuted
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
                        }

                        MouseArea {
                            id: wifiMouse
                            property bool longPressed: false
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: longPressed = false
                            onPressAndHold: {
                                longPressed = true;
                                root.openQuickPanel("wifi", wifiItem);
                            }
                            onClicked: {
                                if (!longPressed)
                                    Networking.wifiEnabled = !Networking.wifiEnabled;
                            }
                        }
                    }

                    Item {
                        id: bluetoothItem
                        visible: root.bluetoothAdapter !== null
                        width: visible ? bluetoothText.implicitWidth : 0
                        height: systemPill.height

                        Text {
                            id: bluetoothText
                            anchors.centerIn: parent
                            text: "󰂯"
                            color: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? root.theme.accent : root.theme.textMuted
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
                        }

                        MouseArea {
                            property bool longPressed: false
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: longPressed = false
                            onPressAndHold: {
                                longPressed = true;
                                root.openQuickPanel("bluetooth", bluetoothItem);
                            }
                            onClicked: {
                                if (!longPressed && root.bluetoothAdapter)
                                    root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled;
                            }
                        }
                    }
                }
            }

            BarPill {
                visible: root.trayItems.length > 0
                width: visible ? trayRow.implicitWidth + 16 : 0
                height: 34
                theme: root.theme
                interactive: true

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: root.trayItems

                        delegate: IconImage {
                            id: trayIcon
                            required property var modelData
                            width: 17
                            height: 17
                            implicitSize: 17
                            source: trayIcon.modelData.icon
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.RightButton && trayIcon.modelData.hasMenu) {
                                        const point = trayIcon.mapToItem(barCanvas, 0, trayIcon.height);
                                        trayIcon.modelData.display(root, point.x, point.y);
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        trayIcon.modelData.secondaryActivate();
                                    } else {
                                        trayIcon.modelData.activate();
                                    }
                                }
                                onWheel: function(wheel) { trayIcon.modelData.scroll(wheel.angleDelta.y, false); }
                            }
                        }
                    }
                }
            }

            BarPill {
                visible: root.batteryVisible
                width: visible ? 82 : 0
                height: 34
                theme: root.theme
                interactive: true

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.batteryIcon()
                        color: UPower.onBattery && root.batteryPercent <= 15 ? root.theme.error : root.theme.accent
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 2 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.batteryPercent + "%"
                        color: root.theme.textAlt
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1; bold: true }
                    }
                }
            }

            IconButton {
                id: controlButton
                theme: root.theme
                icon: "󰣇"
                iconOffsetY: 1
                accessibleName: "Central de controle"
                active: controlCenter.visible || root.idleInhibited
                width: 34
                height: 34
                onClicked: {
                    quickSettings.visible = false;
                    calendarPopup.visible = false;
                    controlCenter.toggleTab("controls");
                }
                onRightClicked: Quickshell.execDetached(["hyprlauncher"])
            }
        }
    }

    PopupWindow {
        id: metricDetails

        readonly property bool showingCpu: cpuHover.containsMouse
        readonly property real metricValue: showingCpu ? root.stats.cpuUsagePrecise : root.stats.memoryUsagePrecise

        anchor.window: root
        anchor.rect.x: Math.max(0, Math.min(root.width - metricDetails.implicitWidth,
            rightSection.x + metricsPill.x + (metricsPill.width - metricDetails.implicitWidth) / 2))
        anchor.rect.y: root.height + 6
        implicitWidth: 310
        implicitHeight: 126
        color: "transparent"
        grabFocus: false
        visible: cpuHover.containsMouse || memoryHover.containsMouse

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: root.theme.panelBackground
            border.color: root.theme.borderStrong
            border.width: 1

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: metricDetails.showingCpu ? "  Processador" : "  Memória RAM"
                        color: root.theme.text
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1; bold: true }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: metricDetails.metricValue.toFixed(2) + "%"
                        color: root.theme.accent
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 2; bold: true }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: metricDetails.showingCpu
                        ? "Carga média (1 min): " + root.stats.loadOne.toFixed(2)
                        : (root.stats.memoryUsedKiB / 1048576).toFixed(2) + " GiB usados de " + (root.stats.memoryTotalKiB / 1048576).toFixed(2) + " GiB"
                    color: root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 7
                    radius: 4
                    color: root.theme.surfaceAlt

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, metricDetails.metricValue / 100))
                        height: parent.height
                        radius: parent.radius
                        color: root.theme.accent

                        Behavior on width {
                            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Text {
                    text: metricDetails.showingCpu ? "Atualização a cada 2 segundos" : "Memória disponível: " + ((root.stats.memoryTotalKiB - root.stats.memoryUsedKiB) / 1048576).toFixed(2) + " GiB"
                    color: root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 3 }
                }
            }
        }
    }

    CalendarPopup {
        id: calendarPopup
        barWindow: root
        theme: root.theme
    }

    QuickSettingsPopup {
        id: quickSettings
        barWindow: root
        theme: root.theme
        stats: root.stats
        sinkAudio: root.sinkAudio
        wifiDevice: root.wifiDevice
        bluetoothAdapter: root.bluetoothAdapter
    }

    ControlCenter {
        id: controlCenter
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
    }
}
