import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "ConnectionEvents.js" as Events

Scope {
    id: root
    required property var notifications
    property bool ready: false
    property var previousNetwork: null
    property var previousBluetooth: null
    property var previousPower: null

    required property var network
    readonly property var networkState: network.networkState
    readonly property var bluetoothState: network.bluetoothState

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
