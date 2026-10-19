# Archblato Shell — continuação e animações, 17/10/2026

## Atualização posterior: central presa ao centro do topo

Pedido seguinte implementado apenas na posição/animação, sem criar a aba Perfil
nem incorporar o calendário nesta etapa:

- Central alinhada ao relógio, sem gap inferior da barra, topo reto e cantos
  inferiores arredondados. Dimensões e quatro abas existentes preservadas.
- Entrada/saída pela borda superior com deslocamento de altura inteira,
  320/260 ms, sem fade/zoom; clipping dá a sensação de painel encaixado.
- Reversão, liberação imediata de foco e fechamento de segurança preservados.
- A validação geométrica encontrou uma falha anterior: o `Binding` genérico da
  lista de transforms não deslocava o Item real. A instalação da lista agora é
  explícita uma vez; os valores dos transforms continuam ligados ao progresso.
  A correção também torna efetivos o encaixe proporcional e o deslocamento dos
  demais popups. Referência de composição: [Qt Quick Transform](https://doc.qt.io/qt-6.12/qml-qtquick-transform.html).
- Testes passaram: 8 arquivos Node, 32 verificações QML, integração Wayland
  isolada e SUPER real abrindo/fechando. Frames intermediários e coordenadas
  renderizadas foram conferidos, não somente o progresso lógico.

Arquivos desta atualização: `ControlCenter.qml`, `AnimatedPopup.qml`,
`PanelReveal.qml`, `DesignTokens.qml`, `TopBar.qml` (comentário de composição),
`tests/tst_PanelReveal.qml`, `tests-panels.qml`, `tests/panel-integration.cjs`,
`README.md` e este relatório. O registro abaixo descreve a etapa anterior.

## Resultado

A arquitetura da primeira etapa foi preservada. Esta continuação fecha o ciclo
de animação, melhora a transição das abas, completa tokens visuais e amplia a
validação. A referência foi usada pela ideia de módulos bem delimitados; não
copiamos a paleta vermelha nem transformamos a central num dashboard gigante.
O White mantém a central compacta, preto/cinza/roxo, JetBrains Mono e quatro abas.

## Implementação e comportamento

- **Painéis:** entrada de 220 ms, saída de 150 ms, deslocamento de 18 px e escala
  de 0,985 a 1. Central e calendário vêm de cima; quick settings usam o ponto do
  botão clicado. Reabrir durante a saída reverte do progresso atual, sem salto.
- **Ciclo de vida:** `opened` controla entrada e trabalho de sistema; `visible`
  mantém somente o desenho até a saída terminar. A máscara fica vazia, o grab é
  liberado e o conteúdo é desabilitado no fechamento lógico. Busca Wi-Fi/Bluetooth
  e observação de mídia não aguardam o fim da animação.
- **Exclusividade/lock:** abrir outro painel encerra imediatamente o anterior.
  O bloqueio também corta a animação. Coordenador continua sendo por monitor;
  não há mudança em WlSessionLock/PAM nem IPC de unlock.
- **Foco:** `HyprlandFocusGrab` permite liberar o grab ainda com a superfície
  visível. A propriedade nativa `PopupWindow.grabFocus` exige hide/show para mudar;
  por isso ela não é usada para controlar a saída. Referências:
  [PopupWindow](https://quickshell.org/docs/v0.3.2/types/Quickshell/PopupWindow/) e
  [HyprlandFocusGrab](https://quickshell.org/docs/v0.2.0/types/Quickshell.Hyprland/HyprlandFocusGrab/).
- **Abas:** crossfade e deslocamento horizontal de 10 px por 180 ms, respeitando
  a direção. A página que sai deixa de aceitar interação imediatamente. Trocas
  rápidas não deixam páginas presas nem criam screenshots/layers intermediários.
- **Notificações:** entrada lateral preservada, saída alinhada ao novo token e
  interrupção da entrada antes de dispensar; toast em saída não recebe cliques.
  Histórico, DND, replacements, ações e limite de três toasts não foram alterados.
- **Layout:** canvas original preservado, reduzido proporcionalmente somente
  quando necessário. No White: 480×480, área de páginas 354 px; Controles 336 px,
  Música 295 px, ambos sem scroll. Calendário calcula suas células pela grade
  lógica para não sofrer redução dupla. Em áreas muito pequenas também encolhem
  textos e alvos — isso não é um reflow universal.
- **Identidade:** cabeçalho “Archblato Shell”, subtítulo “White”; dimensões de
  sliders, capa, tray, toasts, calendário e lock visual passam a usar tokens.
  Cards modulares existentes foram mantidos; sem blur, shader, camada de textura,
  sombra nova ou aumento de transparência.
- **Detalhes CPU/RAM:** tooltip também é suprimido durante o bloqueio.

SUPER continua abrindo/fechando qualquer aba; Esc, IPC, navegação de abas,
integração com notificações e seleção de wallpapers permanecem. Não foram
reescritos MediaController, servidor de notificações, controllers de hardware
ou script de aplicação do wallpaper.

## Validação executada

- `node --test tests/*.test.cjs`: 8 arquivos passaram, zero falhas. Inclui
  conexão/Bluetooth simulados, notificações, atalho, métricas, contrato estrutural
  do lock, seis tamanhos de viewport e cache WebP com caminho contendo espaços.
- `QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests`:
  31 verificações passaram (contando setup/cleanup), zero falhas. Inclui
  sliders/mídia, acessibilidade, reversão de animação, troca rápida de abas,
  exclusividade, lock simulado e isolamento entre monitores simulados.
- `node tests/notification-integration.cjs`: servidor nativo em D-Bus privado;
  replacements, reload, DND, unread, expiração, ações, descarte e histórico.
- `node tests/system-integration.cjs`: rede/Bluetooth falsos, leases de busca,
  brilho com debounce/concorrência/erro e leituras reais de procfs. Nenhum rádio
  real foi alternado e o brilho real não foi modificado.
- `node tests/panel-integration.cjs --live`: superfícies Wayland reais isoladas,
  liberação imediata de entrada, reabertura, exclusividade, quick settings com
  busca falsa, calendário estreito e fechamento/rejeição por lock falso.
- Teclado virtual real no Hyprland: SUPER abre e o segundo SUPER fecha; Ctrl+Tab
  muda a aba; Esc fecha. Capturas de Controles e Música foram inspecionadas.
- `cc -Wall -Wextra ...`: sonda de teclado compilada sem avisos.
- `/usr/lib/qt6/bin/qmllint` nos painéis alterados: saída 0; continuam os avisos
  de metadados nativos do QuickShell (`PopupAnchor`, `PanelWindow`, screen).
  Carregamento nativo e IPC foram validados, sem reiniciar o shell da sessão.

O sandbox inicial impediu criar o socket D-Bus privado; os testes de integração
foram reexecutados com a permissão apropriada e passaram. Os testes não mexeram
no histórico pessoal nem no wallpaper atual.

### Medição no White

`node tests/panel-benchmark.cjs --live`, processo atual, não baseline anterior:

| Amostra | CPU (% de um núcleo) | RSS ao fim |
| --- | ---: | ---: |
| 10,01 s em repouso | 1,70% | 214,4 MiB |
| 20 ciclos abrir/fechar em 13,52 s | 30,92% | 218,4 MiB |

Ao terminar, superfície fechada e nenhuma animação em execução. Os números
incluem o shell inteiro e a sessão em uso; a segunda amostra força animações
continuamente. Não provam economia de energia nem ganho percentual em relação
à versão anterior. Não foi obtida leitura de energia RAPL com o usuário normal.

## Limitações de validação (não funcionalidades removidas)

- Rede e Bluetooth reais não foram desligados, conforme sua orientação.
- Não havia segundo monitor físico: isolamento e geometrias foram simulados.
- Não foi executado um ciclo humano de autenticação PAM; apenas contrato
  estrutural e fechamento com estado de lock simulado. Autenticação ficou intacta.
- Nesta rodada o IPC de mídia retornou `players: 0`; seek/volume foram cobertos
  pelos testes simulados, não repetidos num Pear real. A prova real da primeira
  etapa está registrada no relatório anterior. Repeat/shuffle dependem do player.
- Avisos QtWayland de text-input ao liberar foco continuam aparecendo; não houve
  falha funcional nos testes de teclado/entrada. Sem regressão conhecida nos
  cenários exercitados, não uma garantia sobre hardware não testado.

## Inventário desta continuação

| Arquivo alterado | Mudança |
| --- | --- |
| [PanelReveal.qml](PanelReveal.qml) | Progresso reversível, saída, snap no lock e escala de encaixe. |
| [PanelCoordinator.qml](PanelCoordinator.qml) | Estado lógico e fechamento imediato ao substituir/bloquear. |
| [ControlCenter.qml](ControlCenter.qml) | Base animada, páginas com transição, IPC de estado e identidade White. |
| [CalendarPopup.qml](CalendarPopup.qml) | Ciclo animado, encaixe e grade lógica/tokens. |
| [QuickSettingsPopup.qml](QuickSettingsPopup.qml) | Ciclo animado, origem do botão e busca ligada à abertura lógica. |
| [DesignTokens.qml](DesignTokens.qml) | Tempos de saída/abas e dimensões compartilhadas. |
| [NotificationPopup.qml](NotificationPopup.qml) | Tokens, saída coerente e descarte durante entrada. |
| [ValueSlider.qml](ValueSlider.qml) | Tokens de trilho, knob e escala pressed. |
| [MediaPlayerExpanded.qml](MediaPlayerExpanded.qml) | Tokens da capa e botão compacto, sem mudar integração. |
| [BarTray.qml](BarTray.qml) | Token do tamanho óptico do ícone. |
| [BarMetrics.qml](BarMetrics.qml) | Supressão do tooltip durante lock. |
| [TopBar.qml](TopBar.qml) | Injeta lock nos detalhes e usa abertura lógica do Arch. |
| [LockScreenView.qml](LockScreenView.qml) | Tokens de relógio/radius; nenhuma alteração em autenticação. |
| [tests/tst_PanelReveal.qml](tests/tst_PanelReveal.qml) | Entrada, saída, reversão e cancelamento imediato. |
| [tests/tst_PanelCoordinator.qml](tests/tst_PanelCoordinator.qml) | Contrato lógico atualizado. |
| [tests/wallpapers.test.cjs](tests/wallpapers.test.cjs) | Cache/renovação de thumbnail WebP, isolados em /tmp. |
| [README.md](README.md) | Ciclo novo, testes opcionais e limites. |
| [REFACTOR-2026-10-17.md](REFACTOR-2026-10-17.md) | Identifica o registro como primeira etapa e aponta esta atualização. |

| Arquivo novo | Responsabilidade |
| --- | --- |
| [AnimatedPopup.qml](AnimatedPopup.qml) | Pequena base específica do Archblato/Hyprland: superfície, foco e ciclo. |
| [PanelGeometry.js](PanelGeometry.js) | Encaixe proporcional testável. |
| [TabPage.qml](TabPage.qml) | Transição finita e interação somente na aba selecionada. |
| [tests/panel-geometry.test.cjs](tests/panel-geometry.test.cjs) | Encaixe em seis viewports, sem ampliar. |
| [tests/tst_TabPage.qml](tests/tst_TabPage.qml) | Direção, trocas rápidas e desativação da página de saída. |
| [tests-panels.qml](tests-panels.qml) | Harness nativo com hardware/lock falsos. |
| [tests/panel-integration.cjs](tests/panel-integration.cjs) | Exercita o harness Wayland, apenas com --live. |
| [tests/wayland-key.c](tests/wayland-key.c) | Sonda opcional de teclado, não dependência do shell. |
| [tests/panel-benchmark.cjs](tests/panel-benchmark.cjs) | Medição reproduzível do processo atual, apenas com --live. |
| [ANIMACOES-2026-10-17.md](ANIMACOES-2026-10-17.md) | Este relatório. |

## Opcionais futuros — não implementados automaticamente

OSD de volume/brilho, dashboard com múltiplos módulos simultâneos e favoritos
de wallpapers continuam opcionais. Para ampliar a confiança: teste humano de
lock/unlock, segundo monitor físico e medição energética comparativa controlada.
Não são motivo para adicionar novas camadas ou generalizar o shell pessoal.
