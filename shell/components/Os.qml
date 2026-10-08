// Shared state and the event bus every part of the shell talks through.
pragma Singleton
import QtQuick
import QtCore

QtObject {
    id: os

    // set by Main.qml once everything exists
    property Item root
    property var desktop
    property var dock
    property var agent
    property var cursor

    // ---- settings (persisted) ----
    property Settings settings: Settings {
        location: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/firelamp/shell.conf"
        property string assistantName: ""      // the user names their assistant; no default
        property bool askBeforeRisky: true
        property real cursorSpeed: 1.0
        property bool idleFade: true
        property string appTrust: "{}"
        // which brain answers: 0 Instant (Jev by TypeSafe) … 5 Ultra (Grok 4.7)
        property int effort: 0
        property string modelFast: ""
        property string modelBalanced: ""
        property bool reasoning: false
        property string jevKey: ""             // Jev is bring-your-own-key (TypeSafe)
        property string puterUser: ""          // signed-in Puter name; Fast to Ultra run through Puter.js
        property string appTrust2: ""         // per app: "all" | "risky" (default) | "never"
        // ---- the home screen (DIRECTION §13) ----
        property string homeLayout: ""         // JSON [{uid, kind, size, x, y}]; empty = the default home
        property string wallpaper: "graphite"  // "graphite" or a photo name from assets/photos
        property int dockSize: 1               // 0 small, 1 medium, 2 large
        property int dockMag: 2                // 0 off, 1 subtle, 2 full
        property bool dockBacking: true        // dark grey slab, or floating icons
        property bool dockAutohide: false
        property bool barSeconds: false
        property bool barDate: true
        property int winRadius: 12
        property string look: "graphite"       // graphite | paper | midnight | moss | studio
        property string accent: ""             // the user's color; empty = neutral. Never ember.
        property string myLooks: "[]"           // saved Looks, JSON
        property bool packsAsked: false        // first boot showed "What do you do?"
    }
    // Risky means deleting, sending, paying or sharing; those always ask, whatever this says.
    function trust(app) { try { return JSON.parse(settings.appTrust)[app] || "risky"; } catch (e) { return "risky"; } }
    function setTrust(app, v) { var t = {}; try { t = JSON.parse(settings.appTrust); } catch (e) {} t[app] = v; settings.appTrust = JSON.stringify(t); }
    readonly property string name: settings.assistantName || "Assistant"

    // ---- the live ISO: the shell covers Plasma, so it carries the way to the installer ----
    property bool live: false                     // firelamp-desktops says /run/archiso exists
    function checkLive() {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () { if (x.readyState === XMLHttpRequest.DONE && x.status === 200) os.live = !!JSON.parse(x.responseText).live; };
        x.open("GET", "http://127.0.0.1:7341/live"); x.send();
    }
    function installOS() {
        var x = new XMLHttpRequest(); x.open("POST", "http://127.0.0.1:7341/install-os"); x.send();
        toast("install", "Opening the installer", "Firelamp OS installs from here. Your live session keeps running.");
    }

    // ---- packs: one shared status, so first boot and Settings › Packs agree ----
    property var packStatus: ({})                 // id -> { installed, state, log, removing }
    property bool packHelper: false               // firelamp-desktops answered
    function setPack(id, f) { var st = Object.assign({}, packStatus); st[id] = Object.assign({}, st[id] || {}, f); packStatus = st; }
    function installPack(id, remove) {
        setPack(id, { state: "installing", log: "", removing: !!remove });
        if (!packHelper && demoInstalls) { packDemo.queue.push([id, !!remove]); if (!packDemo.running) packDemo.start(); return; }
        var x = new XMLHttpRequest();
        x.open("POST", "http://127.0.0.1:7341" + (remove ? "/remove-pack/" : "/install-pack/") + id); x.send();
    }
    // recorder / dev builds without the helper: stand-in installs, one after another
    property Timer packDemo: Timer {
        property var queue: []
        interval: 4500; repeat: true
        onTriggered: { var j = queue.shift(); if (j) os.setPack(j[0], { state: "", installed: !j[1] }); if (!queue.length) stop(); }
    }

    // ---- home widgets: sizes are S 2×2, M 4×2, L 4×4 on a 76px unit with 24px gutters ----
    property bool editingHome: false
    readonly property var widgetSizes: ({ S: [152, 152], M: [328, 152], L: [328, 328] })
    readonly property var defaultHome: [
        { uid: 1, kind: "clock", size: "M", x: 72, y: 64 },
        { uid: 2, kind: "weather", size: "S", x: 424, y: 64 },
        { uid: 3, kind: "upnext", size: "M", x: 72, y: 240 },
        { uid: 4, kind: "system", size: "S", x: 424, y: 240 },
        { uid: 5, kind: "nowplaying", size: "M", x: -400, y: 64 },
        { uid: 6, kind: "assistant", size: "M", x: -400, y: 240 } ]
    property var widgets: []
    function loadHome() { try { widgets = settings.homeLayout ? JSON.parse(settings.homeLayout) : defaultHome.slice(); } catch (e) { widgets = defaultHome.slice(); } }
    function saveHome(list) { widgets = list; settings.homeLayout = JSON.stringify(list); }
    function updateWidget(uid, f) { saveHome(widgets.map(function (w) { return w.uid === uid ? Object.assign({}, w, f) : w; })); }
    function removeWidget(uid) { saveHome(widgets.filter(function (w) { return w.uid !== uid; })); }
    function addWidget(kind, size, x, y) {
        var uid = 1; widgets.forEach(function (w) { uid = Math.max(uid, w.uid + 1); });
        saveHome(widgets.concat([{ uid: uid, kind: kind, size: size, x: x, y: y, fresh: true }]));
        return uid;
    }
    function resetHome() { settings.homeLayout = ""; widgets = defaultHome.slice(); }
    Component.onCompleted: loadHome()
    property bool vision: false
    property bool demo: false
    property bool demoInstalls: false             // recorder/dev: stand-in installs when the helper isn't running
    property bool demoUnlabeledSend: false        // recorder: Mail's Send button loses its label

    // ---- events ----
    signal say(string text)                       // the assistant says something in chat
    signal log(var entry)                         // {kind, title, why, app} for the timeline
    signal toast(string icon, string title, string body)
    signal submit(string text)                    // a request for the assistant
    signal timelineToggle(var on)
    signal askOpen()
    signal controlToggle()
    signal trashFull()
    signal trashEmpty()
    signal propose(var plan)                      // a plan waiting for Go / Edit in the Assistant
    signal logUpdate(string gid, var fields)
    signal planEnded(string id, string how)      // a timeline group changed (milestone finished, undone)

    // ---- the activity log (newest first); each milestone holds its routine steps ----
    property ListModel activity: ListModel {}
    function activityIndex(gid) { for (var i = 0; i < activity.count; i++) if (activity.get(i).gid === gid) return i; return -1; }
    onLog: (e) => {
        var d = new Date(), two = function (n) { return (n < 10 ? "0" : "") + n; };
        var t = two(d.getHours()) + ":" + two(d.getMinutes());
        if (e.gid && e.kind !== "milestone") {
            var i = activityIndex(e.gid);
            if (i >= 0) {
                var st = JSON.parse(activity.get(i).steps);
                st.push({ title: e.title, time: t });
                activity.setProperty(i, "steps", JSON.stringify(st));
                activity.setProperty(i, "n", st.length);
                if (e.app) activity.setProperty(i, "app", e.app);
                return;
            }
        }
        activity.insert(0, { gid: e.gid || "", kind: e.kind, title: e.title, why: e.why || "", app: e.app || "", time: t,
                             live: !!e.live, undo: false, until: 0, undone: false, steps: "[]", n: 0, expanded: false });
    }
    onLogUpdate: (gid, f) => {
        var i = activityIndex(gid); if (i < 0) return;
        for (var k in f) activity.setProperty(i, k, f[k]);
        // a milestone lands in time order when it finishes, after any asks inside it
        if (f.live === false && i > 0) activity.move(i, 0, 1);
    }

    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var days: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    function clock(d, seconds) {
        var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds();
        return (h % 12 || 12) + ":" + (m < 10 ? "0" : "") + m + (seconds ? ":" + (s < 10 ? "0" : "") + s : "") + (h < 12 ? " AM" : " PM");
    }
}
