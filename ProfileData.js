function avatarUrl(value) {
    if (typeof value !== "string") throw new Error("Foto inválida.");
    const path = value.trim();
    if (!path) return "";
    if (/[\u0000-\u001f]/.test(path)) throw new Error("Caminho da foto inválido.");
    if (path.startsWith("/")) return "file://" + path.split("/").map(encodeURIComponent).join("/");
    if (path.startsWith("file:///")) {
        const decoded = decodeURIComponent(path.slice(7));
        if (/[\u0000-\u001f]/.test(decoded)) throw new Error("Caminho da foto inválido.");
        return "file://" + decoded.split("/").map(encodeURIComponent).join("/");
    }
    throw new Error("Escolha uma foto local, não um endereço da internet.");
}
function normalize(data) {
    if (!data || typeof data !== "object" || Array.isArray(data)) throw new Error("Perfil inválido.");
    function label(value, max, name) {
        if (typeof value !== "string" || !value.trim() || value.trim().length > max || /[\u0000-\u001f]/.test(value))
            throw new Error(name + " deve ter entre 1 e " + max + " caracteres, em uma linha.");
        return value.trim();
    }
    return {version:1, displayName:label(data.displayName,60,"Nome"),
        computerName:label(data.computerName,40,"Apelido do PC"), avatar:avatarUrl(data.avatar || "")};
}
function parse(text) {
    const data = JSON.parse(text);
    if (data.version !== 1) throw new Error("Versão de perfil não suportada.");
    return normalize(data);
}
