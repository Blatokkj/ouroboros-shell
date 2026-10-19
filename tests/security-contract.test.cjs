const {test} = require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const source=readFileSync(join(__dirname,'../SessionLock.qml'),'utf8');
test('lock retains native Wayland surfaces, PAM and no unlock IPC',()=>{
    assert.match(source,/WlSessionLock\s*\{/);
    assert.match(source,/WlSessionLockSurface\s*\{/);
    assert.match(source,/PamContext\s*\{/);
    assert.match(source,/result === PamResult.Success[\s\S]*?sessionLock.locked = false/);
    const ipc=source.slice(source.lastIndexOf('IpcHandler'));
    assert.doesNotMatch(ipc,/function\s+(unlock|authenticate)/);
    assert.match(ipc,/function lock\(/);
});
test('UI state mirror cannot unlock native backend',()=>{
 const mirror=readFileSync(join(__dirname,'../SessionLockState.qml'),'utf8');
 assert.doesNotMatch(mirror,/backend\.(locked|secure)\s*=/);
 assert.match(mirror,/sampledLocked = backend.locked/);
 assert.match(mirror,/onSecureStateChanged/);
});
