// The agent runtime. A plan (from the "brain") is a list of small steps; each one is
// resolved against the live UI tree (the "reflexes"), performed with the fire cursor,
// and written to the timeline with its reason. Pause and stop work at any moment.
import QtQuick
import "../js/uitree.js" as Tree
import "../js/plans.js" as Plans

Item {
    id: ag
    property string mode: "idle"            // idle | running | paused | stuck | teaching
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
    // plan-first: a proposal waits for Go / Edit; once running, its lines are milestones
    property var proposal: null
    property var lines: []
    property int mi: -1
    property string planId: ""
    property string gid: ""
    property var groups: ({})
    property int seq: 0
    property var cur: null
    property string workApp: ""              // the app whose window the AI is working in
    property var stuckOn: null               // { target, k } when it couldn't find something
    property string blind: ""                // test hook: pretend this target isn't on screen

    // ---- control ----
    function togglePause() {
        if (mode !== "running" && mode !== "paused") return;
        var p = mode !== "paused";
        mode = p ? "paused" : "running";
        cursor.paused = p; capsule.paused = p;
        if (p) cursor.verb = "paused";
        else { capsule.why = ""; if (pending) { var k = pending; pending = null; k(); } }
    }
    // you moved your own mouse into the window it's working in: it steps back on its own
    function autoPause(title) {
        if (mode !== "running" || permission.shown) return;
        capsule.why = "you’re using " + title;
        togglePause();
    }
    function stop() {
        if (mode === "idle") return;
        stopped = true;
        if (mode !== "running") { mode = "running"; cursor.paused = false; capsule.paused = false; capsule.why = ""; capsule.stuck = ""; stuckOn = null; }
        typer.stop(); waiter.stop();
        if (permission.shown) permission.answer(false);
        var k = pending; pending = null;
        finish("stopped");
    }

    // ---- helpers handed to plans ----
    readonly property var api: ({
        app: function (id) { var w = Os.desktop.get(id); return w ? w.content : null; },
        trashFull: function () { Os.trashFull(); },
        trashEmpty: function () { Os.trashEmpty(); }
    })
    function quoteTitle(t) { return t.replace(/“([^”]+)”/g, "<font color=\"#ffffff\">“$1”</font>"); }
    // routine steps file under the current milestone; asks, refusals and stops stand alone
    readonly property var routine: ["open", "click", "type", "look", "move"]
    function log(kind, title, why, app) {
        var inGroup = gid !== "" && routine.indexOf(kind) >= 0;
        Os.log({ kind: kind, title: quoteTitle(title), why: why || "", app: app || "", gid: inGroup ? gid : "" });
        if (inGroup && cur && cur.undo && !cur.logged) { cur.logged = true; groups[gid].undos.push(cur.undo); }
        if (routine.indexOf(kind) >= 0) capsule.steps = ++done;
    }
    function milestone(i) {
        closeMilestone();
        mi = i; gid = planId + ":" + i; groups[gid] = { undos: [] };
        capsule.plan = lines[i].plan; capsule.k = i + 1;
        Os.log({ kind: "milestone", gid: gid, title: lines[i].plan, why: "", app: "", live: true });
    }
    function closeMilestone() {
        if (gid === "") return;
        var g = groups[gid];
        g.until = Date.now() + 30000;
        Os.logUpdate(gid, { title: lines[mi].done, why: lines[mi].why || "", live: false, undo: g.undos.length > 0, until: g.until });
        gid = "";
    }
    // undo a finished milestone, for 30 seconds after it finished
    function undo(id) {
        var g = groups[id];
        if (!g || !g.undos.length || Date.now() > g.until) return;
        for (var i = g.undos.length - 1; i >= 0; i--) g.undos[i](api);
        g.undos = [];
        Os.logUpdate(id, { undo: false, undone: true });
    }
    function appTitle(id) { var w = Os.desktop.get(id); return w ? w.title : id === "dock" ? "Dock" : "Firelamp"; }

    function after(ms, k) { waiter.k = k; waiter.interval = Math.max(1, ms); waiter.restart(); }
    Timer { id: waiter; property var k; onTriggered: { var f = k; k = null; if (f) f(); } }

    // two honest attempts, then it stops and says what blocked it instead of guessing
    function locate(target, k, tries, attempt) {
        tries = tries || 0; attempt = attempt || 1;
        var n = target.name === blind ? null : Tree.find(Os.root, target);
        if (n) { if (n.app !== "system" && n.app !== "desktop") workApp = n.app; return k(n); }
        if (tries < 25) return after(80, function () { locate(target, k, tries + 1, attempt); });
        if (attempt < 2) { cursor.verb = "looking again"; return after(500, function () { locate(target, k, 0, 2); }); }
        stuck(target, k);
    }
    function stuck(target, k) {
        var where = appTitle(target.app);
        var what = target.role === "button" ? "a " + target.name + " button" : "“" + (target.say || target.name) + "”";
        // say what actually blocked it: an unlabeled control is different from nothing at all
        var blank = Tree.unlabeled(Os.root).filter(function (n) { return n.app === target.app; }).length > 0;
        var line = blank && target.does ? "Couldn’t tell which button " + target.does + ". There’s an unlabeled icon"
                                        : "Couldn’t find " + what + " in " + where;
        mode = "stuck"; stuckOn = { target: target, k: k };
        cursor.busy = false; cursor.clearTarget(); cursor.note = "Stuck"; cursor.paused = true;
        capsule.stuck = line;
        log("stuck", line, "I tried twice, then stopped instead of guessing.", where);
        Os.say(blank ? "I can’t tell which button " + target.does + ": one of them is an icon with no label, and I don’t click things I can’t name. Press Show me and click it for me, or stop."
                     : "I couldn’t find " + what + " in " + where + ", so I stopped instead of guessing. Press Show me and click it for me, or stop.");
    }
    // "Show me": your next click in that window tells it where the thing is
    function showMe() {
        if (mode !== "stuck") return;
        mode = "teaching";
        var t = stuckOn.target, w = Os.desktop.get(t.app);
        if (w) Os.desktop.focusWindow(w);
        capsule.stuck = "Click the " + (t.role === "button" ? t.name + " button" : "“" + (t.say || t.name) + "”") + " for me";
        cursor.note = "Show me";
    }
    function taught(n) {
        if (mode !== "teaching" || !n) return;
        var s = stuckOn; stuckOn = null;
        mode = "running"; capsule.stuck = ""; cursor.paused = false; cursor.note = "";
        if (blind === s.target.name) blind = "";
        if (!n.name) n.name = s.target.name;
        log("look", "You showed me the " + n.name + " button", "I’ll use it from here.", appTitle(n.app));
        workApp = n.app;
        Os.say("Got it, thanks. Carrying on.");
        s.k(n);
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
            var b = n.bounds;
            var tx = b.w > 120 ? b.x + Math.min(b.w / 2, 40 + Math.random() * 20) : b.x + b.w / 2;
            cursor.moveTo(tx, b.y + b.h / 2, function () {
                cursor.aim(target.say || n.name, function () { gate(function () { k(n); }); });
            }, Math.min(b.w, b.h * 3));
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
            var title = Os.desktop.registry[s.app].winTitle || Os.desktop.registry[s.app].title;
            // "Ask before anything" for this app: one OK before it starts working there
            if (Os.trust(s.app) === "all" && !s.allowed) {
                capsule.what = "Waiting for your OK"; cursor.busy = true;
                log("ask", "Asked before using " + title, "You set " + title + " to ask before anything.", "Firelamp");
                return permission.ask({ app: s.app, title: "Let " + Os.name + " work in " + title + "?", body: "You set " + title + " to ask before anything. Change this in Settings › Assistant.",
                                        deny: "Not Now", allow: "Allow" }, function (ok) {
                    cursor.busy = false;
                    if (stopped) return;
                    if (!ok) { log("denied", "You said no, so I stopped there", "", "Firelamp"); Os.say("Okay, I won’t touch " + title + "."); return finish("denied"); }
                    s.allowed = true; exec(s, next);
                });
            }
            capsule.what = "Opening " + title; cursor.verb = "opening " + title;
            var r = Os.dock.iconRect(s.app);
            // not in the dock (the UI Tree console on a real install): open it without the trip
            if (!r) {
                Os.desktop.open(s.app); workApp = s.app;
                log("open", "Opened " + title, s.why, title);
                return after(560, next);
            }
            return cursor.moveTo(r.x + r.width / 2, r.y + r.height / 2, function () {
                cursor.aim(title, function () {
                    gate(function () {
                        cursor.click(function () {
                            Os.desktop.open(s.app);
                            workApp = s.app;
                            cursor.clearTarget();
                            log("open", "Opened " + title, s.why, title);
                            after(560, next);
                        });
                    });
                });
            }, r.width);
        }
        case "click":
            capsule.what = s.title || "Clicking “" + (s.target.say || s.target.name) + "”";
            return point(s.target, "clicking", function (n) {
                cursor.click(function () {
                    if (n.item.aiActivate) n.item.aiActivate();
                    cursor.clearTarget();
                    log("click", s.title || "Clicked “" + (s.target.say || n.name) + "”", s.why, appTitle(n.app));
                    after(280, function () { unmark(); next(); });
                });
            });
        case "read":
            capsule.what = s.title;
            return point(s.target, "reading", function (n) {
                if (n.item.aiSelectAll) n.item.aiSelectAll();
                s.done(n.item.aiText ? n.item.aiText() : "");
                cursor.busy = true;
                after(500, function () { cursor.busy = false; cursor.clearTarget(); log("look", s.title, s.why, appTitle(n.app)); unmark(); next(); });
            });
        case "type":
            capsule.what = s.title || "Typing in “" + (s.target.say || s.target.name) + "”";
            return point(s.target, "typing in", function (n) {
                cursor.click(function () {
                    if (n.item.aiActivate) n.item.aiActivate();
                    cursor.verb = "typing…";
                    cursor.clearTarget(); cursor.busy = true;
                    typer.start2(n.item, typeof s.text === "function" ? s.text() : s.text, s.cps ? 1000 / s.cps : 45, function () {
                        cursor.busy = false;
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
                    cursor.clearTarget();
                    locate(s.dst, function (dn) {
                        cursor.verb = "moving to " + dn.name;
                        if (dn.item.aiDropTarget !== undefined) dn.item.aiDropTarget = true;
                        cursor.moveTo(dn.bounds.x + dn.bounds.w / 2, dn.bounds.y + dn.bounds.h / 2 - 10, function () {
                          cursor.aim(s.dst.say || dn.name, function () {
                            gate(function () {
                                cursor.pressed = false; ghost.visible = false;
                                if (dn.item.aiDropTarget !== undefined) dn.item.aiDropTarget = false;
                                cursor.click(function () {
                                    if (s.drop) s.drop(api);
                                    log("move", s.title || "Moved “" + sn.name + "” into “" + dn.name + "”", s.why, appTitle(sn.app));
                                    cursor.clearTarget();
                                    after(380, function () { unmark(); next(); });
                                });
                            });
                          });
                        }, dn.bounds.w);
                    });
                };
                // apps can hand over a clean icon for the dragged thing; otherwise snapshot it
                if (sn.item.aiIcon) lift(sn.item.aiIcon, 52, 52);
                else sn.item.grabToImage(function (res) { lift(res.url, sn.bounds.w, sn.bounds.h); });
            });
        case "confirm":
            if (!Os.settings.askBeforeRisky) return next();
            capsule.what = "Waiting for your OK"; cursor.verb = "waiting for you"; cursor.clearTarget(); cursor.busy = true;
            log("ask", s.logTitle || "Asked for permission", s.why, "Firelamp");
            var req = Object.assign({ why: s.why }, s.request);
            return permission.ask(req, function (ok) {
                cursor.busy = false;
                if (stopped) return;
                if (ok) return after(250, next);
                log("denied", "You said no, so I stopped there", "", "Firelamp");
                Os.say(s.denied || "Okay, I stopped there.");
                finish("denied");
            });
        }
        next();
    }

    // types about 45 ms a character, ±15; catches up if frames are slow, so the speed holds anywhere
    Timer {
        id: typer
        property var item; property string text; property int i; property var k; property real base: 45; property real last: 0; property real owed: 0
        repeat: true
        function start2(it, t, perChar, done) {
            item = it; text = t; i = 0; k = done; owed = 0; last = Date.now();
            base = perChar / (Os.settings.cursorSpeed || 1); interval = Math.max(8, Math.min(15, base)); start();
        }
        onTriggered: {
            var now = Date.now(), dt = now - last; last = now;
            if (ag.mode === "paused") return;
            owed += dt;
            while (i < text.length && owed > 0) {
                var ch = text[i++];
                if (item.aiType) item.aiType(ch);
                owed -= (ch === " " ? 1.3 : 1) * base * (1 + (Math.random() * 2 - 1) / 3);
            }
            if (i >= text.length) { stop(); var f = k; k = null; f(); }
        }
    }

    function step() {
        gate(function () {
            if (pc >= steps.length) return finish("done");
            var s = steps[pc++];
            cur = s;
            if (s.op === "milestone") { milestone(s.i); return after(120, step); }
            exec(s, step);
        });
    }

    function run(plan, pick, id) {
        if (mode !== "idle") { Os.say("I'm still working on the last thing. Pause or stop me first."); return; }
        steps = plan.steps(pick); pc = 0; done = 0; stopped = false; pending = null; label = plan.label;
        lines = plan.lines ? plan.lines(pick) : []; mi = -1; gid = ""; planId = id || "p" + (++seq); workApp = "";
        mode = "running";
        capsule.steps = 0; capsule.what = plan.label; capsule.plan = ""; capsule.k = 0; capsule.total = lines.length;
        capsule.paused = false; capsule.why = ""; capsule.stuck = ""; capsule.shown = true;
        var r = Os.dock.iconRect("assistant");
        cursor.verb = "";
        cursor.show(r ? Qt.point(r.x + r.width / 2, r.y) : null);
        after(300, step);
    }

    function finish(how) {
        typer.stop();
        closeMilestone();
        if (how === "done") log("done", "Done", label, "Firelamp");
        if (how === "stopped") { log("denied", "Stopped by you", "You pressed stop, so I stopped right away.", "Firelamp"); Os.say("Stopped. Nothing else was changed."); }
        stopped = true;
        unmark(); ghost.visible = false; cursor.pressed = false; cursor.paused = false; cursor.note = ""; cursor.verb = ""; cursor.busy = false; cursor.clearTarget();
        Os.planEnded(planId, how);
        lines = []; workApp = ""; stuckOn = null;
        var r = Os.dock.iconRect("assistant");
        var end = function () { cursor.hide(); capsule.shown = false; capsule.stuck = ""; capsule.why = ""; mode = "idle"; };
        if (r) cursor.moveTo(r.x + r.width / 2, r.y + 4, end); else end();
    }

    function handle(text) {
        var p = Plans.match(text);
        // the hand-written plans act on the sample notes, mail and Downloads, so only --demo runs them
        if (p && !Os.demo && p !== Plans.vision) p = null;
        if (!p) {
            if (Os.demo) Os.say("I'm running in demo mode, so I only know a few tasks so far. Try “Email Ana my meeting notes”, “Tidy up my Downloads” or “Show me what you see”.");
            else Os.say("I can't do that one yet: this build only knows “Show me what you see”. Nothing on your computer was touched.");
            return;
        }
        if (mode !== "idle") { Os.say("I'm still working on the last thing. Pause or stop me first."); return; }
        // simple things just happen; multi-step or risky ones show the plan first
        if (!p.lines) return run(p);
        proposal = { id: "p" + (++seq), plan: p, text: text };
        Os.say(p.intro);
        Os.propose({ id: proposal.id, lines: p.lines(0), prefs: p.prefs || null, text: text });
    }
    function linesFor(pick) { return proposal ? proposal.plan.lines(pick) : []; }
    function go(id, pick) {
        if (!proposal || proposal.id !== id) return;
        var p = proposal; proposal = null;
        run(p.plan, pick, id);
    }
    function edit(id) { if (proposal && proposal.id === id) proposal = null; }
}
