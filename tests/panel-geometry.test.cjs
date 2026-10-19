const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {runInNewContext}=require('node:vm');
const geometry={};
runInNewContext(readFileSync(require('node:path').join(__dirname,'../PanelGeometry.js'),'utf8'),geometry);
test('panels fit White and smaller logical viewports without clipping or enlargement',()=>{
 for(const [w,h] of [[1920,1080],[1366,768],[1280,720],[960,540],[640,360],[360,300]]){
  for(const [pw,ph] of [[480,480],[480,518],[380,458],[300,180],[390,468]]){
   const fit=geometry.fit(pw,ph,w-24,h-60);
   assert.ok(fit.width<=w-24 && fit.height<=h-60);
   assert.ok(fit.scale>0 && fit.scale<=1);
   assert.ok(pw*fit.scale-fit.width<1 && ph*fit.scale-fit.height<1);
  }
 }
 assert.equal(geometry.fit(480,480,1896,1020).scale,1);
});
