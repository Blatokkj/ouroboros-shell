// Real freedesktop notifications on a private D-Bus + offscreen QuickShell.
// Does not touch the desktop's notification history, daemon, music or lock.
const assert = require('node:assert/strict');
const { spawn, spawnSync, execFileSync } = require('node:child_process');
const { mkdtempSync, rmSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join } = require('node:path');

if (!process.argv.includes('--private-bus')) {
    const result = spawnSync('dbus-run-session', ['--', process.execPath, __filename, '--private-bus'], { stdio: 'inherit' });
    process.exit(result.status ?? 1);
}

const runtime = mkdtempSync(join(tmpdir(), 'archblato-notifications-test-'));
const env = { ...process.env, QT_QPA_PLATFORM: 'offscreen', XDG_RUNTIME_DIR: runtime };
const config = join(__dirname, '../tests-notifications.qml');
const shell = spawn('qs', ['--path', config, '--no-color'], { env });
let log = '';
shell.stdout.on('data', data => { log += data; });
shell.stderr.on('data', data => { log += data; });
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
function run(command, args) { return execFileSync(command, args, { env, encoding: 'utf8', timeout: 5000, stdio: ['ignore', 'pipe', 'pipe'] }).trim(); }
function ipc(target, method, ...args) { return run('qs', ['ipc', '--path', config, 'call', target, method, ...args.map(String)]); }
function snapshot() { return JSON.parse(ipc('test', 'snapshot')); }
function status() { return JSON.parse(ipc('notifications', 'status')); }
function notify(title, { replace = 0, body = 'Corpo de teste', timeout = 80, transient = false, resident = false, actions = [] } = {}) {
    const result = run('busctl', ['--user', 'call', 'org.freedesktop.Notifications', '/org/freedesktop/Notifications',
        'org.freedesktop.Notifications', 'Notify', 'susssasa{sv}i', 'QuickShell Test', String(replace), '', title, body,
        String(actions.length), ...actions, '2', 'transient', 'b', String(transient), 'resident', 'b', String(resident), String(timeout)]);
    return Number(result.split(' ')[1]);
}
async function until(check, label) {
    for (let i = 0; i < 60; i++) {
        try { if (check()) return; } catch {}
        await delay(100);
    }
    throw new Error('Timeout: ' + label);
}

(async () => {
    try {
        await until(() => status().ready, 'QuickShell ready');
        const id = notify('Original');
        await until(() => snapshot().length === 1, 'notification tracked');
        assert.equal(status().unread, 1);
        assert.equal(Number(ipc('notifications', 'count')), 0, 'lock suppression hides popups');
        notify('Atualizada', { replace: id });
        await until(() => snapshot()[0].title === 'Atualizada', 'in-place replacement');
        assert.equal(snapshot().length, 1, 'replacement must not duplicate history');
        const timestamp = snapshot()[0].timestamp;

        ipc('test', 'quiet', true);
        ipc('test', 'reload');
        await until(() => log.split('Configuration Loaded').length >= 3, 'hot reload');
        await until(() => snapshot().length === 1, 'history restored');
        assert.equal(snapshot()[0].timestamp, timestamp, 'reload preserves timestamps');
        assert.equal(status().unread, 1, 'reload preserves unread state');
        assert.equal(status().doNotDisturb, true, 'DND survives reload');

        ipc('test', 'suppress', false);
        notify('Silenciosa');
        await until(() => snapshot().length === 2, 'DND retains history');
        assert.equal(Number(ipc('notifications', 'count')), 0, 'DND hides popups');
        notify('Transitória', { transient: true });
        await delay(120);
        assert.equal(snapshot().length, 2, 'transient notifications are not archived');
        ipc('notifications', 'open');
        assert.equal(status().unread, 0, 'opening marks history read');
        ipc('notifications', 'close');
        ipc('test', 'quiet', false);

        notify('Temporária');
        await until(() => Number(ipc('notifications', 'count')) === 1, 'popup appears');
        ipc('test', 'expireToast'); // Same callback used by the popup's animation/timer.
        assert.equal(Number(ipc('notifications', 'count')), 0);
        assert.equal(snapshot().length, 3, 'expired popup remains in history');
        notify('Persistente', { timeout: 0 });
        await delay(300);
        assert.equal(Number(ipc('notifications', 'count')), 1);
        assert.equal(snapshot()[0].duration, 0, 'zero timeout is preserved for the popup timer');
        ipc('notifications', 'clear');

        const actionId = notify('Ação', { resident: true, actions: ['default', 'Abrir'] });
        await until(() => snapshot()[0].serverId === actionId, 'action notification');
        assert.equal(snapshot()[0].actions[0].text, 'Abrir');
        const monitor = spawn('gdbus', ['monitor', '--session', '--dest', 'org.freedesktop.Notifications'], { env });
        let signals = '';
        monitor.stdout.on('data', data => { signals += data; });
        try {
            await until(() => signals.includes('owned by'), 'D-Bus monitor');
            ipc('test', 'action', actionId, 'default');
            await until(() => signals.includes('ActionInvoked'), 'native notification action');
            ipc('test', 'remove', 'app-' + actionId);
            await until(() => signals.includes('NotificationClosed'), 'native notification dismissal');
        } finally { monitor.kill(); }

        for (let i = 0; i < 103; i++) notify('Aviso ' + i);
        await until(() => snapshot().length === 100, 'history capped at 100');
        assert.equal(snapshot()[0].title, 'Aviso 102');
        ipc('notifications', 'clearHistory');
        assert.equal(snapshot().length, 0);
        assert.equal(Number(ipc('notifications', 'count')), 0);
        assert.doesNotMatch(log, /TypeError|ReferenceError|Failed to load configuration|Binding loop/);
        console.log('PASS: native notifications, replacements, reload, DND, unread, expiry, actions, dismissal and bounded history');
    } catch (error) {
        try { console.error('Final test state:', ipc('notifications', 'status'), ipc('test', 'snapshot')); } catch {}
        throw error;
    } finally {
        shell.kill();
        await new Promise(resolve => { if (shell.exitCode !== null) resolve(); else shell.once('exit', resolve); });
        // Only this test's freshly-created runtime directory is removed.
        rmSync(runtime, { recursive: true, force: true });
    }
})().catch(error => { console.error(error); console.error(log); process.exitCode = 1; });
