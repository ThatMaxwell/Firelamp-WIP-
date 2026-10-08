#!/usr/bin/env python3
"""Render the Firelamp SDDM theme outside SDDM, with stand-in sddm/userModel/sessionModel objects.

    xvfb-run -a -s "-screen 0 1440x900x24" python3 tools/sddm_preview.py OUTDIR

Writes login.png (as it opens), login-sessions.png (session list open) and
login-failed.png (after a wrong password).
"""
import sys
from pathlib import Path
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer, QUrl, Qt, QPoint, QEvent
from PySide6.QtGui import QGuiApplication, QStandardItemModel, QStandardItem, QMouseEvent, QKeyEvent
from PySide6.QtQuick import QQuickView

ROOT = Path(__file__).resolve().parent.parent
THEME = ROOT / "iso/profile/airootfs/usr/share/sddm/themes/firelamp"
out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)


class Model(QStandardItemModel):
    def __init__(self, roles, rows, last):
        super().__init__()
        self._roles = {Qt.UserRole + i + 1: r.encode() for i, r in enumerate(roles)}
        self.setItemRoleNames(self._roles)
        for row in rows:
            it = QStandardItem()
            for i, v in enumerate(row):
                it.setData(v, Qt.UserRole + i + 1)
            self.appendRow(it)
        self._last = last

    def _get_last(self):
        return self._last
    lastIndex = Property(int, _get_last, constant=True)
    lastUser = Property(str, lambda self: "carrot", constant=True)


class Sddm(QObject):
    loginFailed = Signal()
    loginSucceeded = Signal()
    canReboot = Property(bool, lambda self: True, constant=True)
    canPowerOff = Property(bool, lambda self: True, constant=True)

    @Slot(str, str, int)
    def login(self, user, password, session):
        QTimer.singleShot(250, self.loginFailed.emit)

    @Slot()
    def reboot(self): pass

    @Slot()
    def powerOff(self): pass


class Keyboard(QObject):
    capsLock = Property(bool, lambda self: False, constant=True)


app = QGuiApplication(sys.argv)
view = QQuickView()
sessions = Model(["name", "file", "comment"], [
    ["KDE Plasma", "plasma.desktop", ""], ["GNOME", "gnome.desktop", ""],
    ["Hyprland", "hyprland.desktop", ""], ["niri", "niri.desktop", ""]], 0)
users = Model(["name", "realName", "icon"], [["carrot", "Carrot", ""]], 0)
ctx = view.rootContext()
sddm, kb = Sddm(), Keyboard()
ctx.setContextProperty("sddm", sddm)
ctx.setContextProperty("sessionModel", sessions)
ctx.setContextProperty("userModel", users)
ctx.setContextProperty("config", {"defaultSession": "plasma"})
ctx.setContextProperty("keyboard", kb)
view.setResizeMode(QQuickView.SizeRootObjectToView)
view.setSource(QUrl.fromLocalFile(str(THEME / "Main.qml")))
if view.status() == QQuickView.Error:
    sys.exit("\n".join(e.toString() for e in view.errors()))
view.resize(1440, 900)
view.show()


def click(x, y):
    for t in (QEvent.MouseButtonPress, QEvent.MouseButtonRelease):
        QGuiApplication.sendEvent(view, QMouseEvent(t, QPoint(x, y), view.mapToGlobal(QPoint(x, y)), Qt.LeftButton, Qt.LeftButton, Qt.NoModifier))


def shot(name):
    view.grabWindow().save(str(out / f"{name}.png"))


def key(code, text=""):
    for t in (QEvent.KeyPress, QEvent.KeyRelease):
        QGuiApplication.sendEvent(view, QKeyEvent(t, code, Qt.NoModifier, text))


def type_text(s):
    for ch in s:
        key(0, ch)


QTimer.singleShot(800, lambda: shot("login"))
QTimer.singleShot(900, lambda: click(40, 900 - 32))
QTimer.singleShot(1500, lambda: shot("login-sessions"))
QTimer.singleShot(1600, lambda: click(40, 900 - 32))
QTimer.singleShot(1900, lambda: type_text("hunter2"))
QTimer.singleShot(2100, lambda: shot("login-typed"))
QTimer.singleShot(2200, lambda: key(Qt.Key_Return))
QTimer.singleShot(3300, lambda: shot("login-failed"))
QTimer.singleShot(3400, lambda: (view.setSource(QUrl()), app.quit()))
app.exec()
