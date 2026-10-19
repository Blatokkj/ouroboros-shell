# Música compacta e tema do Pear — 2026-10-19

## Entrega

- `BarMedia.qml`: largura pelo tamanho real do texto, ícones e margens;
  transição curta e limite de largura preservado. Texto literal, fallback de
  identidade e controles existentes mantidos.
- `DesignTokens.qml`: limite `barMediaMaxWidth` de 210 px.
- `scripts/pear-theme.cjs`: gerador de CSS apenas de cores, usando a paleta
  escura atual e as variáveis do tema pessoal já instalado.
- `scripts/wallpaper-theme.cjs`: inclui o CSS no fluxo existente de aplicação,
  backup e rollback. Sem polling ou reinício automático do player.
- `pear-theme.css`: camada gerada para o wallpaper atual, sem alterar layout.
- `tests/tst_BarMedia.qml`, `tests/pear-theme.test.cjs` e
  `tests/wallpaper-theme.test.cjs`: regressões de largura/controles e geração,
  validação e rollback das cores.
- `README.md`, `docs/architecture.md`, `docs/design.md` e `docs/quality.md`:
  contratos e limites atualizados; este arquivo registra a entrega.

## Ativação no setup

Com autorização explícita, o Pear foi fechado e reaberto uma vez. Alteração
externa: somente `options.themes` em `~/.config/YouTube Music/config.json`,
adicionando o CSS do Archblato após o CSS pessoal. Comparação por hash confirmou
os outros campos intactos; o tema anterior não foi editado.
Reabertura confirmada por processo principal e retorno do player MPRIS.
Não houve reinício do QuickShell nem alteração de conta, MPRIS ou PipeWire.

Sem Git disponível. Backup privado dos fontes afetados e da lista anterior de
temas: `/tmp/archblato-media-pear-5I8Mnq/` (temporário; não contém cópia da conta).

## Verificação

- `node scripts/verify.cjs --integration`: passou após a implementação e
  novamente após a correção de especificidade dos seletores CSS.
- Sintaxe, qmllint, testes Node, 49 casos QtTest e três integrações isoladas
  (system, profile, notification) passaram. Avisos nativos do qmllint permanecem.
- Revisão independente somente leitura identificou conflito do CSS pessoal
  na barra de progresso; corrigido também para foco/hover e revisado novamente.
- Configuração do Pear revalidada após reabertura: ambos os temas registrados.
- Não foi feita certificação visual de todas as telas do YT Music nem teste
  de rádios/hardware. Registro/MPRIS não comprovam aparência renderizada.

## Limitação original (resolvida pelo adaptador abaixo)

O Pear 3.12 lê os arquivos CSS ao carregar a página, mas não observa alterações
no disco. Novos wallpapers geram novas cores; para vê-las no Pear é necessário
recarregar a página ou reabrir o app. Não se interrompe música automaticamente.
Essa limitação foi conferida no código oficial da versão instalada:
[inicialização](https://github.com/pear-devs/pear-desktop/blob/v3.12.0/src/index.ts)
e [injeção CSS](https://github.com/pear-devs/pear-desktop/blob/v3.12.0/src/plugins/utils/main/css.ts).

Na primeira entrega não havia atualização em tempo real. A continuação solicitada
pelo usuário implementou o adaptador abaixo; não é mais uma pendência nesta versão.

## Continuação: cores em tempo real

Implementado e ativado em 2026-10-19:

- `scripts/pear-live-theme.cjs`: dois watchers de diretório, debounce de 80 ms,
  paleta validada e CSS apenas para a origem exata do YT Music. Sem polling,
  processo adicional residente, servidor, depuração remota, recarga da página
  ou execução de JavaScript no renderer pessoal.
- `scripts/pear-theme.cjs`: escopo adicional para a camada ao vivo vencer o CSS
  estático, independentemente da ordem de inserção. Mantém só cores.
- `scripts/pear-desktop`, `integrations/pear/main.cjs` e `package.json`: entrada
  pessoal que carrega o ASAR instalado sem modificá-lo, preservando identidade,
  userData, appPath, plugins e flags. Em outra versão do pacote, o script abre
  o Pear original (sem cores ao vivo) até revisão; conta/reprodução não dependem
  de manter uma versão antiga instalada.
- `MediaController.qml`: abertura sem player usa o lançador pessoal; raise,
  volume, seek e MPRIS/PipeWire não foram alterados.
- `scripts/wallpaper-theme.cjs`: comentário atualizado; segue gerando CSS
  estático e publicando a paleta atomicamente, sem reiniciar o player.
- `tests/pear-live-theme.test.cjs`: atomicidade, concorrência, duplicatas,
  erro/recuperação, symlink, origens, navegação abortada, opt-out e encerramento.
- `tests/pear-launcher.test.cjs`: flags/argumentos em executáveis falsos.
- `tests/pear-theme-integration.cjs`: Electron real com página e áudio sintéticos
  numa sessão isolada; verifica cor computada, prioridade, remoção, erro/recovery
  e avanço do áudio sem reload. Não acessa a conta nem a rede do YT Music.
- `scripts/verify.cjs` e `tests/verify.test.cjs`: incluem a sintaxe do adaptador
  e o novo teste renderizado somente em `--integration`.
- `README.md`, `docs/architecture.md`, `docs/quality.md`, `docs/onboarding.md`,
  `docs/setup.md` e este relatório: funcionamento, recuperação e limites atualizados.

Alteração externa autorizada: criado
`~/.local/share/applications/com.github.th-ch.youtube-music.desktop`, apontando
para o lançador pessoal. Nenhum atalho anterior existia nesse caminho. O arquivo
de sistema, o pacote e a configuração da conta não foram editados nesta continuação.
O Pear estava fechado no momento da ativação; foi aberto pelo adaptador. Processo
principal, MPRIS e estado Playing confirmados; ambos os temas continuam registrados.
`desktop-file-validate` passou. O QuickShell não foi reiniciado.

Backup privado adicional dos fontes afetados:
`/tmp/archblato-pear-live-ptINKP/` (temporário; sem dados da conta).

### Evidência final

`node scripts/verify.cjs --integration` passou: sintaxe, qmllint, Node, 49
verificações QtTest e quatro integrações isoladas. Testes pontuais do lançador,
watcher, gerador e verificador também passaram após os últimos ajustes.
Revisão independente somente leitura confirmou as correções de navegação
abortada e remoções pendentes, sem novos achados bloqueantes.

O teste renderizado encontrou remoção ineficaz com CSS de origem `user` no
Electron instalado. A implementação final usa origem `author` com especificidade
maior; remoção e retorno ao CSS anterior foram testados. O relógio de áudio do
teste é aguardado por condição, não por um instante presumido entre frames.
Avisos nativos de qmllint/serviços do D-Bus privado permanecem visíveis.

### Limites e recuperação

- A renderização foi validada na fixture Electron; não foi feita inspeção de
  todas as páginas da conta do usuário nem troca do wallpaper pessoal para testar.
- Abrir diretamente `/usr/bin/pear-desktop` conserva o fallback estático e requer
  recarga para novas cores. Launcher e central usam o adaptador automaticamente.
- Remover `pear-theme.css` da lista de temas desliga a camada ao vivo; reabrir
  também retira o CSS estático já carregado. Para voltar ao lançamento original,
  use `/usr/bin/pear-desktop`; o atalho local pode ter seu Exec revertido para ele.
- Não há implementação pendente do escopo desta continuação. Rever compatibilidade
  após atualizar o Pear e conferir visualmente outras telas são acompanhamentos
  opcionais, não alterações automáticas do pacote.
