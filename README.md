# Archblato QuickShell

Barra principal do Archblato, implementada em QuickShell. Ela cobre:

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

## Execução

O autostart do Archblato inicia esta configuração com:

```bash
qs --daemonize --no-duplicate --path ~/.config/archblato/quickshell
```

Durante o desenvolvimento, rode em primeiro plano para acompanhar os logs:

```bash
qs --path ~/.config/archblato/quickshell
```

O QuickShell recarrega automaticamente quando os arquivos QML mudam. Para encerrar apenas esta configuração:

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

A Central de Controle tem quatro abas: **Controles**, **Música**,
**Notificações** e **Wallpapers**, com indicador animado e tamanho fixo compacto
de até 480×480 (adaptado a telas menores). O Arch abre Controles; a música da
barra abre Música; clicar no corpo de um pop-up abre Notificações. `Esc` ou o ×
fecha o painel; clicar novamente no atalho da aba aberta também o fecha.
A galeria de wallpapers agora é uma aba, sem janela separada, e permanece
aberta após aplicar uma imagem. A central reúne:

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

```bash
node tests/connection-events.test.cjs
node tests/notification-state.test.cjs
node tests/desktop-ui.test.cjs
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests
node tests/notification-integration.cjs
```

O último comando inicia um D-Bus privado e um QuickShell sem janelas, validando
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
