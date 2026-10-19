import QtQuick

Rectangle {
    required property var theme
    color: theme.background
    radius: theme.radiusDock
    topLeftRadius: 0
    topRightRadius: 0
    border.width: theme.borderFocus
    border.color: Qt.rgba(theme.textMuted.r, theme.textMuted.g, theme.textMuted.b, 0.3)
}
