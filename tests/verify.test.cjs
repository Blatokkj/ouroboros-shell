const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync, existsSync} = require('node:fs');
const {join, dirname} = require('node:path');
const {buildChecks, runChecks, parseArgs} = require('../scripts/verify.cjs');

test('default checks are native, offscreen and exclude live/integration sessions', () => {
    const checks = buildChecks();
    assert.ok(checks.some(c => c.command.endsWith('/qmllint')));
    assert.ok(checks.some(c => c.args.includes('--test')));
    assert.equal(checks.find(c => c.command.endsWith('/qmltestrunner')).env.QT_QPA_PLATFORM, 'offscreen');
    // Parsing an integration script is safe; executing it must remain opt-in.
    assert.ok(checks.filter(c => c.args[0] !== '--check')
        .every(c => !c.args.some(a => /--live|integration\.cjs|benchmark/.test(a))));
});

test('integration mode adds only isolated harnesses including the synthetic Electron page', () => {
    const base = buildChecks();
    const extended = buildChecks({integration: true});
    assert.deepEqual(extended.slice(0, base.length), base);
    assert.deepEqual(extended.slice(base.length).map(c => c.args[0]), [
        'tests/system-integration.cjs', 'tests/profile-integration.cjs',
        'tests/notification-integration.cjs', 'tests/pear-theme-integration.cjs'
    ]);
});

test('unknown options are rejected rather than silently broadening scope', () => {
    assert.deepEqual(parseArgs(['--integration', '--list']), {integration: true, list: true, help: false});
    assert.throws(() => parseArgs(['--live']), /Opção desconhecida/);
});

test('runner preserves failure code and does not execute subsequent checks', () => {
    const calls = [];
    const checks = [{label:'first', command:'tool', args:['file with spaces']},
        {label:'second', command:'never', args:[]}];
    assert.equal(runChecks(checks, (cmd, args, options) => {
        calls.push({cmd, args, options});
        return {status: 7};
    }, () => {}), 7);
    assert.equal(calls.length, 1);
    assert.deepEqual(calls[0].args, ['file with spaces']);
    assert.equal(calls[0].options.shell, false);
    assert.ok(calls[0].options.cwd.endsWith('/quickshell'));
});

test('missing tools and interrupted children are failures, not skipped checks', () => {
    const checks = [{label:'missing', command:'missing', args:[]}];
    assert.equal(runChecks(checks, () => ({error: new Error('ENOENT'), status:null}), () => {}), 1);
    assert.equal(runChecks(checks, () => ({signal:'SIGTERM', status:null}), () => {}), 1);
    assert.equal(runChecks(checks, () => ({status:0}), () => {}), 0);
});

test('setup documents exist and their local Markdown links resolve', () => {
    const root = join(__dirname, '..');
    const documents = ['AGENTS.md', 'CLAUDE.md', 'PRODUCT.md', 'README.md',
        'docs/architecture.md', 'docs/design.md', 'docs/onboarding.md',
        'docs/quality.md', 'docs/setup.md'];
    for (const document of documents) {
        const path = join(root, document);
        const body = readFileSync(path, 'utf8');
        assert.ok(body.trim(), `${document} must not be empty`);
        // These documents use simple inline links; external URLs/anchors are not fetched.
        for (const match of body.matchAll(/\]\(([^\s)]+)\)/g)) {
            const target = match[1];
            if (/^(?:https?:|#)/.test(target)) continue;
            assert.ok(existsSync(join(dirname(path), target.split('#')[0])), `${document}: ${target}`);
        }
    }
    assert.equal(readFileSync(join(root, 'CLAUDE.md'), 'utf8').trim(), '@AGENTS.md');
});
