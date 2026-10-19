# Arquitetura observada

Verificada em 2026-10-18. Fontes: arquivos citados abaixo, README e testes.
Revalidar após mudanças em composição, controllers, persistência ou QuickShell.

## Mapa

```text
shell.qml
├── Theme + WallpaperTheme / SystemStats / NetworkController / BrightnessController / PowerController
├── ProfileStore / SessionLock / SystemNotifications / MediaController
└── Variants (um TopBar por monitor)
    ├── Bar*.qml + relógio + botão Arch
    ├── PanelCoordinator (exclusividade local)
    └── ControlCenter / CalendarPopup / QuickSettingsPopup
```

[TopBar](../TopBar.qml) orquestra módulos pequenos. A
[central](../ControlCenter.qml) compõe Controles, Música, Avisos, Wallpapers e
Perfil. Não existe frontend web, banco SQL, ORM, servidor HTTP ou bundler.
QML/JS rodam no QuickShell; scripts auxiliares usam Bash/Node e ferramentas do Arch.

## Fronteiras que devem permanecer

| Responsabilidade | Fonte | Contrato |
|---|---|---|
| Rede e Bluetooth | [NetworkController](../NetworkController.qml) | Estado compartilhado, ações e leases de busca; não duplicar detecção na UI |
| Brilho | [BrightnessController](../BrightnessController.qml) | Feedback imediato, debounce de 120 ms, um processo por vez, última solicitação prevalece |
| CPU/RAM/temperatura | [SystemStats](../SystemStats.qml) | FileView/procfs e sensores do White; script diagnóstico fora do polling |
| Painéis | [PanelCoordinator](../PanelCoordinator.qml), [AnimatedPopup](../AnimatedPopup.qml) | Exclusividade por monitor; entrada/foco liberados antes da animação terminar |
| Mídia | [MediaController](../MediaController.qml) | Pear/YT Music/Chromium, MPRIS, PipeWire por processo e filhos, seleção, seek, repeat/shuffle |
| Avisos | [SystemNotifications](../SystemNotifications.qml) | Histórico limitado, unread, DND, actions, replacements, transitórias e três toasts |
| Lock | [SessionLock](../SessionLock.qml), [SessionLockState](../SessionLockState.qml) | PAM autoriza unlock; espelho apenas relê estado nativo, nunca autentica |
| Perfil | [ProfileStore](../ProfileStore.qml), [ProfileData](../ProfileData.js) | Validação, escrita atômica após Salvar, falha mantém estado anterior; nome/foto compartilhados com o lock |
| Wallpaper | [WallpaperPicker](../WallpaperPicker.qml), [script](../scripts/wallpapers) | Galeria pessoal, validação de caminho/formato, cache, hyprpaper e aplicação da paleta |
| Cores | [WallpaperTheme](../WallpaperTheme.qml), [extração](../scripts/wallpaper-palette.cjs), [aplicação](../scripts/wallpaper-theme.cjs) | JSON validado observado sem reload QML; alvos pessoais explícitos, backup inicial e rollback em falha |

## Dados e efeitos externos

- `profile.json` só nasce ao salvar; não renomeia conta Linux ou hostname.
  A foto é uma referência a PNG/JPEG local, não uma cópia. Não incluir esse JSON
  em publicação automática, snapshots de código ou relatórios.
- Histórico/DND usam persistência de hot reload do QuickShell, não armazenamento
  permanente em disco; não sobrevivem ao encerramento da sessão.
- Wallpaper altera a configuração pessoal de hyprpaper. Listagem e cache são
  separados da aplicação; testes usam diretórios temporários. A aplicação usa
  `flock` para serializar cliques entre monitores e depois extrai as cores com
  ImageMagick. Retorno 2 significa wallpaper aplicado, mas falha nas cores.
- A paleta atualiza `archblato/theme.sh`, `hypr/theme.lua`, `hypr/hyprtoolkit.conf`,
  os dois TOMLs de Alacritty (o principal sobrescreve o import), CSS GTK 3/4, Fastfetch e
  `pear-theme.css` e `wallpaper-colors.json`. Não executa o antigo `usability/apply.sh`, não reinicia
  hyprpaper/QuickShell e não altera PAM. Não é uma transação global entre processos:
  escritas são atômicas por arquivo, com restauração das cores em caso de falha.
- [pear-theme.cjs](../scripts/pear-theme.cjs) gera somente cores, sobrepondo as
  variáveis do CSS pessoal do Pear sem alterar layout. O arquivo foi registrado
  uma vez após o tema existente; trocar wallpaper não reescreve configurações
  do Pear nem reinicia o app. O launcher pessoal [pear-desktop](../scripts/pear-desktop)
  inicia [o adaptador local](../integrations/pear/main.cjs), que preserva identidade,
  userData e appPath e importa o Pear instalado sem alterar o ASAR.
- [pear-live-theme.cjs](../scripts/pear-live-theme.cjs) observa os diretórios da
  paleta e da configuração do Pear (renames atômicos), com debounce de 80 ms.
  Lê somente cores validadas e a presença do tema na lista; insere CSS apenas em
  `https://music.youtube.com`, sem JS no renderer, reload, sockets ou polling.
  Login não recebe estilos. Mantém uma camada por janela, serializa mudanças e
  preserva IDs de remoções pendentes. Navegação só invalida IDs após commit.
  JSON inválido mantém a última paleta; tirar o tema da lista remove a camada ao vivo.
  O pacote 3.12.0 e seus plugins permanecem intactos; versão diferente cai no
  launcher original e no CSS estático até revalidar o adaptador.
- O gerador pessoal `themes/quickshellthemes.sh` preserva os bindings da paleta.
  O backup inicial de cores fica fora do código, em `archblato/theme-backup`.
  O link GTK4 específico para Orchis vira um wrapper local que importa o tema
  original; backup/rollback preservam o destino do link. Não se escreve em `/usr/share`.
- Depois de confirmar as cores dos arquivos, `scripts/mouse-theme.cjs` sincroniza
  somente o LED 0 do perfil 0 do G203 LIGHTSYNC (modelo `usb:046d:c092:0`), via
  ratbagctl/ratbagd. Descobre o ID em cada aplicação e recusa modelo/perfil inesperado
  ou ajustes pendentes. Não altera cursor, DPI, botões ou perfil. Sem polling:
  confirmação limitada após escrita, nenhuma escrita quando a cor já coincide.
- Falha/ausência de RGB retorna 3 no CLI e em `scripts/wallpapers`: o tema desktop
  permanece aplicado e a galeria informa pendência. Não reverte cores já aplicadas
  por causa de periférico desconectado; reaplicar tenta novamente. Os testes usam
  ratbagctl falso, nunca o mouse real. Novos alvos de arquivo são acrescentados ao
  backup original sem substituir entradas anteriores.
- PAM, NetworkManager, Bluetooth, PipeWire e UPower são serviços reais.
  D-Bus privado e fakes dos harnesses não comprovam comportamento do hardware.
- Comandos do sistema são operações sensíveis; leia o caller antes de executar.
  Não introduzir concatenação de dados externos em comandos de shell.

## Decisões e histórico

Não adicionar wrappers onde não reduzem complexidade. Não dividir arquivos só
para atender um limite de linhas: nesta leitura ControlCenter tem 422 linhas e
QuickSettingsPopup 495. São pontos de atenção, não motivo para refatorar neste setup.

No QuickShell 0.3.2, o espelho de lock foi acrescentado por atualização perdida
do estado nativo após unlock. A revisão do backend e o teste PAM real continuam
necessários antes de mudar essa decisão. Detalhes e evidência histórica:
[refatoração](../REFACTOR-2026-10-17.md),
[animações](../ANIMACOES-2026-10-17.md),
[pós-lock e Perfil](../PERFIL-LOCK-2026-10-17.md).

Os relatórios datados são histórico, não prevalecem sobre código e testes atuais.
