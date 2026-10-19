import QtQuick

Row {
    id: root
    required property var theme
    required property date date
    spacing: 10
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.date.toLocaleString(Qt.locale("pt_BR"), "ddd, dd MMM")
        color: root.theme.textMuted
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1; height: 18
        color: root.theme.borderStrong
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.date, "HH:mm")
        color: root.theme.text
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1; bold: true }
    }
}
