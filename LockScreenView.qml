import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Widgets

Item {
    id: root

    required property var theme
    required property var stats
    property var profile: null
    required property string wallpaperPath
    required property string authMessage
    required property bool authError
    required property bool authenticating
    required property bool secure
    required property int clearRevision

    signal passwordSubmitted(string password)

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryVisible: battery.ready && battery.isLaptopBattery
    readonly property int batteryPercent: Math.round(battery.percentage * 100)
    readonly property var locale: Qt.locale("pt_BR")
    readonly property string userName: String(Quickshell.env("USER") || "usuário")
    readonly property string displayName: profile && profile.displayName ? profile.displayName : userName
    readonly property string avatarSource: profile && profile.avatar ? profile.avatar
        : "file:///var/lib/AccountsService/icons/" + encodeURIComponent(userName)

    onClearRevisionChanged: {
        passwordInput.text = "";
        passwordInput.forceActiveFocus();
    }

    onAuthenticatingChanged: {
        if (!authenticating)
            passwordInput.forceActiveFocus();
    }

    SystemClock {
        id: lockClock
        precision: SystemClock.Seconds
    }

    Image {
        anchors.fill: parent
        source: root.wallpaperPath.length ? "file://" + encodeURI(root.wallpaperPath) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.theme.background.r, root.theme.background.g, root.theme.background.b, 0.78)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.10) }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.36) }
        }
    }

    ColumnLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Math.max(54, parent.height * 0.08)
        }
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(lockClock.date, "HH:mm:ss")
            color: root.theme.text
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontLockClock; bold: true }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: lockClock.date.toLocaleString(root.locale, "dddd, dd 'de' MMMM 'de' yyyy")
            color: root.theme.textAlt
            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 2 }
        }
    }

    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 48)
        height: 310
        radius: root.theme.radiusLock
        color: Qt.rgba(root.theme.background.r, root.theme.background.g, root.theme.background.b, 0.90)
        border.color: root.authError ? root.theme.error : root.theme.borderStrong
        border.width: root.theme.borderThin

        ColumnLayout {
            anchors {
                fill: parent
                margins: 24
            }
            spacing: root.theme.spaceLarge

            ClippingRectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 86
                Layout.preferredHeight: 86
                radius: 43
                color: root.theme.surface
                border.color: root.theme.borderStrong
                border.width: 2

                Image {
                    id: lockAvatar
                    objectName: "lockAvatar"
                    anchors.fill: parent
                    source: root.avatarSource
                    sourceSize: Qt.size(172, 172)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !lockAvatar.visible
                    text: root.displayName.charAt(0).toUpperCase()
                    color: root.theme.accent
                    font { family: root.theme.fontFamily; pixelSize: 32; bold: true }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                objectName: "lockDisplayName"
                text: root.displayName
                textFormat: Text.PlainText
                Layout.maximumWidth: parent.width
                elide: Text.ElideRight
                color: root.theme.text
                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 3; bold: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: root.theme.radiusLarge
                color: root.theme.surface
                border.color: passwordInput.activeFocus ? root.theme.accent : root.theme.borderSubtle
                border.width: root.theme.borderThin

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 8
                    }
                    spacing: root.theme.spaceMedium

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            enabled: !root.authenticating
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            selectByMouse: false
                            color: root.theme.text
                            selectionColor: root.theme.accent
                            selectedTextColor: root.theme.background
                            verticalAlignment: TextInput.AlignVCenter
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
                            Keys.onReturnPressed: {
                                if (text.length > 0 && !root.authenticating)
                                    root.passwordSubmitted(text);
                            }
                            Keys.onEnterPressed: {
                                if (text.length > 0 && !root.authenticating)
                                    root.passwordSubmitted(text);
                            }
                            Component.onCompleted: forceActiveFocus()
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            visible: passwordInput.text.length === 0
                            text: "Digite sua senha"
                            color: root.theme.textMuted
                            font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                        }
                    }

                    IconButton {
                        theme: root.theme
                        icon: root.authenticating ? "󰑓" : "→"
                        active: passwordInput.text.length > 0
                        onClicked: {
                            if (passwordInput.text.length > 0 && !root.authenticating)
                                root.passwordSubmitted(passwordInput.text);
                        }

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                            running: root.authenticating
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.authMessage.length ? root.authMessage : root.secure ? "Sessão protegida" : "Protegendo sessão…"
                color: root.authError ? root.theme.error : root.theme.textMuted
                font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 2 }
            }
        }

        Behavior on border.color { ColorAnimation { duration: root.theme.motionFast } }
    }

    RowLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 28
        }
        spacing: root.theme.spaceLarge

        Rectangle {
            implicitWidth: statusRow.implicitWidth + 28
            implicitHeight: 42
            radius: root.theme.radiusPanel
            color: root.theme.pillBackground
            border.color: root.theme.borderSubtle
            border.width: root.theme.borderThin

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 14

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Networking.wifiEnabled ? "󰖩" : "󰖪"
                    color: Networking.wifiEnabled ? root.theme.accent : root.theme.textMuted
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize + 1 }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: " " + root.stats.cpuUsage + "%"
                    color: root.theme.textAlt
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: " " + root.stats.memoryUsage + "%"
                    color: root.theme.textAlt
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.batteryVisible
                    text: "󰁹 " + root.batteryPercent + "%"
                    color: root.theme.accent
                    font { family: root.theme.fontFamily; pixelSize: root.theme.fontSize - 1 }
                }
            }
        }

        IconButton {
            theme: root.theme
            icon: "󰤄"
            accessibleName: "Suspender"
            onClicked: Quickshell.execDetached(["systemctl", "suspend"])
        }

    }
}
