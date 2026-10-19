import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    required property var stats
    // Optimistic feedback remains visible until a fresh hardware sample arrives.
    readonly property int percent: pending >= 0 ? pending : stats.brightness
    property int pending: -1
    property int revision: 0
    property int appliedRevision: 0
    property string error: ""
    function setPercent(value) {
        if (!Number.isFinite(value)) return;
        pending = Math.max(1, Math.min(100, Math.round(value)));
        revision++;
        debounce.restart();
    }
    Timer {
        id: debounce
        interval: 120
        onTriggered: {
            if (writer.running) return; // Its exit schedules the newest request.
            root.appliedRevision = root.revision;
            writer.command = ["brightnessctl", "set", root.pending + "%"];
            writer.running = true;
        }
    }
    Process {
        id: writer
        onExited: function(code) {
            root.error = code === 0 ? "" : "Não foi possível ajustar o brilho";
            if (root.appliedRevision !== root.revision) debounce.restart();
            else {
                root.stats.refresh();
                settle.restart();
            }
        }
    }
    Timer {
        id: settle
        interval: 2300
        onTriggered: if (!writer.running && !debounce.running) root.pending = -1
    }
}
