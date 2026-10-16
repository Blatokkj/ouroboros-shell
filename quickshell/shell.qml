pragma ComponentBehavior: Bound

import Quickshell

ShellRoot {
    id: shell

    Theme {
        id: shellTheme
    }

    SystemStats {
        id: systemStats
    }

    SessionLock {
        id: sessionLock
        theme: shellTheme
        stats: systemStats
    }

    SystemNotifications {
        id: systemNotifications
        theme: shellTheme
        suppressed: sessionLock.locked
    }

    MediaController {
        id: mediaController
    }

    Variants {
        model: Quickshell.screens

        delegate: TopBar {
            required property var modelData

            screen: modelData
            stats: systemStats
            theme: shellTheme
            lockController: sessionLock
            notifications: systemNotifications
            media: mediaController
        }
    }
}
