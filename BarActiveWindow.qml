pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

BarPill {
    id: root
    required property var hyprMonitor

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property bool belongsToScreen: {
        if (!toplevel || !root.hyprMonitor)
            return false;
        if (Hyprland.monitors.values.length === 1)
            return true;
        if (toplevel.monitor === root.hyprMonitor)
            return true;
        const state = toplevel.lastIpcObject;
        return state && state.monitor === root.hyprMonitor.id;
    }

    interactive: true
    visible: belongsToScreen && toplevel.title.length > 0
    width: visible ? Math.min(340, Math.max(140, activeTitle.implicitWidth + 44)) : 0
    height: root.theme.barHeight

    Row {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 9

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰖯"
            color: root.theme.accent
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize }
        }

        Text {
            id: activeTitle
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(292, implicitWidth)
            text: root.toplevel ? root.toplevel.title : ""
            elide: Text.ElideRight
            color: root.theme.textAlt
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
        }
    }

}
