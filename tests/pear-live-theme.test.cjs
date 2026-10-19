const {test} = require('node:test');
const assert = require('node:assert/strict');
const {EventEmitter} = require('node:events');
const fs = require('node:fs');
const {join} = require('node:path');
const {installLiveTheme, musicPage} = require('../scripts/pear-live-theme.cjs');
const {paletteFromPixels} = require('../scripts/wallpaper-palette.cjs');
const {pearTheme: generateTheme} = require('../scripts/pear-theme.cjs');
const pearTheme = palette => generateTheme(palette, true);
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(check) {
    for (let i = 0; i < 60; i++) { if (check()) return; await pause(20); }
    assert.fail('Timed out waiting for CSS update');
}
function fixture(t) {
    const dir = fs.mkdtempSync('/tmp/archblato-pear-unit-');
    const palettePath = join(dir, 'wallpaper-colors.json');
    const themePath = join(dir, 'pear-theme.css');
    const configPath = join(dir, 'config.json');
    const red = paletteFromPixels(Buffer.from([255, 0, 0]));
    const blue = paletteFromPixels(Buffer.from([0, 0, 255]));
    const put = (path, data) => {
        fs.writeFileSync(path + '.tmp', data);
        fs.renameSync(path + '.tmp', path);
    };
    put(palettePath, JSON.stringify(red));
    put(configPath, JSON.stringify({options: {themes: [themePath]}}));
    const app = new EventEmitter(), reports = [];
    const dispose = installLiveTheme({app, palettePath, themePath, configPath, report: x => reports.push(x)});
    t.after(() => { dispose(); fs.rmSync(dir, {recursive: true, force: true}); });
    function window(url = 'https://music.youtube.com/watch?v=fixture') {
        const contents = new EventEmitter();
        const css = new Map();
        let id = 0;
        Object.assign(contents, {url, dead: false, inserts: 0, delay: 0,
            getURL() { return this.url; }, isDestroyed() { return this.dead; },
            async insertCSS(text, options) {
                assert.equal(options.cssOrigin, 'author');
                this.inserts++;
                if (this.delay) await pause(this.delay);
                const key = String(++id); css.set(key, text); return key;
            },
            async removeInsertedCSS(key) {
                if (this.failRemoval) { this.failRemoval = false; throw new Error('Transient failure'); }
                css.delete(key);
            }
        });
        app.emit('browser-window-created', {}, {webContents: contents});
        contents.emit('did-finish-load');
        return {contents, css};
    }
    return {dir, app, reports, palettePath, themePath, configPath, red, blue, put, window, dispose};
}
test('only the exact HTTPS YT Music origin receives colors', () => {
    assert.equal(musicPage('https://music.youtube.com/watch?v=x'), true);
    for (const url of ['https://accounts.google.com', 'http://music.youtube.com',
        'https://music.youtube.com.evil.test', 'file:///tmp/page', 'invalid']) assert.equal(musicPage(url), false);
});
test('atomic palette updates replace CSS, skip duplicates and preserve the old theme on errors', async t => {
    const f = fixture(t), {contents, css} = f.window();
    await until(() => css.size === 1);
    f.put(f.palettePath, JSON.stringify(f.blue));
    await until(() => css.size === 1 && [...css.values()][0] === pearTheme(f.blue));
    assert.equal(contents.inserts, 2);
    f.put(f.palettePath, JSON.stringify(f.blue));
    await pause(140);
    assert.equal(contents.inserts, 2);
    f.put(f.palettePath, '{bad');
    await until(() => f.reports.length === 1);
    assert.equal([...css.values()][0], pearTheme(f.blue));
    fs.unlinkSync(f.palettePath);
    fs.symlinkSync(f.configPath, f.palettePath);
    await pause(140);
    assert.equal(contents.inserts, 2, 'symlinks must not be read as palettes');
    f.put(f.palettePath, JSON.stringify(f.red));
    await until(() => [...css.values()][0] === pearTheme(f.red));
});
test('login pages are skipped; removing the registered theme removes the live layer', async t => {
    const f = fixture(t), login = f.window('https://accounts.google.com'), music = f.window();
    await until(() => music.css.size === 1);
    assert.equal(login.contents.inserts, 0);
    f.put(f.configPath, JSON.stringify({options: {themes: []}}));
    await until(() => music.css.size === 0);
    f.put(f.configPath, JSON.stringify({options: {themes: [f.themePath]}}));
    await until(() => music.css.size === 1);
});
test('updates during a pending insert converge without accumulating CSS', async t => {
    const f = fixture(t), {contents, css} = f.window();
    await until(() => css.size === 1);
    contents.delay = 220;
    f.put(f.palettePath, JSON.stringify(f.blue));
    await until(() => contents.inserts === 2);
    f.put(f.palettePath, JSON.stringify(f.red));
    await until(() => contents.inserts === 3 && css.size === 1 && [...css.values()][0] === pearTheme(f.red));
});
test('navigation cancels stale CSS; reload reapplies and disposal closes watchers/listeners', async t => {
    const f = fixture(t), {contents, css} = f.window();
    await until(() => css.size === 1);
    contents.delay = 150;
    f.put(f.palettePath, JSON.stringify(f.blue));
    await until(() => contents.inserts === 2);
    contents.emit('did-navigate');
    contents.url = 'https://accounts.google.com';
    css.clear(); contents.emit('did-finish-load');
    await pause(200);
    assert.equal(css.size, 0);
    contents.url = 'https://music.youtube.com';
    contents.emit('did-navigate');
    contents.emit('did-finish-load');
    await until(() => css.size === 1);
    f.dispose();
    assert.equal(f.app.listenerCount('browser-window-created'), 0);
    assert.equal(contents.listenerCount('did-finish-load'), 0);
    const before = contents.inserts;
    f.put(f.palettePath, JSON.stringify(f.red));
    await pause(140); assert.equal(contents.inserts, before);
});
test('failed navigation preserves the active document and theme updates', async t => {
    const f = fixture(t), {contents, css} = f.window();
    await until(() => css.size === 1);
    contents.emit('did-start-navigation', {}, 'https://accounts.google.com', false, true);
    contents.emit('did-fail-provisional-load', {}, -3, 'ERR_ABORTED');
    f.put(f.palettePath, JSON.stringify(f.blue));
    await until(() => css.size === 1 && [...css.values()][0] === pearTheme(f.blue));
});
test('failed removal keeps the old ID for cleanup on the next update', async t => {
    const f = fixture(t), {contents, css} = f.window();
    await until(() => css.size === 1);
    contents.failRemoval = true;
    f.put(f.palettePath, JSON.stringify(f.blue));
    await until(() => f.reports.length === 1);
    f.put(f.palettePath, JSON.stringify(f.blue));
    await until(() => css.size === 1 && [...css.values()][0] === pearTheme(f.blue));
    assert.equal(contents.inserts, 2, 'retry cleans retired CSS without inserting another copy');
});
