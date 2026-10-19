const {execFileSync} = require('node:child_process');
const {readFileSync, statSync} = require('node:fs');

function hsl(r, g, b) {
    r /= 255; g /= 255; b /= 255;
    const hi = Math.max(r,g,b), lo = Math.min(r,g,b), d = hi-lo, l = (hi+lo)/2;
    let h = 0;
    if (d) h = (hi === r ? (g-b)/d + (g < b ? 6 : 0) : hi === g ? (b-r)/d+2 : (r-g)/d+4) / 6;
    return [h, d ? d/(1-Math.abs(2*l-1)) : 0, l];
}

function hex(h,s,l) {
    const hue = n => {
        const k = (n+h*12)%12;
        return Math.round(255*(l-s*Math.min(l,1-l)*Math.max(-1,Math.min(k-3,9-k,1))));
    };
    return '#'+[hue(0),hue(8),hue(4)].map(v=>v.toString(16).padStart(2,'0')).join('');
}

function luminance(color) {
    const c=color.slice(1).match(/../g).map(v=>parseInt(v,16)/255)
        .map(v=>v<=.04045?v/12.92:((v+.055)/1.055)**2.4);
    return c[0]*.2126+c[1]*.7152+c[2]*.0722;
}

function readableTone(h,s,lightness,background) {
    const floor=(luminance(background)+.05)*4.55-.05;
    if (luminance(hex(h,s,lightness))>=floor) return hex(h,s,lightness);
    // Dark wallpaper accents sometimes need lifting for small text/icons, not pastel by default.
    let low=lightness, high=1;
    for(let i=0;i<14;i++) {
        const mid=(low+high)/2;
        if(luminance(hex(h,s,mid))>=floor) high=mid; else low=mid;
    }
    return hex(h,s,high);
}

function paletteFromPixels(pixels) {
    if (!pixels.length || pixels.length % 3) throw new Error('Amostra RGB inválida');
    const buckets = new Map();
    let totalLightness=0, totalLuminance=0;
    for (let i=0;i<pixels.length;i+=3) {
        const rgb = [pixels[i],pixels[i+1],pixels[i+2]];
        const [h,s,l] = hsl(...rgb);
        totalLightness+=l;
        totalLuminance+=luminance('#'+rgb.map(v=>v.toString(16).padStart(2,'0')).join(''));
        if (s < .15 || l < .08 || l > .92) continue;
        const key = Math.floor(h*24);
        const bucket = buckets.get(key) || {weight:0, rgb:[0,0,0]};
        const weight = s * (1-Math.abs(l-.5));
        bucket.weight += weight;
        rgb.forEach((v,c)=>bucket.rgb[c]+=v*weight);
        buckets.set(key,bucket);
    }
    const winner = [...buckets.values()].sort((a,b)=>b.weight-a.weight)[0];
    const count=pixels.length/3;
    const [h,s,sourceLightness] = winner ? hsl(...winner.rgb.map(v=>v/winner.weight)) : [270/360,.35,totalLightness/count];
    const darkSurface=(lightness,fraction)=>{
        const limit=totalLuminance/count*fraction;
        while(lightness>0 && luminance(hex(h,.13,lightness))>limit) lightness=Math.max(0,lightness-.001);
        return hex(h,.13,lightness);
    };
    const background=darkSurface(.045,.30), surface=darkSurface(.085,.50), surfaceAlt=darkSurface(.13,.75);
    // About 15% lower HSL lightness than the dominant wallpaper color, limited by readability.
    const accentLightness=Math.min(.60,sourceLightness*.85);
    const accent=readableTone(h,Math.max(.35,Math.min(.7,s)),accentLightness,surfaceAlt);
    return {
        BACKGROUND:background, SURFACE:surface, SURFACE_ALT:surfaceAlt,
        TEXT:hex(h,.10,.96), TEXT_ALT:hex(h,.12,.86), TEXT_MUTED:hex(h,.13,.66),
        PRIMARY:accent, ACCENT:accent, SECONDARY:readableTone((h+.08)%1,.5,Math.min(.64,accentLightness+.04),surfaceAlt),
        TOOLKIT:accent.slice(1), BORDER_ACTIVE:`rgba(${accent.slice(1)}ff)`,
        BORDER_INACTIVE:`rgba(${hex(h,.12,.35).slice(1)}aa)`
    };
}

function extractPalette(path) {
    if (!statSync(path).isFile() || statSync(path).size > 64*1024*1024) {
        throw new Error('Wallpaper deve ser um arquivo de até 64 MiB');
    }
    // Read through stdin: spaces, # and brackets in filenames cannot become ImageMagick syntax.
    const pixels = execFileSync('magick', ['-','-auto-orient','-thumbnail','64x64!',
        '-background','#0b0b0d','-alpha','remove','-colorspace','sRGB','-depth','8','rgb:-'],
    {input:readFileSync(path),timeout:15000,maxBuffer:64*1024});
    return paletteFromPixels(pixels);
}

module.exports = {extractPalette, paletteFromPixels};
