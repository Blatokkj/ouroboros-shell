# Ouroboros Shell

Shell pessoal do White, feito com QuickShell. Não é um framework nem uma
configuração universal: hardware, caminhos e integrações continuam feitos para
este setup. Ele cobre:

- workspaces do Hyprland por monitor;
- título da janela ativa;
- relógio com calendário e precisão de segundos;
- CPU, memória e brilho;
- áudio PipeWire com controles;
- mídia MPRIS;
- system tray;
- bateria via UPower.
- Wi-Fi e Bluetooth nativos;
- central de controle com sliders e toggles;
- idle inhibitor e perfis de energia;
- tela de bloqueio nativa, autenticada por PAM, e desligamento com confirmação;
- galeria de wallpapers integrada, com prévias e aplicação instantânea;
- detalhes precisos de CPU e RAM ao passar o mouse;
- pop-ups nativos de rede, Bluetooth, carregador e bateria baixa.
- central de notificações de aplicativos, histórico e modo não perturbe;
- player expandido com prioridade para Pear Desktop / YT Music.
- perfil pessoal editável (nome, foto PNG/JPEG e apelido do computador).

## Manutenção e contexto

- [Produto pessoal e limites](PRODUCT.md).
- [Instruções para agentes](AGENTS.md).
- [Arquitetura e contratos](docs/architecture.md).
- [Design e interação](docs/design.md).
- [Diagnóstico e recuperação no White](docs/onboarding.md).
- [Testes e revisão](docs/quality.md).
- [Setup de desenvolvimento, catálogo e evidências](docs/setup.md).

## Execução

O autostart do Ouroboros inicia esta configuração com:

```bash
qs --daemonize --no-duplicate --path ~/.config/archblato/quickshell
```

Somente se esta configuração não estiver ativa, é possível iniciá-la em primeiro
plano para acompanhar os logs (não abra uma segunda instância):

```bash
qs --path ~/.config/archblato/quickshell
```

O QuickShell recarrega automaticamente quando os arquivos QML mudam. Para
acompanhar a instância existente, prefira `qs log --path . --no-color -t 30`
nesta pasta. Encerrar esta configuração é uma ação manual do usuário, não uma
etapa de testes; nunca faça isso com a sessão bloqueada:

```bash
qs kill -p ~/.config/archblato/quickshell
```

## Controles

- Workspaces: clique para ativar.
- Arch, à direita: clique esquerdo abre a Central de Controle; clique direito
  abre o launcher. Ele substitui a engrenagem; não há outro Arch à esquerda.
- Horário: clique abre o calendário; o painel mostra data completa e horário
  com hora, minuto e segundo.
- CPU/RAM: passe o mouse para ver percentual preciso, carga média e valores em
  GiB.
- Mídia: clique abre a central com o player expandido, clique do meio alterna
  play/pause, clique direito traz o aplicativo à frente e a roda troca de faixa.
- Notificações: abra a aba correspondente na central; o contador da aba indica
  avisos não lidos. O botão não perturbe fica dentro dela, sem sino na barra.
- Áudio: clique esquerdo abre o controle compacto, clique do meio silencia,
  clique direito abre o Pavucontrol e a roda ajusta o volume.
- Brilho: clique abre o controle compacto e a roda ajusta o valor diretamente.
- Wi-Fi/Bluetooth: clique curto liga ou desliga; mantenha pressionado para abrir
  a lista de redes ou dispositivos. Redes novas exibem o campo de senha.
- O próprio ícone de Wi-Fi indica a intensidade do sinal, sem pop-up de hover;
  a cor de alerta indica conectividade limitada/portal.
  O ícone duplicado do nm-applet fica oculto (o applet continua funcionando).
- Tray: clique esquerdo ativa, meio executa a ação secundária e direito abre o
  menu.
- Wallpapers: abra a aba Wallpapers para pré-visualizar e aplicar com um clique.
- SUPER sozinho (ao soltar): abre Controles no monitor ativo ou fecha a central
  se ela já estiver aberta, independentemente da aba. O atalho está em
  `~/.config/hypr/binds.lua` e chama `scripts/open-control-center.cjs` via Node;
  os atalhos com SUPER e outras teclas continuam disponíveis.
- Central: controla Wi-Fi, Bluetooth, modo avião, suspensão e perfil de energia;
  o cadeado abre a tela de bloqueio do QuickShell.

A tela também pode ser acionada pelo script `scripts/lock-screen`, útil para
atalhos do Hyprland ou para um daemon de inatividade.

```bash
~/.config/archblato/quickshell/scripts/lock-screen
```

Ela usa o bloqueio de sessão do Wayland em todos os monitores e a senha do
usuário atual, autenticada pelo serviço PAM `login` do sistema. O wallpaper
é atualizado a cada bloqueio. O desbloqueio só acontece após o PAM confirmar
a autenticação; não existe comando IPC para desbloquear.

O bloqueio automático por inatividade não está configurado. Evite encerrar ou
reiniciar o processo do QuickShell enquanto a sessão estiver bloqueada.

## Avisos de conexão e energia

Os avisos aparecem no canto superior direito do monitor ativo, abaixo da barra.
Mostram o nome da rede ou dispositivo e desaparecem em 5 segundos (7 para
alertas, 10 para bateria crítica). Passar o mouse pausa a contagem; o × fecha
o aviso. São exibidos até três de cada vez, e um novo estado da mesma conexão
atualiza o aviso existente.

- Rede conectada/desconectada e Wi-Fi ativado/desativado.
- Internet restabelecida, acesso limitado e redes com portal de autenticação,
  conforme o estado informado pelo NetworkManager. Se a verificação de
  conectividade estiver desabilitada, o aviso informa somente a conexão à rede.
- Bluetooth ativado/desativado e dispositivos conectados/desconectados.
- Carregador conectado/desconectado e bateria passando por 15% e 5%.

A inicialização/reload apenas registra o estado atual das conexões. Os pop-ups
ficam suprimidos durante o bloqueio da sessão, sem expor conteúdo na tela de
bloqueio. O QuickShell agora atende também às notificações dos aplicativos pelo
serviço `org.freedesktop.Notifications`; não execute outro daemon de notificações
(como Dunst) junto dele. Os avisos equivalentes do nm-applet foram desativados
para evitar duplicação. Para restaurá-los se remover este módulo:

```bash
gsettings set org.gnome.nm-applet disable-connected-notifications false
gsettings set org.gnome.nm-applet disable-disconnected-notifications false
```

Uma prévia que não altera nenhuma conexão pode ser acionada com:

```bash
qs ipc --path ~/.config/archblato/quickshell call notifications preview
```

## Central e player

A Central de Controle tem cinco abas: **Controles**, **Música**,
**Avisos** (notificações), **Wallpapers** e **Perfil**, com indicador animado.
No White mede 480×518, incluindo a faixa integrada do relógio; o corpo continua
480×480, adaptado a telas menores. O Arch abre Controles; a música da
barra abre Música; clicar no corpo de um pop-up abre Notificações. `Esc` ou o ×
fecha o painel; clicar novamente no atalho da aba aberta também o fecha.
A galeria de wallpapers agora é uma aba, sem janela separada, e permanece
aberta após aplicar uma imagem.

A central, o calendário e os quick settings ficam conectados à borda física da
tela. O corpo desliza sob uma faixa fixa (320 ms entrando, 260 ms saindo), sem
fade ou zoom. Bordas externas são discretas, retas em cima e arredondadas embaixo.
Quando central/calendário estão visíveis, o relógio da barra aparece dentro dessa
faixa, sem duplicação. Clicar nele na central abre o calendário; no calendário,
fecha o painel. O calendário permanece um painel próprio.

Na aba Perfil, edite seu nome e o apelido do PC, escolha uma foto PNG/JPEG e
pressione **Salvar**. **Cancelar** descarta o rascunho. Os dados são gravados
atomicamente em `profile.json` nesta pasta, sobrevivem ao reload/reinício e são
compartilhados entre monitores. Nenhuma conta Linux ou hostname é renomeado.
O nome e a foto salvos também são usados no lockscreen. A foto continua sendo
um arquivo local: não a mova/apague depois de selecionar. Sem foto personalizada,
o lock usa a imagem existente do AccountsService; imagem indisponível mostra a inicial.

## Cores do wallpaper

Escolher um wallpaper agora também extrai sua cor predominante e aplica uma
paleta escura ao shell (incluindo o lock), bordas do Hyprland, Hyprtoolkit/launcher,
Alacritty, GTK 3/4, Fastfetch, tema do Pear Desktop e RGB do mouse físico Logitech G203 LIGHTSYNC.
Fontes, gaps, geometria e cores semânticas de erro/aviso são
preservados. Nenhum polling foi acrescentado: a extração ocorre só ao aplicar.

A paleta agora puxa para tons mais escuros que a imagem: fundos limitados pela
luminosidade média e acento partindo de 85% da luminosidade HSL da cor dominante,
sem clareamento pastel fixo. Texto/acentos têm piso de contraste: em imagens muito
escuras, os destaques podem ficar mais claros que a fonte para continuar legíveis.

As cores do shell chegam por `wallpaper-colors.json`, sem reiniciar o QuickShell.
Alacritty acompanha a configuração; apps GTK/launcher já abertos podem precisar
ser reabertos. Outros apps com tema próprio, sites e apps Qt sem integração de
paleta não são forçados a adotar essas cores.

O Pear usa a mesma paleta escura, preservando o CSS pessoal e seu layout. Aberto
pelo launcher ou pela central, acompanha novas cores **sem recarregar a página
nem interromper a música**. A extensão pessoal observa arquivos por eventos,
com debounce de 80 ms, e substitui apenas sua camada de cores. Não abre servidor
ou porta de depuração e não modifica o pacote instalado.

`pear-theme.css` continua como fallback estático. Abrir diretamente por
`/usr/bin/pear-desktop` não carrega a extensão: nesse caso, novas cores só aparecem
após recarregar a página. Para desativar a camada ao vivo, remova somente
`pear-theme.css` em Opções → Ajustes visuais → Temas; para também retirar a camada
estática já carregada, reabra o app. O adaptador foi validado para Pear 3.12.0;
outra versão usa automaticamente o lançador original até revisão da integração.

O backup inicial das configurações de cores fica em
`~/.config/archblato/theme-backup/before.json`, preservado entre trocas. Se a etapa
de cores falhar, ela tenta restaurar os arquivos alterados e a galeria informa
“Wallpaper aplicado; falha nas cores”. O wallpaper escolhido permanece aplicado.
Esta integração é da galeria do shell; trocar por ferramentas externas não a aciona.

O Fastfetch mantém a arte Aperture e seus módulos; as novas cores aparecem na
próxima execução, não em texto já impresso. O G203 recebe o acento via `ratbagctl`
(mesmo ratbagd do Piper), sem alterar DPI, botões, polling rate ou perfil.
Respiração preserva duração/brilho; ciclo vira cor fixa para acompanhar a paleta.
LED desligado continua desligado. Mouse ausente, ajustes pendentes no Piper ou
falha de confirmação deixam o tema do desktop aplicado e mostram “RGB pendente”.
Resolva no Piper e reaplique o wallpaper para tentar novamente; não há polling
nem sincronização automática ao reconectar o mouse. Não edite no Piper durante
a aplicação: o serviço compartilha ajustes entre clientes, sem transação exclusiva.
O estado inicial conhecido do LED fica em `theme-backup/mouse-before.json`;
campos que ratbagctl não expõe em certos modos são `null`. O ponteiro não é alterado.

Detalhes, arquivos e validações: [Perfil e tema](PERFIL-TEMA-2026-10-18.md).
A foto é uma referência ao arquivo escolhido: mantenha-o no mesmo caminho.
O seletor suspende temporariamente o grab da central e fecha junto com ela,
inclusive ao bloquear a sessão. WebP não é oferecido para perfil porque o Qt
instalado no White não tem esse decoder; wallpapers mantêm seu cache WebP atual.

A central reúne:

- histórico de até 100 avisos, mais recentes primeiro, com horário, imagens e
  ações fornecidas pelo aplicativo;
- remoção individual e limpeza geral;
- não perturbe: silencia os pop-ups, mas continua recebendo o histórico;
- capa, título, artista, álbum quando disponível, play/pause e troca de faixa;
- progresso em minutos/segundos, com busca ao arrastar e soltar;
- volume do player e controles de repetição/aleatório quando suportados.

Controles e música cabem sem scroll, com capa e informações lado a lado. O
histórico usa Anterior/Próximo; avisos longos têm páginas de texto e ações
acessíveis por botões, sem perder o conteúdo. Apenas a galeria permite rolagem.
Na música, clique ou arraste a barra de tempo para buscar; Tab e as setas
também ajustam os sliders.

O histórico e o estado de não perturbe sobrevivem ao hot reload, mas não ao
encerramento do QuickShell/logout: não são gravados em disco. Fechar um pop-up
mantém o aviso no histórico; remover um cartão encerra a notificação no
aplicativo. Notificações marcadas como transitórias não são arquivadas.

O player usa MPRIS e PipeWire, sem autenticação ou dependências do Spotify. Reconhece
Pear/YT Music inclusive quando o nome D-Bus é `chromium.instance…` e a identidade
é `com.github.th-ch.youtube-music`. Havendo vários players, o botão de troca no
cabeçalho permite selecionar outro. Sem players, a seta no cabeçalho abre o Pear.

Na top bar, a cápsula de música acompanha a largura do título com uma transição
curta; nomes longos continuam limitados a 210 px, com reticências. Cliques e
rolagem mantêm os controles existentes.

Os controles dependem das capacidades anunciadas pelo aplicativo. A interface
Chromium do Pear fornece capa, progresso e reprodução, mas anuncia um volume
MPRIS que ignora alterações. Para esse caso, o slider ajusta apenas os fluxos
PipeWire pertencentes ao processo do player e seus filhos, identificados por
D-Bus e /proc; não muda o volume geral nem o de outros aplicativos. A resolução
usa Node.js e busctl. Se não houver fluxo correspondente, o slider é desabilitado.
Repetição/aleatório ficam ocultos quando não são anunciados pelo aplicativo.
Não é necessário alterar sua conta nem reiniciar o Pear.

Para abrir a central por atalho:

```bash
qs ipc --path ~/.config/archblato/quickshell call notifications open
```

## Testes

Verificação consolidada, sem interagir com a sessão pessoal:

```bash
node scripts/verify.cjs
node scripts/verify.cjs --integration
```

O primeiro reúne sintaxe JS/Bash, qmllint, Node e QtTest offscreen. O segundo
acrescenta as três integrações em D-Bus privado e um teste Electron com página
sintética, janela invisível e sessão separada (precisa de display). `--list` mostra os comandos sem
executar; testes `--live` nunca entram nesses modos. Avisos do qmllint permanecem
visíveis. Não há dependências npm nem etapa de build. Comandos individuais:

```bash
node --test tests/*.test.cjs
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
node tests/notification-integration.cjs
node tests/system-integration.cjs
node tests/profile-integration.cjs
```

O teste de notificações inicia um D-Bus privado e um QuickShell sem janelas, validando
recebimento, substituição, histórico, reload, não perturbe e ações reais de
notificações. Requer `qs`, `dbus-run-session`, `busctl` e `gdbus`; não altera o
histórico da sessão nem a reprodução de música.

## Próximas etapas

1. Adicionar OSD nativo para volume e brilho.
2. Adicionar histórico de wallpapers favoritos.

## Temas

`~/.config/archblato/themes/quickshellthemes.sh` gera `Theme.qml` usando o
tema central em `~/.config/archblato/theme.sh`. O fluxo normal continua sendo
`~/.config/archblato/usability/apply.sh`.

## Organização do shell

- `TopBar.qml` compõe os dez módulos `Bar*.qml`, o relógio e o botão Arch.
  Os módulos recebem somente o estado e os eventos de que precisam.
- `NetworkController.qml` compartilha rede, Bluetooth, modo avião e leases de
  busca entre barra, central, quick settings e monitor de notificações.
- `BrightnessController.qml` fornece feedback imediato, debounce de 120 ms e
  apenas um processo `brightnessctl` por vez. A última solicitação prevalece;
  erros voltam à leitura real e são indicados no slider. O mínimo é 1%, evitando
  apagar a tela ao arrastar até o início.
- `PowerController.qml` concentra perfil de energia e desligamento; confirmação
  continua na UI. PipeWire simples permanece direto: não ganhou um wrapper.
- `PanelCoordinator.qml`, por monitor, mantém um painel principal aberto e
  fecha todos no lock. SUPER continua alternando a central em qualquer aba.
- `SessionLockState.qml` espelha o estado nativo em eventos de lock/secure e após
  operações de PAM, com releitura no próximo ciclo do Qt. Evita UI presa em
  "locked" após desbloquear no QuickShell 0.3.2; nunca escreve no backend do lock.
- `ProfileStore.qml` centraliza apenas o perfil pessoal salvo. `ProfilePage.qml`
  mantém o rascunho separado; falhas de gravação não substituem os dados atuais.
- `AnimatedPopup.qml` separa abertura lógica de superfície visível. Ao fechar,
  foco, entrada e buscas são liberados imediatamente; o desenho termina sua
  animação de saída. Lock e substituição por outro painel não esperam a animação.
- `PanelReveal.qml` faz entrada/saída reversíveis por deslocamento, alpha e
  escala sutil nos popups flutuantes; a central usa deslocamento de altura inteira
  recortado pela borda superior. `TabPage.qml` faz a troca horizontal curta entre abas e desabilita
  imediatamente a página de saída. Não há timers de animação em repouso.
- `PanelGeometry.js` preserva o canvas compacto e só o reduz quando falta espaço.
  No White continua 480×480; telas muito pequenas reduzem também texto/controles,
  sem adicionar scroll. Não é um layout universal nem um dashboard gigante.
- `Theme.qml` fornece a paleta e herda `DesignTokens.qml`: medidas, fontes,
  bordas e movimento. O gerador da paleta preserva essa herança.
- `ModuleCard.qml` é somente a moldura visual de um módulo, sem regras de sistema.
  Player, calendário, notificações e wallpapers continuam componentes próprios,
  que poderão compor um dashboard futuro sem trocar seus controllers.
- `SystemStats.qml` lê arquivos com `FileView` assíncrono a cada 2 segundos,
  sem criar processos. Os sensores são os do White: `intel_backlight` e
  `thermal_zone0` (os mesmos selecionados pelo script anterior).
  `scripts/system-stats` fica disponível como diagnóstico, fora do polling.
- QuickToggle aceita Tab, Enter e Espaço, expõe ações acessíveis e indica foco.
  Chevron só aparece em navegação. As abas aceitam setas e Ctrl+Tab;
  Esc fecha calendário/quick settings e cancela a confirmação de desligamento.
- Wallpapers reutilizam a listagem por 2 segundos em reaberturas rápidas.
  O botão Atualizar ignora esse intervalo; aplicação e cache WebP permanecem.

O teste `tests/system-integration.cjs` usa rede/Bluetooth simulados e um
`brightnessctl` falso em um D-Bus privado. Não alterna os rádios nem ajusta o
brilho do White. Exercita debounce, concorrência, erro e leituras reais de procfs.

Detalhes da evolução, arquivos e validações:
[Refatoração inicial](REFACTOR-2026-10-17.md) e
[conclusão de animações e validação](ANIMACOES-2026-10-17.md), seguidas da
[correção pós-lock, encaixe na tela e Perfil](PERFIL-LOCK-2026-10-17.md).

Testes opcionais na sessão desbloqueada (abrem/fecham painéis brevemente):

```bash
node tests/panel-integration.cjs --live
node tests/panel-benchmark.cjs --live
```

O primeiro usa superfícies Wayland reais com rede, brilho e lock falsos. Não
desconecta dispositivos nem bloqueia a sessão. O segundo mede CPU/RSS do processo
atual, incluindo 20 ciclos da central, e restaura sua aba/abertura inicial;
não representa benchmark comparativo nem medição de energia.

`tests/wayland-key.c` é uma sonda manual de teclado virtual para validar SUPER,
Esc e navegação de abas no compositor. Não faz parte do shell nem dos testes
automáticos. Compilação usando as bibliotecas já presentes no White:

```bash
cc -Wall -Wextra tests/wayland-key.c -o /tmp/archblato-key $(pkg-config --cflags --libs wayland-client xkbcommon)
```

Execute `/tmp/archblato-key super` somente quando quiser acionar o atalho real.
