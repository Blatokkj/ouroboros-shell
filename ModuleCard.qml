import QtQuick

// Shared visual shell only; each module owns its layout and behavior.
Rectangle {
    required property var theme
    radius: theme.radiusLarge
    color: theme.surface
    border.color: theme.borderSubtle
    border.width: theme.borderThin
}
