pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

BarPill {
    id: root
    required property var stats
    required property var barWindow
    required property var lockController
    width: 164
    height: root.theme.barHeight
    interactive: true

    Row {
        anchors.centerIn: parent
        spacing: root.theme.spaceLarge

        Item {
            width: cpuText.implicitWidth
            height: root.height

            Text {
                id: cpuText
                anchors.centerIn: parent
                text: " " + root.stats.cpuUsage + "%"
                color: cpuHover.containsMouse ? root.theme.accent : root.theme.textAlt
                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }

                Behavior on color { ColorAnimation { duration: root.theme.motionFast } }
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
            height: root.height

            Text {
                id: memoryText
                anchors.centerIn: parent
                text: " " + root.stats.memoryUsage + "%"
                color: memoryHover.containsMouse ? root.theme.accent : root.theme.textAlt
                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }

                Behavior on color { ColorAnimation { duration: root.theme.motionFast } }
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

    PopupWindow {
        id: metricDetails
    
        readonly property bool showingCpu: cpuHover.containsMouse
        readonly property real metricValue: showingCpu ? root.stats.cpuUsagePrecise : root.stats.memoryUsagePrecise
    
        anchor.window: root.barWindow
        anchor.rect.x: Math.max(0, Math.min(root.barWindow.width - metricDetails.implicitWidth,
            root.mapToItem(root.barWindow.contentItem, 0, 0).x + (root.width - metricDetails.implicitWidth) / 2))
        anchor.rect.y: root.barWindow.height + 6
        implicitWidth: 310
        implicitHeight: 126
        color: "transparent"
        grabFocus: false
        visible: !root.lockController.locked && (cpuHover.containsMouse || memoryHover.containsMouse)
    
        Rectangle {
            anchors.fill: parent
            radius: root.theme.radiusPanel
            color: root.theme.panelBackground
            border.color: root.theme.borderStrong
            border.width: root.theme.borderThin
    
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
                            NumberAnimation { duration: root.theme.motionSlow; easing.type: Easing.OutCubic }
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
}
