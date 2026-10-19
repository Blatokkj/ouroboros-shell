# Design e interação

Verificado em 2026-10-18 contra os componentes.

## Fontes de verdade

- [Theme.qml](../Theme.qml): fallback gerado pelo tema Archblato e bindings da
  paleta do wallpaper. [WallpaperTheme](../WallpaperTheme.qml) valida/observa o
  JSON de cores sem recarregar a UI; dados inválidos mantêm a última paleta válida.
- [DesignTokens.qml](../DesignTokens.qml): dimensões, radius, espaçamentos,
  fontes, ícones e durações. Ajustes de geometria ficam aqui, não no gerador.
- [DockFrame](../DockFrame.qml)/[DockHeader](../DockHeader.qml): moldura e faixa
  conectadas à borda; [ModuleCard](../ModuleCard.qml): agrupamento visual simples.

Identidade: preto/cinza com acento do wallpaper (roxo no fallback), JetBrains Mono/Nerd Font, contraste e densidade
adequados ao White. Painéis devem parecer partes do desktop, sem blur pesado,
shaders caros ou transparência excessiva.

A extração mantém fundos escuros levemente tingidos, limitados a 30%/50%/75% da
luminância média do wallpaper (fundo/superfícies), além dos tetos escuros existentes.
O acento parte de 85% da luminosidade HSL dominante, com teto de 60%, e só é
clareado quando necessário para contraste mínimo de 4,5:1 sobre a superfície.
O secundário segue o mesmo piso de contraste, sem o antigo pastel fixo. Erro/aviso
continuam semânticos, não seguem a imagem. Wallpapers acromáticos usam roxo.
O perfil salvo fornece nome/foto ao lock sem mudar o usuário enviado ao PAM.

## Movimento e encaixe existentes

[PanelReveal](../PanelReveal.qml) faz entrada/saída reversíveis. Painéis encaixados
deslizam por baixo da faixa superior, sem fade/zoom; popups flutuantes usam
deslocamento curto com opacity/scale. [TabPage](../TabPage.qml) anima troca de
abas e desativa imediatamente a página de saída. Não acrescentar timers em repouso.

[BarMedia](../BarMedia.qml) mede o título sem depender da largura do layout,
inclui ícones/margens e limita a cápsula ao token `barMediaMaxWidth` (210 px).
A largura acompanha títulos curtos com `motionFast`; os longos usam reticências.

Central/calendário assumem o relógio da barra enquanto visíveis. Topo reto e
cantos inferiores arredondados reforçam conexão à borda física. O corpo compacto
da central mantém 480×480, acrescido da faixa do relógio; geometria reduz o canvas
quando necessário. Isso não é uma promessa de layout universal.

## Revisão de UI

- Conferir tamanho óptico dos ícones, alinhamento, margens e estados hover/pressed.
- Testar Tab, Enter/Espaço, setas, Ctrl+Tab e Esc nos componentes pertinentes.
- [QuickToggle](../QuickToggle.qml) tem foco visível, ações acessíveis e chevron
  opcional; toggles simples não devem parecer links de navegação.
- Sliders precisam de feedback imediato e valor final coerente com o backend.
- Revisar vazio, carregando, erro e indisponível, além do estado com dados.
- Perfil: fechar seletor ao sair/bloquear, restaurar foco ao cancelar e não
  persistir rascunho antes de Salvar.
- Controles/Música/Perfil devem caber; wallpaper permite scroll e Avisos usa páginas.

QtTest verifica parte dessas interações; não certifica contraste, leitores de tela
ou fluidez percebida. Não foi constatada uma preferência global de movimento
reduzido implementada: considerar em tarefa futura, não declarar suporte existente.
Revalidar esta orientação após mudanças de tokens, composição ou interação.
