// Private Unix socket, inside Pear's main process. No TCP, credentials, files of music history or arbitrary eval.
const fs = require('node:fs');
const net = require('node:net');
const {join} = require('node:path');
const {musicPage} = require('./pear-music-page.cjs');

function validRequest(r) {
    if (!r || !Number.isSafeInteger(r.seq) || r.seq < 0) return false;
    if (['snapshot', 'playlists', 'more', 'shuffle'].includes(r.action)) return true;
    if (r.action === 'repeat') return ['none', 'all', 'one'].includes(r.mode);
    if (r.action === 'queue') return Number.isInteger(r.index) && r.index >= 0 && r.index < 500 && /^[\w-]{1,160}$/.test(r.id || '');
    if (r.action === 'playlist') return typeof r.id === 'string' && /^[\w-]{1,160}$/.test(r.id);
    return false;
}

async function createBridge({path, execute, openPlaylist, pid = process.pid}) {
    const clients = new Set();
    let continuation = '', playlistIds = new Set();
    const server = net.createServer(socket => {
        if (clients.size >= 4) return socket.destroy();
        clients.add(socket);
        socket.setEncoding('utf8');
        let buffer = '', pending = 0, chain = Promise.resolve();
        socket.on('error', () => {});
        socket.on('close', () => clients.delete(socket));
        socket.on('data', data => {
            buffer += data;
            if (buffer.length > 8192) return socket.destroy();
            while (buffer.includes('\n')) {
                const cut = buffer.indexOf('\n'), line = buffer.slice(0, cut);
                buffer = buffer.slice(cut + 1);
                let request;
                try { request = JSON.parse(line); } catch { socket.destroy(); return; }
                if (!validRequest(request) || ++pending > 8) { socket.destroy(); return; }
                chain = chain.then(async () => {
                    if (socket.destroyed) return;
                    let timer;
                    try {
                        const action = request.action;
                        const operation = async () => {
                            if (action === 'playlist') {
                                if (!playlistIds.has(request.id)) throw new Error('stale');
                                await openPlaylist(request.id);
                                return {ok: true};
                            }
                            if (action === 'more' && !continuation) return {playlists: [], more: false};
                            const input = action === 'more' ? {action: 'playlists', continuation} : {
                                action, mode: request.mode, index: request.index, id: request.id
                            };
                            const data = await execute(input);
                            if (action === 'playlists' || action === 'more') {
                                continuation = data.continuation || '';
                                if (action === 'playlists') playlistIds = new Set();
                                for (const item of data.playlists) playlistIds.add(item.id);
                                return {playlists: data.playlists, more: Boolean(continuation)};
                            }
                            return data;
                        };
                        const data = await Promise.race([operation(), new Promise((_, reject) => {
                            timer = setTimeout(() => reject(new Error('timeout')), 6000);
                        })]);
                        const message = JSON.stringify({seq: request.seq, action, pid, data}) + '\n';
                        if (!socket.destroyed && message.length <= 1024 * 1024 && socket.writableLength < 1024 * 1024) socket.write(message);
                        else socket.destroy();
                    } catch {
                        if (!socket.destroyed) socket.write(JSON.stringify({seq: request.seq, action: request.action, pid, error: 'Não foi possível consultar/aplicar no Pear. Tente novamente.'}) + '\n');
                    } finally { clearTimeout(timer); pending--; }
                });
            }
        });
    });
    // Never unlink an active server. A stale socket from this exact private directory is recoverable.
    if (fs.existsSync(path)) {
        if (!fs.lstatSync(path).isSocket()) throw new Error('Destino não é socket');
        const active = await new Promise(resolve => {
            const probe = net.createConnection(path);
            probe.once('connect', () => { probe.destroy(); resolve(true); });
            probe.once('error', error => resolve(!['ECONNREFUSED', 'ENOENT'].includes(error.code)));
        });
        if (active) throw new Error('Bridge já ativo');
        fs.unlinkSync(path);
    }
    await new Promise((resolve, reject) => { server.once('error', reject); server.listen(path, resolve); });
    fs.chmodSync(path, 0o600);
    return () => { for (const client of clients) client.destroy(); server.close(); };
}

function installMusicBridge({app, BrowserWindow}) {
    app.whenReady().then(async () => {
        const runtime = process.env.XDG_RUNTIME_DIR;
        const stat = runtime && fs.lstatSync(runtime);
        if (!stat?.isDirectory() || stat.uid !== process.getuid() || (stat.mode & 0o077)) throw new Error('Runtime não privado');
        const directory = join(runtime, 'archblato-pear');
        fs.mkdirSync(directory, {mode: 0o700, recursive: true});
        const privateStat = fs.lstatSync(directory);
        if (!privateStat.isDirectory() || privateStat.uid !== process.getuid() || (privateStat.mode & 0o077)) throw new Error('Diretório não privado');
        const current = () => {
            const win = BrowserWindow.getAllWindows().find(w => {
                try { return new URL(w.webContents.getURL()).origin === 'https://music.youtube.com'; } catch { return false; }
            });
            if (!win) throw new Error('Player indisponível');
            return win;
        };
        const close = await createBridge({path: join(directory, 'music.sock'),
            execute: request => current().webContents.executeJavaScript(`(${musicPage.toString()})(${JSON.stringify(request)})`),
            // Explicit playlist click: let the original Pear/YT Music page load and play it.
            openPlaylist: id => current().webContents.loadURL(`https://music.youtube.com/watch?list=${encodeURIComponent(id)}`)});
        app.once('will-quit', close);
    }).catch(() => console.warn('[Archblato] Bridge musical indisponível; MPRIS e volume continuam disponíveis.'));
}
module.exports = {installMusicBridge, createBridge, validRequest};
