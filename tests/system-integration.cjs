// Private bus and fake brightnessctl: never changes White's radios or brightness.
const assert = require('node:assert/strict');
const {spawn, spawnSync, execFileSync} = require('node:child_process');
const {mkdtempSync, readFileSync, rmSync} = require('node:fs');
const {join} = require('node:path');
const {tmpdir} = require('node:os');
if (!process.argv.includes('--private-bus')) {
    const result = spawnSync('dbus-run-session', ['--', process.execPath, __filename, '--private-bus'], {stdio:'inherit'});
    process.exit(result.status ?? 1);
}
const dir = mkdtempSync(join(tmpdir(), 'archblato-system-test-'));
const logPath = join(dir,'brightness.log');
const env = {...process.env, QT_QPA_PLATFORM:'offscreen', XDG_RUNTIME_DIR:dir,
    PATH:join(__dirname,'fixtures')+':'+process.env.PATH, ARCHBLATO_TEST_BRIGHTNESS_LOG:logPath};
const config=join(__dirname,'../tests-system.qml');
const shell=spawn('qs',['--path',config,'--no-color'],{env});
let log='';
shell.stdout.on('data',d=>log+=d); shell.stderr.on('data',d=>log+=d);
const delay=ms=>new Promise(r=>setTimeout(r,ms));
const ipc=(method,...args)=>execFileSync('qs',['ipc','--path',config,'call','test',method,...args.map(String)],{env,encoding:'utf8',timeout:3000,stdio:['ignore','pipe','pipe']}).trim();
const status=()=>JSON.parse(ipc('status'));
const calls=()=>{try{return readFileSync(logPath,'utf8').trim().split('\n').filter(Boolean).map(JSON.parse);}catch{return []}};
async function until(check) { for(let i=0;i<60;i++){try{if(check())return;}catch{} await delay(100);}throw new Error('Timeout');}
(async()=>{
 try {
    await until(()=>status().ram>0);
    assert.deepEqual(JSON.parse(ipc('networkChecks')),[]);
    ipc('burst');
    assert.equal(status().percent,90,'immediate visual feedback');
    await until(()=>status().refreshes===1);
    assert.deepEqual(calls(),[['set','90%']],'90 drag events coalesce into one process');
    ipc('brightnessTo',150);
    await until(()=>status().refreshes===2);
    assert.deepEqual(calls()[1],['set','100%']);
    ipc('brightnessTo',20);
    await until(()=>calls().length===3);
    ipc('brightnessTo',30); ipc('brightnessTo',70);
    await until(()=>calls().length===4 && status().refreshes>=3);
    assert.deepEqual(calls().at(-1),['set','70%'],'latest request wins while process completes');
    ipc('brightnessTo',13);
    await until(()=>status().error.length>0);
    await delay(2400);
    assert.equal(status().percent,40,'failed write eventually falls back to hardware sample');
    const s=status();
    assert.ok(s.uptime>0 && s.total>s.ram && s.cpu>=0 && s.cpu<=100);
    const total=Number(/^MemTotal:\s+(\d+)/m.exec(readFileSync('/proc/meminfo','utf8'))[1]);
    assert.equal(s.total,total,'FileView agrees with procfs');
    assert.ok(!/TypeError|ReferenceError|Failed to load configuration/.test(log),log);
    console.log('PASS: shared network/Bluetooth, scan leases, brightness debounce/clamp and native procfs metrics');
 } catch(e) { console.error(log); console.error(e); process.exitCode=1; }
 finally { shell.kill('SIGTERM'); await new Promise(r=>shell.once('exit',r)); rmSync(dir,{recursive:true,force:true}); }
})();
