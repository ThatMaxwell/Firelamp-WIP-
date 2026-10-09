// Firelamp on a real Wayland session (KWin): the same shell as Main.qml, split into
// layer-shell surfaces so real apps (Konsole, Dolphin, the browser…) stack correctly.
//   bottom   this window: wallpaper, home widgets, Firelamp's own windows (Notes, Settings)
//   (normal) every real app
//   top      the menu bar and the dock, each reserving its edge (apps maximize between them)
//   overlay  the launcher, Control Center, menus, first-boot cards — mapped only while open
//   overlay  the AI's capsule: its own small surface, so Stop always takes clicks
//   overlay  the AI's layer (fire cursor, vision, toasts): never takes input
// firelamp-shell runs this when org.kde.layershell is installed and falls back to Main.qml.
// layer-shell-qt only takes its named enum values here (plain numbers fail to load).
import QtQuick
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShell
import "components"
import "js/uitree.js" as Tree

Main {
    id: main
    layered: true
    visibility: Window.Windowed
    LayerShell.Window.scope: "firelamp-desktop"
    LayerShell.Window.layer: LayerShell.Window.LayerBottom
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand

    // ---- the menu bar ----
    Window {
        id: barWin
        visible: true
        color: "transparent"; flags: Qt.FramelessWindowHint
        width: Screen.width; height: Theme.menubarH
        LayerShell.Window.scope: "firelamp-bar"
        LayerShell.Window.layer: LayerShell.Window.LayerTop
        LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
        LayerShell.Window.exclusionZone: Theme.menubarH
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
    }

    // ---- the dock: grows while the pointer is on it, so icons can magnify ----
    Window {
        id: dockWin
        readonly property string side: Os.settings.dockSide
        readonly property real base: main.dockItem.height + 14
        readonly property real room: dockHover.hovered && Os.settings.dockMag > 0 ? 64 : 0
        readonly property real depth: main.dockItem.tucked ? 4 : base + room
        visible: true
        color: "transparent"; flags: Qt.FramelessWindowHint
        width: side === "bottom" ? Screen.width : depth
        height: side === "bottom" ? depth : Screen.height
        LayerShell.Window.scope: "firelamp-dock"
        LayerShell.Window.layer: LayerShell.Window.LayerTop
        LayerShell.Window.anchors: side === "left" ? LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom : side === "right" ? LayerShell.Window.AnchorRight | LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom : LayerShell.Window.AnchorBottom | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
        LayerShell.Window.exclusionZone: Os.settings.dockAutohide ? 0 : base
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
        HoverHandler { id: dockHover; onHoveredChanged: main.dockHot = hovered }
    }

    // ---- launcher, Control Center, menus, permission sheet, first boot: only while open ----
    readonly property bool overlayWanted: main.askBarItem.shown || main.controlItem.open || main.barItem.menu !== null
        || main.permissionItem.shown || main.cardsList.some(function (c) { return c.shown || (c.visible && c.opacity > 0 && c.shown === undefined); })
    // stays mapped a moment after closing, so the close animation can play
    onOverlayWantedChanged: if (!overlayWanted) overlayHide.restart()
    Timer { id: overlayHide; interval: 260 }
    Window {
        id: overlayWin
        visible: main.overlayWanted || overlayHide.running
        color: "transparent"; flags: Qt.FramelessWindowHint
        width: Screen.width; height: Screen.height
        LayerShell.Window.scope: "firelamp-launcher"
        LayerShell.Window.layer: LayerShell.Window.LayerOverlay
        LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityExclusive
    }

    // ---- the AI's capsule (Pause, Stop, Show me, Done): its own small surface, because Stop
    // must always take clicks while the rest of the AI's layer lets them through ----
    Window {
        id: capWin
        visible: main.capsuleItem.shown || main.capsuleItem.opacity > 0
        color: "transparent"; flags: Qt.FramelessWindowHint
        width: main.capsuleItem.width + 48; height: main.capsuleItem.height + 12 + 28
        LayerShell.Window.scope: "firelamp-capsule"
        LayerShell.Window.layer: LayerShell.Window.LayerOverlay
        LayerShell.Window.anchors: LayerShell.Window.AnchorTop
        LayerShell.Window.exclusionZone: 0
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
    }

    // ---- the AI's layer: drawn over everything, clicks pass straight through ----
    Window {
        id: aiWin
        visible: true
        color: "transparent"; flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput
        width: Screen.width; height: Screen.height
        LayerShell.Window.scope: "firelamp-ai"
        LayerShell.Window.layer: LayerShell.Window.LayerOverlay
        LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
    }

    Component.onCompleted: {
        main.barItem.parent = barWin.contentItem;
        main.dockItem.parent = dockWin.contentItem;
        [main.askBarItem, main.controlCatcher, main.controlItem, main.menuLayerItem, main.permissionItem].concat(main.cardsList)
            .forEach(function (it) { it.parent = overlayWin.contentItem; });
        // below the bar (its exclusive zone), centred by the compositor, shadow inside the surface
        main.capsuleItem.parent = capWin.contentItem;
        main.capsuleItem.anchors.horizontalCenter = undefined;
        main.capsuleItem.x = 24; main.capsuleItem.y = 12;
        [main.visionItem, main.toastsItem, main.ghostItem, main.cursorItem]
            .forEach(function (it) { it.parent = aiWin.contentItem; });
        // the AI still sees the bar and dock, at their real place on screen
        Tree.setExtraRoots([Os.root, main.contentItem], [
            { item: barWin.contentItem, origin: function () { return { x: 0, y: 0 }; } },
            { item: dockWin.contentItem, origin: function () {
                return { x: dockWin.side === "right" ? main.width - dockWin.width : 0,
                         y: dockWin.side === "bottom" ? main.height - dockWin.height : 0 }; } }]);
    }
}
