pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

AnimatedPopup {
    id: root
    panelItem: canvas
    required property var network
    required property var brightness
    required property var power
    required property var stats
    required property var sinkAudio
    required property var battery
    required property int batteryPercent
    required property bool idleInhibited
    required property var lockController
    required property var notifications
    required property var media
    required property var profile
    focusSuspended: profilePage.choosingPhoto
    signal idleToggleRequested
    signal calendarRequested
    property string selectedTab: "controls"
    property int tabDirection: 1
    function selectTab(key) {
        tabDirection = tabKeys.indexOf(key) >= tabKeys.indexOf(selectedTab) ? 1 : -1;
        selectedTab = key;
    }
    readonly property var tabKeys: ["controls", "music", "notifications", "wallpapers", "profile"]
    readonly property bool musicVisible: opened && selectedTab === "music"
    readonly property real wingWidth: Math.max(0, Math.min(theme.musicWingWidth, (barWindow.width - theme.controlCenterWidth) / 2 - theme.spaceXLarge))
    readonly property bool wingsFit: wingWidth >= 180
    readonly property real wingSpan: wingsFit ? wingWidth + theme.spaceMedium : 0
    preferredWidth: theme.controlCenterWidth + wingSpan * 2
    activeMask: Region {
        item: panel
        Region { item: header }
        Region { item: wings.interactive ? leftWing : null }
        Region { item: wings.interactive ? rightWing : null }
    }
    MusicWingsReveal {
        id: wings
        theme: root.theme
        delay: root.theme.musicWingsDelay
        active: root.musicVisible && root.wingsFit
        suppressed: root.lockController.locked || root.notifications.suppressed
        onInteractiveChanged: if (!interactive && root.opened) canvas.forceActiveFocus()
    }
    onMusicVisibleChanged: media.setViewActive(barWindow.screen ? barWindow.screen.name : "unknown", musicVisible)
    Component.onDestruction: {
        if (media)
            media.setViewActive(barWindow && barWindow.screen ? barWindow.screen.name : "unknown", false);
    }

    function openTab(tab) {
        if (lockController.locked || notifications.suppressed || !barWindow.screen)
            return;
        const wasVisible = opened;
        selectTab(tabKeys.includes(tab) ? tab : "controls");
        controlsPage.powerConfirmation = false;
        if (selectedTab === "notifications")
            notifications.openCenter(barWindow.screen.name);
        else
            notifications.closeCenter();
        opened = true;
        if (!wasVisible) panel.forceActiveFocus();
    }
    function focusTab(index) {
        const next = (index + tabKeys.length) % tabKeys.length;
        openTab(tabKeys[next]);
        tabs.itemAt(next).forceActiveFocus();
    }
    function toggleTab(tab) {
        if (opened && selectedTab === tab)
            opened = false;
        else
            openTab(tab);
    }

    edgeAttached: true
    preferredHeight: theme.controlCenterHeight + edgeHeaderHeight
    anchor.window: barWindow
    anchor.rect.x: Math.max(0, (barWindow.width - width) / 2)
    anchor.rect.y: edgeAnchorY
    color: "transparent"
    onOpenedChanged: {
        if (!opened) {
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
                root.selectTab("notifications");
                controlsPage.powerConfirmation = false;
                root.opened = true;
                panel.forceActiveFocus();
            } else if (root.selectedTab === "notifications") {
                root.opened = false;
            }
        }
    }

    IpcHandler {
        target: "control-center-" + (root.barWindow.screen ? root.barWindow.screen.name : "unknown")
        function open(tab: string): void {
            root.openTab(tab);
        }
        function toggle(): void {
            if (root.opened)
                root.opened = false;
            else
                root.openTab("controls");
        }
        function close(): void {
            root.opened = false;
        }
        function status(): string {
            return JSON.stringify({
                visible: root.opened,
                rendered: root.visible,
                animating: root.animating,
                inputActive: root.inputActive,
                edgeAttached: root.edgeAttached,
                revealProgress: root.revealProgress,
                panelTop: panel.mapToItem(root.contentItem, 0, 0).y,
                anchorX: root.anchor.rect.x,
                anchorY: root.anchor.rect.y,
                surfaceY: root.contentItem.mapToGlobal(0, 0).y,
                barY: root.barWindow.contentItem.mapToGlobal(0, 0).y,
                tab: root.selectedTab,
                musicWatching: root.media.watching,
                wingsReady: wings.ready,
                wingsProgress: wings.progress,
                wingsInteractive: wings.interactive,
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


    FocusScope {
        id: canvas
        width: root.preferredWidth
        height: root.preferredHeight
        focus: true
        Keys.onEscapePressed: root.opened = false
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
                root.focusTab(root.tabKeys.indexOf(root.selectedTab) + (event.modifiers & Qt.ShiftModifier ? -1 : 1));
                event.accepted = true;
            }
        }

        MusicSidePanel {
            id: leftWing
            theme: root.theme; bridge: root.media.library; library: true
            width: root.wingWidth; height: root.theme.musicWingHeight
            x: root.wingSpan - width + root.wingSpan * (1 - wings.progress) - root.theme.spaceMedium
            y: root.edgeHeaderHeight + root.theme.controlCenterHeight - height - root.theme.panelPadding
            opacity: wings.progress
            visible: root.wingsFit && wings.presented
            enabled: root.inputActive && wings.interactive
        }
        MusicSidePanel {
            id: rightWing
            theme: root.theme; bridge: root.media.library
            width: root.wingWidth; height: root.theme.musicWingHeight
            x: root.wingSpan + root.theme.controlCenterWidth + root.theme.spaceMedium - root.wingSpan * (1 - wings.progress)
            y: leftWing.y
            opacity: wings.progress
            visible: root.wingsFit && wings.presented
            enabled: root.inputActive && wings.interactive
        }
        DockFrame {
            id: panel
            theme: root.theme
            x: root.wingSpan
            width: root.theme.controlCenterWidth
            height: root.preferredHeight
            z: 1

        ColumnLayout {
            anchors {
                fill: parent
                margins: root.theme.panelPadding
                topMargin: root.theme.panelPadding + root.edgeHeaderHeight
            }
            spacing: root.theme.spaceMedium
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: "Archblato Shell"
                        elide: Text.ElideRight
                        color: root.theme.text
                        font {
                            family: root.theme.fontFamily
                            pixelSize: root.theme.fontHeading
                            bold: true
                        }
                    }
                    Text {
                        text: root.profile.computerName + " · " + controlsPage.formatDuration(root.stats.uptimeSeconds)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        color: root.theme.textMuted
                        font {
                            family: root.theme.fontFamily
                            pixelSize: root.theme.fontCaption
                        }
                    }
                }
                IconButton {
                    theme: root.theme
                    icon: "󰌾"
                    accessibleName: "Bloquear sessão"
                    onClicked: {
                        root.opened = false;
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
                    onClicked: root.opened = false
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.theme.tabHeight
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
                        id: tabs
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
                                label: "Avisos",
                                icon: "󰂚"
                            },
                            {
                                key: "wallpapers",
                                label: "Wallpapers",
                                icon: "󰸉"
                            },
                            {
                                key: "profile",
                                label: "Perfil",
                                icon: "󰀄"
                            }
                        ]
                        delegate: Item {
                            id: tab
                            required property var modelData
                            required property int index
                            readonly property bool selected: root.selectedTab === modelData.key
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            activeFocusOnTab: true
                            Accessible.role: Accessible.PageTab
                            Accessible.name: modelData.label
                            Accessible.selected: selected
                            Keys.onLeftPressed: root.focusTab(index - 1)
                            Keys.onRightPressed: root.focusTab(index + 1)
                            Accessible.onPressAction: root.openTab(modelData.key)
                            Keys.onReturnPressed: root.openTab(modelData.key)
                            Keys.onEnterPressed: root.openTab(modelData.key)
                            Keys.onSpacePressed: root.openTab(modelData.key)
                            Rectangle {
                                anchors.fill: parent
                                radius: root.theme.radiusSmall
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
                                        pixelSize: root.theme.fontSmall
                                    }
                                }
                            }
                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    tab.forceActiveFocus();
                                    root.openTab(tab.modelData.key);
                                }
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
                            duration: root.theme.motionNormal
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
                TabPage {
                    anchors.fill: parent
                    theme: root.theme
                    direction: root.tabDirection
                    selected: root.selectedTab === "controls"
                    ControlPage {
                        id: controlsPage
                        network: root.network
                        brightness: root.brightness
                        power: root.power
                        anchors.fill: parent
                        theme: root.theme
                        stats: root.stats
                        sinkAudio: root.sinkAudio
                        battery: root.battery
                        batteryPercent: root.batteryPercent
                        idleInhibited: root.idleInhibited
                        onIdleToggleRequested: root.idleToggleRequested()
                    }
                }
                TabPage {
                    anchors.fill: parent
                    theme: root.theme
                    direction: root.tabDirection
                    selected: root.selectedTab === "notifications"
                    NotificationCenter {
                        anchors.fill: parent
                        theme: root.theme
                        notifications: root.notifications
                    }
                }
                TabPage {
                    anchors.fill: parent
                    theme: root.theme
                    direction: root.tabDirection
                    selected: root.selectedTab === "music"
                    MediaPlayerExpanded {
                        id: musicPlayer
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        theme: root.theme
                        media: root.media
                    }
                }
                TabPage {
                    anchors.fill: parent
                    theme: root.theme
                    direction: root.tabDirection
                    selected: root.selectedTab === "profile"
                    ProfilePage {
                        id: profilePage
                        anchors.fill: parent
                        theme: root.theme
                        profile: root.profile
                        active: root.opened && root.selectedTab === "profile"
                    }
                }
                TabPage {
                    anchors.fill: parent
                    theme: root.theme
                    direction: root.tabDirection
                    selected: root.selectedTab === "wallpapers"
                    WallpaperPicker {
                        id: wallpaperPage
                        anchors.fill: parent
                        theme: root.theme
                    }
                }
            }
        }
        }
    }
    DockHeader {
        id: header
        x: root.wingSpan * root.layoutScale
        width: root.theme.controlCenterWidth * root.layoutScale
        height: root.edgeHeaderHeight * root.layoutScale
        theme: root.theme
        showClock: true
        date: root.barWindow.clockDate
        enabled: root.inputActive
        onClicked: root.calendarRequested()
    }
}
