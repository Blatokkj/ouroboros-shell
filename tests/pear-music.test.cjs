const {test} = require('node:test');
const assert = require('node:assert/strict');
const {runInNewContext} = require('node:vm');
const {musicPage} = require('../scripts/pear-music-page.cjs');
const {validRequest} = require('../scripts/pear-music-bridge.cjs');
function fixture() {
    const state = {repeatMode: 'NONE', shuffleEnabled: false};
    const entry = {videoId: 'video1', title: {runs: [{text: '<b>Faixa</b>'}]}, shortBylineText: {runs: [{text: 'Artista'}]},
        lengthText: {simpleText: '2:30'}, selected: true, thumbnail: {thumbnails: [{url: 'https://i.ytimg.com/a.jpg'}]}};
    const list = [{playlistPanelVideoRenderer: entry}, {playlistPanelVideoWrapperRenderer: {primaryRenderer: {playlistPanelVideoRenderer: {...entry, videoId: 'video2'}}}}];
    const actions = [], calls = [];
    const bar = {getState: () => ({queue: state}), queue: {shuffle: () => state.shuffleEnabled = !state.shuffleEnabled},
        onRepeatButtonClick: () => state.repeatMode = {NONE: 'ALL', ALL: 'ONE', ONE: 'NONE'}[state.repeatMode]};
    const queue = {queue: {getItems: () => list}, dispatch: action => actions.push(action)};
    const app = {networkManager: {fetch: async (path, body) => { calls.push({path, body}); return {
        items: [{musicTwoRowItemRenderer: {title: {runs: [{text: 'Minha lista'}]}, navigationEndpoint: {browseEndpoint: {browseId: 'VLPL_test'}},
            thumbnailRenderer: {musicThumbnailRenderer: {thumbnail: {thumbnails: [{url: 'https://lh3.googleusercontent.com/a'}]}}}}}],
        continuations: [{nextContinuationData: {continuation: 'page2'}}]
    }; }}};
    const context = {document: {querySelector: selector => ({'ytmusic-player-bar': bar, '#queue': queue, 'ytmusic-app': app})[selector]},
        location: {origin: 'https://music.youtube.com'}, URL, setTimeout};
    const invoke = request => runInNewContext(`(${musicPage.toString()})(${JSON.stringify(request)})`, context);
    return {state, list, actions, calls, context, invoke};
}
test('queue wrappers, metadata and selected item normalize without exposing credentials', async () => {
    const f = fixture(), data = await f.invoke({action: 'snapshot'});
    assert.equal(data.queue.length, 2); assert.equal(data.queue[1].index, 1);
    assert.equal(data.queue[0].title, '<b>Faixa</b>'); assert.equal(data.repeat, 'none');
    assert.ok(data.canShuffle && data.canRepeat);
    assert.equal(data.queue[0].art, 'https://i.ytimg.com/a.jpg');
});
test('all three native repeat modes and shuffle work without changing autoplay', async () => {
    const f = fixture(); f.state.autoplay = true;
    for (const mode of ['all', 'one', 'none']) {
        await f.invoke({action: 'repeat', mode});
        assert.equal((await f.invoke({action: 'snapshot'})).repeat, mode);
        assert.equal(f.state.autoplay, true);
    }
    await f.invoke({action: 'shuffle'}); assert.equal(f.state.shuffleEnabled, true);
});
test('queue selections reject stale IDs and unsupported request data', async () => {
    const f = fixture();
    await assert.rejects(f.invoke({action: 'queue', index: 0, id: 'old'}), /stale/);
    assert.equal(f.actions.length, 0);
    await f.invoke({action: 'queue', index: 1, id: 'video2'});
    assert.equal(f.actions[0].payload, 1);
    for (const r of [{seq: 1, action: 'eval'}, {seq: 1, action: 'playlist', id: 'https://evil.test'},
        {seq: 1, action: 'repeat', mode: 'invalid'}, {seq: 1, action: 'queue', index: -1, id: 'x'}]) assert.equal(validRequest(r), false);
});
test('library requests use existing session manager and normalize a bounded continuation', async () => {
    const f = fixture(); const data = await f.invoke({action: 'playlists'});
    assert.equal(f.calls[0].path, '/browse'); assert.equal(f.calls[0].body.browseId, 'FEmusic_liked_playlists');
    assert.equal(data.playlists[0].id, 'PL_test'); assert.equal(data.continuation, 'page2');
    f.context.location.origin = 'https://accounts.google.com';
    await assert.rejects(f.invoke({action: 'playlists'}), /wrong-origin/);
    assert.equal(f.calls.length, 1);
});
