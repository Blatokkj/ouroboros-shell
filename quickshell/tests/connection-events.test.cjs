const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { runInNewContext } = require('node:vm');
const { join } = require('node:path');
const events = {};
runInNewContext(readFileSync(join(__dirname, '../ConnectionEvents.js'), 'utf8'), events);

const online = { wifiEnabled: true, status: 'full', label: 'Casa' };
const disconnected = { wifiEnabled: true, status: 'offline', label: '' };
const adapter = { name: 'Notebook', enabled: true };
const headphones = { name: 'Fones', adapter: '/adapter' };
const btEmpty = { adapters: { '/adapter': adapter }, devices: {} };
const btConnected = { adapters: { '/adapter': adapter }, devices: { '/headphones': headphones } };

test('initial state and unchanged state do not produce notifications', () => {
    assert.equal(events.networkEvents(null, online).length, 0);
    assert.equal(events.networkEvents(online, { ...online }).length, 0);
    assert.equal(events.bluetoothEvents(null, btConnected).length, 0);
    assert.equal(events.bluetoothEvents(btConnected, btConnected).length, 0);
    assert.equal(events.powerEvents(null, { ready: true }).length, 0);
});

test('internet disconnect and reconnect show the previous/current network name', () => {
    const lost = events.networkEvents(online, disconnected);
    assert.equal(lost.length, 1);
    assert.match(lost[0].body, /Casa/);
    assert.equal(lost[0].level, 'warning');
    const restored = events.networkEvents(disconnected, online);
    assert.equal(restored[0].title, 'Internet restabelecida');
    assert.equal(restored[0].key, lost[0].key);
});

test('internet outage while Wi-Fi stays connected is detected', () => {
    const limited = { ...online, status: 'limited' };
    assert.equal(events.networkEvents(online, limited)[0].title, 'Sem acesso à internet');
    assert.equal(events.networkEvents(limited, online)[0].title, 'Internet restabelecida');
});

test('a captive portal is distinguished from internet access', () => {
    const result = events.networkEvents(disconnected, { ...online, status: 'portal' });
    assert.equal(result[0].title, 'Rede pede autenticação');
});

test('without connectivity checks, a link is not presented as confirmed internet access', () => {
    assert.equal(events.networkEvents(disconnected, { ...online, status: 'connected' })[0].title, 'Rede conectada');
});

test('turning off Wi-Fi produces one notification and leaves Ethernet accurate', () => {
    const off = events.networkEvents(online, { ...disconnected, wifiEnabled: false });
    assert.equal(off.length, 1);
    assert.equal(off[0].title, 'Wi-Fi desativado');
    const wired = { ...online, label: 'Ethernet' };
    const stayedOnline = events.networkEvents(wired, { ...wired, wifiEnabled: false });
    assert.equal(stayedOnline.length, 1);
    assert.equal(stayedOnline[0].key, 'wifi-radio');
});

test('switching networks produces one updated network notice', () => {
    const result = events.networkEvents(online, { ...online, label: 'Trabalho' });
    assert.equal(result.length, 1);
    assert.match(result[0].body, /Trabalho/);
});

test('Bluetooth connection/disconnection includes the actual device name', () => {
    const connected = events.bluetoothEvents(btEmpty, btConnected);
    assert.equal(connected[0].title, 'Bluetooth conectado');
    assert.equal(connected[0].body, 'Fones');
    assert.equal(events.bluetoothEvents(btConnected, btEmpty)[0].title, 'Bluetooth desconectado');
});

test('turning off or unplugging the Bluetooth adapter avoids a device-notification storm', () => {
    const off = { adapters: { '/adapter': { ...adapter, enabled: false } }, devices: {} };
    const disabled = events.bluetoothEvents(btConnected, off);
    assert.equal(disabled.length, 1);
    assert.equal(disabled[0].title, 'Bluetooth desativado');
    assert.equal(events.bluetoothEvents(btConnected, { adapters: {}, devices: {} }).length, 1);
});

test('multiple Bluetooth devices are tracked independently', () => {
    const two = { ...btConnected, devices: { ...btConnected.devices, '/mouse': { name: 'Mouse', adapter: '/adapter' } } };
    const result = events.bluetoothEvents(two, btConnected);
    assert.equal(result.length, 1);
    assert.equal(result[0].body, 'Mouse');
});

test('power notices wait for UPower to be ready', () => {
    const battery = { ready: true, onBattery: true, percent: 80 };
    assert.equal(events.powerEvents({ ...battery, ready: false }, battery).length, 0);
    assert.equal(events.powerEvents(battery, { ...battery, onBattery: false })[0].title, 'Carregador conectado');
});

test('battery alerts occur at thresholds, including a sudden drop to critical', () => {
    const battery = { ready: true, onBattery: true, percent: 16 };
    assert.equal(events.powerEvents(battery, { ...battery, percent: 15 })[0].title, 'Bateria baixa');
    assert.equal(events.powerEvents({ ...battery, percent: 15 }, { ...battery, percent: 14 }).length, 0);
    assert.equal(events.powerEvents(battery, { ...battery, percent: 4 })[0].level, 'error');
});
