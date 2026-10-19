pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

BarPill {
    id: root
    required property var hyprMonitor

    interactive: true
    width: workspaceRow.implicitWidth + 16
    height: root.theme.barHeight

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: root.theme.spaceTiny

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
                        NumberAnimation { duration: root.theme.motionPanel; easing.type: Easing.OutCubic }
                    }
                    Behavior on height {
                        NumberAnimation { duration: root.theme.motionPanel; easing.type: Easing.OutCubic }
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
                    NumberAnimation { duration: root.theme.motionPanel; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    ScriptModel {
        id: workspaceModel
        values: Hyprland.workspaces.values.filter(workspace => workspace.id > 0 && workspace.monitor === root.hyprMonitor)
    }

}
