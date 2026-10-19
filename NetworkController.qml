import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import "DesktopUi.js" as Display

QtObject {
    id: root
    property var networking: Networking
    property var bluetooth: Bluetooth
    readonly property var wifiDevice: networking.devices.values.find(device => device.type === DeviceType.Wifi) || null
    readonly property var wifiNetwork: wifiDevice ? wifiDevice.networks.values.find(network => network.connected) || null : null
    readonly property var bluetoothAdapter: bluetooth.defaultAdapter
    readonly property bool wifiEnabled: networking.wifiEnabled
    readonly property bool bluetoothEnabled: bluetoothAdapter !== null && bluetoothAdapter.enabled
    readonly property bool wiredConnected: networking.devices.values.some(device => device.type === DeviceType.Wired && device.connected)
    readonly property bool airplaneMode: !wifiEnabled && !bluetoothEnabled
    readonly property bool limited: (wifiNetwork !== null || wiredConnected) && networking.canCheckConnectivity
        && networking.connectivityCheckEnabled && networking.connectivity !== NetworkConnectivity.Full
    readonly property string icon: Display.wifiIcon(wifiEnabled, wifiNetwork !== null, wifiNetwork ? wifiNetwork.signalStrength : 0, wiredConnected)
    // One lease per monitor: closing one popup must not cancel another monitor's scan.
    property var scanRequests: ({})
    function setScanning(owner, mode) {
        const next = Object.assign({}, scanRequests);
        if (mode) next[owner] = mode;
        else delete next[owner];
        scanRequests = next;
    }
    function updateScanning() {
        const modes = Object.values(scanRequests);
        if (wifiDevice) wifiDevice.scannerEnabled = wifiEnabled && modes.includes("wifi");
        if (bluetoothAdapter) bluetoothAdapter.discovering = bluetoothEnabled && modes.includes("bluetooth");
    }
    onScanRequestsChanged: updateScanning()
    onWifiEnabledChanged: updateScanning()
    onBluetoothEnabledChanged: updateScanning()
    onWifiDeviceChanged: updateScanning()
    onBluetoothAdapterChanged: updateScanning()
    function toggleWifi() { networking.wifiEnabled = !wifiEnabled; }
    function toggleBluetooth() { if (bluetoothAdapter) bluetoothAdapter.enabled = !bluetoothEnabled; }
    function toggleAirplane() {
        const enabled = airplaneMode;
        networking.wifiEnabled = enabled;
        if (bluetoothAdapter) bluetoothAdapter.enabled = enabled;
    }
    function activateWifi(network) {
        if (network.connected) network.disconnect();
        else if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) network.connect();
        else return false;
        return true;
    }
    function connectWithPassword(network, password) { if (network && password) network.connectWithPsk(password); }
    function activateBluetooth(device) {
        if (device.connected) device.disconnect();
        else if (device.paired) device.connect();
        else device.pair();
    }
    // Reading the nested properties inside these bindings subscribes to their
    // change signals, including devices added/removed after startup.
    readonly property var networkState: {
        const links = [];
        for (const device of networking.devices.values) {
            if (!device.connected)
                continue;
            let name = device.type === DeviceType.Wired ? "Ethernet" : device.name;
            for (const network of device.networks.values) {
                if (network.connected) {
                    name = network.name || name;
                    break;
                }
            }
            links.push(name);
        }
        links.sort();
        let status = links.length ? "connected" : "offline";
        if (links.length && networking.canCheckConnectivity && networking.connectivityCheckEnabled) {
            if (networking.connectivity === NetworkConnectivity.Full)
                status = "full";
            else if (networking.connectivity === NetworkConnectivity.Portal)
                status = "portal";
            else if (networking.connectivity === NetworkConnectivity.Limited || networking.connectivity === NetworkConnectivity.None)
                status = "limited";
        }
        return { wifiEnabled: networking.wifiEnabled, status: status, label: links.join(" + ") };
    }

    readonly property var bluetoothState: {
        const adapters = {};
        const devices = {};
        for (const adapter of bluetooth.adapters.values) {
            adapters[adapter.dbusPath] = { name: adapter.name || "Adaptador Bluetooth", enabled: adapter.enabled };
            for (const device of adapter.devices.values) {
                if (device.connected)
                    devices[device.dbusPath] = { name: device.name || device.deviceName || device.address, adapter: adapter.dbusPath };
            }
        }
        return { adapters: adapters, devices: devices };
    }


}
