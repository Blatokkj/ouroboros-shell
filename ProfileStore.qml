import QtQuick
import Quickshell
import Quickshell.Io
import "ProfileData.js" as Data

Scope {
    id: root
    // Personal data, written only after pressing Save. No system account changes.
    property string storagePath: Quickshell.shellDir + "/profile.json"
    readonly property string userName: Quickshell.env("USER") || "blato"
    property string hostName: ""
    property string displayName: userName
    property string computerName: "White"
    property string avatar: ""
    property bool ready: false
    property bool saving: false
    property string message: ""
    property bool error: false
    property var pending: null
    signal saved
    function apply(data) {
        displayName = data.displayName;
        computerName = data.computerName;
        avatar = data.avatar;
    }
    function save(name, computer, photo) {
        if (!ready || saving) return false;
        try { pending = Data.normalize({displayName:name,computerName:computer,avatar:photo}); }
        catch (e) { message = String(e.message); error = true; return false; }
        saving = true; error = false; message = "Salvando…";
        file.setText(JSON.stringify(pending, null, 2) + "\n");
        return true;
    }
    FileView {
        id: hostname
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.hostName = text().trim()
    }
    FileView {
        id: file
        path: root.storagePath
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try { root.apply(Data.parse(text())); }
            catch (e) { root.message = "Não foi possível ler o perfil: " + e.message; root.error = true; }
            root.ready = true;
        }
        onLoadFailed: error => {
            root.ready = true;
            if (error !== FileViewError.FileNotFound) {
                root.error = true; root.message = "Não foi possível abrir o perfil salvo.";
            }
        }
        onSaved: {
            if (!root.pending) return;
            root.apply(root.pending);
            root.pending = null; root.saving = false; root.error = false;
            root.message = "Perfil salvo.";
            root.saved();
        }
        onSaveFailed: {
            root.pending = null; root.saving = false; root.error = true;
            root.message = "Não foi possível salvar. Seu perfil anterior foi preservado.";
        }
    }
}
