// Firelamp OS desktop shell. Run with Qt's `qml` tool:  qml shell/Main.qml
// Flags (after `--`): --nosplash  --name=…  --reset  --still  --windowed  --demo (sample content)
import QtQuick
import QtQuick.Window
import "components"
import "js/art.js" as Art
import "js/uitree.js" as Tree

Window {
    id: win
    readonly property var args: Qt.application.arguments
    function flag(f) { return args.indexOf("--" + f) >= 0; }
    function opt(k) { for (var i = 0; i < args.length; i++) if (args[i].indexOf("--" + k + "=") === 0) return args[i].slice(k.length + 3); return ""; }

    width: 1440; height: 900
    visibility: flag("windowed") ? Window.Windowed : Window.FullScreen
    visible: true
    color: Theme.bg
    title: "Firelamp OS"
    flags: Qt.FramelessWindowHint

    // a human answering the permission sheet (used by the recorder)
    property bool autoAllow: false

    readonly property var apps: [
        { id: "assistant", title: Os.name, icon: "assistant", src: "Assistant", w: 400, h: 620, place: "right" },
        { id: "files", title: "Files", icon: "files", src: "Files", w: 820, h: 520 },
        { id: "web", title: "Web", icon: "web", src: "Web", w: 940, h: 600 },
        { id: "mail", title: "Mail", icon: "mail", src: "Mail", w: 980, h: 600 },
        { id: "notes", title: "Notes", icon: "notes", src: "Notes", w: 820, h: 540 },
        { id: "terminal", title: "Terminal", icon: "terminal", src: "Terminal", w: 680, h: 440, titled: true },
        { id: "calendar", title: "Calendar", icon: "calendar", src: "Calendar", w: 780, h: 560 },
        { id: "photos", title: "Photos", icon: "photos", src: "Photos", w: 760, h: 528 },
        { id: "music", title: "Music", icon: "music", src: "Music", w: 340, h: 700 },
        { id: "settings", title: "System Settings", icon: "settings", src: "Settings", w: 800, h: 640 },
        { id: "about", title: "About Firelamp OS", icon: "assistant", src: "About", w: 360, h: 480, noDock: true }
    ]

    // On a real install these dock items open real Linux apps (Dolphin, your default browser,
    // Konsole running bash, Gwenview…); the windows in apps/ are the --demo stand-ins.
    readonly property var external: ["files", "web", "mail", "terminal", "calendar", "photos", "music"]
    function shows(a) { return Os.demo || external.indexOf(a.id) < 0 || !!Os.realApps[a.id]; }
    function launch(id) {
        if (id === "install") return Os.installOS();
        if (!Os.demo && (id === "downloads" || id === "trash")) return Os.openApp("files", id === "trash" ? "trash" : "Downloads");
        if (id === "downloads") id = "files";
        if (id === "trash") return;
        if (!Os.demo && external.indexOf(id) >= 0) return Os.openApp(id);
        if (desktop.registry[id]) desktop.open(id);
    }
    function ask(text) {
        var a = desktop.get("assistant");
        if (a && a.content) { desktop.focusWindow(a); a.content.submit(text); }
        else desktop.open("assistant", { prompt: text });
    }
    // used by the recorder and the "Try it" chips
    function demo(text) { ask(text); }
    // small hooks the recorder uses to film single interactions
    function closeTop() { desktop.closeFocused(); }
    function openAsk() { askBar.open(); }
    function toggleControl() { control.open = !control.open; }
    function notify(icon, title, body) { Os.toast(icon, title, body); }
    function sheet(on) {
        if (on) permission.ask({ app: "notes", title: "Delete the note “Groceries”?", body: "It moves to Recently Deleted for 30 days.",
                                 deny: "Keep It", allow: "Delete" }, function () {});
        else permission.answer(false);
    }
    // plan card: press Go, or pick an option (recorder)
    function go() { var a = desktop.get("assistant"); if (a && a.content && a.content.goPlan) a.content.goPlan(); }
    function pickPref(i) { var a = desktop.get("assistant"); if (a && a.content && a.content.pickPref) a.content.pickPref(i); }
    // test hook: make the agent unable to find a target, to show the stuck state
    function blind(name) { agent.blind = name; }
    function unlabelSend() { Os.demoUnlabeledSend = true; }
    function probeUnlabeled() { var l = Tree.unlabeled(screen); probeX = l.length ? l[0].bounds.x + l[0].bounds.w / 2 : -1; probeY = l.length ? l[0].bounds.y + l[0].bounds.h / 2 : -1; }
    function showMe() { agent.showMe(); }
    function togglePause() { agent.togglePause(); }
    function setTrust(app, v) { Os.setTrust(app, v); }
    function openSettings(pane) { var w = desktop.get("settings"); if (w && w.content) { desktop.focusWindow(w); w.content.pane = pane; } else desktop.open("settings", { pane: pane }); }
    function settingsScroll(y) { var s = desktop.get("settings"); if (s && s.content) s.content.scrollTo(y); }
    function timelineOpen(on) { Os.timelineToggle(on); }
    function expandActivity(i) { var n = 0; for (var j = 0; j < Os.activity.count; j++) if (Os.activity.get(j).kind === "milestone" && n++ === i) return Os.activity.setProperty(j, "expanded", true); }
    function editHome(on, tab) { if (tab) editHome.tab = tab; else if (on) editHome.tab = "Widgets"; Os.editingHome = on; bar.closeMenu(); }
    function sheetTab(t) { editHome.tab = t; }
    function addWidget(kind, size) { editHome.add(kind, size); }
    function desktopMenu(x, y) { desktop.contextMenu(x, y - Theme.menubarH); }
    function resetHome() { Os.resetHome(); }
    function setSetting(k, v) { Os.settings[k] = v; }
    function showPacks() { packsCard.picked = {}; packsCard.shown = true; }
    function exportLook(url) { editHome.exportLook(url); }
    function importLook(url) { editHome.importLook(url); }
    function pageStack(uid, i) { Os.pageStack(uid, i); }
    function showBrowsers() { browserCard.shown = true; }
    // recorder: activate a control by name, the way the AI would
    function probeTap(name) { var n = Tree.find(win.contentItem, { name: name }); if (n && n.item.aiActivate) n.item.aiActivate(); }
    property real probeX: -1
    property real probeY: -1
    function probe(name) { var n = Tree.find(win.contentItem, { name: name }); probeX = n ? n.bounds.x + n.bounds.w / 2 : -1; probeY = n ? n.bounds.y + n.bounds.h / 2 : -1; }
    function pointAt(x, y, label, w) {
        if (!cursor.shown) cursor.show(Qt.point(x - 260, y + 180));
        cursor.moveTo(x, y, function () { cursor.aim(label, function () { cursor.click(function () { cursor.clearTarget(); }); }); }, w || 40);
    }

    Item {
        id: screen
        anchors.fill: parent
        focus: true
        // boot: the desktop settles in from slightly closer, then the dock rises
        property bool booted: false
        opacity: booted ? 1 : 0
        scale: booted ? 1 : 1.05
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 1100; easing.type: Easing.OutQuint } }

        Wallpaper { anchors.fill: parent; still: win.flag("still") }

        Desktop {
            id: desktop
            anchors.fill: parent
            anchors.topMargin: Theme.menubarH
            onFocusChanged2: (w) => bar.appName = w ? w.title : "Desktop"
            onContextMenu: (x, y) => bar.openAt(x, y + Theme.menubarH, [
                { label: "Edit Home…", sc: "⌘E", action: function () { win.editHome(true); } },
                { label: "Change Wallpaper…", action: function () { win.editHome(true, "Wallpaper"); } }, "-",
                { label: "Display Settings…" } ])
            Component.onCompleted: {
                var r = {};
                win.apps.forEach(function (a) { r[a.id] = Object.assign({ source: Qt.resolvedUrl("apps/" + a.src + ".qml") }, a); });
                registry = r;
            }
        }

        Dock {
            id: dock
            // bottom, or turned onto the left or right edge about its centre (mirrored on the right)
            readonly property string side: Os.settings.dockSide
            transform: [ Rotation { origin.x: dock.width / 2; origin.y: dock.height / 2; angle: dock.turn },
                         Scale { origin.x: dock.width / 2; origin.y: dock.height / 2; xScale: dock.mirrored ? -1 : 1 } ]
            // autohide: tucked away until your pointer reaches its edge
            readonly property bool tucked: Os.settings.dockAutohide && !Os.editingHome && (side === "left" ? win.lastX < 0 || win.lastX > dock.height + 20
                                           : side === "right" ? win.lastX < 0 || win.lastX < win.width - (dock.height + 20)
                                           : win.lastY < 0 || win.lastY < win.height - (dock.height + 20))
            property real edge: screen.booted && !tucked ? 7 : -110
            Behavior on edge { SequentialAnimation { PauseAnimation { duration: 250 } NumberAnimation { duration: 900; easing.type: Easing.OutQuint } } }
            x: side === "left" ? edge + height / 2 - width / 2 : side === "right" ? parent.width - edge - height / 2 - width / 2 : (parent.width - width) / 2
            y: side === "bottom" ? parent.height - height - edge : (parent.height - height) / 2
            items: win.apps.filter(function (a) { return !a.noDock && win.shows(a); }).map(function (a) { return { id: a.id, icon: a.icon, title: a.title }; })
                   .concat(["-"], Os.live ? [{ id: "install", icon: "install", title: "Install Firelamp OS" }] : [],
                           [{ id: "downloads", icon: "downloads", title: "Downloads" }, { id: "trash", icon: "trash", title: "Trash" }])
            aiActiveId: agent.mode !== "idle" ? "assistant" : ""
            onLaunch: (id) => win.launch(id)
        }

        TopBar {
            id: bar; width: parent.width; menuLayer: menuLayer
            y: screen.booted ? 0 : -height
            Behavior on y { SequentialAnimation { PauseAnimation { duration: 150 } NumberAnimation { duration: 700; easing.type: Easing.OutQuint } } }
        }
    }

    EditHome { id: editHome; anchors.fill: parent; z: 30; home: desktop.home }

    // ---- everything above the desktop: the AI's own layer ----
    Capsule {
        id: capsule
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.menubarH + 12
        z: 20
    }
    Toasts { x: parent.width - width - 14; y: Theme.menubarH + 12; z: 21 }

    Image {
        id: ghost
        objectName: "ghost"
        sourceSize: Qt.size(104, 104)
        z: 39
        visible: false
        opacity: 0.85
        x: cursor.px - width / 2; y: cursor.py - height / 2 + 6
        rotation: -4
        property bool aiHidden: true
    }
    VisionOverlay { target: screen; z: 35 }
    FireCursor { id: cursor; z: 40 }
    PermissionSheet { id: permission; objectName: "permission"; z: 50; onShownChanged: if (shown && win.autoAllow) allowLater.start() }
    Timer { id: allowLater; interval: 1700; onTriggered: permission.answer(true) }
    AskBar { id: askBar; z: 55; onGo: (t) => win.ask(t); onLaunch: (id) => win.launch(id)
             apps: win.apps.filter(function (a) { return !a.noDock && a.id !== "assistant" && win.shows(a); }) }
    // clicking anywhere else closes Control Center
    MouseArea { anchors.fill: parent; z: 56; enabled: control.open; onPressed: control.open = false }
    ControlCenter { id: control; z: 57; x: parent.width - width - 8; y: Theme.menubarH + 6 }
    Item { id: menuLayer; anchors.fill: parent; z: 60
        MouseArea { anchors.fill: parent; enabled: bar.menu !== null; onPressed: bar.closeMenu() } }
    // after naming, the desktop isn't empty: the Assistant is open with what it noticed
    NameCard { id: nameCard; z: 70; onDone: { if (!Os.settings.packsAsked) packsCard.shown = true; else if (!Os.settings.browserAsked) browserCard.shown = true; else { screen.booted = true; openAssistant.start(); } } }
    PacksCard { id: packsCard; z: 71; onDone: { if (!Os.settings.browserAsked) browserCard.shown = true; else { screen.booted = true; openAssistant.start(); } } }
    BrowserCard { id: browserCard; z: 72; onDone: { screen.booted = true; openAssistant.start(); } }
    Timer { id: openAssistant; interval: 900; onTriggered: win.launch("assistant") }
    Splash {
        anchors.fill: parent; z: 80
        visible: !win.flag("nosplash")
        onFinished: { if (!Os.settings.assistantName) nameCard.shown = true; else screen.booted = true; }
    }

    Agent { id: agent; objectName: "agent"; cursor: cursor; capsule: capsule; permission: permission; ghost: ghost }

    // Your own mouse. When it moves into the window the AI is working in, the AI pauses
    // itself; you get the window back without hunting for a button.
    property real lastX: -1
    property real lastY: -1
    property real inWork: 0
    function userMoved(x, y) {
        var d = lastX < 0 ? 0 : Math.abs(x - lastX) + Math.abs(y - lastY);
        lastX = x; lastY = y;
        if (agent.mode !== "running" || !agent.workApp) { inWork = 0; return; }
        var w = desktop.get(agent.workApp);
        if (!w || !w.visible) return;
        var p = w.mapToItem(null, 0, 0);
        if (x >= p.x && y >= p.y && x <= p.x + w.width && y <= p.y + w.height) {
            inWork += d;
            if (inWork > 24) { inWork = 0; agent.autoPause(w.title); }
        } else inWork = 0;
    }
    Item {
        anchors.fill: parent; z: 90
        HoverHandler { id: userHover; onPointChanged: win.userMoved(point.position.x, point.position.y) }
    }
    // "Show me": while the AI is stuck, your next click in its window points at the thing
    MouseArea {
        anchors.fill: parent; z: 19
        enabled: agent.mode === "teaching"
        cursorShape: Qt.PointingHandCursor
        onPressed: (m) => {
            var t = agent.stuckOn ? agent.stuckOn.target : null;
            agent.taught(Tree.hit(screen, m.x, m.y, t ? t.app : ""));
        }
    }
    // the system pointer, drawn by the shell only when recording (the X grab hides the real one)
    UserPointer { visible: win.flag("pointer") && win.lastX >= 0; x: win.lastX; y: win.lastY; z: 95 }

    Connections {
        target: Os
        function onSubmit(t) { agent.handle(t); }
        // Super, rerouted from KWin through firelamp-desktops: our launcher, never Plasma's
        function onLauncherKey() {
            Os.ack("launcher-key");
            if (!screen.booted || Os.editingHome) return;
            if (askBar.shown) { askBar.close(); return; }
            Os.ack("launcher-open");
            win.raise(); win.requestActivate();
            Os.raiseShell();                  // Wayland ignores raise(); KWin does it for us
            askBar.open();
        }
        function onTrashFull() { dock.trashIcon = Art.icon("trash", true); }
        function onTrashEmpty() { dock.trashIcon = Art.icon("trash", false); }
        function onAskOpen() { askBar.open(); }
        function onControlToggle() { control.open = !control.open; }
        // Activity opens as the Assistant's second view
        function onTimelineToggle(on) {
            var a = desktop.get("assistant");
            if (!a) { a = desktop.open("assistant"); Qt.callLater(function () { if (a.content) a.content.showActivity(on === undefined ? true : on); }); return; }
            desktop.focusWindow(a);
            if (a.content) a.content.showActivity(on);
        }
    }

    Shortcut { sequences: ["Esc"]; context: Qt.ApplicationShortcut
        onActivated: { if (Os.editingHome) Os.editingHome = false; else if (askBar.shown) askBar.close(); else if (control.open) control.open = false; else if (bar.menu) bar.closeMenu(); else if (agent.mode !== "idle") agent.stop(); else { var a = desktop.get("assistant"); if (a && a.content && a.content.activity) a.content.activity = false; } } }
    Shortcut { sequences: ["Ctrl+Space"]; context: Qt.ApplicationShortcut; onActivated: agent.togglePause() }
    Shortcut { sequences: ["Alt+Space", "Ctrl+K"]; context: Qt.ApplicationShortcut; onActivated: askBar.open() }
    Shortcut { sequences: ["Ctrl+Alt+V"]; context: Qt.ApplicationShortcut; onActivated: Os.vision = !Os.vision }
    Shortcut { sequences: ["Ctrl+Alt+T"]; context: Qt.ApplicationShortcut; onActivated: Os.timelineToggle(undefined) }
    Shortcut { sequences: ["Meta+E"]; context: Qt.ApplicationShortcut; onActivated: win.editHome(!Os.editingHome) }
    Shortcut { sequences: ["Ctrl+W"]; context: Qt.ApplicationShortcut; onActivated: desktop.closeFocused() }
    Shortcut { sequences: ["Ctrl+M"]; context: Qt.ApplicationShortcut; onActivated: desktop.minimizeFocused() }

    Component.onCompleted: {
        if (flag("reset")) Os.settings.assistantName = "";
        if (opt("name")) Os.settings.assistantName = opt("name");
        if (flag("demo")) Os.demo = true;
        if (flag("demo-installs")) Os.demoInstalls = true;
        if (flag("live")) Os.live = true; else Os.checkLive();
        Os.listen();
        Os.root = screen; Os.desktop = desktop; Os.dock = dock; Os.agent = agent; Os.cursor = cursor;
        if (flag("nosplash")) { if (!Os.settings.assistantName) nameCard.shown = true; else screen.booted = true; }
    }
}
