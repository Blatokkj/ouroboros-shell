import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "ConnectionEvents.js" as Events

Scope {
    id: root
    required property var notifications
    property bool ready: false
    property var previousNetwork: null
    property var previousBluetooth: null
    property var previousPower: null

    // Reading the nested properties inside these bindings subscribes to their
    // change signals, including devices added/removed after startup.
    readonly property var networkState: {
        const links = [];
        for (const device of Networking.devices.values) {
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
        if (links.length && Networking.canCheckConnectivity && Networking.connectivityCheckEnabled) {
            if (Networking.connectivity === NetworkConnectivity.Full)
                status = "full";
            else if (Networking.connectivity === NetworkConnectivity.Portal)
                status = "portal";
            else if (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.None)
                status = "limited";
        }
        return { wifiEnabled: Networking.wifiEnabled, status: status, label: links.join(" + ") };
    }

    readonly property var bluetoothState: {
        const adapters = {};
        const devices = {};
        for (const adapter of Bluetooth.adapters.values) {
            adapters[adapter.dbusPath] = { name: adapter.name || "Adaptador Bluetooth", enabled: adapter.enabled };
            for (const device of adapter.devices.values) {
                if (device.connected)
                    devices[device.dbusPath] = { name: device.name || device.deviceName || device.address, adapter: adapter.dbusPath };
            }
        }
        return { adapters: adapters, devices: devices };
    }

    readonly property var powerState: ({
        ready: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery,
        onBattery: UPower.onBattery,
        percent: Math.round(UPower.displayDevice.percentage * 100)
    })

    onNetworkStateChanged: if (ready) networkDebounce.restart()
    onBluetoothStateChanged: if (ready) bluetoothDebounce.restart()
    onPowerStateChanged: if (ready) powerDebounce.restart()

    function publish(events) {
        for (const event of events)
            notifications.push(event);
    }

    Timer {
        interval: 2500
        running: true
        onTriggered: {
            root.previousNetwork = root.networkState;
            root.previousBluetooth = root.bluetoothState;
            root.previousPower = root.powerState;
            root.ready = true;
        }
    }
    Timer {
        id: networkDebounce
        interval: 800
        onTriggered: {
            root.publish(Events.networkEvents(root.previousNetwork, root.networkState));
            root.previousNetwork = root.networkState;
        }
    }
    Timer {
        id: bluetoothDebounce
        interval: 450
        onTriggered: {
            root.publish(Events.bluetoothEvents(root.previousBluetooth, root.bluetoothState));
            root.previousBluetooth = root.bluetoothState;
        }
    }
    Timer {
        id: powerDebounce
        interval: 800
        onTriggered: {
            root.publish(Events.powerEvents(root.previousPower, root.powerState));
            root.previousPower = root.powerState;
        }
    }
}
