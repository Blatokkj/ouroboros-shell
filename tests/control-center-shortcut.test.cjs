const { test } = require('node:test');
const assert = require('node:assert/strict');
const { openControlCenter } = require('../scripts/open-control-center.cjs');

test('toggles the central on the focused monitor, not the first monitor', () => {
    const calls = [];
    openControlCenter((command, args, options) => {
        calls.push({ command, args, options });
        return JSON.stringify([{ name: 'eDP-1', focused: false }, { name: 'DP-2', focused: true }]);
    });
    assert.equal(calls[0].command, 'hyprctl');
    assert.deepEqual(calls[0].args, ['monitors', '-j']);
    assert.equal(calls[1].command, 'qs');
    assert.deepEqual(calls[1].args.slice(-3), ['call', 'control-center-DP-2', 'toggle']);
    assert.ok(calls.every(call => call.options.timeout === 3000));
});

test('does not send IPC when no monitor is focused', () => {
    let count = 0;
    assert.throws(() => openControlCenter(() => { count++; return '[]'; }), /monitor ativo/);
    assert.equal(count, 1);
});

test('propagates session failures instead of starting another shell', () => {
    assert.throws(() => openControlCenter(() => { throw new Error('socket unavailable'); }), /socket unavailable/);
});
