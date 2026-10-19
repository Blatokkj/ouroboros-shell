# Perfil no lock e cores do wallpaper — 2026-10-18

## Implementação

- `shell.qml`, `SessionLock.qml`, `LockScreenView.qml`: o mesmo ProfileStore
  fornece nome/foto à apresentação do lock. A imagem é carregada em tamanho
  limitado; indisponível mostra inicial, sem foto usa AccountsService. PAM,
  WlSessionLock, usuário de autenticação e IPC de lock permanecem inalterados.
- `ProfilePage.qml`: orientação de que nome/foto salvos também aparecem no lock.
  Não muda conta Linux, hostname ou imagem global do AccountsService.
- `DesignTokens.qml`, `Theme.qml`, `WallpaperTheme.qml`: paleta observável por
  JSON; valida todas as cores, mantém estado anterior em dados inválidos e volta
  ao fallback ao remover o arquivo. Sem polling ou reload QML a cada troca.
- `scripts/wallpaper-palette.cjs`: ImageMagick existente reduz a imagem para
  amostragem 64×64. Cor predominante gera fundos escuros, acento e texto legíveis.
  Imagens acromáticas usam roxo. Limite de entrada 64 MiB e timeout de 15 segundos.
- `scripts/wallpaper-theme.cjs`: atualiza somente cores dos alvos pessoais abaixo;
  valida estrutura antes de escrever, preserva opções não relacionadas, mantém
  backup inicial e tenta rollback se aplicação/reload falhar.
- `scripts/wallpapers`, `WallpaperPicker.qml`: aplicação serializada entre
  monitores, estado “wallpaper e cores” e distinção de falha parcial. Galeria,
  WebP, cache de previews e hyprpaper continuam existentes.
- `tests-profile.qml`, `tests/profile-integration.cjs`, `tests/fixtures/avatar.svg`:
  foto sintética carregada na apresentação real do lock, persistência após
  reinício e troca de JSON sem recriar o root QML. Não cria lock real/PAM.
- `tests/wallpaper-theme.test.cjs`: extração, contraste das amostras, preservação,
  idempotência, rollback, links, temporários preexistentes e aplicação com fake.
- `README.md`, `docs/architecture.md`, `docs/design.md`, `docs/quality.md`:
  contratos e limites atualizados.

## Configuração fora desta pasta

O gerador `~/.config/archblato/themes/quickshellthemes.sh` foi ajustado para manter
os bindings dinâmicos. Cópia anterior:
`/tmp/archblato-profile-theme-5gFtju/quickshellthemes.sh.before`.

Alvos gerados ao selecionar wallpaper:

- `~/.config/archblato/theme.sh`;
- `~/.config/hypr/theme.lua` e `hyprtoolkit.conf`;
- `~/.config/alacritty/theme.toml` e `alacritty.toml`;
- `~/.config/gtk-{3.0,4.0}/gtk.css` e `archblato-colors.css`;
- `wallpaper-colors.json` nesta pasta.

No White, o `gtk-4.0/gtk.css` originalmente é um link para Orchis. Ele vira um
arquivo local que importa o mesmo CSS de `/usr/share/themes/Orchis-Dark-Compact`,
seguido das cores locais. Nada é escrito no tema instalado. Apenas esse link
conhecido é aceito; outros links, inclusive quebrados, são rejeitados.

## Recuperação e limites

`~/.config/archblato/theme-backup/before.json` guarda o estado anterior à primeira
aplicação, incluindo texto/permissões ou destino do link GTK4. Não é sobrescrito
nas próximas trocas. Não publicá-lo automaticamente: é configuração pessoal.
Restaurar manualmente somente os alvos listados nesse backup, com a sessão
desbloqueada; valor `null` identifica arquivo gerado que antes não existia.

Não há transação global: cada arquivo é substituído atomicamente e o reload do
Hyprland acontece ao final. Se falhar, o script tenta restaurar as cores, mas o
wallpaper já aplicado permanece. SIGKILL/queda do sistema pode interromper esse
rollback; o backup permite recuperação. Não executar o antigo apply.sh para
validar esta integração, pois ele reinicia hyprpaper e ressincroniza Waypaper.

A paleta alcança shell/lock, bordas Hyprland, Hyprtoolkit, Alacritty e GTK 3/4.
GTK/launcher abertos podem exigir reabertura. Não impõe cores a sites, temas
internos de Electron/YT Music ou apps Qt sem integração. Ferramentas externas
de wallpaper não disparam a paleta; a integração está na galeria do shell.
Não altera geometria/animações, fontes nem autenticação, e não instala dependências.

## Validação e pendências

- Extração e oito testes de tema em fixtures: passaram.
- Integração isolada de perfil/foto/cores: passou.
- Parse CSS GTK 3/4: sem erro de CSS. A validação final dos arquivos aplicados,
  com base Orchis e display inicializado no GTK4, passou sem aqueles avisos de ícones.
- Revisão independente somente leitura: corrigidas proteção do temporário
  preexistente e detecção de symlink quebrado; teste de ausência de reload foi
  fortalecido com identificador por instância QML.
- Primeira aplicação real foi interrompida antes das escritas devido ao link
  Orchis; adaptação específica foi adicionada e testada com rollback.
- `node scripts/verify.cjs --integration`: passou após as correções — 48 testes
  Node, 44 casos QtTest (incluindo init/cleanup), três integrações isoladas,
  sintaxe JS/Bash e qmllint. Avisos nativos preexistentes do qmllint permanecem;
  exit 0 não significa ausência de avisos. Uma execução intermediária apontou
  o link deste relatório antes de sua criação; corrigido.
- `bash -n ~/.config/archblato/themes/quickshellthemes.sh`: passou.
- Aplicação real da paleta do wallpaper já selecionado: passou. Backup criado,
  `hyprctl configerrors` vazio, sessão desbloqueada e sem erros de carregamento
  nos últimos 40 registros consultados. Nenhuma troca de wallpaper foi forçada.
- Segunda revisão independente, incluindo a exceção Orchis: sem novos achados.
- Não foram executados unlock PAM, toggles de rádio ou testes live de painéis.

Não há etapa de implementação pendente nesta solicitação. A validação perceptiva
do lock durante autenticação e da aparência em todos os apps não foi automatizada.
Os harnesses encerram seus próprios processos; a instância pessoal não foi reiniciada.

Opcionais futuros, não implementados: seletor manual para fixar uma cor em vez
da extração e botão de restaurar paleta pelo backup. Não são requisitos deste fluxo.

## Extensão: Fastfetch e RGB físico do G203

Pedido posterior: sincronizar Fastfetch e o mouse físico controlado pelo Piper,
explicitamente **não** o ponteiro. Nenhum arquivo de tema de cursor foi alterado.

Arquivos desta extensão:

- `scripts/mouse-theme.cjs` (novo): descoberta por nome/modelo, perfil único/LED 0,
  proteção de ajustes pendentes, escrita única e confirmação limitada via ratbagctl.
- `scripts/wallpaper-theme.cjs`: cores de logo/display do Fastfetch, preservando
  JSONC, arte Aperture e módulos; backup incremental; RGB após aplicação desktop.
- `scripts/wallpapers` e `WallpaperPicker.qml`: saída 3 para RGB pendente sem
  classificar o desktop como falha ou desfazer o tema.
- `tests/mouse-theme.test.cjs` (novo), `tests/wallpaper-theme.test.cjs`:
  formatos reais dos modos, falhas, backup, preservação e CLI com mouse falso.
- `README.md`, `docs/architecture.md`, `docs/quality.md` e este relatório.
- Fora do projeto: `~/.config/fastfetch/config.jsonc` e o estado RGB no ratbagd.

Backup privado dos arquivos de código desta extensão e Fastfetch anterior:
`/tmp/archblato-rgb-fastfetch-Z13MkX`. Recuperação durável: configuração original
do Fastfetch adicionada a `~/.config/archblato/theme-backup/before.json`, sem
substituir entradas antigas; estado inicial do LED em `mouse-before.json`.

Só a cor é alterada em modo respiração ou fixo. Ciclo precisa virar cor fixa;
desligado é respeitado e reportado como pendente. DPI, mapeamentos, polling rate,
brilho e duração não são escritos. A checagem de dirty é preventiva, não lock
global do ratbagd: não editar simultaneamente no Piper. Falhas do mouse não
revertem o tema; não há daemon/reconexão automática, basta reaplicar na galeria.

Referências consultadas: [Piper/ratbagd](https://github.com/libratbag/piper#piper),
[configuração Fastfetch](https://github.com/fastfetch-cli/fastfetch/wiki/Configuration)
e código do ratbagctl 0.18 instalado. Nenhuma dependência instalada.

Validação: 14 testes direcionados passaram antes do escurecimento adicional;
revisão independente encontrou campos condicionais em ratbagctl e a correção foi
coberta nos fakes. Aplicação real RGB/Fastfetch terminou com exit 0, incluindo
confirmação limitada do LED. Uma segunda sincronização leu o wallpaper então atual
dentro de flock, corrigindo a paleta aplicada inicialmente com a seleção anterior.
Fastfetch real renderizou o logo com a paleta gravada (sem rodar módulos de comandos).
Nenhuma alteração de ponteiro ou rádio foi realizada.

### Escurecimento solicitado depois

`scripts/wallpaper-palette.cjs` agora usa luminosidade dominante como referência
para acentos em vez de clareamento fixo; fundos também têm limites relativos à
luminância média da imagem. Texto/acentos mantêm piso de contraste, portanto não
se promete que todo texto será mais escuro que um wallpaper quase preto.
`tests/wallpaper-palette.test.cjs` acrescenta três casos puros de brilho/contraste.
`README.md` e `docs/design.md` documentam o comportamento.

Testes locais após essa alteração: 3 de paleta, 5 de mouse e 7 casos de configuração
passaram. Os dois casos que invocam ImageMagick foram impedidos pelo sandbox
(`spawnSync magick EPERM`); não foram ocultados/desativados. Sintaxe e qmllint
passaram com avisos nativos existentes. QtTest separado: 44 casos passaram;
os seis testes do verificador/documentação também passaram.
Revisão final somente leitura não encontrou novo problema bloqueante.

Pendências explícitas: a variante mais escura ainda não foi aplicada na sessão;
a comparação adicional de DPI/botões antes/depois não pôde ser concluída porque
o mecanismo de aprovação recusou a chamada por limite de uso do revisor. Nenhuma
tentativa de contornar a restrição foi feita. A execução completa com integrações
precisa ser repetida quando a aprovação estiver disponível; não atribuir o resultado
histórico anterior a este estado final. O script atualizado já será usado na
próxima aplicação normal pela galeria. Não há serviço de tarefa em background.
