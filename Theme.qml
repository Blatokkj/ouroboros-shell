import QtQuick

DesignTokens {
    // Gerado automaticamente por themes/quickshellthemes.sh.
    readonly property color background: wallpaperColors.BACKGROUND || "#0b0b0d"
    readonly property color barBackground: Qt.rgba(background.r, background.g, background.b, 0.75)
    readonly property color surface: wallpaperColors.SURFACE || "#15151a"
    readonly property color surfaceAlt: wallpaperColors.SURFACE_ALT || "#202028"
    readonly property color pillBackground: Qt.rgba(background.r, background.g, background.b, 0.88)
    readonly property color panelBackground: Qt.rgba(background.r, background.g, background.b, 0.97)

    readonly property color accent: wallpaperColors.ACCENT || "#9b5cff"
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.20)
    readonly property color borderSubtle: Qt.rgba(accent.r, accent.g, accent.b, 0.24)
    readonly property color borderStrong: Qt.rgba(accent.r, accent.g, accent.b, 0.55)
    readonly property color text: wallpaperColors.TEXT || "#f5f5f5"
    readonly property color textAlt: wallpaperColors.TEXT_ALT || "#dddddd"
    readonly property color textMuted: wallpaperColors.TEXT_MUTED || "#9b9ba5"

    readonly property color warning: "#ffca6a"
    readonly property color error: "#ff6b81"

    readonly property string fontFamily: "JetBrainsMono NF"
    readonly property int fontSize: 13
    readonly property int radius: 12
    readonly property int borderWidth: 2
}
