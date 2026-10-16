import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import "NotificationState.js" as State

Scope {
    id: root
    required property var theme
    property bool suppressed: false
    property bool popupsEnabled: true
    property var targetScreen: null
    property string centerScreenName: ""
    readonly property bool centerOpen: centerScreenName !== ""
    readonly property alias model: notices
    property var history: JSON.parse(storage.entriesJson || "[]")
    onHistoryChanged: storage.entriesJson = JSON.stringify(history)
    property alias doNotDisturb: storage.dnd
    readonly property int unreadCount: history.filter(function(n) { return n.unread; }).length

    PersistentProperties {
        id: storage
        reloadableId: "notification-history"
        // Serialize snapshots: QJSValues cannot cross QML engines on hot reload.
        property string entriesJson: "[]"
        property int nextId: 0
        property bool dnd: false
    }

    function focusedScreen() {
        const monitor = Hyprland.focusedMonitor;
        return Quickshell.screens.find(function(s) { return monitor && s.name === monitor.name; })
            || Quickshell.screens[0] || null;
    }
    function openCenter(screenName) {
        if (suppressed) return;
        const screen = focusedScreen();
        centerScreenName = screenName || (screen ? screen.name : "");
        history = State.markRead(history);
        clearToasts();
    }
    function closeCenter() { centerScreenName = ""; }
    function toggleCenter(screenName) {
        if (centerScreenName === screenName) closeCenter();
        else openCenter(screenName);
    }
    function liveNotification(id) {
        return server.trackedNotifications.values.find(function(n) { return n.id === id; }) || null;
    }
    function record(item, silent) {
        if (!item.transient) {
            const previous = history;
            history = State.upsert(history, item, 100);
            // Bound retained native objects too, not only their visual snapshots.
            previous.forEach(function(old) {
                if (!root.history.some(function(n) { return n.eventKey === old.eventKey; })) {
                    const live = root.liveNotification(old.serverId);
                    if (live) live.expire();
                }
            });
        } else {
            history = history.filter(function(n) { return n.eventKey !== item.eventKey; });
        }
        if (silent || suppressed || doNotDisturb || centerOpen) {
            if (item.transient) Qt.callLater(function() {
                const live = root.liveNotification(item.serverId);
                if (live) live.expire();
            });
            return;
        }
        const toast = { uid: item.uid, eventKey: item.eventKey, title: item.title,
            body: item.body, icon: item.icon, level: item.level, duration: item.duration,
            serverId: item.serverId, transient: item.transient };
        for (let i = 0; i < notices.count; i++) {
            if (notices.get(i).eventKey === item.eventKey) {
                notices.set(i, toast);
                return;
            }
        }
        if (!notices.count) targetScreen = focusedScreen();
        if (notices.count >= 3) dismiss(notices.get(0).uid);
        notices.append(toast);
    }
    function push(event) {
        record({ uid: ++storage.nextId, eventKey: event.key, serverId: -1,
            title: event.title || "", body: event.body || "", icon: event.icon || "󰂚",
            appName: "Sistema", image: "", appIcon: "", actions: [], transient: false,
            level: event.level || "info", timestamp: Date.now(), unread: !centerOpen,
            duration: event.level === "error" ? 10000 : event.level === "warning" ? 7000 : 5000 }, false);
    }
    function receive(notification, restored) {
        const key = "app-" + notification.id;
        const previous = history.find(function(n) { return n.eventKey === key; });
        const imageHint = notification.hints["image-path"] || notification.hints["image_path"] || "";
        const iconHint = imageHint && !imageHint.includes("/") && !imageHint.includes(":") ? imageHint : "";
        // notify-send also uses image-path for themed icons. Those belong in the
        // header, not in a giant thumbnail (missing theme icons use a glyph).
        const picture = imageHint.startsWith("/") ? "file://" + imageHint
            : notification.image.startsWith("image://icon/") ? "" : notification.image;
        record({ uid: ++storage.nextId, eventKey: key, serverId: notification.id,
            title: notification.summary || notification.appName || "Notificação",
            body: notification.body, icon: "󰂚", appName: notification.appName || "Aplicativo",
            image: picture || "", appIcon: notification.appIcon || iconHint,
            actions: notification.actions.map(function(a) { return { id: a.identifier, text: a.text }; }),
            transient: notification.transient,
            level: notification.urgency === NotificationUrgency.Critical ? "error" : "info",
            timestamp: restored && previous ? previous.timestamp : Date.now(),
            unread: restored && previous ? previous.unread : !centerOpen,
            duration: notification.expireTimeout < 0 ? 5000 : Math.round(notification.expireTimeout)
        }, restored);
    }
    function dismiss(uid) {
        for (let i = 0; i < notices.count; i++) {
            const item = notices.get(i);
            if (item.uid === uid) {
                const transientId = item.transient ? item.serverId : -1;
                notices.remove(i);
                const live = liveNotification(transientId);
                if (live) live.expire();
                return;
            }
        }
    }
    function clearToasts() {
        while (notices.count) dismiss(notices.get(0).uid);
    }
    function forget(key) {
        history = history.filter(function(n) { return n.eventKey !== key; });
        for (let i = notices.count - 1; i >= 0; i--)
            if (notices.get(i).eventKey === key) notices.remove(i);
    }
    function removeEntry(key) {
        const item = history.find(function(n) { return n.eventKey === key; });
        const live = item ? liveNotification(item.serverId) : null;
        if (live) live.dismiss();
        forget(key);
    }
    function clearHistory() {
        const entries = history.slice();
        entries.forEach(function(n) { root.removeEntry(n.eventKey); });
        clearToasts();
    }
    function invokeAction(serverId, actionId) {
        const live = liveNotification(serverId);
        if (!live) return;
        const action = live.actions.find(function(a) { return a.identifier === actionId; });
        if (action) action.invoke();
    }

    onSuppressedChanged: if (suppressed) { clearToasts(); closeCenter(); }
    onDoNotDisturbChanged: if (doNotDisturb) clearToasts()
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.centerOpen && !Quickshell.screens.some(function(s) { return s.name === root.centerScreenName; }))
                root.closeCenter();
        }
    }
    ListModel { id: notices }
    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        onNotification: notification => {
            notification.tracked = true;
            root.receive(notification, notification.lastGeneration);
        }
    }
    Instantiator {
        model: server.trackedNotifications
        delegate: Scope {
            id: watcher
            required property var modelData
            Timer {
                id: refresh
                interval: 30
                onTriggered: root.receive(watcher.modelData, false)
            }
            Connections {
                target: watcher.modelData
                function onSummaryChanged() { refresh.restart(); }
                function onBodyChanged() { refresh.restart(); }
                function onImageChanged() { refresh.restart(); }
                function onAppIconChanged() { refresh.restart(); }
                function onAppNameChanged() { refresh.restart(); }
                function onTransientChanged() { refresh.restart(); }
                function onHintsChanged() { refresh.restart(); }
                function onActionsChanged() { refresh.restart(); }
                function onUrgencyChanged() { refresh.restart(); }
                function onExpireTimeoutChanged() { refresh.restart(); }
                function onClosed() { refresh.stop(); root.forget("app-" + watcher.modelData.id); }
            }
        }
    }
    ConnectionMonitor { id: monitor; notifications: root }
    Loader {
        active: root.popupsEnabled
        Component.onCompleted: {
            if (root.popupsEnabled) setSource("NotificationPopup.qml", {
                theme: root.theme, notifications: root,
                screen: Qt.binding(function() { return root.targetScreen; })
            });
        }
    }
    IpcHandler {
        target: "notifications"
        function preview(): void {
            root.push({ key: "preview-network", title: "Internet restabelecida", body: "Prévia · Sua conexão não foi alterada.", icon: "󰖩", level: "info" });
            root.push({ key: "preview-bluetooth", title: "Bluetooth conectado", body: "Prévia · Fones de ouvido", icon: "󰂱", level: "info" });
        }
        function open(): void { root.openCenter(""); }
        function close(): void { root.closeCenter(); }
        function clear(): void { root.clearToasts(); }
        function clearHistory(): void { root.clearHistory(); }
        function count(): int { return notices.count; }
        function status(): string {
            return JSON.stringify({ ready: monitor.ready, network: monitor.networkState,
                bluetoothDevices: Object.keys(monitor.bluetoothState.devices).length,
                suppressed: root.suppressed, doNotDisturb: root.doNotDisturb,
                history: root.history.length, unread: root.unreadCount, centerOpen: root.centerOpen });
        }
    }
}
