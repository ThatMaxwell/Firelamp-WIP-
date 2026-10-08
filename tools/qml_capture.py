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
from PySide6.QtCore import QObject, QTimer, QUrl, QPoint, Qt, QMetaObject, Q_ARG, QEvent, QPointF
from PySide6.QtGui import QGuiApplication, QMouseEvent
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
import shiboken6

ROOT = Path(__file__).resolve().parent.parent
scene, out = sys.argv[1], Path(sys.argv[2]) / sys.argv[1]
out.mkdir(parents=True, exist_ok=True)
for f in [*out.glob("*.png"), *out.glob("*.jpg")]:
    f.unlink()

app = QGuiApplication(["firelamp", "--nosplash", "--windowed", "--name=Pip", *sys.argv[3:]])
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


def start(at):
    # ffmpeg grabs the X display on its own, so recording never stalls Qt's animations
    def f():
        global ffmpeg
        g = win.geometry()
        ffmpeg = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-y", "-f", "x11grab", "-draw_mouse", "0", "-framerate", "15",
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


def at(ms, fn):
    QTimer.singleShot(ms, fn)



if scene == "desktop":
    at(600, lambda: call("launch", "notes"))
    at(1300, lambda: call("launch", "assistant"))
    still("desktop", 2600)
    stop(2800)
elif scene == "apps":
    for i, a in enumerate(["terminal", "settings", "calendar", "web", "photos", "music", "about"]):
        at(500 + i * 1500, lambda a=a: call("launch", a))
        still("app-" + a, 1400 + i * 1500)
    stop(500 + 7 * 1500 + 300)
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
    stop(1400 + int(sys.argv[3] if len(sys.argv) > 3 and sys.argv[3].isdigit() else 40000))
elif scene == "timeline":
    at(300, lambda: call("launch", "assistant"))
    at(800, lambda: call("demo", "Email Ana my meeting notes"))
    still("timeline", 30000)
    stop(30500)

sys.exit(app.exec())
