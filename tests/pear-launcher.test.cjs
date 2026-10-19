const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {join, resolve} = require('node:path');
const {spawnSync} = require('node:child_process');

test('personal launcher keeps flags/arguments and removes Node-only mode without altering the parent', t => {
    const dir = fs.mkdtempSync('/tmp/archblato-pear-launch-');
    t.after(() => fs.rmSync(dir, {recursive: true, force: true}));
    fs.writeFileSync(join(dir, 'pacman'), '#!/bin/sh\nprintf "%s\\n" "pear-desktop 3.12.0-1"\n', {mode: 0o700});
    fs.writeFileSync(join(dir, 'electron42'), '#!/bin/bash\nprintf "%s\\0" "$@"\nprintf "RUN_AS_NODE=%s\\0DEV=%s\\0" "${ELECTRON_RUN_AS_NODE-unset}" "${ELECTRON_IS_DEV-unset}"\n', {mode: 0o700});
    fs.writeFileSync(join(dir, 'pear-flags.conf'), '# Comment\n--some-flag=value\n  # Indented\n--one --two\n');
    const source = resolve(__dirname, '../scripts/pear-desktop');
    const env = {...process.env, PATH: `${dir}:${process.env.PATH}`, XDG_CONFIG_HOME: dir, ELECTRON_RUN_AS_NODE: '1'};
    delete env.NODE_TEST_CONTEXT;
    delete env.NODE_OPTIONS;
    const result = spawnSync('bash', [source, 'argument with spaces'], {
        env,
        encoding: 'utf8', timeout: 3000
    });
    assert.equal(result.status, 0, result.stderr);
    assert.ok(result.stdout.trim(), result.stderr);
    assert.deepEqual(result.stdout.split('\0'), [resolve(__dirname, '../integrations/pear'),
        '--some-flag=value', '--one', '--two', 'argument with spaces', 'RUN_AS_NODE=unset', 'DEV=0', '']);
});
