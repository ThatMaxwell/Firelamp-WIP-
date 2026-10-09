// Firelamp on a real Wayland session (KWin): the same shell as Main.qml, split into
// layer-shell surfaces so real apps (Konsole, Dolphin, the browser…) stack correctly.
//   bottom   this window: wallpaper, home widgets, Firelamp's own windows (Notes, Settings)
//   (normal) every real app
//   top      the menu bar and the dock, each reserving its edge (apps maximize between them)
//   overlay  the launcher, Control Center, menus, first-boot cards — mapped only while open
//   overlay  the AI's layer (fire cursor, capsule, vision, toasts): never takes input
// firelamp-shell runs this when org.kde.layershell is installed and falls back to Main.qml.
// Layer-shell values as numbers: layer 1 bottom, 2 top, 3 overlay; anchors top 1, bottom 2,
// left 4, right 8; keyboard 0 none, 1 exclusive, 2 on demand.
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
    LayerShell.Window.layer: 1
    LayerShell.Window.anchors: 15
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.keyboardInteractivity: 2

    // ---- the menu bar ----
    Window {
        id: barWin
        visible: true
        color: "transparent"; flags: Qt.FramelessWindowHint
        width: Screen.width; height: Theme.menubarH
        LayerShell.Window.scope: "firelamp-bar"
        LayerShell.Window.layer: 2
        LayerShell.Window.anchors: 1 | 4 | 8
        LayerShell.Window.exclusionZone: Theme.menubarH
        LayerShell.Window.keyboardInteractivity: 0
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
        LayerShell.Window.layer: 2
        LayerShell.Window.anchors: side === "left" ? 4 | 1 | 2 : side === "right" ? 8 | 1 | 2 : 2 | 4 | 8
        LayerShell.Window.exclusionZone: Os.settings.dockAutohide ? 0 : base
        LayerShell.Window.keyboardInteractivity: 0
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
        LayerShell.Window.layer: 3
        LayerShell.Window.anchors: 15
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.keyboardInteractivity: 1
    }

    // ---- the AI's layer: drawn over everything, clicks pass straight through ----
    Window {
        id: aiWin
        visible: true
        color: "transparent"; flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput
        width: Screen.width; height: Screen.height
        LayerShell.Window.scope: "firelamp-ai"
        LayerShell.Window.layer: 3
        LayerShell.Window.anchors: 15
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.keyboardInteractivity: 0
    }

    Component.onCompleted: {
        main.barItem.parent = barWin.contentItem;
        main.dockItem.parent = dockWin.contentItem;
        [main.askBarItem, main.controlCatcher, main.controlItem, main.menuLayerItem, main.permissionItem].concat(main.cardsList)
            .forEach(function (it) { it.parent = overlayWin.contentItem; });
        [main.visionItem, main.capsuleItem, main.toastsItem, main.ghostItem, main.cursorItem]
            .forEach(function (it) { it.parent = aiWin.contentItem; });
        // the AI still sees the bar and dock, at their real place on screen
        Tree.setExtraRoots([Os.root, main.contentItem], [
            { item: barWin.contentItem, origin: function () { return { x: 0, y: 0 }; } },
            { item: dockWin.contentItem, origin: function () {
                return { x: dockWin.side === "right" ? main.width - dockWin.width : 0,
                         y: dockWin.side === "bottom" ? main.height - dockWin.height : 0 }; } }]);
    }
}
