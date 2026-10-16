pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PopupWindow {
    id: root
    required property var barWindow
    required property var theme
    required property var stats
    required property var sinkAudio
    required property var battery
    required property int batteryPercent
    required property bool idleInhibited
    required property var lockController
    required property var notifications
    required property var media
    signal idleToggleRequested
    property string selectedTab: "controls"
    readonly property var tabKeys: ["controls", "music", "notifications", "wallpapers"]
    readonly property bool musicVisible: visible && selectedTab === "music"
    onMusicVisibleChanged: media.setViewActive(barWindow.screen ? barWindow.screen.name : "unknown", musicVisible)
    Component.onDestruction: {
        if (media)
            media.setViewActive(barWindow && barWindow.screen ? barWindow.screen.name : "unknown", false);
    }

    function openTab(tab) {
        if (lockController.locked || notifications.suppressed || !barWindow.screen)
            return;
        selectedTab = tabKeys.includes(tab) ? tab : "controls";
        controlsPage.powerConfirmation = false;
        if (selectedTab === "notifications")
            notifications.openCenter(barWindow.screen.name);
        else
            notifications.closeCenter();
        visible = true;
        panel.forceActiveFocus();
    }
    function toggleTab(tab) {
        if (visible && selectedTab === tab)
            visible = false;
        else
            openTab(tab);
    }

    anchor.window: barWindow
    anchor.rect.x: Math.max(0, barWindow.width - width)
    anchor.rect.y: barWindow.height + 6
    implicitWidth: Math.min(480, barWindow.width - 8)
    implicitHeight: Math.min(480, barWindow.screen ? barWindow.screen.height - 60 : 480)
    color: "transparent"
    grabFocus: true
    visible: false
    onVisibleChanged: {
        if (!visible) {
            controlsPage.powerConfirmation = false;
            if (barWindow.screen && notifications.centerScreenName === barWindow.screen.name)
                notifications.closeCenter();
        }
    }

    // Toast clicks and the existing notifications IPC open this same window.
    Connections {
        target: root.notifications
        function onCenterScreenNameChanged() {
            if (root.barWindow.screen && root.notifications.centerScreenName === root.barWindow.screen.name) {
                root.selectedTab = "notifications";
                controlsPage.powerConfirmation = false;
                root.visible = true;
                panel.forceActiveFocus();
            } else if (root.selectedTab === "notifications") {
                root.visible = false;
            }
        }
    }

    IpcHandler {
        target: "control-center-" + (root.barWindow.screen ? root.barWindow.screen.name : "unknown")
        function open(tab: string): void {
            root.openTab(tab);
        }
        function toggle(): void {
            if (root.visible)
                root.visible = false;
            else
                root.openTab("controls");
        }
        function close(): void {
            root.visible = false;
        }
        function status(): string {
            return JSON.stringify({
                visible: root.visible,
                tab: root.selectedTab,
                musicWatching: root.media.watching,
                width: root.width,
                height: root.height,
                pageHeight: pageArea.height,
                controlsHeight: controlsPage.naturalHeight,
                musicHeight: musicPlayer.implicitHeight,
                wallpaperCount: wallpaperPage.wallpapers.length,
                wallpaperApplying: wallpaperPage.applying
            });
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 22
        color: root.theme.panelBackground
        border.color: root.theme.borderStrong
        focus: true
        Keys.onEscapePressed: root.visible = false
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.98
        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 210
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: "Central de controle"
                        elide: Text.ElideRight
                        color: root.theme.text
                        font {
                            family: root.theme.fontFamily
                            pixelSize: 18
                            bold: true
                        }
                    }
                    Text {
                        text: "Uptime  " + controlsPage.formatDuration(root.stats.uptimeSeconds)
                        color: root.theme.textMuted
                        font {
                            family: root.theme.fontFamily
                            pixelSize: 10
                        }
                    }
                }
                IconButton {
                    theme: root.theme
                    icon: "󰌾"
                    accessibleName: "Bloquear sessão"
                    onClicked: {
                        root.visible = false;
                        root.lockController.lock();
                    }
                }
                IconButton {
                    theme: root.theme
                    icon: ""
                    danger: true
                    active: controlsPage.powerConfirmation
                    accessibleName: "Opções de desligamento"
                    onClicked: {
                        const wasConfirming = controlsPage.powerConfirmation;
                        root.openTab("controls");
                        controlsPage.powerConfirmation = !wasConfirming;
                    }
                }
                IconButton {
                    theme: root.theme
                    icon: "󰅖"
                    accessibleName: "Fechar central de controle"
                    onClicked: root.visible = false
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: root.theme.borderSubtle
                }
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Repeater {
                        model: [
                            {
                                key: "controls",
                                label: "Controles",
                                icon: "󰒓"
                            },
                            {
                                key: "music",
                                label: "Música",
                                icon: "󰎈"
                            },
                            {
                                key: "notifications",
                                label: "Notificações",
                                icon: "󰂚"
                            },
                            {
                                key: "wallpapers",
                                label: "Wallpapers",
                                icon: "󰸉"
                            }
                        ]
                        delegate: Item {
                            id: tab
                            required property var modelData
                            readonly property bool selected: root.selectedTab === modelData.key
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            activeFocusOnTab: true
                            Accessible.role: Accessible.PageTab
                            Accessible.name: modelData.label
                            Accessible.onPressAction: root.openTab(modelData.key)
                            Keys.onReturnPressed: root.openTab(modelData.key)
                            Keys.onSpacePressed: root.openTab(modelData.key)
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: tabMouse.containsMouse || tab.activeFocus ? root.theme.surfaceAlt : "transparent"
                                opacity: 0.6
                            }
                            Column {
                                anchors.centerIn: parent
                                spacing: 3
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: tab.modelData.icon
                                    color: tab.selected ? root.theme.accent : root.theme.textMuted
                                    font {
                                        family: root.theme.fontFamily
                                        pixelSize: 19
                                    }
                                }
                                Text {
                                    width: Math.max(0, tab.width - 4)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: tab.modelData.label + (tab.modelData.key === "notifications" && root.notifications.unreadCount > 0 ? " · " + root.notifications.unreadCount : "")
                                    color: tab.selected ? root.theme.text : root.theme.textMuted
                                    font {
                                        family: root.theme.fontFamily
                                        pixelSize: 11
                                    }
                                }
                            }
                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openTab(tab.modelData.key)
                            }
                        }
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width / root.tabKeys.length - 16
                    x: root.tabKeys.indexOf(root.selectedTab) * parent.width / root.tabKeys.length + 8
                    height: 2
                    radius: 1
                    color: root.theme.accent
                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Item {
                id: pageArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ControlPage {
                    id: controlsPage
                    anchors.fill: parent
                    visible: root.selectedTab === "controls"
                    theme: root.theme
                    stats: root.stats
                    sinkAudio: root.sinkAudio
                    battery: root.battery
                    batteryPercent: root.batteryPercent
                    idleInhibited: root.idleInhibited
                    onIdleToggleRequested: root.idleToggleRequested()
                }
                NotificationCenter {
                    anchors.fill: parent
                    visible: root.selectedTab === "notifications"
                    theme: root.theme
                    notifications: root.notifications
                }
                MediaPlayerExpanded {
                    id: musicPlayer
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    visible: root.selectedTab === "music"
                    theme: root.theme
                    media: root.media
                }
                WallpaperPicker {
                    id: wallpaperPage
                    anchors.fill: parent
                    visible: root.selectedTab === "wallpapers"
                    theme: root.theme
                }
            }
        }
    }
}
