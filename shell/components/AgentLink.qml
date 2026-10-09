// The line to the real assistant: firelamp-agent (agent/), a normal Linux program on
// 127.0.0.1:7342. It thinks with an LLM, reads every app through AT-SPI and acts on them;
// this side shows it: the fire cursor, the capsule, the plan, Activity and the permission sheet.
// Events arrive on a long poll; the ones carrying `req` wait for an answer on /reply.
import QtQuick
import "../js/uitree.js" as Tree

Item {
    id: link
    property var agent                       // Agent.qml
    readonly property string base: "http://127.0.0.1:7342"
    property bool up: false                  // the agent answered
    property var status: ({})                // GET /status: brain, jev, puter_user, keyboard
    property int last: -1
    property var snap: []                    // the shell's own elements, as last sent to the agent
    property var aiLayer: null               // the AI layer above every window (AiLayer*.qml)

    function post(path, body, cb) {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return;
            var r = null; try { r = JSON.parse(x.responseText); } catch (e) {}
            if (cb) cb(x.status, r);
        };
        x.open("POST", base + path); x.setRequestHeader("Content-Type", "application/json");
        x.send(JSON.stringify(body || {}));
    }
    function reply(req, body) { post("/reply", Object.assign({ req: req }, body || {})); }

    // what the user set in Settings › Assistant travels with every request
    function settings() {
        var s = Os.settings;
        return { name: s.assistantName, effort: s.effort, reasoning: s.reasoning, modelFast: s.modelFast,
                 modelBalanced: s.modelBalanced, askBeforeRisky: s.askBeforeRisky, trust: s.appTrust, jevKey: s.jevKey };
    }
    function ask(text, done) { post("/ask", { text: text, settings: settings() }, function (code, r) { done(code, r); }); }
    function pause(on) { post("/pause", { on: on }); }
    function stop() { post("/stop", {}); }
    function signInPuter(cb) { post("/puter/signin", {}, function (code, r) { if (cb) cb(code === 200, r); }); }
    function signOutPuter() { post("/puter/signout", {}, function () { Os.settings.puterUser = ""; refresh(); }); }

    function hello() {
        // Firelamp's own apps; the dock's others (Files, Web, Terminal…) open real Linux apps,
        // which the agent finds and drives like any other installed app
        var w = Os.root ? Os.root.Window.window : null, external = w && w.external && !Os.demo ? w.external : [];
        var apps = Os.desktop ? Object.keys(Os.desktop.registry).filter(function (k) { return k !== "assistant" && k !== "about" && external.indexOf(k) < 0; })
                                     .map(function (k) { return { id: k, title: Os.desktop.registry[k].title }; }) : [];
        post("/hello", { apps: apps }, function (code, r) {
            link.up = code === 200;
            if (r) { link.status = r; if (r.puter_user !== undefined) Os.settings.puterUser = r.puter_user; }
        });
    }
    function refresh() {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return;
            link.up = x.status === 200;
            if (x.status === 200) { var r = JSON.parse(x.responseText); link.status = r; Os.settings.puterUser = r.puter_user || ""; }
        };
        x.open("GET", base + "/status"); x.send();
    }

    // ---- the event stream ----
    function listen() {
        var x = new XMLHttpRequest();
        poll = x;
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE || x !== link.poll) return;
            link.poll = null; watchdog.stop();
            try {
                if (x.status !== 200) {
                    // not running (yet): try again shortly, and say hello when it's back
                    if (link.up) agent.lost();
                    link.up = false; link.last = -1; relisten.interval = 3000;
                    return;
                }
                var r = JSON.parse(x.responseText);
                if (!link.up || link.last < 0) { link.up = true; hello(); }
                if (link.last >= 0) r.events.forEach(link.handle);
                link.last = r.last;
                relisten.interval = 10;
            } catch (err) {
                console.warn("AgentLink:", err);
                relisten.interval = 1000;
            } finally {
                relisten.start();
            }
        };
        x.open("GET", base + "/events?after=" + last); x.send();
        watchdog.restart();
    }
    property var poll: null
    // a poll that never comes back (the agent was killed mid-answer): drop it and ask again
    Timer { id: watchdog; interval: 40000; onTriggered: { var x = link.poll; link.poll = null; if (x) x.abort(); link.up = false; link.last = -1; relisten.interval = 500; relisten.start(); } }
    Timer { id: relisten; onTriggered: link.listen() }
    // settings the agent picks its brain by: tell it as soon as they change, so Settings shows the truth
    Timer { id: pushConfig; interval: 600; onTriggered: link.post("/config", link.settings(), function () { link.refresh(); }) }
    Connections {
        target: Os.settings
        function onEffortChanged() { pushConfig.restart(); }
        function onReasoningChanged() { pushConfig.restart(); }
        function onModelFastChanged() { pushConfig.restart(); }
        function onModelBalancedChanged() { pushConfig.restart(); }
        function onJevKeyChanged() { pushConfig.restart(); }
        function onAssistantNameChanged() { pushConfig.restart(); }
    }
    Component.onCompleted: Qt.callLater(listen)

    function handle(e) {
        var a = agent;
        switch (e.kind) {
        case "start": return a.realStart(e);
        case "say":
            Os.say(e.text);
            // the conversation isn't open (closed mid-task): the answer still has to reach you
            if (!Os.desktop || !Os.desktop.get("assistant")) Os.toast("assistant", Os.name, e.text);
            return;
        case "think": if (a.real) { a.capsule.what = e.text; } return;
        case "plan": return a.realPlan(e);
        case "step": if (a.real && e.i < a.lines.length) a.milestone(e.i); return;
        case "point": return a.realPoint(e, function () { reply(e.req, { ok: true }); });
        case "press": if (a.real) a.cursor.click(function () { a.cursor.clearTarget(); }); return;
        case "busy": if (a.real) a.cursor.busy = e.on; return;
        case "opening": return a.realOpening(e, function () { reply(e.req, { ok: true }); });
        case "log": if (a.real) a.log(e.entry.kind, e.entry.title, e.entry.why, e.entry.app); return;
        case "ask": return a.realAsk(e, function (ok) { reply(e.req, { ok: ok }); });
        case "shell": return shellOp(e);
        case "paused": return a.realPaused(e.on);
        case "done": return a.realDone(e.how);
        case "puter": Os.settings.puterUser = e.user; Os.toast("assistant", "Signed in to Puter", "Your assistant can think now."); return refresh();
        case "needs": return Os.toast("assistant", "Your assistant needs a brain", "Sign in to Puter in Settings › Assistant.");
        }
    }

    // ---- the shell's own UI, for the agent: what it sees and what it does ----
    function shellOp(e) {
        if (e.op === "snapshot") {
            var list = Tree.nodes(Os.root), groups = {}, order = [];
            var own = Os.suggestions.map(function (sg) { return sg.text; }).concat(["Ask " + Os.name, "Assistant status", "Ask"]);
            snap = list;
            for (var i = 0; i < list.length; i++) {
                var n = list[i];
                // not its own chat, its own suggestions or the home widgets' frames
                if (n.app === "assistant" || n.app === "system" || n.role === "widget" || own.indexOf(n.name) >= 0) continue;
                if (!groups[n.app]) { groups[n.app] = []; order.push(n.app); }
                var t = n.item.aiText ? String(n.item.aiText()).slice(0, 200) : "";
                groups[n.app].push({ i: i, name: n.name, role: n.role, text: t });
            }
            var f = Os.desktop.focused;
            reply(e.req, { windows: order.map(function (app) {
                var w = Os.desktop.get(app);
                return { app: app, title: w ? w.title : app === "dock" ? "Dock" : app === "menubar" ? "Menu bar" : app === "desktop" ? "Home" : app,
                         active: !!(f && f.app && f.app.id === app), nodes: groups[app] };
            }) });
            return;
        }
        agent.realShell(e, snap, function (ok, err) { reply(e.req, { ok: ok, error: err || "" }); });
    }

    // the AI layer: a click-through window above every app, so the fire cursor shows over real apps
    function ensureLayer() {
        if (aiLayer) return aiLayer;
        var tries = Qt.platform.pluginName === "wayland" ? ["AiLayerShell.qml", "AiLayer.qml"] : ["AiLayer.qml"];
        for (var i = 0; i < tries.length && !aiLayer; i++) {
            var c = Qt.createComponent(tries[i]);
            if (c.status === Component.Ready) aiLayer = c.createObject(null);
        }
        return aiLayer;
    }
}
