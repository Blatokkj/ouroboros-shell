// Personal Archblato targets only. No system packages, sudo, or shell restart.
const fs = require('node:fs');
const {join, dirname} = require('node:path');
const {execFileSync} = require('node:child_process');
const {extractPalette} = require('./wallpaper-palette.cjs');
const {syncMouse} = require('./mouse-theme.cjs');
const {pearTheme} = require('./pear-theme.cjs');

function fastfetchColors(text, palette) {
    const sections={logo:{'1':palette.ACCENT,'2':palette.SECONDARY,'3':palette.TEXT_MUTED},
        display:{keys:palette.ACCENT,title:palette.TEXT,output:palette.TEXT_ALT,separator:palette.SECONDARY}};
    for (const [section,colors] of Object.entries(sections)) {
        // The existing personal JSONC layout: edit only values, preserving comments and modules.
        const block=new RegExp(`("${section}"\\s*:\\s*\\{[\\s\\S]*?"color"\\s*:\\s*\\{)([^{}]*)(\\})`);
        if (!block.test(text)) throw new Error(`Cores ausentes no Fastfetch: ${section}`);
        text=text.replace(block,(_,prefix,body,end)=>{
            for(const [key,color] of Object.entries(colors)) {
                const entry=new RegExp(`("${key}"\\s*:\\s*)"[^"]*"`);
                if (!entry.test(body)) throw new Error(`Cor ausente no Fastfetch: ${section}.${key}`);
                body=body.replace(entry,`$1"${color}"`);
            }
            return prefix+body+end;
        });
    }
    return text;
}

// White's GTK4 entry is a link to Orchis. Keep that stylesheet as an import;
// never follow the link for writes or edit the system theme.
const orchisGtk4='/usr/share/themes/Orchis-Dark-Compact/gtk-4.0/gtk.css';
function linkedGtkBase(config, relative) {
    if (relative !== 'gtk-4.0/gtk.css') return null;
    const path=join(config,relative);
    return fs.lstatSync(path,{throwIfNoEntry:false})?.isSymbolicLink()
        && fs.readlinkSync(path)===orchisGtk4 ? orchisGtk4 : null;
}

function replaceAssignment(text, key, value) {
    const pattern = new RegExp(`^${key}=.*$`, 'm');
    if (!pattern.test(text)) throw new Error(`Variável ausente no tema: ${key}`);
    return text.replace(pattern, `${key}="${value}"`);
}

function terminalColors(text, palette) {
    const sections = {
        'colors.primary':{background:palette.BACKGROUND, foreground:palette.TEXT},
        'colors.cursor':{cursor:palette.ACCENT, text:palette.BACKGROUND},
        'colors.selection':{background:palette.ACCENT, text:palette.BACKGROUND},
        'colors.normal':{black:palette.SURFACE_ALT, blue:palette.PRIMARY,
            magenta:palette.SECONDARY, cyan:palette.SECONDARY, white:palette.TEXT},
        'colors.bright':{black:palette.TEXT_MUTED, blue:palette.PRIMARY,
            magenta:palette.SECONDARY, cyan:palette.SECONDARY, white:palette.TEXT_ALT}
    };
    let section = '';
    return text.split('\n').map(line => {
        const header = /^\s*\[([^\]]+)\]/.exec(line);
        if (header) section=header[1];
        const entry = /^(\s*)(\w+)\s*=.*$/.exec(line);
        if (entry && sections[section]?.[entry[2]]) return `${entry[1]}${entry[2]} = "${sections[section][entry[2]]}"`;
        return line;
    }).join('\n');
}

function gtkColors(p) {
    return `/* Gerado pelo Archblato a partir do wallpaper. */
@define-color theme_bg_color ${p.BACKGROUND};
@define-color theme_base_color ${p.SURFACE};
@define-color theme_fg_color ${p.TEXT};
@define-color theme_text_color ${p.TEXT};
@define-color theme_selected_bg_color ${p.ACCENT};
@define-color theme_selected_fg_color ${p.BACKGROUND};
@define-color accent_color ${p.ACCENT};
@define-color accent_bg_color ${p.ACCENT};
@define-color accent_fg_color ${p.BACKGROUND};
@define-color window_bg_color ${p.BACKGROUND};
@define-color window_fg_color ${p.TEXT};
@define-color view_bg_color ${p.SURFACE};
@define-color view_fg_color ${p.TEXT};
@define-color headerbar_bg_color ${p.SURFACE};
@define-color headerbar_fg_color ${p.TEXT};
@define-color card_bg_color ${p.SURFACE_ALT};
window, .background { background-color: ${p.BACKGROUND}; color: ${p.TEXT}; }
headerbar { background-image: none; background-color: ${p.SURFACE}; color: ${p.TEXT}; }
entry, textview, textview text { background-color: ${p.SURFACE}; color: ${p.TEXT}; }
button.suggested-action, button:checked, selection { background-image: none; background-color: ${p.ACCENT}; color: ${p.BACKGROUND}; }
progressbar progress, scale highlight { background-image: none; background-color: ${p.ACCENT}; }
`;
}

function themePlan(config, palette) {
    const read = path => fs.readFileSync(join(config,path),'utf8');
    const changes = new Map();
    let theme = read('archblato/theme.sh');
    for (const [key,value] of Object.entries(palette)) theme = replaceAssignment(theme,key,value);
    const rgb = palette.BACKGROUND.slice(1).match(/../g).map(v=>parseInt(v,16)).join(',');
    theme = replaceAssignment(theme,'BAR_BACKGROUND',`rgba(${rgb},0.75)`);
    theme = replaceAssignment(theme,'POPUP_BACKGROUND',`rgba(${rgb},0.92)`);
    changes.set('archblato/theme.sh',theme);
    let hypr = read('hypr/theme.lua');
    for (const [key,value] of Object.entries({background:palette.BACKGROUND,text:palette.TEXT,
        active:palette.BORDER_ACTIVE,inactive:palette.BORDER_INACTIVE})) {
        const pattern=new RegExp(`(\\b${key}\\s*=\\s*)"[^"]*"`);
        if (!pattern.test(hypr)) throw new Error(`Cor ausente em theme.lua: ${key}`);
        hypr=hypr.replace(pattern,`$1"${value}"`);
    }
    changes.set('hypr/theme.lua',hypr);
    const toolkit=read('hypr/hyprtoolkit.conf');
    if (!/^accent\s*=/m.test(toolkit)) throw new Error('Accent ausente no hyprtoolkit');
    changes.set('hypr/hyprtoolkit.conf',toolkit.replace(/^accent\s*=.*$/m,`accent = 0x${palette.TOOLKIT}`));
    for (const file of ['alacritty/theme.toml','alacritty/alacritty.toml']) changes.set(file,terminalColors(read(file),palette));
    changes.set('fastfetch/config.jsonc',fastfetchColors(read('fastfetch/config.jsonc'),palette));
    for (const version of ['3.0','4.0']) {
        const css=`gtk-${version}/gtk.css`;
        const base=linkedGtkBase(config,css);
        const current=base ? `@import url("file://${base}");\n` : fs.existsSync(join(config,css))?read(css):'';
        const imported=current.replace(/^\s*@import\s+(?:url\()?['"]archblato-colors\.css['"]\)?;\s*$/gm,'').trimEnd();
        changes.set(css,`${imported}\n@import 'archblato-colors.css';\n`);
        changes.set(`gtk-${version}/archblato-colors.css`,gtkColors(palette));
    }
    // Static fallback; the personal Pear launcher also watches the palette below for live colors.
    changes.set('archblato/quickshell/pear-theme.css',pearTheme(palette));
    // Last: a data-file update, never a QML reload while a theme process is alive.
    changes.set('archblato/quickshell/wallpaper-colors.json',JSON.stringify(palette,null,2)+'\n');
    return changes;
}

function atomicWrite(path, content, mode=0o600) {
    fs.mkdirSync(dirname(path),{recursive:true});
    const temp=path+`.archblato-${process.pid}.tmp`;
    let fd, created=false;
    try {
        fd=fs.openSync(temp,'wx',mode);
        created=true;
        fs.writeFileSync(fd,content);
        fs.closeSync(fd);
        fd=undefined;
        fs.renameSync(temp,path);
    } finally {
        // EEXIST belongs to another operation: never remove a file we did not create.
        if (fd !== undefined) fs.closeSync(fd);
        if (created && fs.existsSync(temp)) fs.unlinkSync(temp);
    }
}

function applyTheme(config, palette, reload = () => execFileSync('hyprctl',['reload'],{timeout:5000,stdio:'pipe'})) {
    const changes=themePlan(config,palette);
    const originals=new Map();
    for (const relative of changes.keys()) {
        const path=join(config,relative);
        const stat=fs.lstatSync(path,{throwIfNoEntry:false});
        const base=linkedGtkBase(config,relative);
        if (base) { originals.set(relative,{link:base}); continue; }
        if (stat && !stat.isFile()) throw new Error(`Destino não regular: ${relative}`);
        originals.set(relative,stat?{text:fs.readFileSync(path,'utf8'),mode:stat.mode&0o777}:null);
    }
    const backup=join(config,'archblato/theme-backup');
    fs.mkdirSync(backup,{recursive:true,mode:0o700});
    // Preserve original entries; newly integrated targets receive their own first-use backup.
    const backupFile=join(backup,'before.json');
    const saved=fs.existsSync(backupFile)?JSON.parse(fs.readFileSync(backupFile,'utf8')):{};
    let added=false;
    for (const [key,value] of originals) if (!Object.hasOwn(saved,key)) { saved[key]=value; added=true; }
    if (added) atomicWrite(backupFile,JSON.stringify(saved,null,2)+'\n');
    const written=[];
    try {
        for (const [relative,content] of changes) {
            const old=originals.get(relative);
            if (old?.text===content) continue;
            atomicWrite(join(config,relative),content,old?.mode);
            written.push(relative);
        }
        reload();
    } catch (error) {
        for (const relative of written.reverse()) {
            const old=originals.get(relative), path=join(config,relative);
            if (old?.link) { fs.unlinkSync(path); fs.symlinkSync(old.link,path); }
            else if (old) atomicWrite(path,old.text,old.mode); else fs.unlinkSync(path);
        }
        try { reload(); } catch {}
        throw error;
    }
    return backup;
}

if (require.main===module) {
    (async()=>{
    try {
        const [mode,path]=process.argv.slice(2);
        if (!['--apply','--preview'].includes(mode) || !path || process.argv.length!==4) throw new Error('Uso: wallpaper-theme.cjs --preview|--apply IMAGEM');
        const palette=extractPalette(path);
        if (mode==='--preview') console.log(JSON.stringify(palette,null,2));
        else {
            const backup=applyTheme(process.env.ARCHBLATO_CONFIG_ROOT || join(process.env.HOME,'.config'),palette);
            console.log(backup);
            try {
                await syncMouse(palette.ACCENT,{beforeChange:state=>{
                    const path=join(backup,'mouse-before.json');
                    if (!fs.existsSync(path)) atomicWrite(path,JSON.stringify(state,null,2)+'\n');
                }});
            } catch (error) {
                console.error(`Tema aplicado; RGB do mouse pendente: ${error.message}`);
                process.exitCode=3;
            }
        }
    } catch (error) { console.error(`Tema: ${error.message}`); process.exitCode=1; }
    })();
}

module.exports={themePlan,terminalColors,fastfetchColors,applyTheme};
