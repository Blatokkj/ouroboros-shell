// Pure helpers shared by QML and the regression tests.
function upsert(entries, item, limit) {
    return [item].concat(entries.filter(function(entry) {
        return entry.eventKey !== item.eventKey;
    })).slice(0, limit);
}

function markRead(entries) {
    return entries.map(function(entry) { return Object.assign({}, entry, { unread: false }); });
}

function preferredPlayer(player) {
    return /pear|youtube[\s_.-]*music|ytmusic/i.test(
        [player.identity, player.desktopEntry, player.dbusName].join(" "));
}

function selectPlayer(players, selectedName) {
    return players.find(function(p) { return p.dbusName === selectedName; })
        || players.find(function(p) { return preferredPlayer(p) && p.isPlaying; })
        || players.find(preferredPlayer)
        || players.find(function(p) { return p.isPlaying; })
        || players[0] || null;
}

function timeLabel(seconds) {
    if (!Number.isFinite(seconds) || seconds < 0) return "--:--";
    const value = Math.floor(seconds);
    return (value >= 3600 ? Math.floor(value / 3600) + ":" : "")
        + (value >= 3600 ? String(Math.floor(value / 60) % 60).padStart(2, "0") : Math.floor(value / 60))
        + ":" + String(value % 60).padStart(2, "0");
}
