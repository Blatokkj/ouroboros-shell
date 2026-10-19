pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var theme
    required property var notifications

    anchors { top: true; right: true }
    margins { top: theme.barHeight + theme.panelGap + theme.spaceMedium; right: theme.spaceMedium }
    implicitWidth: theme.toastWidth
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "archblato-notifications"
    visible: notifications.model.count > 0 && !notifications.suppressed
    mask: Region { item: stack }

    Column {
        id: stack
        width: parent.width
        spacing: root.theme.spaceSmall
        move: Transition {
            NumberAnimation { properties: "y"; duration: root.theme.motionPanel; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: root.notifications.model

            delegate: Item {
                id: toast
                required property int uid
                required property string title
                required property string body
                required property string icon
                required property string level
                required property int duration
                property bool closing: false
                property real remaining: duration
                readonly property color tint: level === "error" ? root.theme.error : level === "warning" ? root.theme.warning : root.theme.accent
                width: stack.width
                height: card.implicitHeight

                function dismiss() {
                    if (!closing) {
                        closing = true;
                        enterAnimation.stop();
                        exitAnimation.start();
                    }
                }

                onUidChanged: {
                    Qt.callLater(function() {
                        if (!toast)
                            return;
                        enterAnimation.stop();
                        exitAnimation.stop();
                        toast.closing = false;
                        toast.remaining = toast.duration;
                        enterAnimation.start();
                    });
                }

                Timer {
                    property double lastTick: Date.now()
                    interval: 50
                    repeat: true
                    running: toast.duration > 0 && !toast.closing && !hover.hovered && root.visible
                    onRunningChanged: lastTick = Date.now()
                    onTriggered: {
                        const now = Date.now();
                        toast.remaining = Math.max(0, toast.remaining - (now - lastTick));
                        lastTick = now;
                        if (toast.remaining <= 0)
                            toast.dismiss();
                    }
                }

                Rectangle {
                    id: card
                    width: parent.width
                    implicitHeight: Math.max(root.theme.toastMinHeight, content.implicitHeight + root.theme.panelPadding * 2 + root.theme.spaceTiny)
                    height: implicitHeight
                    radius: root.theme.radiusMedium
                    color: root.theme.panelBackground
                    border.color: Qt.rgba(toast.tint.r, toast.tint.g, toast.tint.b, toast.level === "info" ? 0.18 : 0.32)
                    border.width: root.theme.borderThin
                    clip: true
                    enabled: !toast.closing

                    HoverHandler { id: hover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notifications.openCenter(root.screen ? root.screen.name : "")
                    }

                    RowLayout {
                        id: content
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.theme.panelPadding }
                        spacing: root.theme.spaceMedium

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: root.theme.radiusSmall
                            color: Qt.rgba(toast.tint.r, toast.tint.g, toast.tint.b, 0.08)
                            Text {
                                anchors.centerIn: parent
                                text: toast.icon
                                color: toast.tint
                                font { family: root.theme.fontFamily; pixelSize: root.theme.iconSmall }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                Layout.fillWidth: true
                                text: toast.title
                                textFormat: Text.PlainText
                                color: root.theme.text
                                wrapMode: Text.Wrap
                                font { family: root.theme.fontFamily; pixelSize: 12; bold: true }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: toast.body
                                textFormat: Text.PlainText
                                color: root.theme.textMuted
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall }
                            }
                        }

                        IconButton {
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            theme: root.theme
                            color: "transparent"
                            border.color: "transparent"
                            opacity: hover.hovered ? 1 : 0.45
                            icon: "×"
                            accessibleName: "Dispensar notificação"
                            onClicked: toast.dismiss()
                        }
                    }

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 13; rightMargin: 13; bottomMargin: 7 }
                        height: 1
                        visible: toast.duration > 0
                        radius: 1
                        color: root.theme.surfaceAlt
                        Rectangle {
                            width: toast.duration > 0 ? parent.width * Math.max(0, toast.remaining / toast.duration) : 0
                            height: parent.height
                            radius: 1
                            color: Qt.rgba(toast.tint.r, toast.tint.g, toast.tint.b, 0.45)
                            Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.Linear } }
                        }
                    }
                }

                ParallelAnimation {
                    id: enterAnimation
                    NumberAnimation { target: card; property: "x"; from: root.theme.panelTravel; to: 0; duration: root.theme.motionPanel; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: root.theme.motionPanel; easing.type: Easing.OutCubic }
                }
                SequentialAnimation {
                    id: exitAnimation
                    ParallelAnimation {
                        NumberAnimation { target: card; property: "x"; to: root.theme.panelTravel; duration: root.theme.motionExit; easing.type: Easing.InOutCubic }
                        NumberAnimation { target: card; property: "opacity"; to: 0; duration: root.theme.motionExit }
                    }
                    ScriptAction { script: root.notifications.dismiss(toast.uid) }
                }
                Component.onCompleted: enterAnimation.start()
            }
        }
    }
}
