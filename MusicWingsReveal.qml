import QtQuick

Item {
    id: root
    required property var theme
    property bool active: false
    property bool suppressed: false
    property int delay: 5000
    property double startedAt: 0
    property bool ready: false
    property real progress: 0
    readonly property bool presented: ready || progress > 0
    readonly property bool interactive: active && ready && !suppressed
    function restart() {
        waitTimer.stop(); ready = false;
        if (active && !suppressed) { startedAt = Date.now(); waitTimer.interval = delay; waitTimer.start(); }
    }
    function animate() {
        motion.stop();
        if (suppressed) { progress = 0; return; }
        motion.to = ready ? 1 : 0;
        motion.duration = Math.max(1, Math.round((ready ? theme.motionSlow : theme.motionExit) * Math.abs(motion.to - progress)));
        motion.start();
    }
    onActiveChanged: restart()
    onSuppressedChanged: { restart(); if (suppressed) { motion.stop(); progress = 0; } }
    onReadyChanged: animate()
    Component.onCompleted: restart()
    Timer {
        id: waitTimer
        onTriggered: {
            if (!root.active || root.suppressed) return;
            const remaining = root.delay - (Date.now() - root.startedAt);
            // Do not reveal early even when a platform timer wakes before its deadline.
            if (remaining > 0) { interval = remaining; start(); }
            else root.ready = true;
        }
    }
    NumberAnimation { id: motion; target: root; property: "progress"; easing.type: Easing.OutCubic }
}
