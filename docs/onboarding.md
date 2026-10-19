# Trabalhar neste setup

Este documento orienta manutenção no White, não instalação para terceiros.
A configuração é a pasta atual de QuickShell dentro do Archblato.

## Ferramentas existentes

QuickShell/Qt6, Node, Bash, D-Bus, Hyprland e os serviços do desktop são fornecidos
pelo sistema. Não há npm install, lockfile npm ou build da aplicação. O único
`package.json`, em `integrations/pear`, declara a identidade/entrada do adaptador
pessoal do Pear; não instala dependências.
Não executar npm install, instalador remoto ou atualização geral para rodar testes.

O fluxo de wallpaper usa ImageMagick, file e utilitários GNU. As integrações
isoladas precisam de qs, dbus-run-session, busctl e gdbus. Versões observadas e
limites estão em [setup](setup.md).

## Verificar sem tocar no desktop

```bash
node scripts/verify.cjs
node scripts/verify.cjs --integration
```

O segundo comando inclui D-Bus privado e dados temporários. Sandboxes podem
bloquear sockets locais: pedir a permissão necessária, sem trocar pelo barramento
pessoal. Não é necessário desligar internet/Bluetooth ou autenticar no PAM.

## Sessão real

O shell faz hot reload ao editar QML. Primeiro confira se já está rodando;
não inicie outra instância que dispute notificações ou lock. O comando de início
documentado no [README](../README.md) é para quando a configuração não está ativa.

Diagnóstico somente leitura da configuração existente, executado da sua raiz:

```bash
qs list --path .
qs ipc --path . call lock status
qs log --path . --no-color -t 30
```

Logs podem mostrar títulos, caminhos e outros dados pessoais: reveja/redija antes
de compartilhar. Não use kill/restart como solução automática, sobretudo no lock.
Testes `--live` são opt-in: ver [qualidade](quality.md).

## Recuperação

Antes de editar conteúdo relevante sem Git utilizável, guarde cópia privada dos
arquivos afetados em diretório criado por mktemp; registre o caminho. Não copie
credenciais nem o perfil pessoal para um backup de código.

Se uma mudança falhar: preserve logs pertinentes, compare somente arquivos da
tarefa e restaure apenas trechos comprovadamente introduzidos por ela. Não use
reset/checkout destrutivo, não sobrescreva alterações posteriores do usuário.
Confira o lock e combine qualquer recuperação de QML que afete a sessão em uso.

Este setup muda apenas documentação e verificações; para desfazê-lo, compare o
README com seu backup e remova somente os arquivos novos enumerados em
[setup](setup.md), após confirmar que não receberam trabalho posterior.
Nenhuma configuração global precisa ser revertida.

## Agentes e continuidade

Leia [AGENTS.md](../AGENTS.md). [CLAUDE.md](../CLAUDE.md) é apenas a ponte para as
mesmas instruções, não uma instalação do Claude. Comece futuras sessões nesta
raiz; sem Git reconhecido, não presuma descoberta automática a partir de subpastas.
O índice leva às fontes detalhadas sob demanda; relatórios datados guardam histórico.
