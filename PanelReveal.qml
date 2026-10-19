import QtQuick

// Finite, reversible animation. No timers or layers once a panel settles.
QtObject {
    id: root
    required property var target
    required property var theme
    property bool shown: false
    property real progress: 0
    readonly property bool presented: shown || progress > 0
    readonly property bool animating: reveal.running
    property real originX: target.width / 2
    property real originY: 0
    property real layoutScale: 1
    // Attached panels slide their full height through the top clipping edge.
    // Floating popups retain their short fade/scale reveal.
    property bool edgeAttached: false
    property Scale fit: Scale { xScale: root.layoutScale; yScale: root.layoutScale }
    function snapClosed() { reveal.stop(); progress = 0; }
    function animate() {
        reveal.stop();
        reveal.to = shown ? 1 : 0;
        const duration = edgeAttached
            ? (shown ? theme.motionDockEnter : theme.motionDockExit)
            : (shown ? theme.motionPanel : theme.motionExit);
        reveal.duration = Math.max(1, Math.round(duration * Math.abs(reveal.to - progress)));
        reveal.easing.type = shown ? Easing.OutCubic : Easing.InOutCubic;
        reveal.start();
    }
    onShownChanged: animate()
    property Translate slide: Translate {
        y: -(root.edgeAttached ? root.target.height : root.theme.panelTravel) * (1 - root.progress)
    }
    property Scale zoom: Scale {
        origin.x: root.originX
        origin.y: root.originY
        xScale: root.edgeAttached ? 1 : root.theme.panelStartScale + (1 - root.theme.panelStartScale) * root.progress
        yScale: xScale
    }
    // Install the transform objects once. A generic Binding to this list can
    // leave it empty in Qt; the objects' own numeric bindings animate thereafter.
    Component.onCompleted: target.transform = [slide, zoom, fit]
    property Binding alpha: Binding { target: root.target; property: "opacity"; value: root.edgeAttached ? 1 : root.progress }
    property NumberAnimation reveal: NumberAnimation { target: root; property: "progress" }
}
