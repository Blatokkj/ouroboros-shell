pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

BarPill {
    id: root
    required property bool batteryVisible
    required property int batteryPercent
    required property var battery
    readonly property string icon: battery.state === UPowerDeviceState.Charging ? "󰂄"
        : batteryPercent < 15 ? "󰁺" : batteryPercent < 35 ? "󰁼" : batteryPercent < 60 ? "󰁾" : batteryPercent < 85 ? "󰂀" : "󰁹"
    visible: root.batteryVisible
    width: visible ? 82 : 0
    height: root.theme.barHeight
    interactive: true

    Row {
        anchors.centerIn: parent
        spacing: 7

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: UPower.onBattery && root.batteryPercent <= 15 ? root.theme.error : root.theme.accent
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 2 }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryPercent + "%"
            color: root.theme.textAlt
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1; bold: true }
        }
    }

}
