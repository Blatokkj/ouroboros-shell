// White's physical G203, via the same ratbagd backend as Piper. Never touches cursors.
const {execFileSync} = require('node:child_process');
const deviceName = 'Logitech G203 LIGHTSYNC Gaming Mouse';
const model = 'usb:046d:c092:0';
function ratbag(args) {
    return execFileSync('ratbagctl',args,{encoding:'utf8',timeout:4000,maxBuffer:64*1024,
        env:{...process.env,LC_ALL:'C'},stdio:['ignore','pipe','pipe']}).trim();
}
function mouseState(info) {
    if (!info.includes(`Model: ${model}`) || !/Number of Profiles:\s*1\b/.test(info)
        || !/Number of Leds:\s*1\b/.test(info) || !/^Profile 0: \(active\)/m.test(info)) {
        throw new Error('G203 com modelo/perfil inesperado; RGB não alterado');
    }
    if (/\(dirty\)/.test(info)) throw new Error('Piper tem alterações pendentes; RGB não alterado');
    const led=/LED: 0, depth: rgb, mode: (off|on|breathing|cycle)([^\n]*)/i.exec(info);
    if (!led) throw new Error('Estado do LED do G203 não reconhecido');
    const mode=led[1].toLowerCase();
    const color=/, color: ([\da-f]{6})\b/i.exec(led[2])?.[1].toLowerCase() ?? null;
    const duration=/, duration: (\d+)/.exec(led[2])?.[1];
    const brightness=/, brightness: (\d+)/.exec(led[2])?.[1];
    if (['on','breathing'].includes(mode) && !color
        || ['cycle','breathing'].includes(mode) && (duration===undefined || brightness===undefined)) {
        throw new Error('Estado do LED do G203 incompleto');
    }
    // ratbagctl deliberately hides some fields in off/on/cycle; do not invent values.
    return {model,profile:0,led:0,mode,color,duration:duration===undefined?null:Number(duration),
        brightness:brightness===undefined?null:Number(brightness)};
}
async function syncMouse(accent,{run=ratbag,beforeChange=()=>{},pause=ms=>new Promise(r=>setTimeout(r,ms))}={}) {
    if (!/^#[\da-f]{6}$/i.test(accent)) throw new Error('Cor RGB inválida');
    const devices=run(['list']).split('\n').map(line=>/^([\w-]+):\s+(.+?)\s*$/.exec(line))
        .filter(match=>match && match[2]===deviceName);
    if (devices.length!==1) throw new Error('G203 ausente ou identificação ambígua');
    const id=devices[0][1];
    const old=mouseState(run([id,'info']));
    if (old.mode==='off') throw new Error('LED desligado no Piper; iluminação preservada');
    const color=accent.slice(1).toLowerCase();
    // Cycle ignores a fixed RGB. Breathing, off, brightness and duration stay as chosen in Piper.
    const mode=old.mode==='cycle'?'on':old.mode;
    if (old.color===color && old.mode===mode) return 'unchanged';
    beforeChange(old);
    // Recheck pending changes immediately before the only write/commit.
    if (JSON.stringify(mouseState(run([id,'info'])))!==JSON.stringify(old)) {
        throw new Error('LED mudou durante a aplicação; tente novamente');
    }
    const args=[id,'profile','0','led','0','set','color',color];
    if (mode!==old.mode) args.push('mode',mode);
    run(args);
    // ratbagctl Commit is asynchronous; a successful command alone is not confirmation.
    for(let attempt=0;attempt<5;attempt++) {
        await pause(150);
        try {
            const actual=mouseState(run([id,'info']));
            if (actual.color===color && actual.mode===mode
                && (actual.duration===null || actual.duration===old.duration)
                && (actual.brightness===null || actual.brightness===old.brightness)) return 'updated';
        } catch { /* brief dirty/resync or disconnect; bounded retry, never another write */ }
    }
    throw new Error('ratbagd não confirmou a cor do G203');
}
module.exports={mouseState,syncMouse};
