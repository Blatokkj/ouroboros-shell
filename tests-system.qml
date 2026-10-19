import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

ShellRoot {
    id: testRoot
    SystemStats { id: stats }
    QtObject {
        id: fakeStats
        property int brightness: 40
        property int refreshes: 0
        function refresh() { refreshes++; }
    }
    BrightnessController { id: brightness; stats: fakeStats }
    QtObject {
        id: adapter
        property bool enabled: true
        property bool discovering: false
        property string dbusPath: "/test"
        property string name: "Test"
        property var devices: ({ values: [] })
    }
    QtObject {
        id: wifi
        property int type: DeviceType.Wifi
        property bool connected: false
        property bool scannerEnabled: false
        property var networks: ({ values: [] })
    }
    QtObject {
        id: networking
        property bool wifiEnabled: true
        property bool canCheckConnectivity: false
        property bool connectivityCheckEnabled: false
        property int connectivity: 0
        property var devices: ({ values: [wifi] })
    }
    QtObject {
        id: bluetooth
        property var defaultAdapter: adapter
        property var adapters: ({ values: [adapter] })
    }
    NetworkController { id: network; networking: networking; bluetooth: bluetooth }
    IpcHandler {
        target: "test"
        function brightnessTo(value: real): void { brightness.setPercent(value); }
        function burst(): void { for (let i = 1; i <= 90; i++) brightness.setPercent(i); }
        function status(): string { return JSON.stringify({
            percent: brightness.percent, refreshes: fakeStats.refreshes, error: brightness.error,
            cpu: stats.cpuUsagePrecise, ram: stats.memoryUsedKiB, total: stats.memoryTotalKiB,
            hardwareBrightness: stats.brightness, uptime: stats.uptimeSeconds
        }); }
        function networkChecks(): string {
            const failures = [];
            if (network.wifiDevice !== wifi) failures.push("shared wifi device");
            wifi.networks = { values: [{connected: true, name: "White test", signalStrength: 0.75}] };
            wifi.connected = true;
            if (!network.wifiNetwork || network.wifiNetwork.name !== "White test") failures.push("connected network");
            network.setScanning("wifi-one", "wifi");
            network.setScanning("wifi-two", "wifi");
            network.setScanning("wifi-one", "");
            if (!wifi.scannerEnabled) failures.push("wifi scan isolation");
            network.toggleWifi();
            if (wifi.scannerEnabled) failures.push("disabled radio scan");
            network.setScanning("wifi-two", "");
            if (networking.wifiEnabled) failures.push("wifi toggle");
            network.toggleBluetooth();
            if (adapter.enabled || !network.airplaneMode) failures.push("bluetooth/airplane state");
            network.toggleAirplane();
            if (!networking.wifiEnabled || !adapter.enabled) failures.push("airplane restores radios");
            network.setScanning("one", "bluetooth");
            network.setScanning("two", "bluetooth");
            network.setScanning("one", "");
            if (!adapter.discovering) failures.push("scan lease isolation");
            network.setScanning("two", "");
            if (adapter.discovering) failures.push("scan release");
            let action = "";
            const device = { connected: false, paired: false, pair: () => action = "pair",
                connect: () => action = "connect", disconnect: () => action = "disconnect" };
            network.activateBluetooth(device);
            if (action !== "pair") failures.push("pair");
            device.paired = true; network.activateBluetooth(device);
            if (action !== "connect") failures.push("connect");
            device.connected = true; network.activateBluetooth(device);
            if (action !== "disconnect") failures.push("disconnect");
            const saved = { connected: false, known: true, connect: () => action = "wifi connect" };
            network.activateWifi(saved);
            if (action !== "wifi connect") failures.push("known wifi");
            network.connectWithPassword({connectWithPsk: value => action = value}, "test-only");
            if (action !== "test-only") failures.push("wifi password");
            return JSON.stringify(failures);
        }
    }
}
