const {test}=require('node:test');
const assert=require('node:assert/strict');
const {syncMouse,mouseState}=require('../scripts/mouse-theme.cjs');
const info=(color='560097',mode='breathing',dirty=false)=>`Model: usb:046d:c092:0
Number of Profiles: 1
Number of Leds: 1
Profile 0: (active)${dirty?' (dirty)':''}
  LED: 0, depth: rgb, mode: ${mode}${['on','breathing'].includes(mode)?`, color: ${color}`:''}${['cycle','breathing'].includes(mode)?', duration: 6200, brightness: 255':''}`;
function fake({mode='breathing',color='560097',dirty=false,confirm=true}={}) {
    const calls=[];let current=color,currentMode=mode;
    return {calls,run:args=>{
        calls.push(args);
        if(args[0]==='list') return 'new-device-id: Logitech G203 LIGHTSYNC Gaming Mouse';
        if(args[1]==='info') return info(current,currentMode,dirty);
        assert.deepEqual(args.slice(0,7),['new-device-id','profile','0','led','0','set','color']);
        if(confirm){current=args[7];if(args[8]==='mode')currentMode=args[9];}
        return '';
    }};
}
test('physical G203: one LED commit, existing breathing/brightness/duration preserved',async()=>{
    const f=fake();let backup;
    assert.equal(await syncMouse('#ab12ef',{...f,pause:async()=>{},beforeChange:state=>backup=state}),'updated');
    assert.equal(backup.color,'560097');assert.equal(backup.mode,'breathing');
    assert.deepEqual(f.calls.filter(a=>a.includes('set')),[['new-device-id','profile','0','led','0','set','color','ab12ef']]);
    assert.ok(f.calls.every(a=>!a.includes('dpi')&&!a.includes('button')));
});
test('already matching color does not write or back up again',async()=>{
    const f=fake({color:'ab12ef'});
    assert.equal(await syncMouse('#ab12ef',{...f,beforeChange:()=>assert.fail('unnecessary backup')}),'unchanged');
    assert.equal(f.calls.length,2);
});
test('pending Piper edits and incompatible hardware refuse every write',async()=>{
    const f=fake({dirty:true});
    await assert.rejects(syncMouse('#ab12ef',f),/pendentes/);
    assert.ok(!f.calls.some(a=>a.includes('set')));
    assert.throws(()=>mouseState(info().replace('c092','c099')),/inesperado/);
    await assert.rejects(syncMouse('#ab12ef',{run:()=>''}),/ausente/);
    await assert.rejects(syncMouse('#ab12ef',{run:()=>Array(2).fill('x: Logitech G203 LIGHTSYNC Gaming Mouse').join('\n')}),/ambígua/);
});
test('backup failure and concurrent LED changes abort before commit',async()=>{
    const f=fake();
    await assert.rejects(syncMouse('#ab12ef',{...f,beforeChange:()=>{throw new Error('backup failed');}}),/backup failed/);
    assert.ok(!f.calls.some(a=>a.includes('set')));
    let reads=0;
    const g=fake();const run=args=>args[1]==='info'?info(++reads===1?'560097':'112233'):g.run(args);
    await assert.rejects(syncMouse('#ab12ef',{run}),/mudou/);
    assert.ok(!g.calls.some(a=>a.includes('set')));
});
test('real CLI formats: solid/cycle work, off stays off, failed asynchronous commit is reported',async()=>{
    const cycle=fake({mode:'cycle'});
    await syncMouse('#ab12ef',{...cycle,pause:async()=>{}});
    assert.deepEqual(cycle.calls.find(a=>a.includes('set')).slice(-2),['mode','on']);
    const solid=fake({mode:'on'});assert.equal(await syncMouse('#ab12ef',{...solid,pause:async()=>{}}),'updated');
    const off=fake({mode:'off'});await assert.rejects(syncMouse('#ab12ef',off),/desligado/);
    assert.ok(!off.calls.some(a=>a.includes('set')));
    const broken=fake({confirm:false});
    await assert.rejects(syncMouse('#ab12ef',{...broken,pause:async()=>{}}),/não confirmou/);
    assert.equal(broken.calls.filter(a=>a.includes('set')).length,1);
    await assert.rejects(syncMouse('bad',{run:()=>assert.fail('invalid input reached command')}),/inválida/);
});
