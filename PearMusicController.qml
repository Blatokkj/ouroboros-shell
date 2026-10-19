import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool active: false
    property int expectedPid: 0
    property var state: ({})
    property var playlists: []
    property bool more: false
    property string error: ""
    property string libraryError: ""
    property bool libraryBusy: false
    property bool actionBusy: false
    property var pending: ({})
    property int sequence: 0
    property int serverPid: 0
    readonly property bool ready: active && socket.connected && serverPid === expectedPid && expectedPid > 0 && state.ready === true
    readonly property bool connected: socket.connected
    readonly property var queue: ready ? state.queue || [] : []
    readonly property string unavailable: expectedPid <= 0 ? "Selecione o Pear Desktop." : "Abra o Pear pelo launcher integrado."

    function reset() {
        state = ({}); playlists = []; more = false; serverPid = 0;
        pending = ({}); libraryBusy = false; actionBusy = false;
        error = ""; libraryError = "";
    }
    function request(action, args) {
        if (!active || !socket.connected || expectedPid <= 0) return false;
        if (action !== "snapshot" && serverPid !== expectedPid) return false;
        if (Object.values(pending).includes(action)) return false;
        const seq = ++sequence;
        const next = Object.assign({}, pending); next[seq] = action; pending = next;
        if (["playlists", "more"].includes(action)) { libraryBusy = true; libraryError = ""; }
        else if (action !== "snapshot") actionBusy = true;
        socket.write(JSON.stringify(Object.assign({}, args || {}, {seq: seq, action: action})) + "\n");
        socket.flush();
        return true;
    }
    function receive(line) {
        try {
            if (line.length > 1024 * 1024) throw new Error("oversized");
            const response = JSON.parse(line);
            const action = pending[response.seq];
            if (!action || response.action !== action) return;
            const next = Object.assign({}, pending); delete next[response.seq]; pending = next;
            libraryBusy = Object.values(pending).some(a => a === "playlists" || a === "more");
            actionBusy = Object.values(pending).some(a => !["snapshot", "playlists", "more"].includes(a));
            serverPid = response.pid;
            if (serverPid !== expectedPid) { state = ({}); playlists = []; return; }
            if (response.error) {
                if (["playlists", "more"].includes(action)) libraryError = response.error;
                else error = response.error;
                return;
            }
            error = "";
            if (action === "snapshot") {
                const first = !state.ready;
                state = response.data;
                if (first && state.ready) request("playlists");
            } else if (["playlists", "more"].includes(action)) {
                const incoming = response.data.playlists || [];
                playlists = action === "more" ? playlists.concat(incoming.filter(p => !playlists.some(old => old.id === p.id))) : incoming;
                more = response.data.more === true;
            } else request("snapshot");
        } catch (_) { error = "Resposta inválida do Pear."; }
    }
    onActiveChanged: {
        if (!active) { socket.connected = false; reset(); }
        else socket.connected = true;
    }
    onExpectedPidChanged: {
        socket.connected = false; reset();
        if (active) socket.connected = true;
    }
    Socket {
        id: socket
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/archblato-pear/music.sock"
        parser: SplitParser { onRead: data => root.receive(data) }
        onConnectionStateChanged: {
            if (connected) root.request("snapshot");
            else root.reset();
        }
    }
    // No polling/processes while the Music tab is closed. One bounded snapshot in flight.
    Timer {
        interval: 1000; repeat: true; running: root.active
        onTriggered: {
            if (!socket.connected) socket.connected = true;
            else root.request("snapshot");
        }
    }
}
