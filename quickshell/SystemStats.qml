import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int cpuUsage: 0
    property int memoryUsage: 0
    property real cpuUsagePrecise: 0
    property real memoryUsagePrecise: 0
    property real memoryUsedKiB: 0
    property real memoryTotalKiB: 0
    property real loadOne: 0
    property int brightness: 0
    property int temperature: 0
    property int uptimeSeconds: 0

    property double previousTotal: 0
    property double previousIdle: 0

    function refresh() {
        if (!poll.running)
            poll.running = true;
    }

    Process {
        id: poll

        command: ["/usr/bin/bash", Quickshell.shellDir + "/scripts/system-stats"]
        stdout: StdioCollector {
            id: output
            waitForEnd: true
        }

        onExited: function(exitCode) {
            if (exitCode !== 0)
                return;

            const values = output.text.trim().split(/\s+/);
            if (values.length < 9)
                return;

            const total = Number(values[0]);
            const idle = Number(values[1]);
            const totalDelta = total - root.previousTotal;
            const idleDelta = idle - root.previousIdle;

            if (root.previousTotal > 0 && totalDelta > 0) {
                root.cpuUsagePrecise = 100 * (totalDelta - idleDelta) / totalDelta;
                root.cpuUsage = Math.round(root.cpuUsagePrecise);
            }

            root.previousTotal = total;
            root.previousIdle = idle;
            root.memoryUsagePrecise = Number(values[2]);
            root.memoryUsage = Math.round(root.memoryUsagePrecise);
            root.brightness = Math.round(Number(values[3]));
            root.temperature = Math.round(Number(values[4]));
            root.uptimeSeconds = Math.round(Number(values[5]));
            root.memoryUsedKiB = Number(values[6]);
            root.memoryTotalKiB = Number(values[7]);
            root.loadOne = Number(values[8]);
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
