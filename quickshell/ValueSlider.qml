import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    property string icon: ""
    property string label: ""
    property string valueText: ""
    property real value: 0
    property bool compact: false
    signal moved(real value)

    implicitHeight: compact ? 40 : 58

    function updateValue(mouseX) {
        const clamped = Math.max(0, Math.min(1, mouseX / trackMouse.width));
        root.moved(clamped);
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Text {
            text: root.icon
            color: root.theme.accent
            font {
                family: root.theme.fontFamily
                pixelSize: root.theme.fontSize + 3
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            color: root.theme.text
            font {
                family: root.theme.fontFamily
                pixelSize: root.compact ? 11 : root.theme.fontSize
                bold: true
            }
        }

        Text {
            text: root.valueText
            color: root.theme.textMuted
            font {
                family: root.theme.fontFamily
                pixelSize: root.theme.fontSize - 1
            }
        }
    }

    Rectangle {
        id: track
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: 8
        }
        height: 6
        radius: 3
        color: root.theme.surfaceAlt

        Rectangle {
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: root.theme.accent

            Behavior on width {
                NumberAnimation { duration: trackMouse.pressed ? 0 : 100 }
            }
        }

        Rectangle {
            id: knob
            x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: root.theme.text
            border.color: root.theme.accent
            border.width: 3
            scale: trackMouse.pressed ? 1.18 : 1

            Behavior on x {
                NumberAnimation { duration: trackMouse.pressed ? 0 : 140; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: trackMouse
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: 30
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) { root.updateValue(mouse.x); }
            onPositionChanged: function(mouse) {
                if (pressed)
                    root.updateValue(mouse.x);
            }
        }
    }
}
