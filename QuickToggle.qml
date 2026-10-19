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
    property bool navigates: false
    property bool checkable: !navigates
    activeFocusOnTab: true
    enabled: available
    Accessible.role: checkable ? Accessible.CheckBox : Accessible.Button
    Accessible.name: title
    Accessible.description: subtitle
    Accessible.checkable: checkable
    Accessible.checked: active
    Accessible.onPressAction: activate()
    Accessible.onToggleAction: activate()
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) activate(); }
    Keys.onEnterPressed: event => { if (!event.isAutoRepeat) activate(); }
    Keys.onSpacePressed: event => { if (!event.isAutoRepeat) activate(); }
    function activate() { if (available) clicked(); }
    signal clicked

    implicitHeight: compact ? theme.toggleCompactHeight : theme.toggleHeight
    radius: theme.radiusLarge
    color: active ? theme.accent : mouseArea.containsMouse ? theme.surfaceAlt : theme.surface
    border.color: activeFocus ? theme.text : active ? theme.accent : theme.borderSubtle
    border.width: activeFocus ? theme.borderFocus : theme.borderThin
    opacity: available ? 1 : 0.45
    scale: mouseArea.pressed ? theme.pressedScale : mouseArea.containsMouse ? theme.hoverScale : 1

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
                pixelSize: root.compact ? root.theme.iconMedium : root.theme.iconLarge
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
                    pixelSize: root.compact ? root.theme.fontSmall : root.theme.fontSize
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
            visible: root.navigates
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
        onClicked: { root.forceActiveFocus(); root.activate(); }
    }

    Behavior on color {
        ColorAnimation { duration: root.theme.motionFast; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: root.theme.motionFast; easing.type: Easing.OutCubic }
    }
}
