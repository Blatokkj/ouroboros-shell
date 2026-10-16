pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "NotificationState.js" as State

Rectangle {
    id: root
    required property var theme
    required property var media
    readonly property var player: media.player
    implicitHeight: content.implicitHeight + 24
    radius: 16
    color: theme.surface
    border.color: theme.borderSubtle
    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.media.label
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: root.theme.textMuted
                font {
                    family: root.theme.fontFamily
                    pixelSize: 10
                }
            }
            IconButton {
                theme: root.theme
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                icon: "󰒋"
                visible: root.media.players.length > 1
                accessibleName: "Trocar aplicativo"
                onClicked: root.media.cyclePlayer()
            }
            IconButton {
                theme: root.theme
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                icon: "󰏌"
                enabled: !root.player || root.player.canRaise
                opacity: enabled ? 1 : 0.35
                accessibleName: "Abrir player"
                onClicked: root.media.openPlayer()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: 12
                color: root.theme.surfaceAlt
                clip: true
                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    sourceSize.width: 192
                    sourceSize.height: 192
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: "󰎈"
                    color: root.theme.accent
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 40
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackTitle || "Mídia sem título" : "Sua música, por aqui"
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    color: root.theme.text
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 14
                        bold: true
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackArtist || root.player.identity : "Abra uma faixa no Pear / YT Music."
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.theme.textMuted
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 11
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.player ? root.player.trackAlbum : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.theme.textMuted
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 10
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            ActionSlider {
                id: seek
                objectName: "mediaSeekSlider"
                property string dragPlayer: ""
                property int dragTrack: 0
                property real dragLength: 0
                Layout.fillWidth: true
                theme: root.theme
                accessibleName: "Posição da música"
                enabled: root.player !== null && root.player.canSeek && root.player.positionSupported && root.player.lengthSupported && root.player.length > 0
                opacity: enabled ? 1 : 0.35
                value: root.player && root.player.length > 0 ? root.media.position / root.player.length : 0
                stepSize: root.player && root.player.length > 0 ? 5 / root.player.length : 0.02
                onStarted: {
                    dragPlayer = root.player ? root.player.dbusName : "";
                    dragTrack = root.player ? root.player.uniqueId : 0;
                    dragLength = root.player ? root.player.length : 0;
                }
                onCommitted: fraction => root.media.seek(fraction * dragLength, dragPlayer, dragTrack)
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.player && root.player.positionSupported ? State.timeLabel(seek.displayedValue * root.player.length) : "--:--"
                    color: root.theme.textMuted
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 10
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: root.player && root.player.lengthSupported ? State.timeLabel(root.player.length) : "--:--"
                    color: root.theme.textMuted
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 10
                    }
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            IconButton {
                theme: root.theme
                icon: "󰒟"
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                visible: root.player !== null && root.player.shuffleSupported
                enabled: root.player !== null && root.player.canControl
                active: root.player !== null && root.player.shuffle
                accessibleName: "Reprodução aleatória"
                onClicked: root.player.shuffle = !root.player.shuffle
            }
            IconButton {
                theme: root.theme
                icon: "󰒮"
                enabled: root.player !== null && root.player.canGoPrevious
                opacity: enabled ? 1 : 0.3
                accessibleName: "Faixa anterior"
                onClicked: root.player.previous()
            }
            IconButton {
                theme: root.theme
                icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                active: true
                enabled: root.player !== null && root.player.canTogglePlaying
                opacity: enabled ? 1 : 0.3
                accessibleName: root.player && root.player.isPlaying ? "Pausar" : "Reproduzir"
                onClicked: root.player.togglePlaying()
            }
            IconButton {
                theme: root.theme
                icon: "󰒭"
                enabled: root.player !== null && root.player.canGoNext
                opacity: enabled ? 1 : 0.3
                accessibleName: "Próxima faixa"
                onClicked: root.player.next()
            }
            IconButton {
                theme: root.theme
                icon: root.media.repeatTrack ? "󰑘" : "󰑖"
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                visible: root.player !== null && root.player.loopSupported
                enabled: root.player !== null && root.player.canControl
                active: root.media.repeatEnabled
                accessibleName: "Alternar repetição"
                onClicked: root.media.cycleRepeat()
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: root.media.canSetVolume ? "󰕾  Volume do player" : "Volume do player indisponível"
                    color: root.theme.textMuted
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 11
                    }
                }
                Text {
                    text: root.media.canSetVolume ? Math.round(root.media.volume * 100) + "%" : "—"
                    color: root.theme.textAlt
                    font {
                        family: root.theme.fontFamily
                        pixelSize: 11
                    }
                }
            }
            ActionSlider {
                objectName: "mediaVolumeSlider"
                property string dragPlayer: ""
                Layout.fillWidth: true
                theme: root.theme
                accessibleName: "Volume do player"
                enabled: root.media.canSetVolume
                opacity: enabled ? 1 : 0.3
                value: root.media.volume
                onStarted: dragPlayer = root.player ? root.player.dbusName : ""
                onPreviewed: value => root.media.setVolume(value, dragPlayer)
                onCommitted: value => root.media.setVolume(value, dragPlayer)
            }
        }
    }
}
