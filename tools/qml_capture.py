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


def mouse(x, y, kind="move"):
    t = {"move": QEvent.MouseMove, "press": QEvent.MouseButtonPress, "release": QEvent.MouseButtonRelease}[kind]
    btn = Qt.NoButton if kind == "move" else Qt.LeftButton
    btns = Qt.LeftButton if kind == "press" else Qt.NoButton
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



if scene == "desktop":
    at(600, lambda: call("launch", "notes"))
    at(1300, lambda: call("launch", "assistant"))
    still("desktop", 2600)
    stop(2800)
elif scene == "apps":
    for i, a in enumerate(["terminal", "settings", "calendar", "web", "photos", "music", "about"]):
        at(500 + i * 2000, lambda a=a: call("launch", a))
        still("app-" + a, 1900 + i * 2000)
    stop(500 + 7 * 2000 + 300)
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
elif scene == "firstboot":
    start(200)
    still("firstboot-empty", 3600)
    for i, ch in enumerate("Juniper"):
        at(4200 + i * 170 + (60 if i % 3 == 1 else 0), lambda ch=ch: key(ch))
    still("firstboot-typed", 5800)
    at(6200, lambda: key(code=Qt.Key_Return))
    still("firstboot-signing", 7350)
    still("firstboot-signed", 8700)
    stop(12500)
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
