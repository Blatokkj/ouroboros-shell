const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {runInNewContext}=require('node:vm');
const data={};
runInNewContext(readFileSync(join(__dirname,'../ProfileData.js'),'utf8'),data);
test('personal profile roundtrips Unicode, quotes and local photo paths',()=>{
 const profile=data.normalize({displayName:'  Blato "宇"  ',computerName:'White',avatar:'/tmp/foto #1 é.png'});
 assert.equal(profile.displayName,'Blato "宇"');
 assert.equal(profile.avatar,'file:///tmp/foto%20%231%20%C3%A9.png');
 assert.equal(JSON.stringify(data.parse(JSON.stringify(profile))),JSON.stringify(profile));
});
test('profile validation rejects empty names, control characters and remote photos',()=>{
 for(const name of ['', ' ', 'a\nb', 'a'.repeat(61)])
  assert.throws(()=>data.normalize({displayName:name,computerName:'White',avatar:''}));
 for(const avatar of ['https://example.com/photo.png','file://remote/photo.png','relative.png','file:///tmp/%00.png'])
  assert.throws(()=>data.normalize({displayName:'blato',computerName:'White',avatar}));
 assert.throws(()=>data.parse('{broken'));
 assert.throws(()=>data.parse('{"version":2}'));
});
