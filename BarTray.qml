pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

BarPill {
    id: root
    required property var trayItems
    required property var barWindow
    visible: root.trayItems.length > 0
    width: visible ? trayRow.implicitWidth + 16 : 0
    height: root.theme.barHeight
    interactive: true

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: root.theme.spaceMedium

        Repeater {
            model: root.trayItems

            delegate: IconImage {
                id: trayIcon
                required property var modelData
                width: root.theme.trayIconSize
                height: root.theme.trayIconSize
                implicitSize: root.theme.trayIconSize
                source: trayIcon.modelData.icon
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton && trayIcon.modelData.hasMenu) {
                            const point = trayIcon.mapToItem(root.barWindow.contentItem, 0, trayIcon.height);
                            trayIcon.modelData.display(root.barWindow, point.x, point.y);
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
