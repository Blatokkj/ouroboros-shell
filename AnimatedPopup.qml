
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "PanelGeometry.js" as Geometry

// Archblato Shell
//
// Regras de interação:
// - Dentro do painel: os controles recebem os cliques.
// - Área vazia dentro do painel: nenhum efeito.
// - Área fora do painel: fecha.
// - Cliques na superfície do popup não atravessam
//   para aplicativos atrás dele.
//
// A região visual é usada para detectar o que está
// dentro do painel, não para excluir eventos de mouse.

PopupWindow {
    id: root

    required property var theme
    required property var barWindow
    required property Item panelItem

    property real preferredWidth:
        theme.controlCenterWidth

    property real preferredHeight:
        theme.controlCenterHeight

    readonly property real edgeHeaderHeight:
        edgeAttached
            ? barWindow.height + barWindow.margins.top
            : 0

    readonly property real edgeAnchorY:
        -barWindow.margins.top

    readonly property var fitted: Geometry.fit(
        preferredWidth,
        preferredHeight,
        barWindow.width - theme.spaceMedium,
        (barWindow.screen
            ? barWindow.screen.height
            : 1080)
            - (edgeAttached
                ? 0
                : barWindow.height + theme.panelGap)
            - theme.viewportBottomGap
    )

    readonly property real layoutScale:
        fitted.scale

    implicitWidth: fitted.width
    implicitHeight: fitted.height

    property bool opened: false
    property bool edgeAttached: false
    property bool focusSuspended: false

    // Fornecida pelo ControlCenter, quando necessário.
    // Contém as áreas reais do painel e das asas.
    property var activeMask: null

    property real revealOriginX:
        panelItem.width / 2

    readonly property real revealProgress:
        reveal.progress

    readonly property bool animating:
        reveal.animating

    readonly property bool inputActive:
        opened && visible && !focusSuspended

    visible: reveal.presented

    grabFocus: false
    color: "transparent"

    anchor.adjustment: edgeAttached
        ? PopupAdjustment.None
        : PopupAdjustment.All

    // A borda superior funciona como uma abertura
    // por onde o painel aparece durante a animação.
    contentItem.clip: edgeAttached

    // CORREÇÃO PRINCIPAL:
    //
    // Quando o popup está ativo, toda a superfície
    // recebe os eventos de mouse.
    //
    // Isso impede que o clique atravesse regiões
    // transparentes e acione janelas atrás.
    //
    // Quando inativo, a máscara vazia permite
    // que a animação de saída termine sem capturar
    // novos cliques.
    mask: inputActive ? null : emptyInput

    Region {
        id: emptyInput
        width: 0
        height: 0
    }

    // Converte um ponto da janela para as coordenadas
    // locais de um componente.
    //
    // mapFromItem considera deslocamentos, escalas
    // e transformações aplicadas pelas animações.
    function containsItem(item, x, y) {
        if (!item)
            return false;

        if (!item.visible || !item.enabled)
            return false;

        if (item.width <= 0 || item.height <= 0)
            return false;

        const point = item.mapFromItem(
            root.contentItem,
            x,
            y
        );

        return point.x >= 0
            && point.y >= 0
            && point.x < item.width
            && point.y < item.height;
    }

    // Verifica a árvore de regiões do painel.
    //
    // O ControlCenter possui:
    // - painel principal;
    // - cabeçalho;
    // - asa esquerda;
    // - asa direita.
    //
    // Cada região é testada individualmente.
    function containsRegion(region, x, y) {
        if (!region)
            return false;

        if (region.item
                && containsItem(region.item, x, y)) {
            return true;
        }

        const children = region.regions;

        if (!children)
            return false;

        for (let i = 0; i < children.length; ++i) {
            if (containsRegion(children[i], x, y))
                return true;
        }

        return false;
    }

    // Detecta se o clique aconteceu dentro
    // de alguma parte funcional do painel.
    function containsPanel(x, y) {
        if (activeMask) {
            return containsRegion(activeMask, x, y);
        }

        // CalendarPopup e QuickSettingsPopup
        // utilizam o próprio panelItem.
        return containsItem(panelItem, x, y);
    }

    // Detector de cliques nas áreas vazias.
    //
    // Ele fica ATRÁS do conteúdo do painel.
    // Botões, abas, sliders e listas têm prioridade.
    //
    // Se não existir um controle no local clicado,
    // este MouseArea recebe o evento.
    MouseArea {
        id: backgroundClickHandler

        parent: root.contentItem
        anchors.fill: parent

        z: -1000

        enabled: root.inputActive

        acceptedButtons:
            Qt.LeftButton
            | Qt.RightButton
            | Qt.MiddleButton

        onClicked: function(mouse) {
            if (!root.opened)
                return;

            // Dentro do painel, uma área vazia:
            // permanece aberto.
            if (root.containsPanel(mouse.x, mouse.y))
                return;

            // Fora do painel, mas ainda dentro
            // da superfície do popup:
            // fecha sem deixar o clique atingir
            // o aplicativo que estiver atrás.
            root.opened = false;
        }
    }

    // Nenhum conteúdo pode receber eventos quando
    // o popup não estiver em modo interativo.
    Binding {
        target: root.panelItem
        property: "enabled"
        value: root.inputActive
    }

    function dismissImmediately() {
        opened = false;
        reveal.snapClosed();
        focusGrab.active = false;
    }

    function updateFocus() {
        if (!opened || focusSuspended) {
            focusGrab.active = false;
            return;
        }

        Qt.callLater(function() {
            if (!root.opened
                    || !root.visible
                    || root.focusSuspended) {
                return;
            }

            focusGrab.active = true;
            root.panelItem.forceActiveFocus();
        });
    }

    onOpenedChanged: updateFocus()

    onFocusSuspendedChanged: updateFocus()

    // Se o compositor esconder a janela,
    // sincroniza o estado lógico.
    onVisibleChanged: {
        if (!visible && opened)
            opened = false;
    }

    // Gerenciamento de foco pelo Hyprland.
    //
    // Um clique em outra janela libera o grab.
    // Um clique dentro do popup não deveria
    // liberar o grab, pois a janela inteira
    // participa da recepção de eventos.
    HyprlandFocusGrab {
        id: focusGrab

        windows: [root]

        onCleared: {
            // Ignora liberações provocadas pelo
            // próprio encerramento ou suspensão.
            if (!root.opened || root.focusSuspended)
                return;

            // Clique fora da janela do popup.
            root.opened = false;
        }
    }

    // Preserva todas as animações existentes.
    PanelReveal {
        id: reveal

        target: root.panelItem
        theme: root.theme

        shown: root.opened
        layoutScale: root.layoutScale

        originX: root.revealOriginX
        edgeAttached: root.edgeAttached
    }
}
