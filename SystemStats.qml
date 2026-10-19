import QtQuick
import Quickshell
import Quickshell.Io
import "Stats.js" as Stats

Scope {
    id: root
    readonly property int cpuUsage: Math.round(cpuUsagePrecise)
    readonly property int memoryUsage: Math.round(memoryUsagePrecise)
    property real cpuUsagePrecise: 0
    property real memoryUsagePrecise: 0
    property real memoryUsedKiB: 0
    property real memoryTotalKiB: 0
    readonly property real loadOne: Number(loadFile.text().trim().split(/\s+/)[0]) || 0
    readonly property int uptimeSeconds: Math.floor(Number(uptimeFile.text().trim().split(/\s+/)[0])) || 0
    readonly property int temperature: Math.round((Number(temperatureFile.text()) || 0) / 1000)
    readonly property int brightness: maxBrightness > 0 ? Math.round(100 * Number(brightnessFile.text()) / maxBrightness) : 0
    readonly property real maxBrightness: Number(brightnessMaxFile.text()) || 0
    property var previousCpu: null

    // White's existing sensors, same ones selected by scripts/system-stats.
    // Asynchronous FileView reads: no process spawn, no blocking the render thread.
    function refresh() {
        cpuFile.reload(); memoryFile.reload(); loadFile.reload();
        uptimeFile.reload(); temperatureFile.reload(); brightnessFile.reload();
    }
    FileView {
        id: cpuFile
        path: "/proc/stat"
        preload: true
        onLoaded: {
            const next = Stats.cpu(text());
            const usage = Stats.usage(root.previousCpu, next);
            if (usage !== null) root.cpuUsagePrecise = usage;
            if (next) root.previousCpu = next;
        }
    }
    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        preload: true
        onLoaded: {
            const sample = Stats.memory(text());
            if (!sample) return;
            root.memoryUsagePrecise = sample.percent;
            root.memoryUsedKiB = sample.used;
            root.memoryTotalKiB = sample.total;
        }
    }
    FileView { id: loadFile; path: "/proc/loadavg" }
    FileView { id: uptimeFile; path: "/proc/uptime" }
    FileView { id: temperatureFile; path: "/sys/class/thermal/thermal_zone0/temp" }
    FileView { id: brightnessFile; path: "/sys/class/backlight/intel_backlight/brightness" }
    FileView { id: brightnessMaxFile; path: "/sys/class/backlight/intel_backlight/max_brightness" }
    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
