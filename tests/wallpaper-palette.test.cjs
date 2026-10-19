const {test}=require('node:test');
const assert=require('node:assert/strict');
const {paletteFromPixels}=require('../scripts/wallpaper-palette.cjs');
function luminance(color) {
    const c=color.slice(1).match(/../g).map(v=>parseInt(v,16)/255).map(v=>v<=.04045?v/12.92:((v+.055)/1.055)**2.4);
    return c[0]*.2126+c[1]*.7152+c[2]*.0722;
}
function color(rgb){return '#'+rgb.map(v=>v.toString(16).padStart(2,'0')).join('');}
test('surfaces are darker than sampled wallpaper, including near-black and saturated blue',()=>{
    for(const rgb of [[0,0,0],[1,1,1],[0,0,12],[40,10,60],[128,128,128],[255,255,255],[0,0,255],[255,0,0]]) {
        const p=paletteFromPixels(Buffer.from(rgb));
        const source=luminance(color(rgb));
        for(const key of ['BACKGROUND','SURFACE','SURFACE_ALT']) assert.ok(luminance(p[key])<=source*.75+1e-9,key+' '+color(rgb));
    }
});
test('bright wallpaper yields darker accents instead of fixed pastel lightness',()=>{
    const rgb=[220,150,240], p=paletteFromPixels(Buffer.from(rgb));
    assert.ok(luminance(p.ACCENT)<luminance(color(rgb)));
    const bright=paletteFromPixels(Buffer.from([200,220,180]));
    const dark=paletteFromPixels(Buffer.from([60,90,30]));
    assert.ok(luminance(dark.ACCENT)<luminance(bright.ACCENT));
});
test('darkening retains readable text and both accents across representative hues',()=>{
    for(const rgb of [[255,0,0],[0,255,0],[0,0,255],[120,0,120],[255,255,0],[0,255,255],[0,0,0],[128,128,128],[255,255,255]]) {
        const p=paletteFromPixels(Buffer.from(rgb));
        for(const key of ['ACCENT','SECONDARY','TEXT','TEXT_ALT','TEXT_MUTED']) {
            assert.ok((luminance(p[key])+.05)/(luminance(p.SURFACE_ALT)+.05)>=4.5,key+' '+color(rgb));
        }
    }
});
