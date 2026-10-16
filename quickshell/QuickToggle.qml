import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool available: true
    property bool compact: false
    signal clicked

    implicitHeight: compact ? 52 : 72
    radius: 22
    color: active ? theme.accent : mouseArea.containsMouse ? theme.surfaceAlt : theme.surface
    border.color: active ? theme.accent : theme.borderSubtle
    border.width: 1
    opacity: available ? 1 : 0.45
    scale: mouseArea.pressed ? 0.985 : mouseArea.containsMouse ? 1.015 : 1

    RowLayout {
        anchors {
            fill: parent
            leftMargin: root.compact ? 10 : 16
            rightMargin: root.compact ? 8 : 14
        }
        spacing: root.compact ? 7 : 12

        Text {
            text: root.icon
            color: root.active ? root.theme.background : root.theme.accent
            font {
                family: root.theme.fontFamily
                pixelSize: root.compact ? 18 : 22
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: root.active ? root.theme.background : root.theme.text
                font {
                    family: root.theme.fontFamily
                    pixelSize: root.compact ? 11 : root.theme.fontSize
                    bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.subtitle
                elide: Text.ElideRight
                color: root.active ? Qt.rgba(root.theme.background.r, root.theme.background.g, root.theme.background.b, 0.72) : root.theme.textMuted
                font {
                    family: root.theme.fontFamily
                    pixelSize: root.compact ? 9 : root.theme.fontSize - 2
                }
            }
        }

        Text {
            text: "󰅂"
            color: root.active ? root.theme.background : root.theme.textMuted
            font {
                family: root.theme.fontFamily
                pixelSize: root.theme.fontSize
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
    }
}
