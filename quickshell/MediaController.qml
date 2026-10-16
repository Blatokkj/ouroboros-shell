import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "NotificationState.js" as State

Scope {
    id: root
    property string selectedName: ""
    property var activeViews: ({})
    readonly property bool watching: Object.keys(activeViews).length > 0
    function setViewActive(name, active) {
        const views = Object.assign({}, activeViews);
        if (active)
            views[name] = true;
        else
            delete views[name];
        activeViews = views;
    }
    readonly property var players: Mpris.players.values
    readonly property var player: State.selectPlayer(players, selectedName)
    readonly property bool isPear: player !== null && State.preferredPlayer(player)
    readonly property string label: player ? (isPear ? "Pear Desktop · YT Music" : player.identity) : "Pear Desktop · YT Music"
    readonly property bool repeatTrack: player !== null && player.loopState === MprisLoopState.Track
    readonly property bool repeatEnabled: player !== null && player.loopState !== MprisLoopState.None
    function openPlayer() {
        if (player && player.canRaise)
            player.raise();
        else if (!player)
            Quickshell.execDetached(["pear-desktop"]);
    }
    function cycleRepeat() {
        if (!player || !player.canControl || !player.loopSupported)
            return;
        player.loopState = player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }
    property real position: 0
    readonly property bool chromiumPlayer: player !== null && player.dbusName.includes(".chromium.")
    readonly property var audioStreams: Pipewire.nodes.values.filter(n => n.isStream && n.audio !== null)
    PwObjectTracker {
        objects: root.audioStreams
    }
    readonly property string processKey: JSON.stringify([player ? player.dbusName : "", audioStreams.map(n => n.ready ? n.properties["application.process.id"] || 0 : 0)])
    property var processMatch: ({
            busName: "",
            pids: []
        })
    readonly property var playerStreams: player && processMatch.busName === player.dbusName ? audioStreams.filter(n => n.ready && n.properties["media.class"] === "Stream/Output/Audio" && processMatch.pids.map(Number).includes(Number(n.properties["application.process.id"]))) : []
    readonly property bool canSetVolume: player !== null && (chromiumPlayer ? playerStreams.length > 0 : player.volumeSupported && player.canControl)
    readonly property real volume: !player ? 0 : chromiumPlayer ? (playerStreams.length ? (playerStreams[0].audio.muted ? 0 : playerStreams[0].audio.volume) : 0) : player.volume
    function setVolume(value, playerName) {
        if (!Number.isFinite(value) || !canSetVolume || player.dbusName !== playerName)
            return false;
        const bounded = Math.max(0, Math.min(1, value));
        if (chromiumPlayer)
            playerStreams.forEach(n => {
                n.audio.volume = bounded;
                n.audio.muted = false;
            });
        else
            player.volume = bounded;
        return true;
    }
    onProcessKeyChanged: resolveDelay.restart()
    Timer {
        id: resolveDelay
        interval: 100
        onTriggered: root.resolveStreams()
    }
    function resolveStreams() {
        if (!player || !chromiumPlayer || resolveProcess.running)
            return;
        resolveProcess.requestKey = processKey;
        resolveProcess.command = ["node", Quickshell.shellDir + "/scripts/player-processes.cjs", player.dbusName, JSON.stringify(audioStreams.map(n => n.ready ? n.properties["application.process.id"] || 0 : 0))];
        resolveProcess.running = true;
    }
    Process {
        id: resolveProcess
        property string requestKey: ""
        stdout: StdioCollector {
            id: resolved
            waitForEnd: true
        }
        onExited: code => {
            if (requestKey !== root.processKey) {
                resolveDelay.restart();
                return;
            }
            try {
                root.processMatch = code === 0 ? JSON.parse(resolved.text) : {
                    busName: "",
                    pids: []
                };
            } catch (_) {
                root.processMatch = {
                    busName: "",
                    pids: []
                };
            }
        }
    }

    function refreshPosition() {
        position = player && player.positionSupported ? Math.max(0, player.position) : 0;
    }
    function cyclePlayer() {
        if (!players.length)
            return;
        const index = players.indexOf(player);
        selectedName = players[(index + 1) % players.length].dbusName;
    }
    function seek(seconds, playerName, trackId) {
        // A track/player may change while the user is dragging the slider.
        if (Number.isFinite(seconds) && player && player.dbusName === playerName && player.uniqueId === trackId && player.canSeek && player.positionSupported && player.lengthSupported) {
            const target = Math.max(0, Math.min(player.length, seconds));
            player.position = target;
            position = target;
            seekRefresh.restart();
            return true;
        }
        return false;
    }
    Timer {
        id: seekRefresh
        interval: 250
        onTriggered: root.refreshPosition()
    }
    onPlayerChanged: refreshPosition()
    onWatchingChanged: if (watching)
        refreshPosition()
    Connections {
        target: root.player
        function onPositionChanged() {
            root.refreshPosition();
        }
        function onPostTrackChanged() {
            root.refreshPosition();
        }
    }
    Timer {
        interval: 500
        repeat: true
        running: root.watching && root.player !== null && root.player.isPlaying
        onTriggered: root.refreshPosition()
    }
    IpcHandler {
        target: "media"
        function status(): string {
            const p = root.player;
            return JSON.stringify(p ? {
                identity: p.identity,
                preferred: root.isPear,
                title: p.trackTitle,
                artist: p.trackArtist,
                art: p.trackArtUrl,
                playing: p.isPlaying,
                position: p.position,
                length: p.length,
                seek: p.canSeek,
                volume: p.volumeSupported,
                volumeValue: root.volume,
                volumeWritable: root.canSetVolume,
                volumeBackend: root.chromiumPlayer ? "pipewire" : "mpris",
                streamIds: root.playerStreams.map(n => n.id),
                dbusName: p.dbusName,
                trackId: p.uniqueId,
                shuffle: p.shuffleSupported,
                loop: p.loopSupported,
                players: root.players.length
            } : {
                players: 0
            });
        }
        function seekTo(seconds: real): bool {
            return root.player ? root.seek(seconds, root.player.dbusName, root.player.uniqueId) : false;
        }
        function volumeTo(value: real): bool {
            return root.player ? root.setVolume(value, root.player.dbusName) : false;
        }
    }
}
