pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: root
    required property var theme
    required property var profile
    property bool active: false
    property bool choosingPhoto: false
    property string avatarDraft: ""
    property bool submitted: false
    readonly property bool dirty: nameField.text !== profile.displayName
        || computerField.text !== profile.computerName || avatarDraft !== profile.avatar
    readonly property bool photoReady: !avatarDraft || avatarImage.status === Image.Ready
    function pickPhoto() {
        if (profile.saving) return;
        choosingPhoto = true;
        photoDialog.open();
    }
    function cancelPhoto() {
        photoDialog.close();
        choosingPhoto = false;
    }
    function resetDraft() {
        if (!profile) return; // Construction/hot-reload may precede property injection.
        nameField.text = profile.displayName;
        computerField.text = profile.computerName;
        avatarDraft = profile.avatar;
    }
    Component.onCompleted: resetDraft()
    onActiveChanged: {
        if (active && !dirty) resetDraft();
        if (!active && choosingPhoto) cancelPhoto();
    }
    Connections {
        target: root.profile
        function onReadyChanged() { if (root.profile.ready) root.resetDraft(); }
        function onSaved() {
            if (root.submitted || !root.dirty) root.resetDraft();
            root.submitted = false;
        }
    }
    FileDialog {
        id: photoDialog
        objectName: "profilePhotoDialog"
        title: "Foto do perfil — Archblato"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Fotos PNG/JPEG (*.png *.jpg *.jpeg)"]
        onAccepted: { root.avatarDraft = selectedFile.toString(); root.choosingPhoto = false; }
        onRejected: root.choosingPhoto = false
    }
    component EditField: TextField {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        color: root.theme.text
        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize }
        selectionColor: root.theme.accent
        selectedTextColor: root.theme.background
        leftPadding: root.theme.spaceMedium
        rightPadding: root.theme.spaceMedium
        background: Rectangle {
            radius: root.theme.radiusSmall
            color: root.theme.surface
            border.color: parent.activeFocus ? root.theme.accent : root.theme.borderSubtle
        }
    }
    ColumnLayout {
        anchors { fill: parent; margins: 1 }
        spacing: root.theme.spaceMedium
        ModuleCard {
            theme: root.theme
            Layout.fillWidth: true
            Layout.preferredHeight: 86
            RowLayout {
                anchors { fill: parent; margins: root.theme.spaceMedium }
                spacing: root.theme.spaceLarge
                Rectangle {
                    Layout.preferredWidth: 66; Layout.preferredHeight: 66
                    color: root.theme.accentSoft
                    radius: root.theme.radiusMedium
                    clip: true
                    Image {
                        id: avatarImage
                        anchors { fill: parent; margins: 3 }
                        source: root.avatarDraft
                        sourceSize: Qt.size(128,128)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !avatarImage.visible
                        text: (nameField.text.trim().charAt(0) || "B").toUpperCase()
                        color: root.theme.accent
                        font { family: root.theme.fontFamily; pixelSize: 30; bold: true }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: nameField.text || root.profile.displayName
                        textFormat: Text.PlainText; elide: Text.ElideRight
                        color: root.theme.text
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontHeading; bold: true }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.profile.userName + "@" + root.profile.hostName
                        textFormat: Text.PlainText; elide: Text.ElideRight
                        color: root.theme.textMuted
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall }
                    }
                    Text {
                        text: "Arch Linux · Archblato Shell"
                        color: root.theme.textMuted
                        font { family: root.theme.fontFamily; pixelSize: root.theme.fontCaption }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Seu nome"; color: root.theme.textMuted; font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall } }
                EditField { id: nameField; objectName: "profileName"; maximumLength: 60; Accessible.name: "Nome no perfil" }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Apelido do PC"; color: root.theme.textMuted; font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall } }
                EditField { id: computerField; objectName: "profileComputer"; maximumLength: 40; Accessible.name: "Apelido do computador no shell" }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            PanelButton {
                theme: root.theme; text: "Escolher foto"
                enabled: !root.profile.saving
                onClicked: root.pickPhoto()
            }
            PanelButton {
                theme: root.theme; text: "Remover foto"
                enabled: !!root.avatarDraft && !root.profile.saving
                onClicked: root.avatarDraft = ""
            }
            Item { Layout.fillWidth: true }
        }
        Text {
            Layout.fillWidth: true
            text: "A foto e o nome salvos também aparecem no lock. Conta Linux e hostname permanecem iguais. Foto PNG/JPEG."
            wrapMode: Text.WordWrap
            color: root.theme.textMuted
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall }
        }
        Item { Layout.fillHeight: true }
        Text {
            Layout.fillWidth: true
            text: avatarImage.status === Image.Error ? "Não foi possível ler a foto. Escolha outra imagem."
                : root.profile.message || (root.dirty ? "Alterações ainda não salvas." : "Seu perfil fica salvo neste setup.")
            wrapMode: Text.WordWrap
            color: root.profile.error || avatarImage.status === Image.Error ? root.theme.error : root.theme.textMuted
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSmall }
        }
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            PanelButton { objectName: "profileCancel"; theme: root.theme; text: "Cancelar"; enabled: root.dirty && !root.profile.saving; onClicked: root.resetDraft() }
            PanelButton {
                theme: root.theme; text: root.profile.saving ? "Salvando…" : "Salvar"; active: true
                objectName: "profileSave"
                enabled: root.profile.ready && !root.profile.saving && root.dirty && root.photoReady
                onClicked: { root.submitted = root.profile.save(nameField.text,computerField.text,root.avatarDraft); }
            }
        }
    }
}
