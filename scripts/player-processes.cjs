// Resolve only audio processes owned by this MPRIS application, never by name alone.
const { execFileSync } = require('node:child_process');
const { readFileSync } = require('node:fs');
const busName = process.argv[2] || '';
if (!/^org\.mpris\.MediaPlayer2\.[\w.-]+$/.test(busName)) process.exit(1);
try {
    const owner = Number(execFileSync('busctl', ['--user', 'call', 'org.freedesktop.DBus',
        '/org/freedesktop/DBus', 'org.freedesktop.DBus', 'GetConnectionUnixProcessID', 's', busName],
        { encoding: 'utf8', timeout: 2000 }).trim().split(' ')[1]);
    const candidates = JSON.parse(process.argv[3] || '[]');
    const pids = candidates.filter(pid => {
        let current = Number(pid);
        const seen = new Set();
        while (Number.isInteger(current) && current > 1 && !seen.has(current)) {
            if (current === owner) return true;
            seen.add(current);
            try {
                const stat = readFileSync('/proc/' + current + '/stat', 'utf8');
                current = Number(stat.slice(stat.lastIndexOf(')') + 2).split(' ')[1]);
            } catch { return false; }
        }
        return false;
    });
    process.stdout.write(JSON.stringify({ busName, pids }));
} catch { process.stdout.write(JSON.stringify({ busName, pids: [] })); }
