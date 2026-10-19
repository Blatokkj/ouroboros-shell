// Real Electron, synthetic page, private session and no requests to Google/Pear.
const fs = require('node:fs');
const {join} = require('node:path');
const assert = require('node:assert/strict');
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));

if (!process.versions.electron) {
    const {spawnSync} = require('node:child_process');
    const dir = fs.mkdtempSync('/tmp/archblato-pear-render-');
    const env = {...process.env, ARCHBLATO_PEAR_TEST_DIR: dir};
    delete env.ELECTRON_RUN_AS_NODE;
    delete env.NODE_OPTIONS;
    try {
        const result = spawnSync('dbus-run-session', ['--', '/usr/lib/electron42/electron',
            __filename, '--disable-gpu', '--disable-dev-shm-usage'],
        {env, stdio: 'inherit', timeout: 20000, killSignal: 'SIGTERM'});
        if (result.error) throw result.error;
        process.exitCode = result.status ?? 1;
    } finally { fs.rmSync(dir, {recursive: true, force: true}); }
} else {
    const {app, BrowserWindow, session} = require('electron');
    const {installLiveTheme} = require('../scripts/pear-live-theme.cjs');
    const {paletteFromPixels} = require('../scripts/wallpaper-palette.cjs');
    const dir = process.env.ARCHBLATO_PEAR_TEST_DIR;
    if (!dir?.startsWith('/tmp/archblato-pear-render-')) throw new Error('Temporary test directory required');
    app.setPath('userData', dir);
    app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');
    const palettePath = join(dir, 'wallpaper-colors.json');
    const themePath = join(dir, 'pear-theme.css');
    const configPath = join(dir, 'config.json');
    const put = (path, value) => {
        fs.writeFileSync(path + '.tmp', value);
        fs.renameSync(path + '.tmp', path);
    };
    const red = paletteFromPixels(Buffer.from([255, 0, 0]));
    const blue = paletteFromPixels(Buffer.from([0, 0, 255]));
    put(palettePath, JSON.stringify(red));
    put(configPath, JSON.stringify({options: {themes: [themePath]}}));
    const reports = [];
    installLiveTheme({app, palettePath, themePath, configPath, report: x => reports.push(x)});
    const watchdog = setTimeout(() => { console.error('FAIL: Electron theme timeout'); app.exit(1); }, 15000);
    app.whenReady().then(async () => {
        // All HTTPS requests stay inside this in-memory session. No network access.
        const isolated = session.fromPartition('archblato-theme-test');
        isolated.protocol.handle('https', () => new Response('<!doctype html><body><ytmusic-player-bar><div id="progress-bar" class="ytmusic-player-bar">Test</div></ytmusic-player-bar><audio id="audio" loop muted></audio></body>',
            {headers: {'content-type': 'text/html'}}));
        const win = new BrowserWindow({show: false, webPreferences: {session: isolated, sandbox: true, contextIsolation: true}});
        const wc = win.webContents;
        const operations = [];
        const insert = wc.insertCSS.bind(wc), remove = wc.removeInsertedCSS.bind(wc);
        wc.insertCSS = async (...args) => { const key = await insert(...args); operations.push(['insert', key]); return key; };
        wc.removeInsertedCSS = async key => { operations.push(['remove', key]); return remove(key); };
        let loads = 0;
        wc.on('did-finish-load', () => loads++);
        await win.loadURL('https://music.youtube.com/archblato-fixture');
        await wc.insertCSS('html:not(.style-scope) { --cust-ytmusic-nowplaying-color: #ffffff !important; }');
        const accent = () => wc.executeJavaScript('getComputedStyle(document.documentElement).getPropertyValue("--cust-ytmusic-nowplaying-color").trim()');
        async function until(check) {
            for (let i = 0; i < 70; i++) { if (await check()) return; await pause(30); }
            assert.fail('Rendered color did not update');
        }
        await until(async () => await accent() === red.ACCENT);
        // Silent WAV: a real media clock, no sound and no external resource.
        const wav = Buffer.alloc(44 + 8000 * 10);
        wav.write('RIFF'); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
        wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
        wav.writeUInt32LE(8000, 24); wav.writeUInt32LE(8000, 28); wav.writeUInt16LE(1, 32);
        wav.writeUInt16LE(8, 34); wav.write('data', 36); wav.writeUInt32LE(wav.length - 44, 40);
        wav.fill(128, 44);
        await wc.executeJavaScript(`window.fixtureMarker = 42; audio.src = ${JSON.stringify('data:audio/wav;base64,' + wav.toString('base64'))}; audio.play();`);
        await until(async () => await wc.executeJavaScript('audio.currentTime > 0.05'));
        const before = await wc.executeJavaScript('audio.currentTime');
        put(palettePath, JSON.stringify(blue));
        await until(async () => await accent() === blue.ACCENT);
        assert.equal(loads, 1, 'theme never reloads the document');
        assert.equal(await wc.executeJavaScript('fixtureMarker'), 42);
        // Audio clocks advance in chunks; wait for progress instead of assuming a tick per CSS update.
        await until(async () => await wc.executeJavaScript('!audio.paused && audio.currentTime') > before);
        put(palettePath, '{bad');
        await until(() => reports.length === 1);
        assert.equal(await accent(), blue.ACCENT);
        put(palettePath, JSON.stringify(red));
        await until(async () => await accent() === red.ACCENT);
        put(configPath, JSON.stringify({options: {themes: []}}));
        try { await until(async () => await accent() === '#ffffff'); }
        catch (error) { console.error({accent: await accent(), reports, operations}); throw error; }
        assert.equal(loads, 1);
        console.log('PASS: rendered live colors, atomic replacements, invalid palette recovery, CSS precedence, opt-out and uninterrupted media clock');
        clearTimeout(watchdog); app.quit();
    }).catch(error => { console.error(error); clearTimeout(watchdog); app.exit(1); });
}
