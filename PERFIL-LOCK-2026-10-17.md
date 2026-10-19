# Archblato — pós-lock, borda da tela e Perfil

## Correção pós-lock

O IPC da sessão ainda retornava `locked` após o usuário já ter desbloqueado,
mantendo central, calendário, tooltip de RAM e avisos suprimidos. A causa é
compatível com o caminho de unlock do QuickShell 0.3.2: o getter nativo pode mudar
sem o sinal que atualizava o binding `root.locked`.
[Implementação nativa da versão instalada](https://raw.githubusercontent.com/quickshell-mirror/quickshell/v0.3.2/src/wayland/session_lock.cpp).

`SessionLockState.qml` relê `locked` e `secure` nos dois sinais e no próximo ciclo
do Qt. `SessionLock.qml` também solicita a releitura depois de pedir lock e depois
do sucesso PAM. A UI voltou a informar `unlocked` e a central voltou a abrir.
O espelho nunca escreve no backend, não trata `secure=false` como autorização
para desbloquear e não adiciona polling. WlSessionLock, PAM, superfícies por
monitor e ausência de IPC de unlock permanecem.

## Borda e apresentação

- A superfície da barra começa em y=0; os elementos mantêm o inset visual de 4 px
  e a área reservada total de 38 px. Janelas não perderam espaço adicional.
- Central, calendário e quick settings usam a borda física. Foi necessário
  desativar o ajuste automático do popup nesses painéis já dimensionados: ele
  impunha um recuo residual de 4 px. Na central real, `surfaceY=0` e `barY=0`.
- Faixa superior fixa; corpo desliza por baixo dela. Central/calendário assumem
  o relógio da barra enquanto abertos. Clicar no relógio integrado da central
  abre o calendário; o coordenador continua impedindo dois painéis principais.
- Moldura escura opaca, contorno cinza discreto, topo reto e cantos inferiores
  de 28 px; sem blur/shader. Paleta roxa permanece nos controles/módulos.
- Central mantém corpo 480×480, mais 38 px de relógio integrado (total 480×518).
  Controles, Música e Perfil continuam sem scroll. Calendário continua separado.

## Perfil

- Quinta aba, com prévia, nome, apelido do computador, usuário e hostname reais.
- Nome/apelido editam somente o shell. Não alteram conta Linux nem hostname.
- Escolher/remover foto, Cancelar e Salvar. Foto PNG/JPEG local; o arquivo original
  é referenciado, não copiado. Se for movido/apagado, é preciso escolher outro.
- `profile.json` é criado somente ao salvar. FileView faz escrita atômica
  assíncrona; erro não confirma o rascunho. Estado compartilhado entre monitores,
  preservado em hot reload e reinício. Nenhuma nova dependência instalada.
- URL remota é rejeitada. WebP não aparece no seletor porque o Qt do White não
  tem decoder para ele; o fluxo WebP de wallpapers não mudou.
- Seletor de foto suspende o grab sem fechar a central; ao cancelar, o foco
  retorna. Fechar a central ou bloquear também fecha o seletor.
- O título curto “Avisos” mantém a aba de notificações e seu contador legíveis
  junto das cinco abas. Identificador IPC `notifications` continua igual.

## Validação

- `node --test tests/*.test.cjs`: nove arquivos, incluindo validação de perfil,
  caminhos Unicode/espaços, rejeição de URL remota e contrato de segurança.
- QtTest offscreen: 44 verificações passaram, incluindo ciclos repetidos lock/unlock, evento antes do getter mudar,
  `secure=false` ainda bloqueado, reabertura dos painéis, Cancelar/Salvar do
  perfil, fechamento do seletor, além dos testes anteriores de animação/mídia.
- `node tests/profile-integration.cjs`: D-Bus privado e diretório temporário;
  defaults, gravação, reinício, entrada inválida e falha real de gravação.
- `node tests/panel-integration.cjs --live`: geometria, reabertura após lock
  simulado, seletor real, suspensão/restauração do foco e fechamento combinado.
- Integrações anteriores de notificações e sistema reexecutadas; rede/Bluetooth
  e brilho continuam simulados, sem desligar os rádios reais.
- Capturas reais da central/Perfil e IPC conferidos. Os avisos de metadados do
  qmllint para tipos nativos e de text-input do QtWayland continuam conhecidos.
- SUPER real fechou a aba Perfil e reabriu a central; Esc encerrou a superfície
  sem manter entrada. O estado de abertura anterior ao teste foi restaurado.

Não executei autenticação com senha do usuário nem teste em segundo monitor
físico. Foi solicitado ao usuário confirmar um ciclo normal de lock/unlock.
Os testes do perfil não alteraram seu nome/foto reais: usaram arquivos temporários.

## Arquivos desta etapa

Novos:

- `SessionLockState.qml`: espelho de estado para UI.
- `ClockLabel.qml`, `DockFrame.qml`, `DockHeader.qml`: relógio reutilizado e moldura/faixa conectadas à tela.
- `ProfileData.js`, `ProfileStore.qml`, `ProfilePage.qml`: validação, persistência e editor.
- `tests/tst_SessionLockState.qml`, `tests/tst_ProfilePage.qml`: regressões de UI/lock.
- `tests/profile-data.test.cjs`, `tests/profile-integration.cjs`, `tests-profile.qml`: dados e persistência isolada.
- `PERFIL-LOCK-2026-10-17.md`: este relatório.

Alterados:

- `SessionLock.qml`: sincronização pós-transição, sem novo caminho de unlock.
- `AnimatedPopup.qml`: encaixe, altura da faixa e suspensão de foco para seletor.
- `ControlCenter.qml`: Perfil, relógio integrado, moldura e diagnóstico de posição.
- `CalendarPopup.qml`, `QuickSettingsPopup.qml`: origem na borda e faixa superior.
- `TopBar.qml`: superfície em y=0, relógio compartilhado e injeção do perfil.
- `shell.qml`: uma instância de perfil para todos os monitores.
- `DesignTokens.qml`: radius da moldura encaixada.
- `tests/tst_PanelCoordinator.qml`: reabertura após desbloqueio.
- `tests/security-contract.test.cjs`: espelho não escreve no backend do lock.
- `tests/panel-geometry.test.cjs`: dimensões com faixa integrada.
- `tests-panels.qml`, `tests/panel-integration.cjs`: seletor/foco e geometria real.
- `README.md`: uso e manutenção atualizados.

Possíveis melhorias futuras, não implementadas: suporte de avatar WebP por
conversão local, recorte manual da foto e uso opcional do perfil no lockscreen.
