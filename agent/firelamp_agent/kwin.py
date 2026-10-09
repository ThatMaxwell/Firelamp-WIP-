"""Window positions and focus, from the compositor.

On Wayland an app doesn't know where its window sits on screen, so AT-SPI only gives
positions inside the window. KWin does know: a tiny KWin script lists every window with its
geometry and calls back into the agent over D-Bus. The same mechanism brings a window to the
front. On X11, AT-SPI's screen positions are already right and xdotool/wmctrl do the focusing.
"""
import itertools
import json
import os
import tempfile
import threading

from gi.repository import Gio, GLib

BUS_NAME = "org.firelamp.Agent"
PATH = "/org/firelamp/Agent"
XML = """<node><interface name="org.firelamp.Agent">
  <method name="Windows"><arg type="s" name="token" direction="in"/><arg type="s" name="json" direction="in"/></method>
</interface></node>"""

LIST_JS = """
var ws = workspace.windowList ? workspace.windowList() : workspace.clientList();
var act = workspace.activeWindow || workspace.activeClient;
var out = [];
for (var i = 0; i < ws.length; i++) {
    var w = ws[i];
    if (!(w.normalWindow || w.dialog) || w.skipTaskbar && !w.dialog) continue;
    var g = w.clientGeometry || w.geometry;
    out.push({pid: w.pid, caption: String(w.caption), cls: String(w.resourceClass), x: g.x, y: g.y,
              w: g.width, h: g.height, active: w === act, minimized: !!w.minimized});
}
callDBus("org.firelamp.Agent", "/org/firelamp/Agent", "org.firelamp.Agent", "Windows", "%TOKEN%", JSON.stringify(out));
"""

ACTIVATE_JS = """
var ws = workspace.windowList ? workspace.windowList() : workspace.clientList();
for (var i = ws.length - 1; i >= 0; i--) {
    var w = ws[i];
    if (w.pid === %PID% && (%CAPTION% === "" || String(w.caption).indexOf(%CAPTION%) >= 0)) {
        if (w.minimized) w.minimized = false;
        if (workspace.activeWindow !== undefined) workspace.activeWindow = w; else workspace.activeClient = w;
        break;
    }
}
"""


class KWin:
    def __init__(self):
        self.ok = False
        self.bus = None
        self.results = {}
        self.cv = threading.Condition()
        self.tokens = itertools.count(1)
        try:
            self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        except Exception:
            return
        # KWin's calls back arrive on a main context of our own, run by our own thread. AT-SPI's
        # connection lives on the default context and must only ever be used from the task's
        # thread: a second thread dispatching it corrupts libatspi's memory.
        self.ctx = GLib.MainContext.new()
        self.ctx.push_thread_default()
        try:
            node = Gio.DBusNodeInfo.new_for_xml(XML)
            self.bus.register_object(PATH, node.interfaces[0], self._on_call, None, None)
            Gio.bus_own_name_on_connection(self.bus, BUS_NAME, Gio.BusNameOwnerFlags.NONE, None, None)
        except Exception:
            return
        finally:
            self.ctx.pop_thread_default()
        loop = GLib.MainLoop.new(self.ctx, False)
        threading.Thread(target=self._dispatch, args=(loop,), name="kwin-dbus", daemon=True).start()
        self.ok = self._has_kwin()

    def _dispatch(self, loop):
        self.ctx.push_thread_default()
        loop.run()

    def _has_kwin(self):
        try:
            r = self.bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                                   "NameHasOwner", GLib.Variant("(s)", ("org.kde.KWin",)), None,
                                   Gio.DBusCallFlags.NONE, 2000, None)
            return bool(r.unpack()[0])
        except Exception:
            return False

    def _on_call(self, conn, sender, path, iface, method, params, invocation):
        if method == "Windows":
            token, data = params.unpack()
            with self.cv:
                try:
                    self.results[token] = json.loads(data)
                except ValueError:
                    self.results[token] = []
                self.cv.notify_all()
        invocation.return_value(None)

    def _run(self, js, name):
        path = os.path.join(tempfile.gettempdir(), "firelamp-agent-%d-%s.js" % (os.getuid(), name))
        with open(path, "w") as fh:
            fh.write(js)

        def call(obj, iface, method, args, sig):
            return self.bus.call_sync("org.kde.KWin", obj, iface, method, GLib.Variant(sig, args) if sig else None,
                                      None, Gio.DBusCallFlags.NONE, 3000, None)
        try:
            call("/Scripting", "org.kde.kwin.Scripting", "unloadScript", (name,), "(s)")
        except Exception:
            pass
        try:
            sid = call("/Scripting", "org.kde.kwin.Scripting", "loadScript", (path, name), "(ss)").unpack()[0]
            if sid < 0:
                return False
            for obj in ("/Scripting/Script%d" % sid, "/%d" % sid):
                try:
                    call(obj, "org.kde.kwin.Script", "run", None, None)
                    return True
                except Exception:
                    continue
        except Exception:
            return False
        return False

    def windows(self, timeout=1.5):
        if not self.ok:
            return None
        token = "t%d" % next(self.tokens)
        if not self._run(LIST_JS.replace("%TOKEN%", token), "firelamp-agent-list"):
            return None
        with self.cv:
            self.cv.wait_for(lambda: token in self.results, timeout=timeout)
            return self.results.pop(token, None)

    def activate(self, pid, caption=""):
        if not self.ok:
            return False
        js = ACTIVATE_JS.replace("%PID%", str(int(pid))).replace("%CAPTION%", json.dumps(caption or ""))
        return self._run(js, "firelamp-agent-activate")
