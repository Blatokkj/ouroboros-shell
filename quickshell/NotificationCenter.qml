pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "DesktopUi.js" as Display

Item {
    id: root
    required property var theme
    required property var notifications
    property int entryIndex: 0
    property int textIndex: 0
    property int actionIndex: 0
    readonly property int entryCount: notifications.history.length
    onEntryCountChanged: entryIndex = Math.max(0, Math.min(entryIndex, entryCount - 1))
    readonly property var entry: notifications.history[Math.min(entryIndex, Math.max(0, notifications.history.length - 1))] || null
    readonly property var pages: Display.textPages(entry ? entry.title + (entry.body ? "\n\n" + entry.body : "") : "", Math.max(1, body.width - 2), Math.max(1, Math.floor(body.height / metrics.lineSpacing)), function (char) {
        return metrics.advanceWidth(char);
    })
    onEntryChanged: {
        textIndex = 0;
        actionIndex = 0;
    }
    onVisibleChanged: if (visible)
        entryIndex = 0
    FontMetrics {
        id: metrics
        font.family: root.theme.fontFamily
        font.pixelSize: 11
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.notifications.history.length + " avisos"
                elide: Text.ElideRight
                color: root.theme.textMuted
                font {
                    family: root.theme.fontFamily
                    pixelSize: 10
                }
            }
            PanelButton {
                theme: root.theme
                text: root.notifications.doNotDisturb ? "Silenciado" : "Não perturbe"
                active: root.notifications.doNotDisturb
                onClicked: root.notifications.doNotDisturb = !root.notifications.doNotDisturb
            }
            PanelButton {
                theme: root.theme
                text: "Limpar"
                enabled: root.notifications.history.length > 0
                onClicked: root.notifications.clearHistory()
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.theme.surface
            border.color: root.theme.borderSubtle
            radius: 14
            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 5
                visible: root.entry !== null
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.entry ? root.entry.appName : ""
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: root.theme.accent
                        font {
                            family: root.theme.fontFamily
                            pixelSize: 11
                            bold: true
                        }
                    }
                    Text {
                        text: root.entry ? Qt.formatDateTime(new Date(root.entry.timestamp), "dd/MM HH:mm") : ""
                        color: root.theme.textMuted
                        font {
                            family: root.theme.fontFamily
                            pixelSize: 9
                        }
                    }
                    IconButton {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        theme: root.theme
                        icon: "×"
                        accessibleName: "Remover aviso"
                        onClicked: if (root.entry) {
                            const index = root.entryIndex;
                            root.notifications.removeEntry(root.entry.eventKey);
                            root.entryIndex = Math.max(0, Math.min(index, root.notifications.history.length - 1));
                        }
                    }
                }
                Image {
                    id: picture
                    Layout.fillWidth: true
                    Layout.preferredHeight: status === Image.Ready ? 48 : 0
                    visible: status === Image.Ready
                    source: root.entry ? root.entry.image : ""
                    asynchronous: true
                    sourceSize.width: 300
                    sourceSize.height: 96
                    fillMode: Image.PreserveAspectFit
                }
                Text {
                    id: body
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 0
                    text: root.pages[Math.min(root.textIndex, root.pages.length - 1)] || ""
                    textFormat: Text.PlainText
                    wrapMode: Text.NoWrap
                    clip: true
                    color: root.theme.text
                    font: metrics.font
                    lineHeightMode: Text.FixedHeight
                    lineHeight: metrics.lineSpacing
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.pages.length > 1
                    PanelButton {
                        theme: root.theme
                        text: "‹ Texto"
                        enabled: root.textIndex > 0
                        onClicked: root.textIndex--
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: (Math.min(root.textIndex, root.pages.length - 1) + 1) + "/" + root.pages.length
                        color: root.theme.textMuted
                        font {
                            family: root.theme.fontFamily
                            pixelSize: 10
                        }
                    }
                    PanelButton {
                        theme: root.theme
                        text: "Texto ›"
                        enabled: root.textIndex < root.pages.length - 1
                        onClicked: root.textIndex++
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.entry !== null && root.entry.actions.length > 0
                    PanelButton {
                        theme: root.theme
                        text: "‹"
                        visible: root.entry !== null && root.entry.actions.length > 1
                        enabled: root.actionIndex > 0
                        onClicked: root.actionIndex--
                    }
                    PanelButton {
                        Layout.fillWidth: true
                        theme: root.theme
                        readonly property var action: root.entry ? root.entry.actions[root.actionIndex] : null
                        text: action ? action.text || "Abrir" : ""
                        onClicked: if (action)
                            root.notifications.invokeAction(root.entry.serverId, action.id)
                    }
                    PanelButton {
                        theme: root.theme
                        text: "›"
                        visible: root.entry !== null && root.entry.actions.length > 1
                        enabled: root.entry !== null && root.actionIndex < root.entry.actions.length - 1
                        onClicked: root.actionIndex++
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                visible: root.entry === null
                spacing: 10
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂜"
                    color: root.theme.accent
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 36
                    }
                }
                Text {
                    text: "Tudo em dia"
                    color: root.theme.text
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 14
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            PanelButton {
                theme: root.theme
                text: "‹ Anterior"
                enabled: root.entryIndex > 0
                onClicked: root.entryIndex--
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.entry ? (Math.min(root.entryIndex, root.notifications.history.length - 1) + 1) + " / " + root.notifications.history.length : "0 / 0"
                color: root.theme.textMuted
                font {
                    family: root.theme.fontFamily
                    pixelSize: 11
                }
            }
            PanelButton {
                theme: root.theme
                text: "Próximo ›"
                enabled: root.entryIndex < root.notifications.history.length - 1
                onClicked: root.entryIndex++
            }
        }
    }
}
