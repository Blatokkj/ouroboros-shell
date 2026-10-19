// Logical panel sizes stay stable; fit only when the White's available area shrinks.
function fit(width, height, availableWidth, availableHeight) {
    const scale = Math.min(1, Math.max(1, availableWidth) / width, Math.max(1, availableHeight) / height);
    return { scale, width: Math.max(1, Math.floor(width * scale)), height: Math.max(1, Math.floor(height * scale)) };
}
