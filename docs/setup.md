# Setup enxuto do Archblato — 2026-10-18

## Fonte, decisão e limites

Toolkit consultado em cópia temporária, revisão imutável
`de66fe371a49f5a4d3b521759e5c401f390b6424`:
[fonte](https://github.com/soumatheusgomes/vibe-coding-toolkit/tree/de66fe371a49f5a4d3b521759e5c401f390b6424).
Guias/templates usados são dessa mesma revisão; não foi copiado o toolkit inteiro.

O usuário aprovou o desenho enxuto após brainstorming: instruções, documentação,
verificação segura e decisão sobre todo o catálogo. Trabalho delimitado de tooling,
sem novo subsistema de runtime. Superpowers não estava disponível; protocolo de
entendimento/aprovação executado manualmente, sem afirmar ativação da skill.

Ordem de entrega: inventário/baseline e backup → documentos e runner com testes →
validação integrada → revisão independente e verificação de preservação.
Nenhuma etapa autoriza alteração global, provider/modelo principal, credenciais,
Git hooks, publicação, serviços pagos ou migração de stack.

## Estado observado

| Item | Evidência |
|---|---|
| Runtime | QuickShell 0.3.2; Qt/qmllint 6.12.0; Node v26.11.1 |
| Cliente | Codex no IDE; executável local codex-cli 0.154.0-alpha.6.2 |
| Projeto | QML/JS + scripts Bash/CJS; dependências do Arch, sem npm install/lockfile; metadados Electron em integrations/pear/package.json |
| Git | git status não reconhece repositório nesta pasta; presença de .git não prova histórico utilizável |
| Instruções anteriores | Nenhum AGENTS.md/AGENTS.override.md de projeto encontrado no inventário |
| Configurações locais | .agents e .codex sem arquivos encontrados; não sobrescritas |
| Ferramentas | qs, Node, QtTest/qmllint, pipx, D-Bus e ImageMagick presentes |
| Ferramentas ausentes no PATH | rtk, graphify, uv/uvx e claude |
| Context7 | Nenhuma ferramenta resolve-library/query-docs exposta nesta sessão |
| Skills úteis já carregadas | openai-docs; skill-installer/skill-creator disponíveis sob demanda, não duplicadas |

Não inspecionar auth.json, tokens ou conteúdo de contas para provar autenticação.
Ferramentas externas disponíveis na sessão não foram usadas para abrir contas,
ler arquivos pessoais remotos ou conectar novos serviços.

## Cobertura de todo o catálogo

Decisões abaixo são a adaptação ao desenho aprovado, não alegação de instalação
integral de plugins. “Equivalente” indica recurso do projeto/cliente reutilizado.
Escopo de toda nova escrita: somente esta configuração; nenhum serviço residente.

| Guia/componente | Necessidade e estado atual | Ação/escopo | Dependência, risco e critério de validação |
|---|---|---|---|
| 01 Superpowers | Processo útil; skill ausente | Equivalente manual + AGENTS local; plugin não instalado | Integração nativa futura depende de instalação/trust do cliente; validar descoberta e uma tarefa, não só arquivos |
| 02 Subagentes | Revisão independente útil; ferramenta nativa disponível | Reutilizar sob demanda, sem roster/config global | Brief com arquivos/permissões; aceitar somente achados verificáveis e conferir diff |
| 03 RTK | Binário ausente; sem lacuna que exija interceptor neste setup | Não adotar no setup enxuto; saída normal preservada | Futuro opt-in exige origem oficial, trust e prova de execução única; não criar wrapper substituto |
| 04 Ponytail full | Redução de escopo já exigida pelo usuário; plugin ausente | Equivalente em AGENTS: menor solução completa, sem retirar requisitos | Revisar diff e ausência de deps/abstrações; não alegar hook/plugin ativo |
| 05 Caveman | Conversa concisa em português; skill ausente | Equivalente de comunicação em AGENTS | Preservar clareza, números/limites; sem proxy ou alegações de economia de tokens |
| 06 ESLint/Biome e quality gates | Núcleo QML, helpers JS/CJS sem stack npm | Equivalente nativo: qmllint, node --check, bash -n, testes | Exit codes e avisos preservados; regras web/logger/ORM e typed lint não se aplicam |
| 07 Graphify | Ausente; árvore pequena, relações QML já mapeadas | Não adotar: mapa de arquitetura e busca direta atendem | Não há grafo gerado/consultado; reconsiderar se navegação justificar dependência/cobertura QML |
| 08 Obsidian | Nenhum vault solicitado | Inaplicável; não criar vault/MCP/export | Sem necessidade/destino autorizado |
| 09 Memória em camadas | README/relatórios presentes; faltava índice | Reutilizar docs e AGENTS; sem MEMORY concorrente | Fonte/data/invalidação nos documentos, leitura sob demanda |
| 10 Hooks | Nenhum hook necessário | Não adotar; comandos explícitos | Não adicionar interceptores, pre-commit/pre-push ou permissões amplas |
| 11 agent-browser | UI nativa, não DOM | Inaplicável; QtTest e Wayland são o equivalente adequado | Nunca usar sessão pessoal do browser/Pear para testar o harness |
| 12 Context7 | Não disponível nesta sessão | Fallback oficial/documentação da versão e ajuda local | Consulta Context7 não validada; eventual adoção requer descoberta e consulta real sem dados privados |
| 13 Anthropic artifact skills | Sem entrega Office/HTML/MCP custom | Inaplicável; skill-creator existente basta se houver tarefa futura | Não instalar coleções duplicadas nem criar skill para esta tarefa isolada |
| 14 Chrome DevTools MCP | Sem frontend Chrome do shell | Inaplicável; logs QS e testes nativos | Não abrir debugging do Pear ou acessar conta do usuário |
| 15 Codex | Cliente já funcional | AGENTS local; CLAUDE como ponte documental, sem instalar cliente | Oficial AGENTS consultado; nova sessão do IDE ainda precisa confirmar descoberta automática |
| 16 Vercel React/composition/transitions/mobile | Nenhuma dessas stacks | Inaplicável | Não instalar React/Expo nem converter animações QML para web |
| 16 Vercel optimize/deploy/CLI | Sem deploy Vercel | Inaplicável | Não criar conta/token/publicação |
| 16 web-design/writing-guidelines | UI QML e docs pessoais | Reutilizar critérios nativos e revisão de docs, sem coleção web | Conferir teclado/foco/link/clareza; não alegar revisão DOM |
| 16 find-skills | Descoberta já disponível pelo catálogo do cliente | Equivalente: catálogo e skill-installer sob demanda | Não instalar CLI npm apenas para listar skills |
| 17 next-dev-loop / next-bundle-optimizer | Sem Next/Turbopack/bundle | Inaplicável | Não atualizar framework nem abrir servidor HTTP |
| 18 PostgreSQL | Sem banco SQL | Inaplicável | Não introduzir Supabase/Drizzle/migrações |
| 19 gh-fix-ci | Sem CI/PR identificados neste snapshot | Inaplicável nesta entrega | Reavaliar quando houver repo/PR/check autorizado; não criar CI só para preencher catálogo |
| 20 differential-review | Revisão pertinente; skill/histórico ausentes | Equivalente manual e Prompt 13 versionado em quality | Revisão read-only sobre arquivos explícitos; relatórios sensíveis privados; sem auditoria total implícita |
| 21 shadcn | Design system QML já existente | Inaplicável | Preservar Theme/DesignTokens; não adotar UI web |
| 22 Sentry MCP | Nenhum serviço/org/projeto escolhido | Inaplicável | Logs locais bastam; não instalar SDK nem conectar conta |
| aia-harness | Estrutura local simples já atendida | Não adotar: duplicaria docs/processos | Sem gerador de agentes/hooks ou instalação de outro cliente |
| Plugins oficiais extras | Sem lacuna concreta para commit/review/hookify/feature-dev/ui-ux-pro-max/claude-code-setup/claude-md-management | Não adotar; recursos nativos e docs | Reavaliar por necessidade; disponibilidade não autoriza instalar/publicar |
| Harness evaluation | Novas instruções/runner precisam prova | Testes do runner, links e recuperação de contexto por revisão | Registrar o que foi observado; não confundir subagente com reinício do IDE |

Não foram instalados plugins, skills, MCPs, CLIs ou dependências novos.
Não há integração “configurada mas secreta”: o que não foi instalado permanece
explicitamente ausente/não adotado. A skill OpenAI Docs orientou a checagem do
formato do AGENTS e a distinção entre arquivo presente e carregamento em nova sessão.

## Documentação e memória

Os nove destinos do manifest foram atendidos: README preservado e acrescido de
índice; PRODUCT, AGENTS, CLAUDE, architecture, design, onboarding, quality e setup
específicos deste shell. Relatórios REFACTOR/ANIMACOES/PERFIL-LOCK preservados como
histórico. Nenhum arquivo foi movido ou eliminado.

AGENTS é o índice curto; documentos detalhados são lidos sob demanda. No Codex,
a cadeia é carregada no início da sessão; sem raiz Git reconhecida, iniciar na
pasta da configuração. A ponte CLAUDE importa AGENTS, mas não prova cliente instalado.
[Documentação oficial consultada](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

Fonte de regras duráveis: decisões explícitas do usuário, arquivos e testes.
architecture/design registram última verificação e gatilho de invalidação.
Mudanças nesses contratos exigem rechecagem; relatórios antigos não prevalecem.
Handoffs temporários devem ficar no registro da tarefa em andamento, com objetivo,
evidência, pendências, bloqueios, recursos próprios e próximo passo. Não criar
memória externa para guardar este setup.

## Verificação e revisão

Baseline de 2026-10-18, antes das alterações:
9 arquivos Node passaram; QtTest 44/44; qmllint da raiz exit 0 com avisos existentes.
Integrações system/profile/notification passaram após autorização para sockets.
A tentativa inicial em sandbox falhou por bind de D-Bus negado, não por regressão.

Novo teste do runner reproduziu módulo ausente antes da implementação.
Após implementação, cinco casos passaram; depois foi acrescentada a verificação
dos documentos/links (seis casos do runner/documentação ao todo).
O teste de exclusão foi corrigido para
distinguir parsing seguro de um script de sua execução; nenhuma proteção removida.
Resultados finais:

| Verificação | Resultado observado |
|---|---|
| node scripts/verify.cjs --integration | PASS: sintaxe JS/Bash, qmllint, 40 testes Node em 10 arquivos, 44 verificações QtTest e três integrações |
| node scripts/verify.cjs, repetição sem elevação | PASS; somente as camadas padrão; sem abrir painel ou executar live |
| node scripts/verify.cjs --live | Exit 1, opção desconhecida; nenhum teste executado |
| --list a partir da raiz e de /tmp | Exit 0; plano ligado à pasta do script, sem execução |
| Documentos/links e ponte CLAUDE | PASS nos testes; links externos não fazem parte do verificador |
| Preservação | SHA-256 dos arquivos originais comparados: só README alterado; runtime e testes antigos idênticos |
| Revisão independente | Sem achados substanciados em runner, testes, docs e diff do README; não equivale a auditoria completa |

O qmllint manteve avisos anteriores, sem supressão. A execução em sandbox pode
apresentar a contagem Node por arquivo; na execução completa foram observados
40 casos individuais. QtTest inclui init/cleanup nos 44 resultados.

Avaliação proporcional das instruções, em contexto novo de subagente Codex:

| Caso selecionado | Resultado e evidência |
|---|---|
| Descobrir instruções/comandos | PASS: revisor encontrou AGENTS → verify e --list |
| Recuperar decisão e conferir fonte | PASS: AGENTS → architecture → SessionLockState/SessionLock; PAM preservado; design → Theme/DesignTokens |
| Revisão somente leitura | PASS: revisor inspecionou diff/fontes e executou apenas teste do runner e listagens; nenhuma escrita solicitada ou observada |
| Reexecução segura | PASS das verificações; hashes preservados. Reaplicação integral do setup duas vezes não executada; ausência de duplicações revisada estaticamente |
| Reiniciar IDE, carregar plugin/MCP | Não executado; arquivo presente não prova descoberta automática em outro cliente |
| Fixture de autorização, handoff falso, pausa e conflitos de workers | Não executados: não foram selecionados para este setup documental/runner, sem mudança no protocolo de autenticação ou orquestrador |

O revisor foi selecionado via ferramenta nativa: gpt-5.6-terra, esforço high,
contexto sem histórico, arquivos explícitos, somente leitura, sem delegação recursiva.
Coordenador preservou modelo/autenticação principal, verificou achados e comparou
hashes por conta própria. Não há medida de tokens/economia nem tempo isolado do
review registrado. Novo subagente não foi apresentado como reinício do IDE.

Não executados neste setup: teclado/desktop live, PAM real, segundo monitor físico,
benchmark de energia, audit de pacotes Arch, nova sessão do IDE/Claude, Context7,
RTK ou Graphify. Não há mudanças visuais ou no comportamento do produto a validar.

## Arquivos e recuperação

Novos: AGENTS.md, CLAUDE.md, PRODUCT.md, os cinco documentos docs/*.md,
scripts/verify.cjs e tests/verify.test.cjs.
Alterado: README.md (índice/comandos/clareza de operação).
O código runtime QML/JS/Bash anterior e testes antigos permaneceram idênticos na
comparação final. Não há mudança visual ou funcional do shell.

Backup privado do README anterior:
`/tmp/archblato-setup-backup-L2ybkD/README.md`.
O diretório temporário tem permissões privadas; não contém perfil/credenciais.
O manifesto original-sha256.txt nesse diretório registra os hashes anteriores.
A cópia do toolkit fica em `/tmp/archblato-toolkit-dNqoyx/source`.
São temporários e podem desaparecer na limpeza de /tmp/reinício; não equivalem
a versionamento durável. Antes de restaurar, comparar com alterações posteriores.
Nenhum dado material foi removido; nenhuma reversão global é necessária.

## Manutenção e próximos passos

- Repetir verificações com os comandos de quality; não instalar nada para rerodar.
- Para reaplicar setup, inventariar estado, preservar customizações, usar uma
  revisão única do toolkit, revisar diferenças e não duplicar seções/servidores.
- Reavaliar ferramentas somente por necessidade concreta; instalação global,
  trust, autenticação e serviços exigem decisão própria, não são feitos em background.
- Em uma nova sessão do IDE aberta nesta raiz, pedir que identifique AGENTS,
  comando seguro e limites do lock. Esse é o próximo teste de carregamento real.
- A validação manual pós-lock continua pendência anterior do produto, não erro
  introduzido pelo setup. Confirmar com o usuário sem pedir senha.
