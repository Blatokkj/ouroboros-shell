// Fixed, bounded renderer operation for the user's existing Pear session.
// No cookie/storage access, remote scripts or arbitrary URLs. Shared with fixture tests.
async function musicPage(request) {
    if (location.origin !== 'https://music.youtube.com') throw new Error('wrong-origin');
    const bar = document.querySelector('ytmusic-player-bar');
    const queue = document.querySelector('#queue');
    const state = () => bar?.getState?.().queue || queue?.queue?.store?.store?.getState?.().queue;
    const items = () => queue?.queue?.getItems?.() || state()?.items || [];
    const video = item => item?.playlistPanelVideoRenderer || item?.playlistPanelVideoWrapperRenderer?.primaryRenderer?.playlistPanelVideoRenderer;
    const text = value => String(value?.simpleText || value?.runs?.map(r => r.text || '').join('') || '').slice(0, 300);
    const thumb = value => {
        const candidates = value?.thumbnails || value?.musicThumbnailRenderer?.thumbnail?.thumbnails || [];
        const url = candidates.find(t => t.width >= 80)?.url || candidates[0]?.url || '';
        try {
            const u = new URL(url);
            return u.protocol === 'https:' && /(^|\.)(ytimg\.com|ggpht\.com|googleusercontent\.com)$/.test(u.hostname) ? u.href : '';
        } catch { return ''; }
    };
    const repeatMode = () => ({NONE: 'none', ALL: 'all', ONE: 'one'})[state()?.repeatMode] || 'unknown';
    const idValid = id => typeof id === 'string' && /^[\w-]{1,160}$/.test(id);
    if (request.action === 'snapshot') {
        const list = items();
        return {
            ready: Boolean(state()), shuffle: Boolean(state()?.shuffleEnabled ?? bar?.hasAttribute('shuffle-on')),
            repeat: repeatMode(), canShuffle: typeof bar?.queue?.shuffle === 'function',
            canRepeat: typeof bar?.onRepeatButtonClick === 'function' && repeatMode() !== 'unknown',
            total: list.length, queue: list.slice(0, 500).flatMap((item, index) => {
                const v = video(item);
                return v ? [{index, id: v.videoId || '', title: text(v.title), artist: text(v.shortBylineText || v.longBylineText),
                    duration: text(v.lengthText), art: thumb(v.thumbnail), selected: Boolean(v.selected)}] : [];
            })
        };
    }
    if (request.action === 'shuffle') {
        if (typeof bar?.queue?.shuffle !== 'function') throw new Error('unsupported');
        bar.queue.shuffle();
        return {ok: true};
    }
    if (request.action === 'repeat') {
        if (!['none', 'all', 'one'].includes(request.mode) || repeatMode() === 'unknown' || !bar?.onRepeatButtonClick) throw new Error('unsupported');
        for (let i = 0; i < 3 && repeatMode() !== request.mode; i++) {
            bar.onRepeatButtonClick();
            await new Promise(resolve => setTimeout(resolve, 30));
        }
        if (repeatMode() !== request.mode) throw new Error('not-applied');
        return {ok: true};
    }
    if (request.action === 'queue') {
        const v = video(items()[request.index]);
        if (!Number.isInteger(request.index) || !v || v.videoId !== request.id || !queue?.dispatch) throw new Error('stale');
        queue.dispatch({type: 'SET_INDEX', payload: request.index});
        return {ok: true};
    }
    if (request.action === 'playlists') {
        const app = document.querySelector('ytmusic-app');
        if (!app?.networkManager?.fetch) throw new Error('unavailable');
        const body = {browseId: 'FEmusic_liked_playlists'};
        if (request.continuation) body.continuation = request.continuation;
        const result = await app.networkManager.fetch('/browse', body);
        const playlists = [], seen = new Set();
        let continuation = '', budget = 12000;
        function visit(node, depth = 0) {
            if (!node || typeof node !== 'object' || depth > 24 || --budget < 0) return;
            const renderer = node.musicTwoRowItemRenderer;
            if (renderer) {
                const endpoint = renderer.navigationEndpoint;
                const browse = endpoint?.browseEndpoint?.browseId || '';
                const id = endpoint?.watchPlaylistEndpoint?.playlistId || (browse.startsWith('VL') ? browse.slice(2) : '');
                if (idValid(id) && !seen.has(id) && playlists.length < 100) {
                    seen.add(id);
                    playlists.push({id, title: text(renderer.title), subtitle: text(renderer.subtitle), art: thumb(renderer.thumbnailRenderer)});
                }
            }
            const token = node.nextContinuationData?.continuation || node.continuationCommand?.token;
            if (!continuation && typeof token === 'string' && token.length < 8192) continuation = token;
            for (const value of Object.values(node)) visit(value, depth + 1);
        }
        visit(result);
        return {playlists, continuation};
    }
    throw new Error('unsupported');
}
module.exports = {musicPage};
