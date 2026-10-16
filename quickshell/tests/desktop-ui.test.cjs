const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { runInNewContext } = require('node:vm');
const { join } = require('node:path');
const ui = {};
runInNewContext(readFileSync(join(__dirname, '../DesktopUi.js'), 'utf8'), ui);
test('Wi-Fi bars follow signal strength and distinguish offline, disabled and wired', () => {
    const icons = [0.1, 0.3, 0.6, 0.9].map(s => ui.wifiIcon(true, true, s, false));
    assert.equal(new Set(icons).size, 4);
    assert.notEqual(ui.wifiIcon(false, false, 0, false), ui.wifiIcon(true, false, 0, false));
    assert.equal(ui.wifiIcon(false, false, 0, true), '󰈀');
});
test('long notification text is paginated without dropping characters', () => {
    const text = 'Notificação longa com acentuação e emoji 🎵. '.repeat(100);
    const pages = ui.textPages(text, 40, 6, () => 1);
    assert.ok(pages.length > 1);
    assert.equal(pages.join('').replaceAll('\n', ''), text);
    assert.ok(pages.every(page => page.split('\n').length <= 6));
    assert.ok(pages.every(page => page.split('\n').every(line => Array.from(line).length <= 40)));
});
test('paragraphs and empty notifications remain displayable', () => {
    assert.equal(ui.textPages('A\n\nB', 20, 10, () => 1)[0], 'A\n\nB');
    assert.equal(ui.textPages('', 0, 0, () => 1)[0], '');
});
