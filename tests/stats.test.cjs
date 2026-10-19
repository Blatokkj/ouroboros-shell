const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { runInNewContext } = require('node:vm');
const stats = {};
runInNewContext(readFileSync(require('node:path').join(__dirname, '../Stats.js'), 'utf8'), stats);
test('CPU excludes guest accounting and includes iowait in idle', () => {
    const sample = stats.cpu('cpu 100 10 20 500 20 5 5 0 99 33\ncpu0 0');
    assert.equal(sample.total, 660); assert.equal(sample.idle, 520);
    assert.equal(stats.usage(sample, { total: 760, idle: 570 }), 50);
});
test('CPU reset/empty samples do not produce invalid percentages', () => {
    assert.equal(stats.cpu(''), null);
    assert.equal(stats.usage(null, {total: 5, idle: 1}), null);
    assert.equal(stats.usage({total: 10, idle: 2}, {total: 5, idle: 1}), null);
});
test('memory uses available memory, retaining precision', () => {
    const sample = stats.memory('MemTotal: 1000 kB\nMemAvailable: 333 kB');
    assert.equal(sample.used, 667); assert.equal(sample.percent, 66.7);
    assert.equal(stats.memory('MemTotal: 0 kB'), null);
});
