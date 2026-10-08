// Window manager: open, focus, minimize to the dock, zoom, close.
import QtQuick

Item {
    id: desk
    property var registry: ({})
    property var windows: []
    property var focused: null
    property int zTop: 10
    property int cascade: 0
    property string aiApp: "desktop"
    property var lastGeo: ({})               // where each app's window was when it closed
    signal focusChanged2(var win)

    Component { id: winComp; AppWindow {} }

    function get(id) { for (var i = 0; i < windows.length; i++) if (windows[i].app.id === id) return windows[i]; return null; }
    function focusWindow(win) {
        if (focused === win) return;
        if (focused) focused.focused = false;
        focused = win;
        if (win) { win.z = ++zTop; win.focused = true; }
        focusChanged2(win);
    }
    function open(id, opts) {
        opts = opts || {};
        var app = registry[id];
        if (!app) return null;
        var existing = get(id);
        if (existing) { if (existing.minimized) existing.restore(); focusWindow(existing); return existing; }
        var wd = Math.min(opts.w || app.w || 760, width - 40), ht = Math.min(opts.h || app.h || 500, height - 120);
        // leave room on the right for the assistant, which lives there
        var room = get("assistant") && id !== "assistant" ? 440 : 0;
        if (app.place === "right" && opts.x === undefined) { opts.x = width - wd - 14; opts.y = 12; }
        var g = lastGeo[id];
        if (g && opts.x === undefined) { opts.x = g.x; opts.y = g.y; wd = g.w; ht = g.h; }
        var x = opts.x !== undefined ? opts.x : Math.max(16, Math.round((width - room - wd) / 2 + (cascade % 4) * 24 - 36));
        var y = opts.y !== undefined ? opts.y : Math.max(16, Math.round((height - 88 - ht) / 2 + (cascade % 4) * 22 - 24));
        if (!g) cascade++;
        var win = winComp.createObject(desk, { app: app, x: x, y: y, width: wd, height: ht, z: ++zTop, opts: opts });
        win.activated.connect(function () { focusWindow(win); });
        win.closed.connect(function () { remove(win); });
        win.minimizedChanged.connect(function () { if (win.minimized && focused === win) { win.focused = false; focused = null; focusWindow(topmost()); } });
        windows = windows.concat([win]);
        Os.dock.setRunning(id, true);
        Os.dock.bounce(id);
        focusWindow(win);
        win.openAnim();
        return win;
    }
    function remove(win) {
        lastGeo[win.app.id] = { x: win.x, y: win.y, w: win.width, h: win.height };
        windows = windows.filter(function (o) { return o !== win; });
        if (!get(win.app.id)) Os.dock.setRunning(win.app.id, false);
        if (focused === win) { focused = null; focusWindow(topmost()); }
        win.destroy();
    }
    function topmost() {
        var best = null;
        for (var i = 0; i < windows.length; i++) if (!windows[i].minimized && (!best || windows[i].z > best.z)) best = windows[i];
        return best;
    }
    function closeFocused() { if (focused) focused.close(); }
    function minimizeFocused() { if (focused) { var f = focused; f.minimize(); focused = null; f.focused = false; focusWindow(topmost()); } }
    function zoomFocused() { if (focused) focused.zoom(); }

    MouseArea { anchors.fill: parent; z: -1; onPressed: desk.focusWindow(null) }
}
