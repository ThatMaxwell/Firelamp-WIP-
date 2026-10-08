#!/usr/bin/env python3
"""Record the Qt shell without a VM: load shell/Main.qml, drive it, grab frames.

    xvfb-run -a -s "-screen 0 1440x900x24" python3 tools/qml_capture.py SCENE OUT_DIR

Scenes: desktop and apps (stills), dock, email, tidy, vision.
The recording lands in OUT_DIR/SCENE/video.mp4 (ffmpeg x11grab); stills in OUT_DIR.
Needs PySide6 (pip install PySide6). Rendering needs OpenGL, so run it under Xvfb,
not the offscreen platform (its software backend has no MultiEffect).
"""
import os, subprocess, sys
from pathlib import Path

os.environ.setdefault("QSG_RENDER_LOOP", "basic")
os.environ.update(QML_XHR_ALLOW_FILE_READ="1", QML_XHR_ALLOW_FILE_WRITE="1")
# frame-exact mode: animations advance exactly 1/60 s per rendered frame, and every frame is
# saved, so the clip is true 60 fps however slow the machine renders
EXACT = len(sys.argv) > 1 and sys.argv[1] == "motion"
if EXACT:
    os.environ["QSG_FIXED_ANIMATION_STEP"] = "1"
from PySide6.QtCore import QObject, QTimer, QUrl, QPoint, Qt, QMetaObject, Q_ARG, QEvent, QPointF
from PySide6.QtGui import QGuiApplication, QMouseEvent, QKeyEvent
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
import shiboken6

ROOT = Path(__file__).resolve().parent.parent
scene, out = sys.argv[1], Path(sys.argv[2]) / sys.argv[1]
out.mkdir(parents=True, exist_ok=True)
for f in [*out.glob("*.png"), *out.glob("*.jpg")]:
    f.unlink()

# first boot runs from scratch: splash, no name, then naming
base = ["firelamp", "--windowed", "--reset"] if scene == "firstboot" else ["firelamp", "--nosplash", "--windowed", "--name=Juniper"]
if scene in ("stuck", "autopause", "desktops", "edithome", "packs", "live", "browsers", "round2"):
    base.append("--pointer")
if scene in ("desktops", "packs", "browsers"):
    base.append("--demo-installs")
if scene == "live":
    base.append("--live")
app = QGuiApplication([*base, *sys.argv[3:]])
engine = QQmlApplicationEngine()
engine.warnings.connect(lambda ws: [print("QML:", w.toString(), file=sys.stderr) for w in ws])
engine.load(QUrl.fromLocalFile(str(ROOT / "shell" / "Main.qml")))
if not engine.rootObjects():
    sys.exit("failed to load Main.qml")
win = shiboken6.wrapInstance(shiboken6.getCppPointer(engine.rootObjects()[0])[0], QQuickWindow)
win.setProperty("autoAllow", True)



def call(fn, *args):
    QMetaObject.invokeMethod(win, fn, *[Q_ARG("QVariant", a) for a in args])


held = {"btn": Qt.NoButton}


def mouse(x, y, kind="move", button=Qt.LeftButton):
    t = {"move": QEvent.MouseMove, "press": QEvent.MouseButtonPress, "release": QEvent.MouseButtonRelease}[kind]
    if kind == "press":
        held["btn"] = button
    btn = Qt.NoButton if kind == "move" else button
    btns = held["btn"] if kind != "release" else Qt.NoButton
    if kind == "release":
        held["btn"] = Qt.NoButton
    ev = QMouseEvent(t, QPointF(x, y), QPointF(x, y), btn, btns, Qt.NoModifier)
    QGuiApplication.sendEvent(win, ev)


def still(name, at):
    def f():
        win.grabWindow().save(str(Path(sys.argv[2]) / f"{name}.png"))
    QTimer.singleShot(at, f)


ffmpeg = None


def when(name, prop, shot, delay):
    """Take a still `delay` ms after the item `name` first has `prop` true."""
    state = {"done": False}
    t = QTimer(app)

    def poll():
        o = win.findChild(QObject, name)
        if o is not None and o.property(prop) and not state["done"]:
            state["done"] = True
            t.stop()
            still(shot, delay)
    t.timeout.connect(poll)
    t.start(60)


def start(at, fps=15):
    # ffmpeg grabs the X display on its own, so recording never stalls Qt's animations
    def f():
        global ffmpeg
        g = win.geometry()
        ffmpeg = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-y", "-f", "x11grab", "-draw_mouse", "0", "-framerate", str(fps),
                                   "-video_size", f"{g.width()}x{g.height()}", "-i", f"{os.environ['DISPLAY']}+{g.x()},{g.y()}",
                                   "-c:v", "libx264", "-preset", "ultrafast", "-crf", "16", "-pix_fmt", "yuv420p", str(out / "video.mp4")],
                                  stdin=subprocess.PIPE)
    QTimer.singleShot(at, f)


def stop(at):
    def f():
        if ffmpeg:
            ffmpeg.communicate(b"q")
        app.quit()
    QTimer.singleShot(at, f)


def key(text="", code=0):
    for t in (QEvent.KeyPress, QEvent.KeyRelease):
        QGuiApplication.sendEvent(win, QKeyEvent(t, code or (ord(text.upper()) if text else 0), Qt.NoModifier, text))


def at(ms, fn):
    QTimer.singleShot(ms, fn)


def on(name, prop, value, fn, delay=0):
    """Run fn `delay` ms after item `name` first has prop == value."""
    t = QTimer(app)

    def poll():
        o = win.findChild(QObject, name)
        if o is not None and o.property(prop) == value:
            t.stop()
            QTimer.singleShot(delay, fn)
    t.timeout.connect(poll)
    t.start(40)


# ---- step runner: each step starts when the one before it ends ----
pos = {"x": 0, "y": 0}


def tap(x, y, button=Qt.LeftButton):
    mouse(x, y, "press", button); mouse(x, y, "release", button)


def glide_to(x, y, ms, then):
    glide(pos["x"], pos["y"], x, y, ms, lambda: (pos.update(x=x, y=y), then()))


def run(steps):
    if not steps:
        return
    step, rest = steps[0], steps[1:]
    nxt = lambda: run(rest)
    kind = step[0]
    if kind == "wait":
        QTimer.singleShot(step[1], nxt)
    elif kind == "still":
        still(step[1], 0); QTimer.singleShot(60, nxt)
    elif kind == "do":
        step[1](); nxt()
    elif kind == "tap":                    # ("tap", name): activate by name, no pointer
        call("probeTap", step[1]); nxt()
    elif kind == "point":                  # ("point", x, y, ms)
        glide_to(step[1], step[2], step[3], nxt)
    elif kind in ("click", "rclick", "drag", "find"):
        name, dx, dy = step[1], (step[2] if len(step) > 2 else 0), (step[3] if len(step) > 3 else 0)
        call("probe", name)
        x, y = win.property("probeX") + dx, win.property("probeY") + dy
        if x < 0:
            print("not found:", name, file=sys.stderr)
        if kind == "click":
            glide_to(x, y, 700, lambda: (tap(x, y), nxt()))
        elif kind == "find":
            glide_to(x, y, 700, nxt)
        elif kind == "drag":               # ("drag", name, dx, dy, tx, ty[, still]): a still while held
            tx, ty = step[4], step[5]
            held = step[6] if len(step) > 6 else None
            def let_go():
                mouse(x + tx, y + ty, "release"); pos.update(x=x + tx, y=y + ty); nxt()
            def at_end():
                if held:
                    QTimer.singleShot(300, lambda: (still(held, 0), QTimer.singleShot(200, let_go)))
                else:
                    let_go()
            glide_to(x, y, 700, lambda: (mouse(x, y, "press"), glide(x, y, x + tx, y + ty, 900, at_end)))


def finished(fn, delay=0):
    """Run fn `delay` ms after the agent has run a task and gone idle again."""
    on("agent", "mode", "running", lambda: on("agent", "mode", "idle", fn, delay))


def glide(x0, y0, x1, y1, ms, then=None):
    """Move the user's mouse along a straight line, like a hand would."""
    n = max(2, ms // 30)
    for i in range(n + 1):
        u = i / n
        u = u * u * (3 - 2 * u)
        QTimer.singleShot(i * 30, lambda u=u: mouse(x0 + (x1 - x0) * u, y0 + (y1 - y0) * u))
    if then:
        QTimer.singleShot(n * 30 + 30, then)



if scene == "desktop":
    at(600, lambda: call("launch", "notes"))
    at(1300, lambda: call("launch", "assistant"))
    still("desktop", 2600)
    stop(2800)
elif scene == "apps":
    # one window at a time on a clean desktop: each app is closed before the next opens
    for i, a in enumerate(["terminal", "settings", "calendar", "web", "photos", "music", "about"]):
        at(500 + i * 2400, lambda a=a: call("launch", a))
        still("app-" + a, 2100 + i * 2400)
        at(2300 + i * 2400, lambda: call("closeTop"))
    stop(500 + 7 * 2400 + 300)
elif scene == "dock":
    start(300)
    cx, y = 720, 900 - 40
    for i, x in enumerate(range(380, 1080, 14)):
        at(400 + i * 40, lambda x=x: mouse(x, y))
    at(400 + 50 * 40, lambda: mouse(720, 600))
    at(400 + 52 * 40, lambda: call("launch", "music"))
    stop(400 + 52 * 40 + 1800)
elif scene in ("email", "tidy", "vision"):
    prompt = {"email": "Email Ana my meeting notes", "tidy": "Tidy up my Downloads", "vision": "Show me what you see"}[scene]
    at(300, lambda: call("launch", "assistant"))
    start(900)
    at(1400, lambda: call("demo", prompt))
    if scene in ("email", "tidy"):
        still(scene + "-plan", 1400 + 3000)
        at(1400 + 3800, lambda: call("go"))
    if scene == "tidy":
        finished(lambda: call("timelineOpen", True), 1500)
        finished(lambda: call("expandActivity", 1), 2300)
        finished(lambda: still("activity", 0), 2900)
    if scene == "email":
        when("permission", "shown", "permission", 700)
    if scene == "tidy":
        when("ghost", "visible", "drag", 450)
    if scene == "vision":
        still("vision", 1400 + 5200)
    if os.environ.get("CAPTURE_EVERY"):     # review frames: a still every N ms
        n = int(os.environ["CAPTURE_EVERY"])
        for k in range(1, 40000 // n):
            still(f"{scene}-{k:02d}", 1400 + k * n)
    stop(1400 + int(sys.argv[3] if len(sys.argv) > 3 and sys.argv[3].isdigit() else 40000))
elif scene == "stuck":
    # Mail's Send is an icon with no accessible label: two tries, then it stops and asks you to show it
    at(300, lambda: call("launch", "assistant"))
    at(600, lambda: call("unlabelSend"))
    at(700, lambda: mouse(1300, 820))
    start(900)
    at(1400, lambda: call("demo", "Email Ana my meeting notes"))
    at(1400 + 3800, lambda: call("go"))
    on("agent", "mode", "stuck", lambda: still("stuck", 0), 1600)

    def teach():
        call("probeUnlabeled")
        x, y = win.property("probeX"), win.property("probeY")
        call("showMe")
        glide(1100, 760, x, y, 1100, lambda: (mouse(x, y, "press"), mouse(x, y, "release")))
        still("show-me", 900)
    on("agent", "mode", "stuck", teach, 2600)
    finished(lambda: stop(1200), 400)
elif scene == "autopause":
    # you reach into the window it's working in, and it steps back on its own
    at(300, lambda: call("launch", "assistant"))
    start(900)
    at(700, lambda: mouse(1300, 820))
    at(1400, lambda: call("demo", "Tidy up my Downloads"))
    at(1400 + 3800, lambda: call("go"))
    at(1400 + 9000, lambda: glide(1300, 820, 520, 420, 900))
    still("autopause", 1400 + 9000 + 1700)
    at(1400 + 9000 + 3600, lambda: call("togglePause"))
    stop(1400 + 9000 + 7000)
elif scene == "firstboot":
    start(200)
    still("firstboot-empty", 3600)
    for i, ch in enumerate("Juniper"):
        at(4200 + i * 170 + (60 if i % 3 == 1 else 0), lambda ch=ch: key(ch))
    still("firstboot-typed", 5300)
    still("firstboot-continue", 6900)
    at(7600, lambda: key(code=Qt.Key_Return))
    still("firstboot-signing", 8900)
    still("firstboot-signed", 10300)
    still("firstboot-after", 14200)
    stop(14600)
elif scene == "trust":
    # Settings › Assistant, scrolled to the per-app "when to ask" list
    at(300, lambda: call("launch", "settings"))
    at(1200, lambda: call("setTrust", "terminal", "all"))
    at(1300, lambda: call("setTrust", "web", "never"))
    at(1500, lambda: call("settingsScroll", 640))
    still("settings-trust", 2400)
    at(2500, lambda: (call("setTrust", "terminal", "risky"), call("setTrust", "web", "risky")))
    stop(2800)
elif scene == "desktops":
    # Settings › Desktops: Plasma is in use, Hyprland gets installed with one click
    at(300, lambda: call("openSettings", "Desktops"))
    at(400, lambda: mouse(1250, 820))
    still("desktops", 2000)
    start(2100)

    def press():
        call("probe", "Install Hyprland")
        x, y = win.property("probeX"), win.property("probeY")
        glide(1250, 820, x, y, 900, lambda: (mouse(x, y, "press"), mouse(x, y, "release"),
                                              QTimer.singleShot(500, lambda: glide(x, y, x + 140, y + 150, 700))))
    at(2400, lambda: call("settingsScroll", 640))
    at(3000, press)
    still("desktops-installing", 5600)
    still("desktops-installed", 11000)
    stop(11800)
elif scene == "edithome":
    # Edit home: right-click the desktop, windows slide away, move / add / resize widgets,
    # try a wallpaper and the dock size, then Done. Steps run one after another, so a slow
    # frame never lets two pointer moves overlap.
    for k, v in (("wallpaper", "graphite"), ("dockSize", 1), ("dockMag", 2), ("dockBacking", True)):
        call("setSetting", k, v)
    call("resetHome")
    at(300, lambda: call("launch", "notes"))
    at(700, lambda: call("launch", "photos"))
    at(1300, lambda: mouse(1180, 700))
    pos.update(x=1180, y=700)

    def typed(text):
        return [("do", lambda ch=ch: key(ch)) for ch in text]

    start(1400)
    at(1500, lambda: run([
        ("point", 720, 760, 600), ("do", lambda: tap(720, 760, Qt.RightButton)), ("wait", 700), ("still", "home-menu"),
        ("click", "Edit Home…"), ("wait", 1100), ("still", "edit-home"),
        # System moves from under Weather to the open space on the right
        ("drag", "system widget", -30, 10, 213, -171), ("wait", 500),
        ("click", "Search widgets"), ("wait", 300), *typed("photo"), ("wait", 400),
        ("click", "Add Photo frame widget"), ("wait", 600),
        # Up next grows from M to L
        ("drag", "Resize upnext widget", 0, 0, 10, 190), ("wait", 900), ("still", "edit-home-widgets"),
        ("click", "Wallpaper"), ("wait", 500), ("click", "Lamp wallpaper"), ("wait", 900), ("still", "edit-home-wallpaper"),
        ("click", "Dock & bar"), ("wait", 500), ("click", "Large"), ("wait", 900), ("still", "edit-home-dock"),
        ("click", "Medium"), ("wait", 400), ("click", "Done"), ("wait", 300), ("point", 1300, 640, 600), ("wait", 900),
        ("still", "home-after"), ("wait", 300),
        ("do", lambda: (call("setSetting", "wallpaper", "graphite"), call("resetHome"))), ("wait", 200),
        ("do", lambda: stop(0)),
    ]))
elif scene == "looks":
    # Edit home › Looks: each preset applies live; then a color of your own
    for k, v in (("look", "graphite"), ("accent", ""), ("winRadius", 12), ("dockSize", 1), ("dockMag", 2), ("wallpaper", "graphite")):
        call("setSetting", k, v)
    call("resetHome")
    at(300, lambda: call("launch", "notes"))
    at(900, lambda: call("editHome", True, "Looks"))
    steps = [("wait", 900), ("still", "looks-graphite")]
    for name in ("Paper", "Midnight", "Moss", "Studio"):
        steps += [("tap", name + " look"), ("wait", 700), ("still", "looks-" + name.lower())]
    steps += [("do", lambda: call("editHome", False, "")), ("wait", 800), ("still", "looks-studio-home"),
              ("do", lambda: call("editHome", True, "Looks")), ("wait", 600)]
    steps += [("tap", "Graphite look"), ("tap", "Blue color"), ("wait", 300), ("do", lambda: call("sheetTab", "Dock & bar")), ("wait", 700), ("still", "looks-accent"),
              ("do", lambda: call("editHome", False, "")), ("wait", 800), ("still", "looks-accent-home"),
              ("do", lambda: [call("setSetting", k, v) for k, v in (("look", "graphite"), ("accent", ""), ("winRadius", 12), ("dockSize", 1), ("dockMag", 2))]),
              ("wait", 100), ("do", lambda: stop(0))]
    at(1200, lambda: run(steps))
elif scene == "packs":
    # First boot's optional "What do you do?", then the same packs in Settings
    call("setSetting", "browserAsked", True)
    at(200, lambda: call("showPacks"))
    steps = [("wait", 900), ("still", "packs-firstboot-empty"),
             ("click", "Make"), ("wait", 250), ("click", "Play"), ("wait", 500), ("point", 900, 760, 500), ("wait", 300), ("still", "packs-firstboot"),
             ("click", "Continue"), ("wait", 1200), ("still", "packs-toast"),
             ("do", lambda: call("openSettings", "Packs")), ("wait", 900), ("click", "Dev pack", -200, 0), ("wait", 600),
             ("click", "Install Office pack"), ("point", 1240, 800, 600), ("wait", 800), ("still", "settings-packs"),
             ("do", lambda: (call("setSetting", "packsAsked", False), call("setSetting", "browserAsked", False))), ("wait", 100), ("do", lambda: stop(0))]
    at(400, lambda: run(steps))
elif scene == "browsers":
    # First boot's "Pick your browser": filter, search, pick Brave; then Settings › Browser
    def typed(text):
        return [("do", lambda ch=ch: key(ch)) for ch in text]
    at(200, lambda: call("showBrowsers"))
    start(300)
    steps = [("wait", 1000), ("still", "browser-firstboot"),
             ("click", "Show all browsers"), ("wait", 900), ("still", "browser-all"),
             ("click", "Private"), ("wait", 700), ("click", "Helium"), ("wait", 500), ("still", "browser-private"),
             ("click", "All"), ("wait", 300), ("click", "Search browsers"), ("wait", 200), *typed("bra"), ("wait", 700), ("still", "browser-search"),
             ("click", "Brave"), ("wait", 600), ("still", "browser-brave"),
             *[("do", lambda: key(code=Qt.Key_Backspace)) for _ in range(3)], ("wait", 600),
             ("click", "Use browser"), ("wait", 1200), ("still", "browser-toast"),
             ("wait", 600), ("do", lambda: call("closeTop")), ("wait", 500),
             ("do", lambda: call("openSettings", "Browser")), ("wait", 700), ("point", 1240, 800, 400), ("still", "settings-browser-installing"),
             ("wait", 4200), ("still", "settings-browser"),
             ("do", lambda: call("setSetting", "browserAsked", False)), ("wait", 100), ("do", lambda: stop(0))]
    at(400, lambda: (mouse(900, 760), pos.update(x=900, y=760), run(steps)))
elif scene == "round2":
    # Edit home round 2: stack two widgets, turn the stack, move the dock to the sides,
    # reorder the top bar, and round-trip a .firelamp-look file
    for k, v in (("wallpaper", "graphite"), ("dockSide", "bottom"), ("barOrder", ""), ("look", "graphite"), ("accent", ""), ("dockSize", 1), ("dockMag", 2)):
        call("setSetting", k, v)
    call("resetHome")
    look = str(Path(sys.argv[2]).resolve() / "Evening.firelamp-look")
    start(300)
    steps = [("do", lambda: (mouse(900, 600), pos.update(x=900, y=600))), ("wait", 400),
             ("do", lambda: call("editHome", True, "Widgets")), ("wait", 1000),
             # System (S) dropped on Weather (S): a stack
             ("drag", "system widget", 0, 0, 0, -176, "stack-drop"), ("wait", 900), ("still", "stack-made"),
             ("click", "Done"), ("wait", 600), ("point", 1100, 640, 500), ("wait", 500), ("still", "stack-home"),
             ("do", lambda: call("pageStack", 2, 0)), ("wait", 150), ("still", "stack-turning"), ("wait", 700), ("still", "stack-weather"),
             ("do", lambda: call("pageStack", 2, 1)), ("wait", 900),
             # the dock on the left, then the right
             ("do", lambda: call("editHome", True, "Dock & bar")), ("wait", 900), ("still", "dockbar-sheet"),
             ("click", "Left"), ("wait", 1400), ("still", "dock-left-sheet"),
             ("click", "Done"), ("wait", 900), ("point", 700, 500, 400), ("wait", 300), ("still", "dock-left"),
             ("do", lambda: call("setSetting", "dockSide", "right")), ("wait", 1400), ("still", "dock-right"),
             ("do", lambda: call("setSetting", "dockSide", "bottom")), ("wait", 1200),
             # the top bar: the clock moves to the front
             ("do", lambda: call("editHome", True, "Dock & bar")), ("wait", 900),
             ("drag", "Clock in the top bar", 0, 0, -190, 0, "bar-order-drag"), ("wait", 700), ("still", "bar-order"),
             ("do", lambda: call("editHome", True, "Looks")), ("wait", 800), ("still", "looks-share"),
             ("do", lambda: call("exportLook", "file://" + look)), ("wait", 500),
             ("do", lambda: call("setSetting", "barOrder", "")), ("wait", 300),
             ("do", lambda: call("importLook", "file://" + look)), ("wait", 1200), ("still", "looks-imported"),
             ("do", lambda: call("editHome", False, "")),
             ("do", lambda: [call("setSetting", k, v) for k, v in (("dockSide", "bottom"), ("barOrder", ""), ("myLooks", "[]"))]),
             ("do", lambda: call("resetHome")), ("wait", 200), ("do", lambda: stop(0))]
    at(400, lambda: run(steps))
elif scene == "live":
    # the live ISO: Install Firelamp OS in the dock and the Firelamp menu
    steps = [("wait", 1200), ("find", "Install Firelamp OS"), ("wait", 900), ("still", "live-dock"),
             ("click", "Firelamp menu"), ("wait", 600), ("still", "live-menu"),
             ("point", 900, 600, 500), ("do", lambda: tap(900, 600)), ("wait", 300),
             ("click", "Install Firelamp OS"), ("wait", 900), ("still", "live-toast"), ("do", lambda: stop(0))]
    at(300, lambda: (mouse(900, 600), pos.update(x=900, y=600), run(steps)))
elif scene == "walls":
    # every wallpaper we ship, full screen, with the home widgets on top
    names = ["graphite", "dynamic", "hills", "lamp", "fog", "dune", "night", "deep-field"]
    steps = [("wait", 900)]
    for n in names:
        steps += [("do", lambda n=n: call("setSetting", "wallpaper", n)), ("wait", 700), ("still", "wall-" + n)]
    steps += [("do", lambda: call("setSetting", "wallpaper", "lamp")), ("do", lambda: call("editHome", True, "Wallpaper")), ("wait", 800), ("still", "edit-home-wallpapers"),
              ("do", lambda: call("editHome", False, "")), ("do", lambda: call("setSetting", "wallpaper", "graphite")), ("wait", 100), ("do", lambda: stop(0))]
    at(300, lambda: run(steps))
elif scene == "effort":
    # Settings › Assistant: the effort picker, Jev (Instant) by default
    at(300, lambda: call("launch", "settings"))
    at(1400, lambda: call("settingsScroll", 82))
    still("settings-effort", 2300)
    stop(2600)
elif scene == "panels":
    at(300, lambda: call("launch", "notes"))
    at(1200, lambda: call("openAsk"))
    still("askbar-empty", 1700)
    for i, ch in enumerate("mu"):
        at(2000 + i * 160, lambda ch=ch: key(ch))
    still("askbar", 2700)
    at(3000, lambda: key(code=Qt.Key_Escape))
    at(3400, lambda: call("toggleControl"))
    still("control-center", 4000)
    at(4300, lambda: call("toggleControl"))
    at(4600, lambda: call("notify", "mail", "Ana Souza", "Thanks! Got the notes. See you at the sync tomorrow."))
    at(4900, lambda: call("notify", "calendar", "Launch sync in 15 minutes", "Hearth room · 10:00"))
    still("toasts", 5700)
    stop(6000)
elif scene == "motion":
    # a 60 fps proof of the house curves: window open/close, sheet in/out, a cursor path.
    # Steps are scheduled in animation time (frames), not wall time, so nothing overlaps.
    plan = [(400, "launch", "notes"), (1500, "closeTop"), (2300, "launch", "notes"), (3400, "sheet", True),
            (4700, "sheet", False), (5600, "pointAt", 380, 280, "Groceries", 240),
            (7000, "pointAt", 1000, 172, "Search", 110), (8400, "pointAt", 390, 214, "Launch sync — Oct 7", 240)]
    end_ms = 10200
    frames = {"n": 0, "on": False}

    def grab():
        if not frames["on"]:
            return
        frames["n"] += 1
        win.grabWindow().save(str(out / f"f{frames['n']:05d}.png"))
        t = frames["n"] * 1000 / 60
        while plan and plan[0][0] <= t:
            step = plan.pop(0)
            call(step[1], *step[2:])
        if t >= end_ms:
            frames["on"] = False
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-framerate", "60", "-i", str(out / "f%05d.png"),
                            "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p", str(out / "video.mp4")])
            app.quit()
            return
        win.update()
    win.frameSwapped.connect(grab, Qt.QueuedConnection)
    at(600, lambda: (frames.update(on=True), win.update()))
elif scene == "timeline":
    at(300, lambda: call("launch", "assistant"))
    at(800, lambda: call("demo", "Email Ana my meeting notes"))
    still("timeline", 30000)
    stop(30500)

sys.exit(app.exec())
