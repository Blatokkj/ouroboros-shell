import QtQuick
import Quickshell
import Quickshell.Io

// Isolated persistence harness. Requires an explicit temporary test path.
ShellRoot {
    property string generation: Date.now() + ":" + Math.random()
    function avatarReady(item): bool {
        if (item.objectName === "lockAvatar") return item.status === Image.Ready;
        for (const child of item.children || []) if (avatarReady(child)) return true;
        return false;
    }
    ProfileStore { id: profile; storagePath: Quickshell.env("ARCHBLATO_TEST_PROFILE") }
    Theme { id: theme }
    WallpaperTheme { theme: theme; path: Quickshell.env("ARCHBLATO_TEST_COLORS") }
    QtObject { id: stats; property int cpuUsage: 0; property int memoryUsage: 0 }
    // Presentation only: no WlSessionLock or PAM context is created here.
    LockScreenView {
        id: lockView; width: 800; height: 800; visible: false
        theme: theme; stats: stats; profile: profile
        wallpaperPath: ""; authMessage: ""; authError: false
        authenticating: false; secure: true; clearRevision: 0
    }
    IpcHandler {
        target: "profile-test"
        function save(name: string, computer: string, avatar: string): bool { return profile.save(name,computer,avatar); }
        function status(): string { return JSON.stringify({ready:profile.ready,saving:profile.saving,error:profile.error,
            name:profile.displayName,computer:profile.computerName,avatar:profile.avatar,message:profile.message,
            lockName:lockView.displayName,lockAvatar:lockView.avatarSource,avatarReady:avatarReady(lockView),
            accent:String(theme.accent),generation:generation}); }
    }
}
