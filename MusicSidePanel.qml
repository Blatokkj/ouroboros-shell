
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    required property var bridge

    property bool library: false

    readonly property var entries: library
        ? bridge.playlists
        : bridge.queue

    readonly property string message: library
        ? bridge.libraryError
        : bridge.error

    radius: theme.radiusPanel
    color: theme.panelBackground

    border {
        color: theme.borderSubtle
        width: theme.borderThin
    }

    function loadMoreIfNeeded() {
        if (!library || !bridge.ready)
            return;

        if (!bridge.more || bridge.libraryBusy)
            return;

        if (listView.height <= 0)
            return;

        const remaining = listView.contentHeight
                        - listView.contentY
                        - listView.height;

        if (remaining < 180)
            bridge.request("more");
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.theme.panelPadding
        }

        spacing: root.theme.spaceMedium

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true

                text: root.library
                    ? "Playlists"
                    : "Fila de músicas"

                color: root.theme.text
                elide: Text.ElideRight

                font {
                    family: root.theme.fontFamily
                    pixelSize: root.theme.fontSmall
                    bold: true
                }
            }

            IconButton {
                theme: root.theme
                icon: "󰑐"

                Layout.preferredWidth:
                    root.theme.iconButtonCompactSize

                Layout.preferredHeight:
                    root.theme.iconButtonCompactSize

                accessibleName: root.library
                    ? "Atualizar playlists"
                    : "Atualizar fila"

                enabled: root.bridge.ready
                    && !root.bridge.libraryBusy

                onClicked: {
                    root.bridge.request(
                        root.library ? "playlists" : "snapshot"
                    );
                }
            }
        }

        // Estado vazio ou erro
        Text {
            Layout.fillWidth: true

            visible: !root.bridge.ready
                || root.message !== ""
                || root.entries.length === 0

            text: !root.bridge.ready
                ? root.bridge.unavailable
                : root.message ||
                    (root.library && root.bridge.libraryBusy
                        ? "Carregando playlists…"
                        : root.library
                            ? "Nenhuma playlist carregada."
                            : "A fila está vazia.")

            wrapMode: Text.Wrap
            textFormat: Text.PlainText

            color: root.theme.textMuted

            font {
                family: root.theme.fontFamily
                pixelSize: root.theme.fontCaption
            }
        }

        // Área de rolagem
        Item {
            id: scrollContainer

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            ListView {
                id: listView

                anchors.fill: parent

                model: root.entries

                spacing: 6
                clip: true

                boundsBehavior: Flickable.StopAtBounds

                // Rolagem suave
                flickDeceleration: 2500
                maximumFlickVelocity: 1800

                // Permite arrastar e clicar
                pressDelay: 120

                // Mantém alguns itens preparados
                cacheBuffer: 160

                interactive: root.bridge.ready

                onContentYChanged:
                    root.loadMoreIfNeeded()

                onMovementEnded:
                    root.loadMoreIfNeeded()

                onCountChanged:
                    Qt.callLater(root.loadMoreIfNeeded)

                onHeightChanged:
                    Qt.callLater(root.loadMoreIfNeeded)

                delegate: Rectangle {
                    id: musicRow

                    required property var modelData

                    width: listView.width
                    height: 52

                    radius: root.theme.radiusSmall

                    readonly property bool selected:
                        Boolean(modelData.selected)

                    color: selected
                        || activeFocus
                        || mouse.containsMouse
                        ? root.theme.surfaceAlt
                        : "transparent"

                    border {
                        color: musicRow.activeFocus
                            ? root.theme.accent
                            : "transparent"

                        width: musicRow.activeFocus ? 1 : 0
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: root.theme.motionFast
                        }
                    }

                    activeFocusOnTab: true

                    enabled: root.bridge.ready
                        && !root.bridge.actionBusy

                    Accessible.role: Accessible.Button

                    Accessible.name:
                        (root.library
                            ? "Reproduzir playlist "
                            : "Reproduzir faixa ")
                        + modelData.title

                    function activate() {
                        if (!enabled)
                            return;

                        if (root.library) {
                            root.bridge.request(
                                "playlist",
                                { id: modelData.id }
                            );
                        } else {
                            root.bridge.request(
                                "queue",
                                {
                                    index: modelData.index,
                                    id: modelData.id
                                }
                            );
                        }
                    }

                    Accessible.onPressAction: activate()

                    Keys.onReturnPressed: activate()
                    Keys.onEnterPressed: activate()
                    Keys.onSpacePressed: activate()

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 5
                        }

                        spacing: root.theme.spaceSmall

                        // Capa da música ou playlist
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36

                            radius: root.theme.radiusSmall
                            color: root.theme.surface

                            clip: true

                            Image {
                                id: artwork

                                anchors.fill: parent

                                source: musicRow.modelData.art || ""

                                sourceSize.width: 72
                                sourceSize.height: 72

                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                            }

                            Text {
                                anchors.centerIn: parent

                                visible: artwork.status
                                    !== Image.Ready

                                text: musicRow.selected
                                    ? "󰎈"
                                    : root.library
                                        ? "󰲸"
                                        : "󰝚"

                                color: root.theme.accent
                                font.family: root.theme.fontFamily
                            }
                        }

                        // Informações
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true

                                text: musicRow.modelData.title
                                textFormat: Text.PlainText

                                elide: Text.ElideRight
                                color: musicRow.selected
                                    ? root.theme.accent
                                    : root.theme.text

                                font {
                                    family: root.theme.fontFamily
                                    pixelSize: root.theme.fontCaption
                                    bold: musicRow.selected
                                }
                            }

                            Text {
                                Layout.fillWidth: true

                                text: (
                                    root.library
                                        ? musicRow.modelData.subtitle
                                        : musicRow.modelData.artist
                                ) || ""

                                textFormat: Text.PlainText
                                elide: Text.ElideRight

                                color: root.theme.textMuted

                                font {
                                    family: root.theme.fontFamily
                                    pixelSize: root.theme.fontCaption
                                }
                            }
                        }

                        // Duração
                        Text {
                            visible: !root.library

                            text: musicRow.modelData.duration || ""

                            color: root.theme.accent

                            font {
                                family: root.theme.fontFamily
                                pixelSize: root.theme.fontCaption
                            }
                        }
                    }

                    MouseArea {
                        id: mouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            musicRow.forceActiveFocus();
                            musicRow.activate();
                        }
                    }
                }
            }

            // Hover para revelar scrollbar
            HoverHandler {
                id: scrollHover
            }

            // Scrollbar discreta
            Rectangle {
                id: scrollbar

                width: 3
                radius: 2

                anchors.right: parent.right
                anchors.rightMargin: 1

                y: listView.visibleArea.yPosition
                    * scrollContainer.height

                height: Math.max(
                    24,
                    Math.min(
                        scrollContainer.height,
                        listView.visibleArea.heightRatio
                        * scrollContainer.height
                    )
                )

                color: root.theme.accent

                visible: listView.contentHeight
                    > listView.height + 1

                opacity: scrollHover.hovered
                    || listView.moving
                    ? 0.85
                    : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 70
                    }
                }
            }

            // Degradê superior
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }

                height: 16
                visible: listView.contentY > 2

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: root.color
                    }

                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            // Degradê inferior
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 16

                visible: listView.contentHeight
                    > listView.height
                    && !listView.atYEnd

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }

                    GradientStop {
                        position: 1.0
                        color: root.color
                    }
                }
            }
        }

        // Indicador de carregamento adicional
        Text {
            Layout.fillWidth: true

            visible: root.library
                && root.bridge.libraryBusy
                && root.entries.length > 0

            text: "Carregando mais playlists…"

            horizontalAlignment: Text.AlignHCenter

            color: root.theme.textMuted

            font {
                family: root.theme.fontFamily
                pixelSize: root.theme.fontCaption
            }
        }
    }
}
