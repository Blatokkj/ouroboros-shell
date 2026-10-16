pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    required property var theme
    required property var entry
    required property var notifications
    implicitHeight: content.implicitHeight + 24
    radius: 14
    color: theme.surface
    border.color: entry.level === "error" ? theme.error : theme.borderSubtle

    ColumnLayout {
        id: content
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Image {
                id: appImage
                Layout.preferredWidth: 20; Layout.preferredHeight: 20
                visible: status === Image.Ready
                source: root.entry.appIcon ? (root.entry.appIcon.indexOf(":") >= 0 || root.entry.appIcon.startsWith("/")
                    ? root.entry.appIcon : Quickshell.iconPath(root.entry.appIcon, true)) : ""
                sourceSize.width: 40; sourceSize.height: 40
                fillMode: Image.PreserveAspectFit
            }
            Text {
                visible: appImage.status !== Image.Ready
                text: root.entry.icon
                color: root.theme.accent
                font { family: root.theme.fontFamily; pixelSize: 17 }
            }
            Text {
                Layout.fillWidth: true
                text: root.entry.appName
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: root.theme.textMuted
                font { family: root.theme.fontFamily; pixelSize: 10 }
            }
            Text {
                text: Qt.formatDateTime(new Date(root.entry.timestamp), "dd/MM · HH:mm")
                color: root.theme.textMuted
                font { family: root.theme.fontFamily; pixelSize: 9 }
            }
            IconButton {
                theme: root.theme
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                icon: "×"
                accessibleName: "Remover notificação"
                onClicked: root.notifications.removeEntry(root.entry.eventKey)
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.entry.title
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: root.theme.text
            font { family: root.theme.fontFamily; pixelSize: 12; bold: true }
        }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: root.theme.textMuted
            font { family: root.theme.fontFamily; pixelSize: 11 }
        }
        Image {
            Layout.fillWidth: true
            Layout.preferredHeight: status === Image.Ready ? Math.min(130, implicitHeight) : 0
            visible: status === Image.Ready
            source: root.entry.image
            asynchronous: true
            sourceSize.width: 600
            sourceSize.height: 260
            fillMode: Image.PreserveAspectFit
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root.entry.actions.length > 0
            Repeater {
                model: root.entry.actions
                delegate: PanelButton {
                    required property var modelData
                    theme: root.theme
                    width: Math.min(implicitWidth, parent.width)
                    text: modelData.text || (modelData.id === "default" ? "Abrir" : "Ação")
                    onClicked: root.notifications.invokeAction(root.entry.serverId, modelData.id)
                }
            }
        }
    }
}
