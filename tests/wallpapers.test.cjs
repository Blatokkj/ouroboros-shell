const {test}=require('node:test');
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const {mkdtempSync,rmSync,mkdirSync,statSync,utimesSync}=require('node:fs');
const {join}=require('node:path');
const script=join(__dirname,'../scripts/wallpapers');
test('missing wallpaper folder is an error, not a successful empty gallery',()=>{
 const result=spawnSync('bash',[script,'list'],{env:{...process.env,ARCHBLATO_WALLPAPER_DIR:'/proc/archblato-folder-does-not-exist'},encoding:'utf8'});
 assert.equal(result.status,1);assert.match(result.stderr,/Pasta de wallpapers indisponível/);
});
test('set rejects paths outside the personal wallpaper folder before calling hyprpaper',()=>{
 const dir=mkdtempSync('/tmp/archblato-wallpaper-test-');
 try{
  const result=spawnSync('bash',[script,'set','/etc/hosts'],{env:{...process.env,ARCHBLATO_WALLPAPER_DIR:dir},encoding:'utf8'});
  assert.equal(result.status,1);assert.match(result.stderr,/fora da pasta permitida/);
 }finally{rmSync(dir,{recursive:true,force:true});}
});
test('WebP previews handle spaces, stay cached and refresh after the image changes',()=>{
 const dir=mkdtempSync('/tmp/archblato-wallpaper-test-');
 const gallery=join(dir,'gallery with spaces');
 mkdirSync(gallery);
 const source=join(gallery,'purple wallpaper.webp');
 const env={...process.env,ARCHBLATO_WALLPAPER_DIR:gallery,TMPDIR:dir};
 const list=()=>{
  const result=spawnSync('bash',[script,'list'],{env,encoding:'utf8'});
  assert.equal(result.status,0,result.stderr);
  const row=result.stdout.split('\n').find(line=>line.startsWith('PREVIEW\t'));
  assert.ok(row,'WebP must have a thumbnail');
  const [,original,preview]=row.split('\t');
  assert.equal(original,source);
  assert.ok(preview.startsWith(dir+'/'),'cache remains isolated from personal previews');
  return preview;
 };
 try{
  const made=spawnSync('magick',['-size','8x8','xc:#552277',source],{encoding:'utf8'});
  assert.equal(made.status,0,made.stderr);
  const preview=list();
  const size=spawnSync('magick',['identify','-format','%wx%h',preview],{encoding:'utf8'});
  assert.equal(size.stdout,'480x270');
  const cached=statSync(preview).mtimeMs;
  assert.equal(list(),preview);
  assert.equal(statSync(preview).mtimeMs,cached,'opening again must not reconvert');
  // Make the cache older deterministically, without depending on filesystem clock resolution.
  const old=new Date(1000);
  utimesSync(preview,old,old);
  list();
  assert.ok(statSync(preview).mtimeMs>1000,'modified images regenerate their preview');
 }finally{rmSync(dir,{recursive:true,force:true});}
});
