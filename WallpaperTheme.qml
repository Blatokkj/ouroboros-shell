import QtQuick
import Quickshell
import Quickshell.Io

// Update colors without reloading the shell (and without touching the lock lifecycle).
Scope {
    id: root
    required property var theme
    property string path: Quickshell.shellDir + "/wallpaper-colors.json"
    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root.theme.wallpaperColors = {};
        }
        onLoaded: {
            try {
                const data = JSON.parse(text());
                const keys = ["BACKGROUND", "SURFACE", "SURFACE_ALT", "ACCENT", "TEXT", "TEXT_ALT", "TEXT_MUTED"];
                const colors = {};
                for (const key of keys) {
                    if (!/^#[0-9a-fA-F]{6}$/.test(data[key])) throw new Error("Paleta inválida");
                    colors[key] = data[key];
                }
                root.theme.wallpaperColors = colors;
            } catch (error) { console.warn("Paleta de wallpaper inválida; mantendo cores anteriores."); }
        }
    }
}
