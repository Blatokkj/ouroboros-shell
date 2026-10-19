const {test}=require('node:test');
const assert=require('node:assert/strict');
const {pearTheme}=require('../scripts/pear-theme.cjs');
const {paletteFromPixels}=require('../scripts/wallpaper-palette.cjs');
test('Pear colors follow the palette and cover the existing custom CSS variables',()=>{
    const p=paletteFromPixels(Buffer.from([210,110,160]));
    const css=pearTheme(p);
    assert.ok(css.includes(`--cust-ytmusic-dark-background: ${p.BACKGROUND} !important;`));
    assert.ok(css.includes(`--cust-ytmusic-nowplaying-color: ${p.ACCENT} !important;`));
    assert.ok(css.includes(`--paper-slider-active-color: ${p.ACCENT} !important;`));
    // Existing theme uses #progress-bar.ytmusic-player-bar and focused/hover variants.
    // Keep our root+host scope so its !important rules cannot win by specificity.
    assert.ok(css.includes('html:not(.style-scope) ytmusic-player-bar #progress-bar.ytmusic-player-bar[focused]'));
    assert.ok(css.includes('html:not(.style-scope) ytmusic-player-bar:hover #progress-bar.ytmusic-player-bar'));
    assert.ok(css.includes(`--paper-slider-knob-start-color: ${p.ACCENT} !important;`));
    assert.ok(css.includes(`--yt-spec-text-secondary: ${p.TEXT_MUTED} !important;`));
    assert.notEqual(css,pearTheme(paletteFromPixels(Buffer.from([0,0,255]))));
    assert.doesNotMatch(css,/url\(|@import|display:|width:|height:|font:|animation:|filter:/);
    assert.equal(css,pearTheme(p),'generation is deterministic');
});
test('invalid colors cannot introduce CSS or external resources',()=>{
    const p=paletteFromPixels(Buffer.from([1,2,3]));
    assert.throws(()=>pearTheme({...p,ACCENT:'red; background: url(https://example.com)'}),/Cor inválida/);
});
