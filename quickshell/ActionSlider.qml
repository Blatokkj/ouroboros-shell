import QtQuick

// Keeps the drag draft separate from live backend updates, including on release.
Item {
    id: root
    required property var theme
    property real value: 0
    property real stepSize: 0.02
    property string accessibleName: ""
    property real draft: 0
    readonly property real displayedValue: mouse.pressed ? draft : Math.max(0, Math.min(1, value))
    signal started
    signal previewed(real value)
    signal committed(real value)
    implicitHeight: 28
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName
    function updateDraft(x) {
        draft = Math.max(0, Math.min(1, (x - 7) / Math.max(1, width - 14)));
        previewed(draft);
    }
    function step(direction) {
        started();
        draft = Math.max(0, Math.min(1, value + direction * stepSize));
        committed(draft);
    }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: 7
        }
        height: 4
        radius: 2
        color: root.theme.surfaceAlt
        Rectangle {
            width: parent.width * root.displayedValue
            height: parent.height
            radius: 2
            color: root.theme.accent
        }
    }
    Rectangle {
        x: 1 + (parent.width - 14) * root.displayedValue
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: 6
        color: root.theme.text
        border.width: root.activeFocus ? 2 : 0
        border.color: root.theme.accent
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => {
            root.started();
            root.updateDraft(event.x);
        }
        onPositionChanged: event => {
            if (pressed)
                root.updateDraft(event.x);
        }
        onReleased: event => {
            root.updateDraft(event.x);
            root.committed(root.draft);
        }
    }
}
