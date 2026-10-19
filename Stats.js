// Linux accounting used on White. Guest time is already included in user/nice.
function cpu(text) {
    const fields = text.split("\n", 1)[0].trim().split(/\s+/);
    if (fields[0] !== "cpu" || fields.length < 9) return null;
    const times = fields.slice(1, 9).map(Number);
    if (!times.every(Number.isFinite)) return null;
    return { total: times.reduce((a, b) => a + b, 0), idle: times[3] + times[4] };
}
function usage(previous, next) {
    if (!previous || !next || next.total <= previous.total) return null;
    return Math.max(0, Math.min(100, 100 * (1 - (next.idle - previous.idle) / (next.total - previous.total))));
}
function memory(text) {
    const total = /^MemTotal:\s+(\d+)/m.exec(text);
    const available = /^MemAvailable:\s+(\d+)/m.exec(text);
    if (!total || !available || Number(total[1]) <= 0) return null;
    const used = Math.max(0, Number(total[1]) - Number(available[1]));
    return { total: Number(total[1]), used, percent: 100 * used / Number(total[1]) };
}
