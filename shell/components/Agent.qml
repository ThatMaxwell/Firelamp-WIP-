// The agent runtime. A plan (from the "brain") is a list of small steps; each one is
// resolved against the live UI tree (the "reflexes"), performed with the fire cursor,
// and written to the timeline with its reason. Pause and stop work at any moment.
import QtQuick
import "../js/uitree.js" as Tree
import "../js/plans.js" as Plans

Item {
    id: ag
    property string mode: "idle"            // idle | running | paused
    property var cursor
    property var capsule
    property var permission
    property var mark
    property var ghost
    property var steps: []
    property int pc: 0
    property int done: 0
    property string label: ""
    property bool stopped: false
    property var pending: null               // continuation held while paused

    // ---- control ----
    function togglePause() {
        if (mode === "idle") return;
        var p = mode !== "paused";
        mode = p ? "paused" : "running";
        cursor.paused = p; capsule.paused = p;
        if (p) cursor.verb = "paused";
        else if (pending) { var k = pending; pending = null; k(); }
    }
    function stop() {
        if (mode === "idle") return;
        stopped = true;
        if (mode === "paused") { mode = "running"; cursor.paused = false; capsule.paused = false; }
        typer.stop(); waiter.stop();
        if (permission.shown) permission.answer(false);
        var k = pending; pending = null;
        finish("stopped");
    }

    // ---- helpers handed to plans ----
    readonly property var api: ({
        app: function (id) { var w = Os.desktop.get(id); return w ? w.content : null; },
        trashFull: function () { Os.trashFull(); }
    })
    function quoteTitle(t) { return t.replace(/“([^”]+)”/g, "<font color=\"#ffffff\">“$1”</font>"); }
    function log(kind, title, why, app) {
        Os.log({ kind: kind, title: quoteTitle(title), why: why || "", app: app || "" });
        if (kind !== "done" && kind !== "denied") capsule.steps = ++done;
    }
    function appTitle(id) { var w = Os.desktop.get(id); return w ? w.title : id === "dock" ? "Dock" : "Firelamp"; }

    function after(ms, k) { waiter.k = k; waiter.interval = Math.max(1, ms); waiter.restart(); }
    Timer { id: waiter; property var k; onTriggered: { var f = k; k = null; if (f) f(); } }

    function locate(target, k, tries) {
        tries = tries || 0;
        var n = Tree.find(Os.root, target);
        if (n) return k(n);
        if (tries > 25) { Os.say("I couldn't find “" + target.name + "” on screen, so I stopped."); return finish("error"); }
        after(80, function () { locate(target, k, tries + 1); });
    }
    function markItem(n) {
        if (!mark) return;
        mark.x = n.bounds.x - 4; mark.y = n.bounds.y - 4; mark.width = n.bounds.w + 8; mark.height = n.bounds.h + 8;
        mark.opacity = 1;
    }
    function unmark() { if (mark) mark.opacity = 0; }
    function point(target, verb, k) {
        locate(target, function (n) {
            cursor.verb = verb + " " + (target.say || n.name);
            markItem(n);
            var b = n.bounds;
            var tx = b.w > 120 ? b.x + Math.min(b.w / 2, 40 + Math.random() * 20) : b.x + b.w / 2;
            cursor.moveTo(tx, b.y + b.h / 2, function () { gate(function () { k(n); }); });
        });
    }
    // every continuation passes through the gate, so pause and stop take effect between moves
    function gate(k) {
        if (stopped) return;
        if (mode === "paused") { pending = k; return; }
        k();
    }

    // ---- steps ----
    function exec(s, next) {
        switch (s.op) {
        case "say": Os.say(s.text); return after(150, next);
        case "think": capsule.what = s.text; cursor.verb = s.text.toLowerCase() + "…"; return after(s.ms || 700, next);
        case "wait": return after(s.ms, next);
        case "log": log(s.kind, s.title, s.why, s.app); return next();
        case "vision": Os.vision = s.on; return after(200, next);
        case "open": {
            var title = Os.desktop.registry[s.app].title;
            capsule.what = "Opening " + title; cursor.verb = "opening " + title;
            var r = Os.dock.iconRect(s.app);
            return cursor.moveTo(r.x + r.width / 2, r.y + r.height / 2, function () {
                gate(function () {
                    cursor.click(function () {
                        Os.desktop.open(s.app);
                        log("open", "Opened " + title, s.why, title);
                        after(560, next);
                    });
                });
            });
        }
        case "click":
            capsule.what = s.title || "Clicking “" + (s.target.say || s.target.name) + "”";
            return point(s.target, "clicking", function (n) {
                cursor.click(function () {
                    if (n.item.aiActivate) n.item.aiActivate();
                    log("click", s.title || "Clicked “" + (s.target.say || n.name) + "”", s.why, appTitle(n.app));
                    after(280, function () { unmark(); next(); });
                });
            });
        case "read":
            capsule.what = s.title;
            return point(s.target, "reading", function (n) {
                if (n.item.aiSelectAll) n.item.aiSelectAll();
                s.done(n.item.aiText ? n.item.aiText() : "");
                after(500, function () { log("look", s.title, s.why, appTitle(n.app)); unmark(); next(); });
            });
        case "type":
            capsule.what = s.title || "Typing in “" + (s.target.say || s.target.name) + "”";
            return point(s.target, "typing in", function (n) {
                cursor.click(function () {
                    if (n.item.aiActivate) n.item.aiActivate();
                    cursor.verb = "typing…";
                    typer.start2(n.item, typeof s.text === "function" ? s.text() : s.text, s.cps || 38, function () {
                        log("type", s.title || "Typed into “" + (s.target.say || n.name) + "”", s.why, appTitle(n.app));
                        unmark(); next();
                    });
                });
            });
        case "key":
            return locate(s.target, function (n) { if (n.item.aiKey) n.item.aiKey(s.key); after(220, next); });
        case "drag":
            capsule.what = s.title || "Moving “" + s.src.name + "” to “" + s.dst.name + "”";
            return point(s.src, "grabbing", function (sn) {
                cursor.pressed = true;
                var lift = function (src, w, h) {
                    ghost.source = src; ghost.width = w; ghost.height = h; ghost.visible = true;
                    sn.item.opacity = 0.35;
                    unmark();
                    locate(s.dst, function (dn) {
                        cursor.verb = "moving to " + dn.name;
                        markItem(dn);
                        if (dn.item.aiDropTarget !== undefined) dn.item.aiDropTarget = true;
                        cursor.moveTo(dn.bounds.x + dn.bounds.w / 2, dn.bounds.y + dn.bounds.h / 2 - 10, function () {
                            gate(function () {
                                cursor.pressed = false; ghost.visible = false;
                                if (dn.item.aiDropTarget !== undefined) dn.item.aiDropTarget = false;
                                cursor.click(function () {
                                    if (s.drop) s.drop(api);
                                    log("move", s.title || "Moved “" + sn.name + "” into “" + dn.name + "”", s.why, appTitle(sn.app));
                                    after(380, function () { unmark(); next(); });
                                });
                            });
                        });
                    });
                };
                // apps can hand over a clean icon for the dragged thing; otherwise snapshot it
                if (sn.item.aiIcon) lift(sn.item.aiIcon, 52, 52);
                else sn.item.grabToImage(function (res) { lift(res.url, sn.bounds.w, sn.bounds.h); });
            });
        case "confirm":
            if (!Os.settings.askBeforeRisky) return next();
            capsule.what = "Waiting for your OK"; cursor.verb = "waiting for you";
            log("ask", s.logTitle || "Asked for permission", s.why, "Firelamp");
            var req = Object.assign({ why: s.why }, s.request);
            return permission.ask(req, function (ok) {
                if (stopped) return;
                if (ok) return after(250, next);
                log("denied", "You said no, so I stopped there", "", "Firelamp");
                Os.say(s.denied || "Okay, I stopped there.");
                finish("denied");
            });
        }
        next();
    }

    // types at a human-ish rhythm; catches up if frames are slow, so the speed holds anywhere
    Timer {
        id: typer
        property var item; property string text; property int i; property var k; property real base: 26; property real last: 0; property real owed: 0
        repeat: true
        function start2(it, t, cps, done) {
            item = it; text = t; i = 0; k = done; owed = 0; last = Date.now();
            base = 1000 / cps / (Os.settings.cursorSpeed || 1); interval = Math.max(8, base); start();
        }
        onTriggered: {
            var now = Date.now(), dt = now - last; last = now;
            if (ag.mode === "paused") return;
            owed += dt;
            while (i < text.length && owed > 0) {
                var ch = text[i++];
                if (item.aiType) item.aiType(ch);
                owed -= (ch === " " ? 1.6 : 1) * base * (0.6 + Math.random() * 0.8);
            }
            if (i >= text.length) { stop(); var f = k; k = null; f(); }
        }
    }

    function step() {
        gate(function () {
            if (pc >= steps.length) return finish("done");
            var s = steps[pc++];
            exec(s, step);
        });
    }

    function run(plan) {
        if (mode !== "idle") { Os.say("I'm still working on the last thing. Pause or stop me first."); return; }
        steps = plan.steps(); pc = 0; done = 0; stopped = false; pending = null; label = plan.label;
        mode = "running";
        capsule.steps = 0; capsule.what = plan.label; capsule.paused = false; capsule.shown = true;
        var r = Os.dock.iconRect("assistant");
        cursor.verb = "";
        cursor.show(r ? Qt.point(r.x + r.width / 2, r.y) : null);
        after(300, step);
    }

    function finish(how) {
        typer.stop();
        if (how === "done") log("done", "Done", label, "Firelamp");
        if (how === "stopped") { log("denied", "Stopped by you", "You pressed stop, so I stopped right away.", "Firelamp"); Os.say("Stopped. Nothing else was changed."); }
        stopped = true;
        unmark(); ghost.visible = false; cursor.pressed = false; cursor.paused = false; cursor.verb = "";
        var r = Os.dock.iconRect("assistant");
        var end = function () { cursor.hide(); capsule.shown = false; mode = "idle"; };
        if (r) cursor.moveTo(r.x + r.width / 2, r.y + 4, end); else end();
    }

    function handle(text) {
        var p = Plans.match(text);
        if (!p) { Os.say("I'm running in demo mode, so I only know a few tasks so far. Try “Email Ana my meeting notes”, “Tidy up my Downloads” or “Show me what you see”."); return; }
        run(p);
    }
}
