const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {join}=require('node:path');
const {spawnSync,execFileSync}=require('node:child_process');
const {paletteFromPixels,extractPalette}=require('../scripts/wallpaper-palette.cjs');
const {themePlan,applyTheme,fastfetchColors}=require('../scripts/wallpaper-theme.cjs');
const palette=paletteFromPixels(Buffer.from([255,0,0,255,0,0]));
function fixture() {
    const dir=fs.mkdtempSync('/tmp/archblato-theme-test-');
    const files={
        'archblato/theme.sh':Object.keys(palette).map(k=>`${k}="#123456"`).join('\n')+'\nBAR_BACKGROUND="old"\nPOPUP_BACKGROUND="old"\nFONT="personal"\nGAPS_IN=5\n',
        'hypr/theme.lua':'return { background = "#111111", text = "#ffffff", border = { active = "old", inactive = "old" }, rounding = 5 }\n',
        'hypr/hyprtoolkit.conf':'accent = 0x112233\nfont_family = Personal\n',
        'alacritty/theme.toml':'[colors.primary]\nbackground = "#111111"\nforeground = "#eeeeee"\n',
        'alacritty/alacritty.toml':'[font]\nsize = 10\n[colors.normal]\nblue = "#123456"\nred = "#ff0000"\n[window]\nopacity = 0.85\n',
        'fastfetch/config.jsonc':'{ // personal\n "logo":{"source":"ascii-aperture","color":{"1":"#111111","2":"#222222","3":"#333333",}},"display":{"color":{"keys":"#111111","title":"#222222","output":"#333333","separator":"#444444"}},"modules":["cpu","memory"] }',
        'gtk-3.0/gtk.css':"@import 'colors.css';\n/* personal CSS */\nbutton { border-radius: 7px; }\n"
    };
    for(const [file,body] of Object.entries(files)) {
        fs.mkdirSync(join(dir,file,'..'),{recursive:true});
        fs.writeFileSync(join(dir,file),body);
    }
    return {dir,files,clean:()=>fs.rmSync(dir,{recursive:true,force:true})};
}
function luminance(hex) {
    const c=hex.slice(1).match(/../g).map(h=>parseInt(h,16)/255).map(v=>v<=.04045?v/12.92:((v+.055)/1.055)**2.4);
    return c[0]*.2126+c[1]*.7152+c[2]*.0722;
}
test('palette follows image hue, stays dark and keeps readable accent/text',()=>{
    const blue=paletteFromPixels(Buffer.from([0,0,255]));
    assert.notEqual(blue.ACCENT,palette.ACCENT);
    for(const p of [palette,blue,paletteFromPixels(Buffer.from([128,128,128]))]) {
        for(const key of ['ACCENT','TEXT','TEXT_MUTED']) assert.ok((luminance(p[key])+.05)/(luminance(p.SURFACE_ALT)+.05)>4.5);
        assert.ok(luminance(p.BACKGROUND)<.02);
    }
    assert.throws(()=>paletteFromPixels(Buffer.alloc(0)));
});
test('ImageMagick extraction accepts spaces and brackets without interpreting filename syntax',()=>{
    const f=fixture();try {
        const image=join(f.dir,'wall [0] # red.png');
        execFileSync('magick',['-size','4x4','xc:red',image]);
        assert.equal(extractPalette(image).ACCENT,palette.ACCENT);
    }finally{f.clean();}
});
test('theme updates actual overrides, preserves custom settings and is repeatable',()=>{
    const f=fixture();try {
        let reloads=0;
        const backup=applyTheme(f.dir,palette,()=>reloads++);
        const read=file=>fs.readFileSync(join(f.dir,file),'utf8');
        assert.match(read('archblato/theme.sh'),/FONT="personal"\nGAPS_IN=5/);
        assert.match(read('alacritty/alacritty.toml'),/size = 10/);
        assert.ok(read('alacritty/alacritty.toml').includes(`blue = "${palette.PRIMARY}"`));
        assert.match(read('alacritty/alacritty.toml'),/red = "#ff0000"/);
        assert.ok(read('fastfetch/config.jsonc').includes(`"1":"${palette.ACCENT}"`));
        assert.match(read('fastfetch/config.jsonc'),/\/\/ personal/);
        assert.match(read('fastfetch/config.jsonc'),/"modules":\["cpu","memory"\]/);
        assert.match(read('gtk-3.0/gtk.css'),/personal CSS/);
        assert.match(read('gtk-3.0/gtk.css'),/border-radius: 7px/);
        assert.deepEqual(JSON.parse(read('archblato/quickshell/wallpaper-colors.json')),palette);
        assert.ok(read('archblato/quickshell/pear-theme.css').includes(`--cust-ytmusic-nowplaying-color: ${palette.ACCENT}`));
        const first=read('gtk-3.0/gtk.css');
        applyTheme(f.dir,palette,()=>reloads++);
        assert.equal(read('gtk-3.0/gtk.css'),first);
        assert.equal(reloads,2);
        const original=JSON.parse(fs.readFileSync(join(backup,'before.json'),'utf8'));
        assert.equal(original['archblato/theme.sh'].text,f.files['archblato/theme.sh']);
    }finally{f.clean();}
});
test('Fastfetch validates known color blocks and expands backup without replacing older originals',()=>{
    const f=fixture();try {
        assert.throws(()=>fastfetchColors('{"logo":{}}',palette),/Cores ausentes/);
        const backup=join(f.dir,'archblato/theme-backup');fs.mkdirSync(backup);
        const original={'archblato/theme.sh':{text:'original palette from previous task',mode:0o600}};
        fs.writeFileSync(join(backup,'before.json'),JSON.stringify(original));
        applyTheme(f.dir,palette,()=>{});
        const saved=JSON.parse(fs.readFileSync(join(backup,'before.json'),'utf8'));
        assert.deepEqual(saved['archblato/theme.sh'],original['archblato/theme.sh']);
        assert.equal(saved['fastfetch/config.jsonc'].text,f.files['fastfetch/config.jsonc']);
    }finally{f.clean();}
});
test('failed reload rolls back all changed files and removes only new generated files',()=>{
    const f=fixture();try {
        assert.throws(()=>applyTheme(f.dir,palette,()=>{throw new Error('reload failed');}),/reload failed/);
        for(const [file,body] of Object.entries(f.files)) assert.equal(fs.readFileSync(join(f.dir,file),'utf8'),body);
        assert.ok(!fs.existsSync(join(f.dir,'archblato/quickshell/wallpaper-colors.json')));
        assert.ok(!fs.existsSync(join(f.dir,'gtk-4.0/gtk.css')));
        assert.ok(!fs.existsSync(join(f.dir,'archblato/quickshell/pear-theme.css')));
    }finally{f.clean();}
});
test('unknown configuration shape fails before writes, and symlink targets are not replaced',()=>{
    const f=fixture();try {
        fs.unlinkSync(join(f.dir,'alacritty/theme.toml'));
        fs.symlinkSync(join(f.dir,'alacritty/alacritty.toml'),join(f.dir,'alacritty/theme.toml'));
        assert.throws(()=>applyTheme(f.dir,palette,()=>{}),/Destino não regular/);
        assert.equal(fs.readFileSync(join(f.dir,'archblato/theme.sh'),'utf8'),f.files['archblato/theme.sh']);
        fs.writeFileSync(join(f.dir,'archblato/theme.sh'),'FONT="personal"');
        assert.throws(()=>themePlan(f.dir,palette),/Variável ausente/);
    }finally{f.clean();}
});
test('broken symlink targets and preexisting temporary files remain untouched',()=>{
    const f=fixture();try {
        const link=join(f.dir,'gtk-4.0/archblato-colors.css');
        fs.mkdirSync(join(f.dir,'gtk-4.0'));
        fs.symlinkSync(join(f.dir,'missing.css'),link);
        assert.throws(()=>applyTheme(f.dir,palette,()=>{}),/Destino não regular/);
        assert.ok(fs.lstatSync(link).isSymbolicLink());
        fs.unlinkSync(link);
        const temp=join(f.dir,`archblato/theme.sh.archblato-${process.pid}.tmp`);
        fs.writeFileSync(temp,'another operation');
        assert.throws(()=>applyTheme(f.dir,palette,()=>{}),/EEXIST/);
        assert.equal(fs.readFileSync(temp,'utf8'),'another operation');
        assert.equal(fs.readFileSync(join(f.dir,'archblato/theme.sh'),'utf8'),f.files['archblato/theme.sh']);
    }finally{f.clean();}
});
test('White Orchis GTK4 link becomes a local import and is restored on failure',()=>{
    const f=fixture();try {
        const css=join(f.dir,'gtk-4.0/gtk.css');
        const target='/usr/share/themes/Orchis-Dark-Compact/gtk-4.0/gtk.css';
        fs.mkdirSync(join(f.dir,'gtk-4.0'));
        fs.symlinkSync(target,css);
        assert.throws(()=>applyTheme(f.dir,palette,()=>{throw new Error('reload failed');}),/reload failed/);
        assert.equal(fs.readlinkSync(css),target,'rollback restores original link, not theme contents');
        const backup=applyTheme(f.dir,palette,()=>{});
        assert.ok(fs.lstatSync(css).isFile());
        const content=fs.readFileSync(css,'utf8');
        assert.ok(content.includes(`@import url("file://${target}");`));
        assert.match(content,/@import 'archblato-colors.css';/);
        assert.deepEqual(JSON.parse(fs.readFileSync(join(backup,'before.json'),'utf8'))['gtk-4.0/gtk.css'],{link:target});
        applyTheme(f.dir,palette,()=>{});
        assert.equal(fs.readFileSync(css,'utf8'),content,'future changes retain exactly one base import');
    }finally{f.clean();}
});
test('wallpaper command changes wallpaper and theme using only an isolated config and fake hyprctl',()=>{
    const f=fixture();try {
        const bin=join(f.dir,'bin');fs.mkdirSync(bin);
        fs.writeFileSync(join(bin,'hyprctl'),'#!/bin/sh\nprintf "%s\\n" "$*" >> "$ARCHBLATO_CONFIG_ROOT/calls"\n',{mode:0o700});
        // Never let this integration touch the real mouse, even with an available system bus.
        fs.writeFileSync(join(bin,'ratbagctl'),'#!/bin/sh\nexit 0\n',{mode:0o700});
        const gallery=join(f.dir,'gallery');fs.mkdirSync(gallery);
        const image=join(gallery,'blue image.png');execFileSync('magick',['-size','4x4','xc:blue',image]);
        const env={...process.env,ARCHBLATO_CONFIG_ROOT:f.dir,ARCHBLATO_WALLPAPER_DIR:gallery,PATH:bin+':'+process.env.PATH};
        const script=join(__dirname,'../scripts/wallpapers');
        const result=spawnSync('bash',[script,'set',image],{env,encoding:'utf8'});
        assert.equal(result.status,3,'absent mouse is partial RGB status, not rollback of desktop colors');
        assert.match(fs.readFileSync(join(f.dir,'calls'),'utf8'),/hyprpaper wallpaper/);
        assert.ok(fs.existsSync(join(f.dir,'archblato/quickshell/wallpaper-colors.json')));
        fs.writeFileSync(join(bin,'ratbagctl'),`#!/usr/bin/env node
const fs=require('node:fs'), a=process.argv.slice(2), file=process.env.ARCHBLATO_CONFIG_ROOT+'/mouse-color';
if(a[0]==='list') console.log('fake-g203: Logitech G203 LIGHTSYNC Gaming Mouse');
else if(a[1]==='info') console.log('Model: usb:046d:c092:0\\nNumber of Profiles: 1\\nNumber of Leds: 1\\nProfile 0: (active)\\nLED: 0, depth: rgb, mode: breathing, color: '+(fs.existsSync(file)?fs.readFileSync(file,'utf8'):'560097')+', duration: 6200, brightness: 255');
else if(a.join(' ').startsWith('fake-g203 profile 0 led 0 set color ')) fs.writeFileSync(file,a[7]);
else process.exit(1);
`,{mode:0o700});
        const success=spawnSync('bash',[script,'set',image],{env,encoding:'utf8'});
        assert.equal(success.status,0,success.stderr);
        assert.equal(fs.readFileSync(join(f.dir,'mouse-color'),'utf8'),extractPalette(image).ACCENT.slice(1));
        assert.equal(JSON.parse(fs.readFileSync(join(f.dir,'archblato/theme-backup/mouse-before.json'),'utf8')).color,'560097');
        fs.writeFileSync(join(f.dir,'archblato/theme.sh'),'broken config');
        assert.equal(spawnSync('bash',[script,'set',image],{env}).status,2,'partial success is reported');
    }finally{f.clean();}
});
