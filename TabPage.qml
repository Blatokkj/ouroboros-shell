import QtQuick

// Keep only the outgoing page for the short crossfade, never a screenshot/layer.
Item {
    id: root
    required property var theme
    property bool selected: false
    property int direction: 1
    property real offset: 0
    property bool initialized: false
    opacity: 0
    visible: selected || opacity > 0
    enabled: selected
    transform: Translate { x: root.offset }
    onSelectedChanged: {
        if (!initialized) return;
        transition.stop();
        if (selected && opacity === 0) offset = direction * theme.tabTravel;
        fade.to = selected ? 1 : 0;
        move.to = selected ? 0 : -direction * theme.tabTravel;
        transition.start();
    }
    Component.onCompleted: { initialized = true; opacity = selected ? 1 : 0; }
    ParallelAnimation {
        id: transition
        NumberAnimation { id: fade; target: root; property: "opacity"; duration: root.theme.motionTab; easing.type: Easing.OutCubic }
        NumberAnimation { id: move; target: root; property: "offset"; duration: root.theme.motionTab; easing.type: Easing.OutCubic }
    }
}
