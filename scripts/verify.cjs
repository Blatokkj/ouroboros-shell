// Explicit checks for White. No downloads, hooks, live IPC or hardware changes.
const {readdirSync} = require('node:fs');
const {join} = require('node:path');
const {spawnSync} = require('node:child_process');
const root = join(__dirname, '..');

function files(directory, suffix) {
    return readdirSync(join(root, directory), {withFileTypes:true})
        .filter(entry => entry.isFile() && entry.name.endsWith(suffix))
        .map(entry => join(directory, entry.name)).sort();
}

function buildChecks({integration = false} = {}) {
    const checks = [];
    for (const file of [...files('.', '.js'), ...files('scripts', '.cjs'), ...files('tests', '.cjs'), ...files('integrations/pear', '.cjs')]) {
        checks.push({label:`Sintaxe JS: ${file}`, command:process.execPath, args:['--check', file]});
    }
    for (const file of ['scripts/lock-screen', 'scripts/system-stats', 'scripts/wallpapers', 'scripts/pear-desktop']) {
        checks.push({label:`Sintaxe Bash: ${file}`, command:'bash', args:['-n', file]});
    }
    checks.push(
        {label:'Lint QML (avisos nativos permanecem visíveis)', command:'/usr/lib/qt6/bin/qmllint',
            args:[...files('.', '.qml'), ...files('tests', '.qml')]},
        {label:'Testes Node', command:process.execPath, args:['--test', ...files('tests', '.test.cjs')]},
        {label:'QtTest offscreen', command:'/usr/lib/qt6/bin/qmltestrunner', args:['-input', 'tests'],
            env:{QT_QPA_PLATFORM:'offscreen'}}
    );
    if (integration) {
        for (const name of ['system', 'profile', 'notification']) {
            checks.push({label:`Integração isolada: ${name}`, command:process.execPath,
                args:[`tests/${name}-integration.cjs`]});
        }
        checks.push({label:'Integração isolada: cores no Electron', command:process.execPath,
            args:['tests/pear-theme-integration.cjs']});
    }
    return checks;
}

function parseArgs(args) {
    for (const arg of args) {
        if (!['--integration', '--list', '--help'].includes(arg)) {
            throw new Error(`Opção desconhecida: ${arg}`);
        }
    }
    return {integration:args.includes('--integration'), list:args.includes('--list'), help:args.includes('--help')};
}

function runChecks(checks, execute = spawnSync, report = console.log) {
    for (const check of checks) {
        report(`\n${check.label}`);
        const result = execute(check.command, check.args, {
            cwd:root, env:{...process.env, ...check.env}, stdio:'inherit', shell:false
        });
        if (result.error || result.signal || result.status !== 0) {
            report(`FALHOU: ${check.label} (${result.error?.message || result.signal || result.status})`);
            return result.status > 0 ? result.status : 1;
        }
    }
    report('\nPASS: verificações selecionadas concluídas. Testes live não foram executados.');
    return 0;
}

if (require.main === module) {
    try {
        const options = parseArgs(process.argv.slice(2));
        if (options.help) {
            console.log('Uso: node scripts/verify.cjs [--integration] [--list]\n'
                + 'Padrão: sintaxe, qmllint, testes Node e QtTest offscreen.\n'
                + '--integration: acrescenta D-Bus privado e Electron invisível com página sintética (precisam de sockets locais/display).\n'
                + '--list: mostra comandos sem executá-los. Nunca inclui --live.');
        } else if (options.list) {
            for (const check of buildChecks(options)) console.log(JSON.stringify(check));
        } else {
            process.exitCode = runChecks(buildChecks(options));
        }
    } catch (error) {
        console.error(error.message);
        process.exitCode = 1;
    }
}

module.exports = {buildChecks, runChecks, parseArgs};
