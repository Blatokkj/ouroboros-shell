const assert=require('node:assert/strict');
const {spawn,spawnSync,execFileSync:run}=require('node:child_process');
const {mkdtempSync,rmSync,readFileSync,mkdirSync,writeFileSync,renameSync,unlinkSync}=require('node:fs');
const {join}=require('node:path');
const {pathToFileURL}=require('node:url');
if(!process.argv.includes('--private-bus')) {
 const result=spawnSync('dbus-run-session',['--',process.execPath,__filename,'--private-bus'],{stdio:'inherit'});
 process.exit(result.status??1);
}
const dir=mkdtempSync('/tmp/archblato-profile-test-');
const file=join(dir,'profile.json');
const colors=join(dir,'wallpaper-colors.json');
const avatar=pathToFileURL(join(__dirname,'fixtures/avatar.svg')).href;
const config=join(__dirname,'../tests-profile.qml');
const env={...process.env,QT_QPA_PLATFORM:'offscreen',XDG_RUNTIME_DIR:dir,ARCHBLATO_TEST_PROFILE:file,ARCHBLATO_TEST_COLORS:colors};
let child,log='';
const pause=ms=>new Promise(r=>setTimeout(r,ms));
const ipc=(method,...args)=>run('qs',['ipc','--path',config,'call','profile-test',method,...args],{env,encoding:'utf8',timeout:3000,stdio:['ignore','pipe','pipe']}).trim();
const status=()=>JSON.parse(ipc('status'));
async function until(check){for(let i=0;i<50;i++){try{if(check())return;}catch{}await pause(80);}throw new Error('Profile timeout');}
async function start(path=file){env.ARCHBLATO_TEST_PROFILE=path;child=spawn('qs',['--path',config,'--no-color'],{env});child.stdout.on('data',d=>log+=d);child.stderr.on('data',d=>log+=d);await until(()=>status().ready);}
async function stop(){if(child&&child.exitCode===null){const done=new Promise(r=>child.once('exit',r));child.kill('SIGTERM');await done;}}
(async()=>{
 try{
  await start();
  const generation=status().generation;
  assert.equal(status().accent,'#9b5cff');
  const palette=require('../scripts/wallpaper-palette.cjs').paletteFromPixels(Buffer.from([255,0,0]));
  // Atomic creation/replacement is exactly how the wallpaper script writes colors.
  const putColors=value=>{writeFileSync(colors+'.tmp',value);renameSync(colors+'.tmp',colors);};
  putColors(JSON.stringify(palette));
  await until(()=>status().accent===palette.ACCENT);
  putColors('{invalid json');
  await pause(250);
  assert.equal(status().accent,palette.ACCENT,'malformed palette keeps previous colors');
  const blue=require('../scripts/wallpaper-palette.cjs').paletteFromPixels(Buffer.from([0,0,255]));
  putColors(JSON.stringify(blue));
  await until(()=>status().accent===blue.ACCENT);
  unlinkSync(colors);
  await until(()=>status().accent==='#9b5cff');
  assert.equal(child.exitCode,null,'color changes do not restart the shell process');
  assert.equal(status().generation,generation,'color changes do not reload the QML root either');
  assert.equal(status().computer,'White');
  assert.equal(ipc('save','Blato Teste','White teste',avatar),'true');
  await until(()=>!status().saving && status().name==='Blato Teste');
  assert.equal(status().lockName,'Blato Teste');
  assert.equal(status().lockAvatar,avatar,'lock consumes committed profile photo');
  await until(()=>status().avatarReady);
  const saved=readFileSync(file,'utf8');
  assert.equal(JSON.parse(saved).computerName,'White teste');
  assert.equal(ipc('save','','White',''),'false');
  assert.equal(readFileSync(file,'utf8'),saved,'invalid input cannot overwrite saved data');
  await stop();await start();
  assert.equal(status().name,'Blato Teste','profile survives full process restart');
  assert.equal(status().avatar,avatar);
  assert.equal(status().lockAvatar,avatar,'photo also reaches lock after restart');
  ipc('save','Blato Teste','White teste','');
  await until(()=>!status().saving && status().avatar==='');
  assert.match(status().lockAvatar,/\/var\/lib\/AccountsService\/icons\//);
  await stop();
  const invalidPath=join(dir,'not-a-file');mkdirSync(invalidPath);
  await start(invalidPath);
  ipc('save','Cannot persist','White','');
  await until(()=>!status().saving && status().error);
  assert.notEqual(status().name,'Cannot persist','failed write does not commit draft');
  assert.ok(!/TypeError|ReferenceError|Failed to load configuration/.test(log),log);
  console.log('PASS: profile/lock photo, atomic save, validation, restart persistence, failed writes and live palette replacement/recovery');
 }catch(e){console.error(log);console.error(e);process.exitCode=1;}
 finally{await stop();rmSync(dir,{recursive:true,force:true});}
})();
