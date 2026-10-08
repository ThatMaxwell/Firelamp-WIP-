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
        property string appTrust2: ""         // per app: "all" | "risky" (default) | "never"
    }
    // Risky means deleting, sending, paying or sharing; those always ask, whatever this says.
    function trust(app) { try { return JSON.parse(settings.appTrust)[app] || "risky"; } catch (e) { return "risky"; } }
    function setTrust(app, v) { var t = {}; try { t = JSON.parse(settings.appTrust); } catch (e) {} t[app] = v; settings.appTrust = JSON.stringify(t); }
    readonly property string name: settings.assistantName || "Assistant"
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
    function clock(d) {
        var h = d.getHours(), m = d.getMinutes();
        return (h % 12 || 12) + ":" + (m < 10 ? "0" : "") + m + (h < 12 ? " AM" : " PM");
    }
}
