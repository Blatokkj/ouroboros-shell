import QtQuick
import Quickshell
import Quickshell.Hyprland
import "PanelGeometry.js" as Geometry

// Archblato/Hyprland popup lifecycle. "opened" owns input and system work;
// "visible" only keeps the surface alive for the short exit animation.
PopupWindow {
    id: root
    required property var theme
    required property var barWindow
    property real preferredWidth: theme.controlCenterWidth
    property real preferredHeight: theme.controlCenterHeight
    readonly property real edgeHeaderHeight: edgeAttached ? barWindow.height + barWindow.margins.top : 0
    readonly property real edgeAnchorY: -barWindow.margins.top
    readonly property var fitted: Geometry.fit(preferredWidth, preferredHeight,
        barWindow.width - theme.spaceMedium,
        (barWindow.screen ? barWindow.screen.height : 1080) - (edgeAttached ? 0 : barWindow.height + theme.panelGap) - theme.viewportBottomGap)
    readonly property real layoutScale: fitted.scale
    implicitWidth: fitted.width
    implicitHeight: fitted.height
    required property Item panelItem
    property bool opened: false
    property bool edgeAttached: false
    // Attached panels are already fitted/clamped by us. Compositor slide
    // adjustment otherwise introduces an inset at the physical screen edge.
    anchor.adjustment: edgeAttached ? PopupAdjustment.None : PopupAdjustment.All
    property bool focusSuspended: false
    property var activeMask: null
    property real revealOriginX: panelItem.width / 2
    readonly property real revealProgress: reveal.progress
    readonly property bool animating: reveal.animating
    readonly property bool inputActive: opened && visible && !focusSuspended
    visible: reveal.presented
    grabFocus: false
    color: "transparent"
    // The top edge acts as the slot from which attached content emerges.
    contentItem.clip: edgeAttached
    mask: inputActive ? activeMask : emptyInput

    function dismissImmediately() {
        opened = false;
        reveal.snapClosed();
        focusGrab.active = false;
    }
    function updateFocus() {
        if (!opened || focusSuspended) focusGrab.active = false;
        else Qt.callLater(function() {
            if (root.opened && root.visible && !root.focusSuspended) {
                focusGrab.active = true;
                root.panelItem.forceActiveFocus();
            }
        });
    }
    onOpenedChanged: updateFocus()
    onFocusSuspendedChanged: updateFocus()
    // A compositor-forced close must not leave logical state or scanning alive.
    onVisibleChanged: if (!visible && opened) opened = false
    Region { id: emptyInput; width: 0; height: 0 }
    Binding { target: root.panelItem; property: "enabled"; value: root.inputActive }
    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: if (!root.focusSuspended) root.opened = false
    }
    PanelReveal {
        id: reveal
        target: root.panelItem
        theme: root.theme
        shown: root.opened
        layoutScale: root.layoutScale
        originX: root.revealOriginX
        edgeAttached: root.edgeAttached
    }
}
