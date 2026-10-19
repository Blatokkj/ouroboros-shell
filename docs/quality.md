# Qualidade e evidência

## Comandos canônicos

```bash
node scripts/verify.cjs
node scripts/verify.cjs --integration
node scripts/verify.cjs --list
```

O comando padrão faz, nesta ordem: sintaxe dos JS/CJS, Bash com `-n`,
qmllint da raiz e dos testes, testes Node e QtTest offscreen.
Usa o diretório do próprio script, não depende do diretório corrente.
Não usa shell para montar comandos, preserva argumentos e para na primeira falha.
Ferramenta ausente ou processo interrompido é erro, não teste pulado.
`--list` mostra o plano sem executar; opções desconhecidas falham.

`--integration` acrescenta os harnesses system, profile, notification e pear-theme,
sequencialmente. Criam processos próprios, D-Bus privado e dados temporários;
não usam o barramento pessoal para emitir avisos ou mudar o perfil.
O último usa o Electron instalado, janela invisível no display disponível e
página HTTPS interceptada localmente, sem acessar o YT Music ou a conta real.
Precisam de permissão para sockets locais/display. Não altere o isolamento para
contornar uma negativa do sandbox.

Testes pontuais continuam disponíveis no README.
[verify.test.cjs](../tests/verify.test.cjs) testa seleção, opt-in, propagação de
erro, interrupção e argumentos; não substitui os testes de produto.

## O que cada camada prova

| Camada | Evidência | Não prova |
|---|---|---|
| Sintaxe + qmllint | Parsing e análise estática nativa | Ausência de bugs ou avisos |
| Node | Helpers puros, contratos, SUPER simulado, wallpaper em fixtures | Teclado/compositor reais |
| QtTest offscreen | Foco, teclado, sliders, tabs, animações e estados de lock simulados | PAM real, aparência percebida, segundo monitor |
| Integração system | Debounce, concorrência/erro, rede/Bluetooth falsos, leitura procfs real | Rádio ou brightnessctl real |
| Integração profile | Validação, escrita/reinício, nome/foto chegando à apresentação do lock e JSON de cores com criação/substituição/remoção | Edição do perfil pessoal ou autenticação PAM |
| Integração notification | Protocolo real no D-Bus privado, reload, actions, DND, limites | Todos os aplicativos na sessão pessoal |
| Live opt-in | Superfícies Wayland e interação real do cenário | Certificação de segurança/performance |

`wallpaper-theme.test.cjs` cobre extração com ImageMagick, contraste das amostras,
preservação de configurações, idempotência, rollback, rejeição de symlinks e o
comando completo de wallpaper com `hyprctl` falso. `ARCHBLATO_CONFIG_ROOT` e
`ARCHBLATO_WALLPAPER_DIR` apontam exclusivamente para fixtures nesses testes.
O fluxo de produção usa os caminhos pessoais existentes; não há instalação extra.

`pear-theme.test.cjs` cobre cores, validação e seletores sobre o CSS pessoal;
o teste de wallpaper cobre geração e rollback desse arquivo. Não comprova a
renderização de todas as telas do YT Music. `tst_BarMedia.qml` cobre títulos
curtos/longos, fallback de identidade, texto literal, cliques e ausência de player.
`pear-live-theme.test.cjs` cobre renames atômicos, concorrência, navegação abortada,
remoções com erro, opt-out, filtros de origem e encerramento dos watchers.
`pear-theme-integration.cjs` verifica CSS computado no Electron, precedência,
remoção, recuperação de JSON inválido e relógio de áudio contínuo sem reload.
`pear-launcher.test.cjs` usa executáveis falsos para testar argumentos e flags,
sem abrir o Pear real.

`mouse-theme.test.cjs` usa saída simulada fiel ao ratbagctl 0.18 (campos diferentes
em off/on/cycle/breathing), verifica recusa de ajustes pendentes, nenhuma escrita
redundante, preservação dos efeitos e confirmação assíncrona. A integração do
wallpaper injeta ratbagctl falso em PATH tanto para mouse ausente quanto presente.
Não há acesso ao RGB real em `verify`, mesmo executando fora do sandbox.

O Qt6 instalado emite avisos preexistentes de metadados de tipos QuickShell,
imports não usados e IDs nos harnesses. A saída não é filtrada; exit 0 do
qmllint não significa zero avisos. Não foram adicionadas supressões ou limiares.
Não há compilação TypeScript, build web, npm audit ou testes SQL aplicáveis.
Não há dependências npm ou lockfile; `integrations/pear/package.json` contém
somente metadados de inicialização do Electron. Atualizações do sistema não
fazem parte deste setup.

A referência de 350 linhas do toolkit é diagnóstico, não uma regra nova de corte.
ControlCenter e QuickSettingsPopup excedem essa referência; medir responsabilidade
e risco antes de dividir. Não copiar regras ESLint de Next/logger/Drizzle para QML.

## Operação real, somente quando autorizada

```bash
node tests/panel-integration.cjs --live
node tests/panel-benchmark.cjs --live
```

Eles interagem com a sessão desbloqueada; não entram no verificador padrão nem
no modo integration. PAM exige ação normal do próprio usuário, nunca coleta de
senha pelo agente. Não alternar rádios reais. Compare benchmarks no mesmo cenário,
sem atribuir economia de energia a um único valor de CPU/RSS.

## Revisão e segurança reutilizáveis

Para mudanças não triviais: delimitar arquivos/snapshot, ler callers e testes,
revisar regressões, dados e efeitos externos; validar achados com cenário concreto.
Sem Git, usar snapshots privados e hashes em vez de inventar base/head.
Uma revisão independente deve ser somente leitura; correções ficam com o autor.
O setup não realizou auditoria completa do produto nem de todas as dependências.

Prompt de segurança adotado por referência imutável:
[Prompt 13, revisão de66fe3](https://github.com/soumatheusgomes/vibe-coding-toolkit/blob/de66fe371a49f5a4d3b521759e5c401f390b6424/docs/prompts/13-security-review.md#prompt).

Invocação: peça ao agente para ler e executar somente o bloco Prompt dessa revisão,
em modo repository sobre a configuração atual, sem corrigir automaticamente.
Para diff, forneça revisões reais e escolha comparação endpoint ou merge-base;
sem histórico, declare snapshot e ausência de histórico.
Preserve cliente/autenticação, use dados sintéticos, não sonde serviços pessoais,
não envie código ou manifests a serviços de auditoria. Relatório redigido deve ir
para diretório privado fora do projeto; não publique vulnerabilidades ou segredos.
Skill differential-review é opcional e não está carregada; revisão manual é o
fallback explícito. Atualizar a referência exige ler o diff do prompt e seus limites.

## Avaliação das instruções

A referência de avaliação é o
[guia 07](https://github.com/soumatheusgomes/vibe-coding-toolkit/blob/de66fe371a49f5a4d3b521759e5c401f390b6424/docs/07-harness-evaluation.md)
e o
[prompt 14](https://github.com/soumatheusgomes/vibe-coding-toolkit/blob/de66fe371a49f5a4d3b521759e5c401f390b6424/docs/prompts/14-harness-evaluation.md).
Selecionar casos úteis ao setup: encontrar instruções/comandos, recuperar uma
decisão e realizar revisão somente leitura. Contexto novo de subagente não
equivale a reiniciar o cliente. Resultados, exclusões e pendências ficam em
[setup](setup.md). Não afirmar que instalação equivale a execução validada.

Atualize este documento quando os comandos, isolamento ou critérios mudarem.
