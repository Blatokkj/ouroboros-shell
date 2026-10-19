pragma ComponentBehavior: Bound

import Quickshell

ShellRoot {
    id: shell

    Theme {
        id: shellTheme
    }
    WallpaperTheme { theme: shellTheme }

    SystemStats {
        id: systemStats
    }

    // System services and the saved personal profile are shared across monitors.
    // Panels and their coordinator remain local to each monitor.
    NetworkController { id: networkController }
    BrightnessController { id: brightnessController; stats: systemStats }
    PowerController { id: powerController }
    ProfileStore { id: profileStore }

    SessionLock {
        id: sessionLock
        theme: shellTheme
        stats: systemStats
        profile: profileStore
    }

    SystemNotifications {
        id: systemNotifications
        network: networkController
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
            network: networkController
            brightness: brightnessController
            power: powerController
            profile: profileStore
        }
    }
}
