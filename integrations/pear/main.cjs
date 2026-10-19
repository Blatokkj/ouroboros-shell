// Personal entry point for White. Load the untouched installed Pear application.
const {app} = require('electron');
const {join, resolve} = require('node:path');
const {pathToFileURL} = require('node:url');
const {readFileSync} = require('node:fs');
const {installLiveTheme} = require('../../scripts/pear-live-theme.cjs');
const archive = '/usr/lib/pear-desktop/app.asar';
const shellDir = resolve(__dirname, '../..');

async function start() {
    const original = JSON.parse(readFileSync(join(archive, 'package.json'), 'utf8'));
    if (original.version !== '3.12.0') throw new Error('Versão do Pear mudou; use /usr/bin/pear-desktop até revisar a integração.');
    // Match upstream identity and paths before it initializes electron-store, plugins or auth.
    app.setName('YouTube Music');
    app.setAppPath(archive);
    app.setPath('userData', join(app.getPath('appData'), 'YouTube Music'));
    installLiveTheme({app,
        palettePath: join(shellDir, 'wallpaper-colors.json'),
        themePath: join(shellDir, 'pear-theme.css'),
        configPath: join(app.getPath('userData'), 'config.json')});
    await import(pathToFileURL(resolve(archive, original.main)).href);
}
start().catch(error => {
    console.error(`[Archblato] Falha ao iniciar integração do Pear: ${error.message}`);
    app.exit(1);
});
