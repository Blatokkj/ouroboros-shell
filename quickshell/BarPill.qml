import QtQuick

Rectangle {
    id: root

    required property var theme
    property bool highlighted: false
    property bool interactive: false

    implicitHeight: 36
    radius: height / 2
    color: highlighted ? theme.accentSoft : interactive && hover.hovered ? theme.surfaceAlt : theme.pillBackground
    border.color: highlighted ? theme.accent : theme.borderSubtle
    border.width: 1
    scale: interactive && hover.hovered ? 1.018 : 1

    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Behavior on color {
        ColorAnimation { duration: 190; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
    }
}
