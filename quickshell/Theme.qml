import QtQuick

QtObject {
    // Gerado automaticamente por themes/quickshellthemes.sh.
    readonly property color background: "#0b0b0d"
    readonly property color barBackground: Qt.rgba(11 / 255.0, 11 / 255.0, 13 / 255.0, 0.75)
    readonly property color surface: "#15151a"
    readonly property color surfaceAlt: "#202028"
    readonly property color pillBackground: Qt.rgba(background.r, background.g, background.b, 0.88)
    readonly property color panelBackground: Qt.rgba(background.r, background.g, background.b, 0.97)

    readonly property color accent: "#9b5cff"
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.20)
    readonly property color borderSubtle: Qt.rgba(accent.r, accent.g, accent.b, 0.24)
    readonly property color borderStrong: Qt.rgba(accent.r, accent.g, accent.b, 0.55)
    readonly property color text: "#f5f5f5"
    readonly property color textAlt: "#dddddd"
    readonly property color textMuted: "#9b9ba5"

    readonly property color warning: "#ffca6a"
    readonly property color error: "#ff6b81"

    readonly property string fontFamily: "JetBrainsMono NF"
    readonly property int fontSize: 13
    readonly property int radius: 12
    readonly property int borderWidth: 2
}
