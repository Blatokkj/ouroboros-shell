pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property var theme
    required property var bridge
    property bool library: false
    property int page: 0
    readonly property var entries: library ? bridge.playlists : bridge.queue
    readonly property int pageSize: 5
    readonly property int pages: Math.max(1, Math.ceil(entries.length / pageSize))
    readonly property string message: library ? bridge.libraryError : bridge.error
    onPagesChanged: page = Math.min(page, pages - 1)
    radius: theme.radiusPanel
    color: theme.panelBackground
    border { color: theme.borderSubtle; width: theme.borderThin }
    ColumnLayout {
        anchors { fill: parent; margins: root.theme.panelPadding }
        spacing: root.theme.spaceMedium
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.library ? "Playlists" : "Fila de músicas"
                color: root.theme.text; elide: Text.ElideRight
                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall; bold: true }
            }
            IconButton {
                theme: root.theme; icon: "󰑐"
                Layout.preferredWidth: root.theme.iconButtonCompactSize
                Layout.preferredHeight: root.theme.iconButtonCompactSize
                accessibleName: root.library ? "Atualizar playlists" : "Atualizar fila"
                enabled: root.bridge.ready && !root.bridge.libraryBusy
                onClicked: root.bridge.request(root.library ? "playlists" : "snapshot")
            }
        }
        Text {
            Layout.fillWidth: true
            visible: !root.bridge.ready || root.message !== "" || root.entries.length === 0
            text: !root.bridge.ready ? root.bridge.unavailable : root.message ||
                (root.library && root.bridge.libraryBusy ? "Carregando playlists…" : root.library ? "Nenhuma playlist carregada." : "A fila está vazia.")
            wrapMode: Text.Wrap; textFormat: Text.PlainText
            color: root.theme.textMuted
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontCaption }
        }
        Repeater {
            model: root.entries.slice(root.page * root.pageSize, (root.page + 1) * root.pageSize)
            delegate: Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: root.theme.radiusSmall
                color: modelData.selected || activeFocus || mouse.containsMouse ? root.theme.surfaceAlt : "transparent"
                border.color: activeFocus ? root.theme.accent : "transparent"
                activeFocusOnTab: true
                enabled: root.bridge.ready && !root.bridge.actionBusy
                Accessible.role: Accessible.Button
                Accessible.name: (root.library ? "Reproduzir playlist " : "Reproduzir faixa ") + modelData.title
                function activate() {
                    if (!enabled) return;
                    root.bridge.request(root.library ? "playlist" : "queue", root.library ? {id: modelData.id} : {index: modelData.index, id: modelData.id});
                }
                Accessible.onPressAction: activate()
                Keys.onReturnPressed: activate()
                Keys.onEnterPressed: activate()
                Keys.onSpacePressed: activate()
                RowLayout {
                    anchors { fill: parent; margins: 5 }
                    spacing: root.theme.spaceSmall
                    Rectangle {
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36
                        radius: root.theme.radiusSmall; color: root.theme.surface
                        Image { id: art; anchors.fill: parent; source: row.modelData.art; sourceSize.width: 72; sourceSize.height: 72; asynchronous: true; fillMode: Image.PreserveAspectFit }
                        Text { anchors.centerIn: parent; visible: art.status !== Image.Ready; text: row.modelData.selected ? "󰎈" : root.library ? "󰲸" : "󰝚"; color: root.theme.accent; font.family: root.theme.fontFamily }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3
                        Text { Layout.fillWidth: true; text: row.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: root.theme.text; font { family: root.theme.fontFamily; pixelSize: root.theme.fontCaption; bold: row.modelData.selected || false } }
                        Text { Layout.fillWidth: true; text: (root.library ? row.modelData.subtitle : row.modelData.artist) || ""; textFormat: Text.PlainText; elide: Text.ElideRight; color: root.theme.textMuted; font { family: root.theme.fontFamily; pixelSize: root.theme.fontCaption } }
                    }
                    Text { visible: !root.library; text: row.modelData.duration || ""; color: root.theme.accent; font { family: root.theme.fontFamily; pixelSize: root.theme.fontCaption } }
                }
                MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { row.forceActiveFocus(); row.activate(); } }
            }
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true
            IconButton { theme: root.theme; icon: "󰅁"; enabled: root.page > 0; accessibleName: "Página anterior"; onClicked: root.page-- }
            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: (root.page + 1) + " / " + root.pages; color: root.theme.textMuted; font { family: root.theme.fontFamily; pixelSize: root.theme.fontCaption } }
            IconButton {
                theme: root.theme; icon: "󰅂"
                enabled: root.page < root.pages - 1 || (root.library && root.bridge.more && !root.bridge.libraryBusy)
                accessibleName: "Próxima página"
                onClicked: { if (root.page < root.pages - 1) root.page++; else root.bridge.request("more"); }
            }
        }
    }
}
