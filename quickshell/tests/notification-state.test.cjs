const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { runInNewContext } = require('node:vm');
const { join } = require('node:path');
const state = {};
runInNewContext(readFileSync(join(__dirname, '../NotificationState.js'), 'utf8'), state);

test('history replaces matching keys, keeps newest first and respects its limit', () => {
    const original = [{ eventKey: 'a', title: 'old' }, { eventKey: 'b' }];
    const updated = state.upsert(original, { eventKey: 'a', title: 'new' }, 2);
    assert.equal(updated.length, 2);
    assert.equal(updated[0].title, 'new');
    assert.equal(updated[1].eventKey, 'b');
    assert.equal(original[0].title, 'old');
    const capped = state.upsert(updated, { eventKey: 'c' }, 2);
    assert.equal(capped.length, 2);
    assert.equal(capped[1].eventKey, 'a');
});

test('marking read preserves contents without mutating existing entries', () => {
    const original = [{ eventKey: 'a', unread: true }, { eventKey: 'b', unread: false }];
    const read = state.markRead(original);
    assert.ok(read.every(entry => !entry.unread));
    assert.equal(read[0].eventKey, 'a');
    assert.equal(original[0].unread, true);
});

const pear = { dbusName: 'org.mpris.MediaPlayer2.chromium.instance58291', identity: 'com.github.th-ch.youtube-music', isPlaying: true };
const browser = { dbusName: 'org.mpris.MediaPlayer2.firefox', identity: 'Firefox', isPlaying: true };
test('recognizes the real Pear Chromium identity and prioritizes it over browsers', () => {
    assert.equal(state.preferredPlayer(pear), true);
    assert.equal(state.selectPlayer([browser, pear], ''), pear);
    assert.equal(state.selectPlayer([browser, { ...pear, isPlaying: false }], '').identity, pear.identity);
    assert.equal(state.preferredPlayer({ identity: 'Pear Desktop' }), true);
    assert.equal(state.preferredPlayer({ dbusName: 'org.mpris.MediaPlayer2.YoutubeMusic' }), true);
});

test('manual selection wins and a vanished player falls back safely', () => {
    assert.equal(state.selectPlayer([browser, pear], browser.dbusName), browser);
    assert.equal(state.selectPlayer([pear], browser.dbusName), pear);
    assert.equal(state.selectPlayer([], ''), null);
    assert.equal(state.selectPlayer([browser], ''), browser);
});

test('formats second-based MPRIS timestamps, including long tracks and missing data', () => {
    assert.equal(state.timeLabel(153.999), '2:33');
    assert.equal(state.timeLabel(0), '0:00');
    assert.equal(state.timeLabel(3605), '1:00:05');
    assert.equal(state.timeLabel(-1), '--:--');
    assert.equal(state.timeLabel(NaN), '--:--');
});
