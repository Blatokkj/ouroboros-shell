import QtQuick
import Quickshell
import Quickshell.Services.UPower

QtObject {
    readonly property bool performance: PowerProfiles.profile === PowerProfile.Performance
    readonly property string profileLabel: performance ? "Performance" : PowerProfiles.profile === PowerProfile.PowerSaver ? "Economia" : "Balanceado"
    readonly property string profileIcon: performance ? "󱐋" : PowerProfiles.profile === PowerProfile.PowerSaver ? "󰌪" : "󰾆"
    function cycleProfile() {
        if (PowerProfiles.profile === PowerProfile.PowerSaver) PowerProfiles.profile = PowerProfile.Balanced;
        else if (PowerProfiles.profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile) PowerProfiles.profile = PowerProfile.Performance;
        else PowerProfiles.profile = PowerProfile.PowerSaver;
    }
    // Confirmation remains in ControlPage. Never exposed over IPC.
    function powerOff() { Quickshell.execDetached(["systemctl", "poweroff"]); }
}
