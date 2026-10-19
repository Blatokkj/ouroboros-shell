pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

BarPill {
    id: root
    required property var mediaPlayer
    signal openRequested
    visible: root.mediaPlayer !== null
    implicitWidth: visible ? Math.min(root.theme.barMediaMaxWidth,
        Math.ceil(titleMetrics.advanceWidth) + musicIcon.implicitWidth + playbackIcon.implicitWidth
        + 2 * root.theme.spaceMedium + 2 * root.theme.spaceLarge) : 0
    width: implicitWidth
    height: root.theme.barHeight
    interactive: true

    TextMetrics {
        id: titleMetrics
        text: title.text
        font: title.font
    }

    Behavior on width {
        enabled: root.visible
        NumberAnimation { duration: root.theme.motionFast; easing.type: Easing.OutCubic }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: root.theme.spaceLarge; rightMargin: root.theme.spaceLarge }
        spacing: root.theme.spaceMedium

        Text {
            id: musicIcon
            text: "󰎈"
            color: root.theme.accent
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 2 }
        }

        Text {
            id: title
            objectName: "barMediaTitle"
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.mediaPlayer ? (root.mediaPlayer.trackTitle || root.mediaPlayer.identity || "") : ""
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: root.theme.textAlt
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
        }

        Text {
            id: playbackIcon
            text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰏤" : "󰐊"
            color: root.theme.text
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (!root.mediaPlayer)
                return;
            if (mouse.button === Qt.LeftButton)
                root.openRequested();
            else if (mouse.button === Qt.RightButton && root.mediaPlayer.canRaise)
                root.mediaPlayer.raise();
            else if (mouse.button === Qt.MiddleButton && root.mediaPlayer.canTogglePlaying)
                root.mediaPlayer.togglePlaying();
        }
        onWheel: function(wheel) {
            if (!root.mediaPlayer)
                return;
            if (wheel.angleDelta.y > 0 && root.mediaPlayer.canGoPrevious)
                root.mediaPlayer.previous();
            else if (wheel.angleDelta.y < 0 && root.mediaPlayer.canGoNext)
                root.mediaPlayer.next();
        }
    }

}
