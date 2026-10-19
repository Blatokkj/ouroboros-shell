# Archblato Shell — produto pessoal

## Objetivo e público

Desktop shell do blato, feito sob medida para o White. A prioridade é manter a
sensação de sistema próprio: coeso, compacto, rápido e pessoal. Código público
não implica suporte a outras máquinas ou instalação universal.

## Fluxos existentes

- Barra por monitor: workspaces, janela ativa, relógio, métricas, mídia,
  áudio, brilho, rede, Bluetooth, bateria e tray.
- SUPER sozinho alterna a central no monitor ativo; atalhos combinados permanecem.
- Central com Controles, Música, Avisos, Wallpapers e Perfil; calendário próprio.
- Clique curto nos rádios alterna estado; segurar abre redes/dispositivos.
- Pear Desktop/YT Music é prioridade de mídia, inclusive identidade Chromium;
  seek e volume preservam as capacidades do player e o fallback PipeWire.
- Notificações: histórico, unread, DND, actions, replacements, transient,
  até três toasts e supressão durante lock.
- Wallpapers: preview, cache WebP e aplicação com um clique via hyprpaper.
- Perfil editável com Save/Cancel; lock real Wayland/PAM em todos os monitores.

Detalhes de uso ficam no [README](README.md), sem uma segunda lista de atalhos aqui.

## Restrições

Preservar a stack, a conta do usuário, paths pessoais e integrações. Não criar
abstrações genéricas, dependências grandes, blur pesado ou serviços permanentes
para desenvolvimento. O custo no White importa mais que efeitos decorativos.
Preto/cinza/roxo, fonte mono/Nerd Font e módulos conectados à interface orientam
a estética. Mudanças são incrementais e testadas; não há reescrita planejada.

## Critérios de aceitação de evoluções

- Fluxos existentes continuam disponíveis; SUPER abre e fecha a central.
- Um painel principal por monitor, foco liberado no fechamento/lock.
- Após autenticação PAM, painéis voltam a responder; nenhum bypass de unlock.
- Controles e Música permanecem compactos; wallpaper pode rolar.
- Arrastar brilho tem feedback imediato e aplicação controlada, sem processo por evento.
- Seek/volume do Pear não passam a controlar outros aplicativos.
- Mudanças de UI preservam teclado, foco visível, feedback e identidade visual.
- Testes simulados não são apresentados como validação de hardware/PAM reais.

## Fora deste setup

Redesign, nova funcionalidade, migração de stack, instalação para terceiros,
serviços externos, atualização geral do Arch e mudanças de segurança do lock.
O setup de desenvolvimento não adiciona OSD, dashboard gigante ou favoritos.

## Pendências de produto

A confirmação manual do ciclo real de lock/unlock e o teste em segundo monitor
físico não estão comprovados por este setup. Opções futuras já registradas no
README continuam propostas, não compromissos de implementação automática.

Atualize este arquivo quando a intenção, limites ou critérios mudarem.
