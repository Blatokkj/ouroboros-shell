// Runs inside Pear's main process. No renderer JS, server, polling or page reload.
const fs = require('node:fs');
const {dirname, basename} = require('node:path');
const {pearTheme} = require('./pear-theme.cjs');

function musicPage(url) {
    try { return new URL(url).origin === 'https://music.youtube.com'; }
    catch { return false; }
}

function readJson(path, limit) {
    const stat = fs.lstatSync(path);
    if (!stat.isFile() || stat.size > limit) throw new Error('Arquivo inválido');
    return JSON.parse(fs.readFileSync(path, 'utf8'));
}

function installLiveTheme({app, palettePath, themePath, configPath,
    report = message => console.warn(`[Archblato] ${message}`)}) {
    const windows = new Map();
    const watchers = [];
    let timer, disposed = false, desiredCss = null;
    let warned = false;
    function warn() {
        if (!warned) report('Não foi possível atualizar as cores do Pear; mantendo o último tema.');
        warned = true;
    }

    // Serialize inserts/removals per window: rapid changes never accumulate stylesheets.
    async function update(contents, state) {
        if (state.busy || state.dead) return;
        state.busy = true;
        try {
            while (!state.dead && !contents.isDestroyed()) {
                for (const key of state.retired) {
                    await contents.removeInsertedCSS(key);
                    state.retired.delete(key);
                }
                const revision = state.revision;
                const css = musicPage(contents.getURL()) && state.loaded ? desiredCss : null;
                if (state.css === css) break;
                const previous = state.key;
                const key = css === null ? null : await contents.insertCSS(css, {cssOrigin: 'author'});
                if (state.dead || contents.isDestroyed()) break;
                if (revision !== state.revision) {
                    // Main-frame navigation invalidates old IDs, including an in-flight insert.
                    if (key) state.retired.add(key);
                    continue;
                }
                state.key = key;
                state.css = css;
                if (previous) {
                    state.retired.add(previous);
                    await contents.removeInsertedCSS(previous);
                    state.retired.delete(previous);
                }
                if (state.css === desiredCss) break;
            }
        } catch { warn(); }
        finally { state.busy = false; }
    }

    function refresh() {
        if (disposed) return;
        try {
            const config = readJson(configPath, 1024 * 1024);
            const enabled = Array.isArray(config.options?.themes) && config.options.themes.includes(themePath);
            desiredCss = enabled ? pearTheme(readJson(palettePath, 16384), true) : null;
            warned = false;
            for (const [contents, state] of windows) void update(contents, state);
        } catch { warn(); }
    }
    function schedule() {
        clearTimeout(timer);
        timer = setTimeout(refresh, 80);
    }
    function onWindow(_event, win) {
        const contents = win.webContents;
        const state = {key: null, css: null, busy: false, dead: false, loaded: false, revision: 0, retired: new Set()};
        // A failed/aborted navigation leaves the old document alive. Invalidate only on commit.
        const committed = () => {
            state.revision++;
            state.loaded = false;
            state.key = state.css = null;
            state.retired.clear();
        };
        const loaded = () => { state.loaded = true; void update(contents, state); };
        const destroyed = () => { state.dead = true; windows.delete(contents); };
        state.detach = () => {
            contents.removeListener('did-navigate', committed);
            contents.removeListener('did-finish-load', loaded);
            contents.removeListener('destroyed', destroyed);
        };
        windows.set(contents, state);
        contents.on('did-navigate', committed);
        contents.on('did-finish-load', loaded);
        contents.once('destroyed', destroyed);
    }
    function dispose() {
        disposed = true;
        clearTimeout(timer);
        for (const watcher of watchers) watcher.close();
        for (const state of windows.values()) { state.dead = true; state.detach(); }
        windows.clear();
        app.removeListener('browser-window-created', onWindow);
        app.removeListener('will-quit', dispose);
    }

    // Watch directories, not inodes: wallpaper and electron-store use atomic renames.
    try {
        for (const path of [palettePath, configPath]) {
            const watcher = fs.watch(dirname(path), {persistent: false}, (_event, file) => {
                if (file === null || file.toString() === basename(path)) schedule();
            });
            watcher.on('error', warn);
            watchers.push(watcher);
        }
        app.on('browser-window-created', onWindow);
        app.once('will-quit', dispose);
        refresh();
    } catch { warn(); dispose(); }
    return dispose;
}

module.exports = {installLiveTheme, musicPage};
