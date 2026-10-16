function wifiIcon(enabled, connected, strength, wired) {
    if (wired && !connected) return "󰈀";
    if (!enabled) return "󰖪";
    if (!connected) return "󰤯";
    if (strength >= 0.75) return "󰤨";
    if (strength >= 0.5) return "󰤥";
    if (strength >= 0.25) return "󰤢";
    return "󰤟";
}

// Explicit text pages keep every character available without a scroll area.
function textPages(text, width, linesPerPage, measure) {
    const lines = [];
    let line = "", used = 0;
    for (const char of Array.from(text || "")) {
        if (char === "\n") { lines.push(line); line = ""; used = 0; continue; }
        const size = measure(char);
        if (line && used + size > Math.max(1, width)) {
            const space = line.lastIndexOf(" ");
            if (space >= 0) {
                lines.push(line.slice(0, space + 1));
                line = line.slice(space + 1);
                used = Array.from(line).reduce(function(sum, ch) { return sum + measure(ch); }, 0);
            } else {
                lines.push(line); line = ""; used = 0;
            }
        }
        line += char;
        used += size;
    }
    lines.push(line);
    const pages = [];
    const count = Math.max(1, Math.floor(linesPerPage));
    for (let i = 0; i < lines.length; i += count) pages.push(lines.slice(i, i + count).join("\n"));
    return pages;
}
