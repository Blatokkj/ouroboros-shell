const { execFileSync } = require('node:child_process');
const { resolve } = require('node:path');

function openControlCenter(run = execFileSync) {
    const options = { encoding: 'utf8', timeout: 3000 };
    const monitors = JSON.parse(run('hyprctl', ['monitors', '-j'], options));
    const monitor = monitors.find(item => item.focused);
    if (!monitor || typeof monitor.name !== 'string' || !monitor.name)
        throw new Error('Nenhum monitor ativo encontrado.');
    // Pass arguments directly: monitor names must never become shell commands.
    run('qs', ['ipc', '--path', resolve(__dirname, '..'), 'call',
        `control-center-${monitor.name}`, 'toggle'], options);
}

if (require.main === module) {
    try { openControlCenter(); }
    catch (error) {
        console.error(`Não foi possível alternar a central: ${error.message}`);
        process.exitCode = 1;
    }
}
module.exports = { openControlCenter };
