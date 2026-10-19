const assert = require('node:assert/strict');
const fs = require('node:fs');
const net = require('node:net');
const {join} = require('node:path');
const {createBridge} = require('../scripts/pear-music-bridge.cjs');
const dir = fs.mkdtempSync('/tmp/archblato-music-bridge-');
const path = join(dir, 'music.sock');
let close, socket;
(async () => {
    const calls = [], opened = [];
    close = await createBridge({path, pid: 123, execute: async request => {
        calls.push(request);
        return request.action === 'playlists' ? {playlists: [{id: 'PL_test', title: 'Fixture'}], continuation: ''} : {ready: true, queue: []};
    }, openPlaylist: async id => opened.push(id)});
    assert.equal(fs.statSync(path).mode & 0o777, 0o600);
    socket = net.createConnection(path); socket.setEncoding('utf8');
    await new Promise((resolve, reject) => { socket.once('connect', resolve); socket.once('error', reject); });
    let seq = 0;
    function request(action, args = {}) {
        return new Promise((resolve, reject) => {
            const timer = setTimeout(() => reject(new Error('RPC timeout')), 2000);
            socket.once('data', data => { clearTimeout(timer); resolve(JSON.parse(data)); });
            socket.write(JSON.stringify({...args, action, seq: ++seq}) + '\n');
        });
    }
    assert.equal((await request('snapshot')).pid, 123);
    assert.ok((await request('playlist', {id: 'not-in-library'})).error);
    await request('playlists'); await request('playlist', {id: 'PL_test'});
    assert.deepEqual(opened, ['PL_test']);
    await assert.rejects(createBridge({path, execute: async () => ({}), openPlaylist: async () => {}}), /ativo/);
    assert.equal((await request('snapshot')).data.ready, true, 'active socket must not be replaced');
    const ended = new Promise(resolve => socket.once('close', resolve));
    socket.write(JSON.stringify({seq: ++seq, action: 'eval', code: 'forbidden'}) + '\n');
    await ended;
    assert.ok(calls.every(r => r.action !== 'eval'));
    console.log('PASS: private music socket, request allowlist, playlist membership and active socket preservation');
})().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => {
    socket?.destroy(); close?.(); fs.rmSync(dir, {recursive: true, force: true});
});
