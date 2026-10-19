import QtQuick

Rectangle {
    id: root

    required property var theme
    property bool highlighted: false
    property bool interactive: false

    implicitHeight: theme.barHeight
    radius: height / 2
    color: highlighted ? theme.accentSoft : interactive && hover.hovered ? theme.surfaceAlt : theme.pillBackground
    border.color: highlighted ? theme.accent : theme.borderSubtle
    border.width: root.theme.borderThin
    scale: interactive && hover.hovered ? theme.hoverScale : 1

    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Behavior on color {
        ColorAnimation { duration: root.theme.motionFast; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: root.theme.motionFast; easing.type: Easing.OutCubic }
    }
}
