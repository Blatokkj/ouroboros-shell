pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    required property var barWindow
    required property var theme

    property date viewDate: new Date()
    property date selectedDate: new Date()
    readonly property int viewYear: viewDate.getFullYear()
    readonly property int viewMonth: viewDate.getMonth()
    readonly property int firstOffset: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7
    readonly property var locale: Qt.locale("pt_BR")

    function sameDay(left, right) {
        return left.getFullYear() === right.getFullYear()
            && left.getMonth() === right.getMonth()
            && left.getDate() === right.getDate();
    }

    function capitalized(value) {
        return value.length ? value.charAt(0).toUpperCase() + value.slice(1) : value;
    }

    function changeMonth(offset) {
        root.viewDate = new Date(root.viewYear, root.viewMonth + offset, 1);
    }

    function showToday() {
        const today = new Date();
        root.viewDate = today;
        root.selectedDate = today;
    }

    function toggle() {
        if (!visible)
            showToday();
        visible = !visible;
    }

    anchor.window: barWindow
    anchor.rect.x: (barWindow.width - width) / 2
    anchor.rect.y: barWindow.height + 6
    implicitWidth: 380
    implicitHeight: calendarContent.implicitHeight + 32
    color: "transparent"
    grabFocus: false
    visible: false

    SystemClock {
        id: exactClock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: root.theme.panelBackground
        border.color: root.theme.borderStrong
        border.width: 1
        scale: root.visible ? 1 : 0.97
        opacity: root.visible ? 1 : 0

        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: calendarContent
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: Qt.formatDateTime(exactClock.date, "HH:mm:ss")
                        color: root.theme.text
                        font { family: root.theme.fontFamily; pixelSize: 30; bold: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.capitalized(exactClock.date.toLocaleString(root.locale, "dddd, dd 'de' MMMM 'de' yyyy"))
                        wrapMode: Text.WordWrap
                        color: root.theme.textMuted
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                    }
                }

                IconButton {
                    theme: root.theme
                    icon: "󰅖"
                    onClicked: root.visible = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: 15
                color: root.theme.surface
                border.color: root.theme.borderSubtle
                border.width: 1

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 5
                        rightMargin: 5
                    }

                    IconButton {
                        theme: root.theme
                        icon: "󰅁"
                        onClicked: root.changeMonth(-1)
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.capitalized(root.viewDate.toLocaleString(root.locale, "MMMM yyyy"))
                        color: root.theme.text
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1; bold: true }
                    }

                    IconButton {
                        theme: root.theme
                        icon: "󰅂"
                        onClicked: root.changeMonth(1)
                    }
                }
            }

            Grid {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 4

                Repeater {
                    model: ["seg", "ter", "qua", "qui", "sex", "sáb", "dom"]

                    delegate: Item {
                        id: weekdayCell
                        required property string modelData
                        width: (root.width - 32 - 24) / 7
                        height: 22

                        Text {
                            anchors.centerIn: parent
                            text: weekdayCell.modelData
                            color: root.theme.accent
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 3; bold: true }
                        }
                    }
                }
            }

            Grid {
                id: dayGrid
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                Layout.minimumHeight: 260
                columns: 7
                columnSpacing: 4
                rowSpacing: 4

                Repeater {
                    model: 42

                    delegate: Rectangle {
                        id: dayCell
                        required property int index
                        readonly property date cellDate: new Date(root.viewYear, root.viewMonth, index - root.firstOffset + 1)
                        readonly property bool inCurrentMonth: cellDate.getMonth() === root.viewMonth
                        readonly property bool isToday: root.sameDay(cellDate, exactClock.date)
                        readonly property bool isSelected: root.sameDay(cellDate, root.selectedDate)

                        width: (root.width - 32 - 24) / 7
                        height: 40
                        radius: 12
                        color: isSelected ? root.theme.accent : dayMouse.containsMouse ? root.theme.surfaceAlt : isToday ? root.theme.accentSoft : "transparent"
                        border.color: isToday && !isSelected ? root.theme.accent : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.cellDate.getDate()
                            color: dayCell.isSelected ? root.theme.background : dayCell.inCurrentMonth ? root.theme.text : root.theme.textMuted
                            opacity: dayCell.inCurrentMonth ? 1 : 0.45
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize; bold: dayCell.isSelected || dayCell.isToday }
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedDate = dayCell.cellDate;
                                if (!dayCell.inCurrentMonth)
                                    root.viewDate = new Date(dayCell.cellDate.getFullYear(), dayCell.cellDate.getMonth(), 1);
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Selecionado: " + Qt.formatDateTime(root.selectedDate, "dd/MM/yyyy")
                    color: root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 2 }
                }

                Rectangle {
                    implicitWidth: todayLabel.implicitWidth + 22
                    implicitHeight: 32
                    radius: 16
                    color: todayMouse.containsMouse ? root.theme.surfaceAlt : root.theme.accentSoft
                    border.color: root.theme.borderStrong
                    border.width: 1

                    Text {
                        id: todayLabel
                        anchors.centerIn: parent
                        text: "Hoje"
                        color: root.theme.accent
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1; bold: true }
                    }

                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showToday()
                    }
                }
            }
        }
    }
}
