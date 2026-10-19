// Opt-in current-session measurement. Does not pretend to reconstruct a pre-refactor baseline.
const {execFileSync:run}=require('node:child_process');
const {readFileSync}=require('node:fs');
const {resolve}=require('node:path');
if(!process.argv.includes('--live')) {console.error('Use --live in an unlocked session; this measures idle and opens/closes the central (about 25 seconds).');process.exit(2);}
const config=resolve(__dirname,'..');
if(run('qs',['ipc','--path',config,'call','lock','status'],{encoding:'utf8'}).trim()!=='unlocked') {
 console.error('Unlock the session before measuring.');process.exit(2);
}
const instances=JSON.parse(run('qs',['list','--path',config,'-j'],{encoding:'utf8'}));
const pid=instances[0].pid;
const ticks=Number(run('getconf',['CLK_TCK'],{encoding:'utf8'}));
const monitor=JSON.parse(run('hyprctl',['monitors','-j'],{encoding:'utf8'})).find(m=>m.focused).name;
const ipc=(method,...args)=>run('qs',['ipc','--path',config,'call','control-center-'+monitor,method,...args],{encoding:'utf8'});
const status=()=>JSON.parse(ipc('status'));
const pause=ms=>new Promise(r=>setTimeout(r,ms));
function sample() {
 const fields=readFileSync('/proc/'+pid+'/stat','utf8').split(') ')[1].split(' ');
 const rss=Number(/^VmRSS:\s+(\d+)/m.exec(readFileSync('/proc/'+pid+'/status','utf8'))[1])/1024;
 return {time:process.hrtime.bigint(),cpu:(Number(fields[11])+Number(fields[12]))/ticks,rssMiB:rss};
}
function report(stage,a,b) {
 const seconds=Number(b.time-a.time)/1e9;
 console.log(JSON.stringify({stage,seconds:+seconds.toFixed(2),cpuPercentOneCore:+(100*(b.cpu-a.cpu)/seconds).toFixed(2),rssMiB:+b.rssMiB.toFixed(1)}));
}
(async()=>{
 const before=status();
 try {
  ipc('close');await pause(400);
  let a=sample();await pause(10000);report('idle',a,sample());
  a=sample();
  for(let i=0;i<20;i++){ipc('open','controls');await pause(260);ipc('close');await pause(190);}
  report('20 open-close cycles',a,sample());
  await pause(500);
  console.log(JSON.stringify({settled:!status().rendered && !status().animating}));
 }finally{if(before.visible)ipc('open',before.tab);else ipc('close');}
})();
