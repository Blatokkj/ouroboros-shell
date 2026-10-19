// Pure state comparisons: no system changes, timers or notifications on startup.
function notice(key, title, body, icon, level) {
    return { key: key, title: title, body: body, icon: icon, level: level || "info" };
}

function networkEvents(previous, current) {
    if (!previous)
        return [];
    const events = [];
    const changed = previous.status !== current.status || previous.label !== current.label;
    const radioChanged = previous.wifiEnabled !== current.wifiEnabled;
    if (changed) {
        if (current.status === "offline") {
            events.push(notice("network", radioChanged && !current.wifiEnabled ? "Wi-Fi desativado" : "Rede desconectada",
                previous.label ? "Conexão com " + previous.label + " encerrada." : "Nenhuma conexão de rede ativa.", "󰖪", "warning"));
        } else if (current.status === "full") {
            events.push(notice("network", previous.status === "full" ? "Rede conectada" : "Internet restabelecida",
                current.label + " · Acesso à internet disponível.", "󰖩"));
        } else if (current.status === "portal") {
            events.push(notice("network", "Rede pede autenticação",
                current.label + " · Abra o navegador para liberar o acesso.", "󰖟", "warning"));
        } else if (current.status === "limited") {
            events.push(notice("network", "Sem acesso à internet",
                "Conectado a " + current.label + ", mas o acesso está limitado.", "󰖪", "warning"));
        } else {
            events.push(notice("network", "Rede conectada", current.label, "󰖩"));
        }
    }
    if (radioChanged && !(changed && !current.wifiEnabled && current.status === "offline")) {
        // When a connection is already established its notice covers enabling Wi-Fi.
        if (!current.wifiEnabled || !changed)
            events.push(notice("wifi-radio", current.wifiEnabled ? "Wi-Fi ativado" : "Wi-Fi desativado",
                current.wifiEnabled ? "As redes sem fio estão disponíveis." : "As conexões sem fio foram desligadas.",
                current.wifiEnabled ? "󰖩" : "󰖪"));
    }
    return events;
}

function bluetoothEvents(previous, current) {
    if (!previous)
        return [];
    const events = [];
    const adapterIds = Object.keys(previous.adapters).concat(Object.keys(current.adapters)
        .filter(function(key) { return !previous.adapters[key]; }));
    adapterIds.forEach(function(key) {
        const oldAdapter = previous.adapters[key];
        const adapter = current.adapters[key];
        if (!adapter || !oldAdapter || adapter.enabled !== oldAdapter.enabled) {
            const enabled = adapter && adapter.enabled;
            events.push(notice("bluetooth-radio:" + key,
                !adapter ? "Bluetooth indisponível" : enabled ? "Bluetooth ativado" : "Bluetooth desativado",
                (adapter || oldAdapter).name, enabled ? "󰂯" : "󰂲", !adapter ? "warning" : "info"));
        }
    });
    Object.keys(previous.devices).forEach(function(key) {
        if (current.devices[key])
            return;
        const device = previous.devices[key];
        const adapter = current.adapters[device.adapter];
        // Switching a radio off produces one notice instead of one per device.
        if (adapter && adapter.enabled)
            events.push(notice("bluetooth:" + key, "Bluetooth desconectado", device.name, "󰂲", "warning"));
    });
    Object.keys(current.devices).forEach(function(key) {
        if (!previous.devices[key])
            events.push(notice("bluetooth:" + key, "Bluetooth conectado", current.devices[key].name, "󰂱"));
    });
    return events;
}

function powerEvents(previous, current) {
    if (!previous || !previous.ready || !current.ready)
        return [];
    const events = [];
    if (previous.onBattery !== current.onBattery) {
        events.push(notice("power", current.onBattery ? "Carregador desconectado" : "Carregador conectado",
            "Bateria em " + current.percent + "%.", current.onBattery ? "󰁹" : "󰂄"));
    }
    if (current.onBattery && current.percent <= 5 && (previous.percent > 5 || !previous.onBattery)) {
        events.push(notice("battery", "Bateria crítica", current.percent + "% restantes. Conecte o carregador.", "󰂃", "error"));
    } else if (current.onBattery && current.percent <= 15 && (previous.percent > 15 || !previous.onBattery)) {
        events.push(notice("battery", "Bateria baixa", current.percent + "% restantes. Conecte o carregador.", "󰁺", "warning"));
    }
    return events;
}
