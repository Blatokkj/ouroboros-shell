pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property var theme

    property var wallpapers: []
    property var previewPaths: ({})
    property string currentWallpaper: ""
    property string pendingWallpaper: ""
    property string statusMessage: ""
    property bool applying: false

    function fileName(path) {
        const parts = path.split("/");
        return parts.length ? parts[parts.length - 1] : path;
    }

    function previewFor(path) {
        return root.previewPaths[path] || path;
    }

    function refresh() {
        if (!listProcess.running)
            listProcess.running = true;
    }

    function selectWallpaper(path) {
        if (root.applying)
            return;
        root.pendingWallpaper = path;
        root.statusMessage = "Aplicando " + root.fileName(path) + "…";
        root.applying = true;
        applyProcess.command = ["/usr/bin/bash", Quickshell.shellDir + "/scripts/wallpapers", "set", path];
        applyProcess.running = true;
    }

    onVisibleChanged: {
        if (visible)
            refresh();
    }

    Process {
        id: listProcess
        command: ["/usr/bin/bash", Quickshell.shellDir + "/scripts/wallpapers", "list"]
        stdout: StdioCollector {
            id: listOutput
            waitForEnd: true
        }

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                root.statusMessage = "Não foi possível carregar os wallpapers";
                return;
            }

            const entries = listOutput.text.trim().split("\n");
            const files = [];
            const previews = {};
            for (let index = 0; index < entries.length; index++) {
                if (entries[index].startsWith("CURRENT\t"))
                    root.currentWallpaper = entries[index].substring(8);
                else if (entries[index].startsWith("FILE\t"))
                    files.push(entries[index].substring(5));
                else if (entries[index].startsWith("PREVIEW\t")) {
                    const fields = entries[index].split("\t");
                    if (fields.length >= 3) {
                        files.push(fields[1]);
                        previews[fields[1]] = fields.slice(2).join("\t");
                    }
                }
            }
            root.wallpapers = files;
            root.previewPaths = previews;
            root.statusMessage = files.length + (files.length === 1 ? " wallpaper disponível" : " wallpapers disponíveis");
        }
    }

    Process {
        id: applyProcess
        command: []
        stdout: StdioCollector {
            id: applyOutput
            waitForEnd: true
        }

        onExited: function (exitCode) {
            root.applying = false;
            if (exitCode === 0) {
                root.currentWallpaper = root.pendingWallpaper;
                root.statusMessage = "Wallpaper aplicado";
            } else {
                root.statusMessage = "Falha ao aplicar o wallpaper";
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 0
        }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Galeria de wallpapers"
                    color: root.theme.text
                    font {
                        family: root.theme.fontFamily
                        pixelSize: root.theme.fontSize + 3
                        bold: true
                    }
                }

                Text {
                    text: root.statusMessage
                    color: root.applying ? root.theme.accent : root.theme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    font {
                        family: root.theme.fontFamily
                        pixelSize: root.theme.fontSize - 2
                    }
                }
            }

            IconButton {
                theme: root.theme
                icon: "󰑓"
                accessibleName: "Atualizar wallpapers"
                enabled: !root.applying && !listProcess.running
                onClicked: root.refresh()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 20
            color: root.theme.surface
            border.color: root.theme.borderSubtle
            border.width: 1
            clip: true

            GridView {
                id: wallpaperGrid
                anchors {
                    fill: parent
                    margins: 8
                }
                clip: true
                model: root.wallpapers
                cellWidth: width / (width < 420 ? 2 : 3)
                cellHeight: 142
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: wallpaperCell
                    required property var modelData

                    width: wallpaperGrid.cellWidth
                    height: wallpaperGrid.cellHeight

                    Rectangle {
                        id: previewCard
                        anchors {
                            fill: parent
                            margins: 5
                        }
                        radius: 16
                        color: root.theme.surfaceAlt
                        border.color: wallpaperCell.modelData === root.currentWallpaper ? root.theme.accent : cardMouse.containsMouse ? root.theme.borderStrong : root.theme.borderSubtle
                        border.width: wallpaperCell.modelData === root.currentWallpaper ? 2 : 1
                        clip: true
                        scale: cardMouse.pressed ? 0.97 : cardMouse.containsMouse ? 1.025 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: 190
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 170
                                easing.type: Easing.OutCubic
                            }
                        }

                        Image {
                            anchors {
                                fill: parent
                                bottomMargin: 28
                            }
                            source: "file://" + encodeURI(root.previewFor(wallpaperCell.modelData))
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 480
                            sourceSize.height: 270
                            cache: true
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 29
                            color: Qt.rgba(root.theme.background.r, root.theme.background.g, root.theme.background.b, 0.94)

                            Text {
                                anchors {
                                    left: parent.left
                                    right: currentMark.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 9
                                    rightMargin: 5
                                }
                                text: root.fileName(wallpaperCell.modelData)
                                elide: Text.ElideMiddle
                                color: root.theme.textAlt
                                font {
                                    family: root.theme.fontFamily
                                    pixelSize: root.theme.fontSize - 3
                                }
                            }

                            Text {
                                id: currentMark
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    rightMargin: 9
                                }
                                visible: wallpaperCell.modelData === root.currentWallpaper
                                text: "󰄬"
                                color: root.theme.accent
                                font {
                                    family: root.theme.fontFamily
                                    pixelSize: root.theme.fontSize
                                }
                            }
                        }

                        Rectangle {
                            id: applyingOverlay
                            anchors.fill: parent
                            visible: root.applying && root.pendingWallpaper === wallpaperCell.modelData
                            color: Qt.rgba(root.theme.background.r, root.theme.background.g, root.theme.background.b, 0.58)

                            Text {
                                anchors.centerIn: parent
                                text: "󰑓"
                                color: root.theme.accent
                                font {
                                    family: root.theme.fontFamily
                                    pixelSize: 28
                                }

                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 900
                                    loops: Animation.Infinite
                                    running: applyingOverlay.visible && root.visible
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.applying
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectWallpaper(wallpaperCell.modelData)
                        }
                    }
                }
            }
        }
    }
}
