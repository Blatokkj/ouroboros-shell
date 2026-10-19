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
    radius: root.theme.radiusLarge
    color: theme.surface
    border.color: theme.borderSubtle
    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.theme.panelPadding
        }
        spacing: root.theme.spaceSmall
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
                    pixelSize: root.theme.fontCaption
                }
            }
            IconButton {
                theme: root.theme
                Layout.preferredWidth: root.theme.iconButtonCompactSize
                Layout.preferredHeight: root.theme.iconButtonCompactSize
                icon: "󰒋"
                visible: root.media.players.length > 1
                accessibleName: "Trocar aplicativo"
                onClicked: root.media.cyclePlayer()
            }
            IconButton {
                theme: root.theme
                Layout.preferredWidth: root.theme.iconButtonCompactSize
                Layout.preferredHeight: root.theme.iconButtonCompactSize
                icon: "󰏌"
                enabled: !root.player || root.player.canRaise
                opacity: enabled ? 1 : 0.35
                accessibleName: "Abrir player"
                onClicked: root.media.openPlayer()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: root.theme.spaceLarge
            Rectangle {
                Layout.preferredWidth: root.theme.mediaCoverSize
                Layout.preferredHeight: root.theme.mediaCoverSize
                radius: root.theme.radiusMedium
                color: root.theme.surfaceAlt
                clip: true
                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    sourceSize.width: root.theme.mediaCoverSize * 2
                    sourceSize.height: root.theme.mediaCoverSize * 2
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.theme.motionFast
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
                spacing: root.theme.spaceTiny
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
                        pixelSize: root.theme.fontSmall
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
                        pixelSize: root.theme.fontCaption
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
                        pixelSize: root.theme.fontCaption
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
                        pixelSize: root.theme.fontCaption
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
                objectName: "mediaShuffleButton"
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                enabled: root.media.canShuffle
                opacity: enabled ? 1 : 0.35
                active: root.media.shuffled
                accessibleName: root.media.shuffled ? "Desativar reprodução aleatória" : "Ativar reprodução aleatória"
                onClicked: root.media.toggleShuffle()
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
                objectName: "mediaRepeatButton"
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                enabled: root.media.canRepeat
                opacity: enabled ? 1 : 0.35
                active: root.media.repeatEnabled
                accessibleName: root.media.repeatLabel + "; alternar modo"
                onClicked: root.media.cycleRepeat()
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.media.repeatLabel + (root.media.shuffled ? " · Aleatório" : "")
            color: root.theme.textMuted
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontCaption }
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
                        pixelSize: root.theme.fontSmall
                    }
                }
                Text {
                    text: root.media.canSetVolume ? Math.round(root.media.volume * 100) + "%" : "—"
                    color: root.theme.textAlt
                    font {
                        family: root.theme.fontFamily
                        pixelSize: root.theme.fontSmall
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
