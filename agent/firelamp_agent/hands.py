"""The hands: act on real apps through the same accessibility tree the eyes read.

Preferred, because they work on X11 and Wayland alike and never miss:
    press   AT-SPI Action (the element's own "press"/"click"/"activate")
    type    AT-SPI EditableText (text goes straight into the field, at the caret)
Keyboard and pointer fallbacks, for things with no accessible action (terminals, shortcuts):
    X11      xdotool, else AT-SPI's synthetic key events
    Wayland  ydotool (needs ydotoold); without it, keys report that they can't be pressed
Apps are launched from their .desktop entries, the way the app menu does it.
"""
import configparser
import glob
import os
import re
import shlex
import shutil
import subprocess
import time

import gi

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi  # noqa: E402

from .eyes import _safe

PRESS_ORDER = ("press", "click", "activate", "jump", "toggle", "open", "select", "expand or contract", "showmenu")
WAYLAND = bool(os.environ.get("WAYLAND_DISPLAY"))


class HandsError(Exception):
    pass


def press(node):
    names = node.actions or []
    idx = None
    for want in PRESS_ORDER:
        if want in names:
            idx = names.index(want)
            break
    if idx is None and names:
        idx = 0
    if idx is not None:
        ok = _safe(lambda: Atspi.Action.do_action(node.acc, idx), False)
        if ok:
            return "pressed"
    # no action: list items and tabs can be selected through their parent
    parent = _safe(node.acc.get_parent)
    if parent is not None and _safe(parent.get_selection_iface):
        i = _safe(node.acc.get_index_in_parent, -1)
        if i >= 0 and _safe(lambda: Atspi.Selection.select_child(parent, i), False):
            return "selected"
    if node.bounds:
        x, y, w, h = node.bounds
        click_at(x + w // 2, y + h // 2)
        return "clicked"
    raise HandsError("it has no action I can press and no position to click")


def focus(node):
    _safe(lambda: Atspi.Component.grab_focus(node.acc), False)


def set_text(node, text, replace=False, progress=None, cancelled=None):
    """Type into an editable element. Text arrives in small bursts so you can watch it being
    written; `progress(done, total)` is called as it goes and `cancelled()` can stop it."""
    if not node.editable or not _safe(node.acc.get_editable_text_iface):
        raise HandsError("not editable")
    acc = node.acc
    focus(node)
    if replace:
        n = _safe(lambda: Atspi.Text.get_character_count(acc), 0) or 0
        _safe(lambda: Atspi.EditableText.delete_text(acc, 0, n), False)
        pos = 0
    else:
        pos = _safe(lambda: Atspi.Text.get_caret_offset(acc), -1)
        if pos is None or pos < 0:
            pos = _safe(lambda: Atspi.Text.get_character_count(acc), 0) or 0
    # about 2.5 s at most on screen, however long the text is
    chunk = max(1, len(text) // 90 + 1)
    i = 0
    while i < len(text):
        if cancelled and cancelled():
            return i
        part = text[i:i + chunk]
        if not _safe(lambda: Atspi.EditableText.insert_text(acc, pos + i, part, len(part.encode("utf-16-le")) // 2), False):
            if i == 0:
                raise HandsError("the field didn't accept text")
            break
        i += len(part)
        if progress:
            progress(i, len(text))
        time.sleep(0.025)
    _safe(lambda: Atspi.Text.set_caret_offset(acc, pos + i), False)
    return i


# ---- keyboard ----
KEYS = {"enter": "Return", "return": "Return", "esc": "Escape", "escape": "Escape", "tab": "Tab",
        "space": "space", "backspace": "BackSpace", "delete": "Delete", "del": "Delete", "up": "Up",
        "down": "Down", "left": "Left", "right": "Right", "home": "Home", "end": "End",
        "pageup": "Prior", "pagedown": "Next", "ctrl": "ctrl", "control": "ctrl", "alt": "alt",
        "shift": "shift", "super": "super", "meta": "super", "win": "super"}
# Linux input event codes, for ydotool
EVDEV = {"ctrl": 29, "shift": 42, "alt": 56, "super": 125, "Return": 28, "Escape": 1, "Tab": 15,
         "space": 57, "BackSpace": 14, "Delete": 111, "Up": 103, "Down": 108, "Left": 105, "Right": 106,
         "Home": 102, "End": 107, "Prior": 104, "Next": 109,
         **{c: k for c, k in zip("1234567890", range(2, 12))},
         **{c: k for c, k in zip("qwertyuiop", range(16, 26))},
         **{c: k for c, k in zip("asdfghjkl", range(30, 39))},
         **{c: k for c, k in zip("zxcvbnm", range(44, 51))},
         **{"F%d" % i: 58 + i for i in range(1, 11)}, "F11": 87, "F12": 88}


def parse_keys(spec):
    """'ctrl+s', 'Return', 'alt+F4' -> ['ctrl', 's'] with X keysym names."""
    out = []
    for p in re.split(r"\s*\+\s*", spec.strip()):
        if not p:
            continue
        low = p.lower()
        if low in KEYS:
            out.append(KEYS[low])
        elif re.fullmatch(r"f\d{1,2}", low):
            out.append(p.upper())
        elif len(p) == 1:
            out.append(p.lower())
        else:
            out.append(p)
    return out


def ydotool_ok():
    return bool(shutil.which("ydotool")) and (os.path.exists(os.environ.get("YDOTOOL_SOCKET", "/tmp/.ydotool_socket"))
                                               or os.path.exists("/run/ydotoold/socket"))


def keyboard_ready():
    if not WAYLAND:
        return True
    return ydotool_ok()


def press_keys(spec):
    keys = parse_keys(spec)
    if not keys:
        raise HandsError("no keys given")
    if not WAYLAND and shutil.which("xdotool"):
        subprocess.run(["xdotool", "key", "--clearmodifiers", "+".join(keys)], check=False, timeout=5)
        return
    if WAYLAND:
        if not ydotool_ok():
            raise HandsError("pressing keys on Wayland needs ydotoold running; I can still click and type into fields")
        codes = []
        for k in keys:
            if k not in EVDEV:
                raise HandsError("I don't know the key " + k)
            codes.append(EVDEV[k])
        seq = ["%d:1" % c for c in codes] + ["%d:0" % c for c in reversed(codes)]
        subprocess.run(["ydotool", "key", *seq], check=False, timeout=5)
        return
    # X11 without xdotool: AT-SPI can send one key at a time (no modifiers)
    if len(keys) == 1:
        sym = _keysym(keys[0])
        if sym and _safe(lambda: Atspi.generate_keyboard_event(sym, None, Atspi.KeySynthType.SYM), False):
            return
    raise HandsError("install xdotool to press key combinations")


def _keysym(name):
    try:
        import gi
        gi.require_version("Gdk", "3.0")
        from gi.repository import Gdk
        v = Gdk.keyval_from_name(name)
        return v or None
    except Exception:
        return None


def type_keys(text):
    """Type by keyboard (terminals and other places that don't take text directly)."""
    if not WAYLAND and shutil.which("xdotool"):
        subprocess.run(["xdotool", "type", "--delay", "18", "--", text], check=False, timeout=60)
        return
    if WAYLAND and ydotool_ok():
        subprocess.run(["ydotool", "type", "--key-delay", "12", "--", text], check=False, timeout=60)
        return
    if not WAYLAND and _safe(lambda: Atspi.generate_keyboard_event(0, text, Atspi.KeySynthType.STRING), False):
        return
    raise HandsError("I can't type by keyboard here" + (" (Wayland needs ydotoold)" if WAYLAND else ""))


def click_at(x, y):
    if not WAYLAND and shutil.which("xdotool"):
        subprocess.run(["xdotool", "mousemove", "--sync", str(int(x)), str(int(y)), "click", "1"], check=False, timeout=5)
        return
    if WAYLAND and ydotool_ok():
        subprocess.run(["ydotool", "mousemove", "--absolute", "-x", str(int(x)), "-y", str(int(y))], check=False, timeout=5)
        subprocess.run(["ydotool", "click", "0xC0"], check=False, timeout=5)
        return
    if not WAYLAND and _safe(lambda: Atspi.generate_mouse_event(int(x), int(y), "b1c"), False):
        return
    raise HandsError("no way to click a point on this session")


# ---- apps ----
def _desktop_dirs():
    dirs = [os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "applications")]
    for d in (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":"):
        dirs.append(os.path.join(d, "applications"))
    dirs.append("/var/lib/flatpak/exports/share/applications")
    dirs.append(os.path.expanduser("~/.local/share/flatpak/exports/share/applications"))
    return dirs


def installed_apps():
    """{name: {exec, file, generic, keywords}} for every app that shows up in a launcher."""
    apps, seen = {}, set()
    for d in _desktop_dirs():
        for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            base = os.path.basename(f)
            if base in seen:
                continue
            seen.add(base)
            cp = configparser.RawConfigParser(strict=False, interpolation=None)
            try:
                cp.read(f, encoding="utf-8")
                e = cp["Desktop Entry"]
            except Exception:
                continue
            if e.get("Type", "Application") != "Application" or e.get("NoDisplay", "").lower() == "true" \
                    or e.get("Hidden", "").lower() == "true" or not e.get("Exec"):
                continue
            name = e.get("Name", base[:-8])
            apps[name] = {"exec": e.get("Exec"), "file": f, "generic": e.get("GenericName", ""),
                          "keywords": e.get("Keywords", ""), "id": base[:-8]}
    return apps


def find_app(query, apps=None):
    apps = apps if apps is not None else installed_apps()
    q = query.lower().strip()
    best, score = None, 0
    for name, a in apps.items():
        n = name.lower()
        s = 0
        if n == q or a["id"].lower() == q or a["id"].lower().endswith("." + q):
            s = 100
        elif n.startswith(q):
            s = 70
        elif q in n:
            s = 50
        elif q in a["generic"].lower():
            s = 40
        elif q in a["keywords"].lower():
            s = 30
        elif q in a["exec"].lower().split(" ")[0]:
            s = 25
        if s > score:
            best, score = name, s
    return (best, apps[best]) if best else (None, None)


def launch(app):
    cmd = re.sub(r"%[fFuUdDnNickvm]", "", app["exec"]).replace("%%", "%")
    try:
        argv = shlex.split(cmd)
    except ValueError:
        argv = cmd.split()
    if not argv:
        raise HandsError("its launcher entry has no command")
    subprocess.Popen(argv, cwd=os.path.expanduser("~"), start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def activate_x11(pid):
    """Bring an app's window to the front on X11."""
    if shutil.which("xdotool"):
        r = subprocess.run(["xdotool", "search", "--onlyvisible", "--pid", str(pid)], capture_output=True, text=True, timeout=5)
        wids = r.stdout.split()
        if wids:
            subprocess.run(["xdotool", "windowactivate", wids[-1]], capture_output=True, timeout=5)
            return True
    if shutil.which("wmctrl"):
        r = subprocess.run(["wmctrl", "-lp"], capture_output=True, text=True, timeout=5)
        for line in r.stdout.splitlines():
            parts = line.split()
            if len(parts) > 2 and parts[2] == str(pid):
                subprocess.run(["wmctrl", "-ia", parts[0]], timeout=5)
                return True
    return False
