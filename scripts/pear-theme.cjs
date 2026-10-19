// Color-only layer for Pear 3.12 and White's existing custom YouTube Music CSS.
function pearTheme(p, live = false) {
    for (const key of ['BACKGROUND','SURFACE','SURFACE_ALT','ACCENT','TEXT','TEXT_ALT','TEXT_MUTED','SECONDARY']) {
        if (!/^#[\da-f]{6}$/i.test(p[key])) throw new Error(`Cor inválida para Pear: ${key}`);
    }
    const alpha=(color,a)=>`rgba(${color.slice(1).match(/../g).map(v=>parseInt(v,16)).join(', ')}, ${a})`;
    const custom={
        'play-nav-color':p.SURFACE,'dark-background':p.BACKGROUND,'dark-foreground':p.SURFACE,
        'light-text-1':p.TEXT,'light-2':p.TEXT_ALT,'light-3':p.TEXT_ALT,
        'light-4':alpha(p.TEXT_MUTED,.55),'light-5':p.ACCENT,
        'medium-1':alpha(p.TEXT_MUTED,.72),'medium-2':p.TEXT_ALT,'medium-3':p.TEXT_MUTED,
        'medium-4':p.TEXT_MUTED,'medium-5':p.SURFACE_ALT,
        'subscribe-color':p.ACCENT,'playbutton-color':p.ACCENT,
        'tertiary-nav-button-color':p.SECONDARY,'nowplaying-color':p.ACCENT,
        'main-text-1':p.TEXT_ALT,'header-text-1':p.TEXT,'header-text-2':p.TEXT_ALT
    };
    const native={
        '--ytmusic-color-black1':p.SURFACE,'--ytmusic-color-black2':p.SURFACE,
        '--ytmusic-color-black3':p.SURFACE_ALT,'--ytmusic-color-black4':p.BACKGROUND,
        '--ytmusic-color-blackpure':p.BACKGROUND,'--ytmusic-color-white1':p.TEXT,
        '--ytmusic-color-grey1':p.TEXT_ALT,'--ytmusic-color-grey2':p.TEXT_MUTED,
        '--ytmusic-static-brand-red':p.ACCENT,'--ytmusic-brand-link-text':p.ACCENT,
        '--ytmusic-setting-item-toggle-active':p.ACCENT,'--ytmusic-dialog-background-color':p.SURFACE,
        '--yt-spec-text-primary':p.TEXT,'--yt-spec-text-secondary':p.TEXT_MUTED,
        '--yt-spec-themed-blue':p.ACCENT,'--yt-spec-brand-link-text':p.ACCENT
    };
    const declarations=[...Object.entries(custom).map(([k,v])=>[`--cust-ytmusic-${k}`,v]),...Object.entries(native)]
        .map(([k,v])=>`  ${k}: ${v} !important;`).join('\n');
    // An explicit scope wins over the static layer, even if upstream inserts it later.
    // Keep author origin: Electron 42's user-origin sheets did not remove in render tests.
    const root = live ? 'html:root:root' : 'html';
    const inside = live ? ':root:root ' : '';
    return `/* Archblato: generated color layer. Load after your existing theme in Pear. */
${root}:not(.style-scope) {
${declarations}
}
${root}, ${inside}body, ${inside}ytmusic-app {
  background-color: ${p.BACKGROUND} !important;
  color: ${p.TEXT} !important;
}
${inside}ytmusic-nav-bar, ${inside}ytmusic-player-bar {
  background-color: ${p.SURFACE} !important;
  color: ${p.TEXT} !important;
}
${inside}ytmusic-search-box {
  --ytmusic-search-background: ${p.SURFACE_ALT} !important;
}
${root}:not(.style-scope) ytmusic-player-bar #progress-bar.ytmusic-player-bar,
${root}:not(.style-scope) ytmusic-player-bar #progress-bar.ytmusic-player-bar[focused],
${root}:not(.style-scope) ytmusic-player-bar:hover #progress-bar.ytmusic-player-bar,
${root}:not(.style-scope) ytmusic-player-bar #volume-slider {
  --paper-slider-active-color: ${p.ACCENT} !important;
  --paper-slider-knob-color: ${p.ACCENT} !important;
  --paper-slider-knob-start-color: ${p.ACCENT} !important;
  --paper-slider-knob-start-border-color: ${p.ACCENT} !important;
  --paper-slider-container-color: ${p.SURFACE_ALT} !important;
}
${inside}ytmusic-player-bar .play-pause-button {
  color: ${p.ACCENT} !important;
}
`;
}
module.exports={pearTheme};
