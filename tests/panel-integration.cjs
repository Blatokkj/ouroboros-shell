// Explicit --live: opens short-lived test surfaces. Never changes real devices or locks the session.
const assert=require('node:assert/strict');
const {spawn,execFileSync:run}=require('node:child_process');
const {join}=require('node:path');
if(!process.argv.includes('--live')) {console.error('Use --live in an unlocked Wayland session.');process.exit(2);}
const config=join(__dirname,'../tests-panels.qml');
const liveConfig=join(__dirname,'..');
assert.equal(run('qs',['ipc','--path',liveConfig,'call','lock','status'],{encoding:'utf8'}).trim(),'unlocked');
const child=spawn('qs',['--path',config,'--no-color']);
let log='';
child.stdout.on('data',d=>log+=d);child.stderr.on('data',d=>log+=d);
const pause=ms=>new Promise(r=>setTimeout(r,ms));
const ipc=(method,...args)=>run('qs',['ipc','--path',config,'call','panel-test',method,...args.map(String)],
    {encoding:'utf8',timeout:3000,stdio:['ignore','pipe','pipe']});
const state=()=>JSON.parse(ipc('status'));
async function until(check) {
    for(let i=0;i<50;i++){try{if(check())return;}catch{} await pause(60);}
    throw new Error('Panel condition timed out');
}
(async()=>{
 try {
    await until(()=>!state().center.opened);
    ipc('open','center');
    await until(()=>state().center.input && !state().center.animating);
    ipc('close');
    let s=state().center;
    assert.ok(!s.opened && !s.input && !s.enabled,'input is released before exit finishes');
    // Reopen before settling, then replace the surface with real quick settings.
    ipc('open','center');
    await until(()=>state().center.opened && !state().center.animating);
    ipc('open','wifi');
    await until(()=>state().quick.input && !state().quick.animating);
    assert.ok(!state().center.rendered,'replacement cannot leave a second main panel drawn');
    assert.equal(state().center.top,-100,'attached panel really travels outside the surface');
    assert.equal(state().scan,'wifi');
    ipc('close');
    assert.equal(state().scan,'','scan stops on logical close, not after animation');
    await until(()=>!state().quick.rendered);
    ipc('open','calendar');
    await until(()=>state().calendar.input && !state().calendar.animating);
    assert.equal(state().calendar.globalY,0,'attached calendar touches the physical monitor edge');
    ipc('narrow');
    await until(()=>state().calendar.scale<1 && state().calendar.width<=332);
    assert.ok(Math.abs(state().calendar.contentWidth-state().calendar.width)<1,
        'fitted content is scaled, not just its window');
    ipc('lockTest',true);
    s=state();
    for(const panel of [s.center,s.calendar,s.quick])
        assert.ok(!panel.rendered && !panel.input && !panel.animating,'fake lock dismisses immediately');
    ipc('open','wifi');
    assert.ok(!state().quick.opened && !state().quick.rendered);
    assert.equal(state().scan,'');
    ipc('lockTest',false);
    ipc('open','calendar');
    await until(()=>state().calendar.input && !state().calendar.animating);
    ipc('close');
    await until(()=>!state().calendar.rendered);
    ipc('profileOpen');
    await until(()=>state().profile.input && !state().profile.animating);
    ipc('photoChoose');
    await until(()=>state().choosingPhoto);
    await pause(300);
    assert.ok(state().profile.opened && !state().profile.input,'photo chooser suspends focus without closing the panel');
    ipc('photoDismiss');
    await until(()=>!state().choosingPhoto && state().profile.input);
    ipc('photoChoose');
    await until(()=>state().choosingPhoto);
    ipc('photoCancel');
    await until(()=>!state().choosingPhoto && !state().profile.rendered);
    assert.ok(!/TypeError|ReferenceError|Binding loop|Failed to load configuration/.test(log),log);
    console.log('PASS: native popup lifecycle, input release, exclusivity, simulated lock/unlock, narrow calendar and photo chooser focus');
 }catch(e){console.error(log);console.error(e);process.exitCode=1;}
 finally {
    const exited=new Promise(resolve=>child.once('exit',resolve));
    if(child.exitCode===null){child.kill('SIGTERM');await exited;}
 }
})();
