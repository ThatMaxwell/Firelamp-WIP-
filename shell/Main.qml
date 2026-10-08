// Firelamp OS desktop shell. Run with Qt's `qml` tool:  qml shell/Main.qml
// Flags (after `--`): --nosplash  --name=…  --reset  --still  --windowed
import QtQuick
import QtQuick.Window
import "components"
import "js/art.js" as Art

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
        { id: "photos", title: "Photos", icon: "photos", src: "Photos", w: 760, h: 520 },
        { id: "music", title: "Music", icon: "music", src: "Music", w: 340, h: 560 },
        { id: "settings", title: "System Settings", icon: "settings", src: "Settings", w: 720, h: 560 },
        { id: "about", title: "About Firelamp OS", icon: "assistant", src: "About", w: 360, h: 480, noDock: true }
    ]

    function launch(id) {
        if (id === "downloads") id = "files";
        if (id === "trash") return;
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
            Component.onCompleted: {
                var r = {};
                win.apps.forEach(function (a) { r[a.id] = Object.assign({ source: Qt.resolvedUrl("apps/" + a.src + ".qml") }, a); });
                registry = r;
            }
        }

        Dock {
            id: dock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: screen.booted ? 7 : -110
            Behavior on anchors.bottomMargin { SequentialAnimation { PauseAnimation { duration: 250 } NumberAnimation { duration: 900; easing.type: Easing.OutQuint } } }
            items: win.apps.filter(function (a) { return !a.noDock; }).map(function (a) { return { id: a.id, icon: a.icon, title: a.title }; })
                   .concat(["-", { id: "downloads", icon: "downloads", title: "Downloads" }, { id: "trash", icon: "trash", title: "Trash" }])
            aiActiveId: agent.mode !== "idle" ? "assistant" : ""
            onLaunch: (id) => win.launch(id)
        }

        TopBar {
            id: bar; width: parent.width; menuLayer: menuLayer
            y: screen.booted ? 0 : -height
            Behavior on y { SequentialAnimation { PauseAnimation { duration: 150 } NumberAnimation { duration: 700; easing.type: Easing.OutQuint } } }
        }
    }

    // ---- everything above the desktop: the AI's own layer ----
    Capsule {
        id: capsule
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.menubarH + 12
        z: 20
    }
    TimelinePanel {
        id: timeline
        x: parent.width - width - 12
        y: Theme.menubarH + 10
        height: parent.height - Theme.menubarH - 110
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
             apps: win.apps.filter(function (a) { return !a.noDock && a.id !== "assistant"; }) }
    // clicking anywhere else closes Control Center
    MouseArea { anchors.fill: parent; z: 56; enabled: control.open; onPressed: control.open = false }
    ControlCenter { id: control; z: 57; x: parent.width - width - 8; y: Theme.menubarH + 6 }
    Item { id: menuLayer; anchors.fill: parent; z: 60
        MouseArea { anchors.fill: parent; enabled: bar.menu !== null; onPressed: bar.closeMenu() } }
    NameCard { id: nameCard; z: 70; onDone: { screen.booted = true; helloToast.start(); } }
    Timer { id: helloToast; interval: 1500; onTriggered: Os.toast("assistant", "Say hi to " + Os.name, "Click its icon in the dock, or press Alt+Space to ask it anything.") }
    Splash {
        anchors.fill: parent; z: 80
        visible: !win.flag("nosplash")
        onFinished: { if (!Os.settings.assistantName) nameCard.shown = true; else screen.booted = true; }
    }

    Agent { id: agent; cursor: cursor; capsule: capsule; permission: permission; ghost: ghost }

    Connections {
        target: Os
        function onSubmit(t) { agent.handle(t); }
        function onTrashFull() { dock.trashIcon = Art.icon("trash", true); }
        function onAskOpen() { askBar.open(); }
        function onControlToggle() { control.open = !control.open; }
    }

    Shortcut { sequences: ["Esc"]; context: Qt.ApplicationShortcut
        onActivated: { if (askBar.shown) askBar.close(); else if (control.open) control.open = false; else if (bar.menu) bar.closeMenu(); else if (agent.mode !== "idle") agent.stop(); else if (timeline.open) timeline.open = false; } }
    Shortcut { sequences: ["Ctrl+Space"]; context: Qt.ApplicationShortcut; onActivated: agent.togglePause() }
    Shortcut { sequences: ["Alt+Space", "Ctrl+K"]; context: Qt.ApplicationShortcut; onActivated: askBar.open() }
    Shortcut { sequences: ["Ctrl+Alt+V"]; context: Qt.ApplicationShortcut; onActivated: Os.vision = !Os.vision }
    Shortcut { sequences: ["Ctrl+Alt+T"]; context: Qt.ApplicationShortcut; onActivated: Os.timelineToggle(undefined) }
    Shortcut { sequences: ["Ctrl+W"]; context: Qt.ApplicationShortcut; onActivated: desktop.closeFocused() }
    Shortcut { sequences: ["Ctrl+M"]; context: Qt.ApplicationShortcut; onActivated: desktop.minimizeFocused() }

    Component.onCompleted: {
        if (flag("reset")) Os.settings.assistantName = "";
        if (opt("name")) Os.settings.assistantName = opt("name");
        Os.root = screen; Os.desktop = desktop; Os.dock = dock; Os.agent = agent; Os.cursor = cursor;
        if (flag("nosplash")) { if (!Os.settings.assistantName) nameCard.shown = true; else screen.booted = true; }
    }
}
