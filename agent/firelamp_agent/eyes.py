"""The eyes: the live AT-SPI2 accessibility tree, turned into a short numbered list.

No screenshots. Every app on the desktop publishes its windows, buttons, menus and text fields
over AT-SPI2 (the screen-reader bus), with roles, names, states and exact bounds. `snapshot()`
walks it and writes the part that matters as compact lines the brain can read:

    [w2] Kate: "Untitled — Kate" (active)
      [14] menu "File"
      [31] push button "Save"
      [40] text "Document" editable focused = "Dear Ana,…"

Each [n] maps back to the live element, so the hands act on exactly what the brain picked.
"""
import os
import time

import gi

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi  # noqa: E402

S = Atspi.StateType
R = Atspi.Role

# Roles that only group other things; unnamed ones are flattened away.
GROUPS = {R.FILLER, R.PANEL, R.SECTION, R.SCROLL_PANE, R.VIEWPORT, R.LAYERED_PANE, R.SPLIT_PANE,
          R.GLASS_PANE, R.ROOT_PANE, R.UNKNOWN, R.REDUNDANT_OBJECT, R.INTERNAL_FRAME, R.FORM,
          R.GROUPING, R.BLOCK_QUOTE, R.TABLE_ROW, R.LIST, R.TREE, R.TABLE, R.TREE_TABLE, R.TOOL_BAR,
          R.STATUS_BAR, R.PAGE_TAB_LIST, R.MENU_BAR, R.EMBEDDED, R.DOCUMENT_FRAME, R.PARAGRAPH,
          R.LANDMARK, R.ARTICLE, R.SCROLL_BAR, R.SEPARATOR, R.IMAGE, R.CANVAS, R.DRAWING_AREA}
# Roles worth showing even without an action interface, when they carry a name.
READABLE = {R.LABEL, R.STATIC, R.HEADING, R.TEXT, R.ENTRY, R.PASSWORD_TEXT, R.DOCUMENT_TEXT,
            R.TERMINAL, R.ALERT, R.NOTIFICATION, R.STATUS_BAR, R.TOOL_TIP, R.CAPTION, R.LINK,
            R.PAGE_TAB, R.LIST_ITEM, R.TABLE_CELL, R.TREE_ITEM, R.ICON, R.DIALOG, R.IMAGE}
WINDOWS = {R.FRAME, R.WINDOW, R.DIALOG, R.ALERT, R.FILE_CHOOSER, R.FILLER, R.COLOR_CHOOSER}

MAX_NODES = 260          # per window
MAX_DEPTH = 30
INVALID = -2147483648


class Node:
    __slots__ = ("id", "acc", "role", "name", "app", "pid", "win", "bounds", "states", "actions", "editable", "text")

    def __init__(self, **kw):
        for k in self.__slots__:
            setattr(self, k, kw.get(k))

    @property
    def label(self):
        """What to call it out loud: its name, or what it is in which app."""
        if self.name:
            return self.name
        what = {"text": "text area", "entry": "text field", "document text": "document", "terminal": "terminal",
                "password text": "password field"}.get(self.role, self.role)
        return "%s %s" % (pretty_app(self.app), what)


class Window:
    __slots__ = ("id", "acc", "app", "pid", "title", "active", "bounds", "lines", "nodes", "truncated")

    def __init__(self, **kw):
        for k in self.__slots__:
            setattr(self, k, kw.get(k))


def _safe(f, default=None):
    try:
        return f()
    except Exception:
        return default


def role_name(acc):
    return _safe(acc.get_role_name, "?") or "?"


def extents(acc, offset=(0, 0)):
    """Screen rectangle (x, y, w, h). On Wayland apps don't know where their window is, so the
    window-relative box is moved by the window's position from the compositor (`offset`)."""
    if not _safe(acc.get_component_iface):
        return None
    if offset != (0, 0):
        e = _safe(lambda: Atspi.Component.get_extents(acc, Atspi.CoordType.WINDOW))
        if e and e.x != INVALID:
            return (e.x + offset[0], e.y + offset[1], e.width, e.height)
    e = _safe(lambda: Atspi.Component.get_extents(acc, Atspi.CoordType.SCREEN))
    if not e or e.x == INVALID or e.width <= 0 or e.height <= 0:
        return None
    return (e.x, e.y, e.width, e.height)


def action_names(acc):
    if not _safe(acc.get_action_iface):
        return []
    n = _safe(lambda: Atspi.Action.get_n_actions(acc), 0) or 0
    return [(_safe(lambda i=i: Atspi.Action.get_action_name(acc, i), "") or "").lower() for i in range(n)]


def text_of(acc, limit=400):
    # call the interfaces explicitly: Accessible has its own get_text(), the old interface getter
    if not _safe(acc.get_text_iface):
        return None
    n = _safe(lambda: Atspi.Text.get_character_count(acc), 0) or 0
    s = _safe(lambda: Atspi.Text.get_text(acc, 0, min(n, limit)), "") or ""
    return s + ("…" if n > limit else "")


def pretty_app(name):
    """AT-SPI app names are often the binary ("konsole", "org.kde.dolphin"): make them readable."""
    n = (name or "").split(".")[-1]
    return n[:1].upper() + n[1:] if n.islower() else n


def caret_point(acc):
    """Where the text caret is on screen, so the cursor can sit right where the words appear."""
    if not _safe(acc.get_text_iface):
        return None
    off = _safe(lambda: Atspi.Text.get_caret_offset(acc), -1)
    if off is None or off < 0:
        return None
    n = _safe(lambda: Atspi.Text.get_character_count(acc), 0) or 0
    r = _safe(lambda: Atspi.Text.get_character_extents(acc, max(0, min(off, n - 1)) if n else 0, Atspi.CoordType.SCREEN))
    if not r or r.x == INVALID or (r.x == 0 and r.y == 0) or r.height <= 0:
        return None
    return (r.x + (r.width if off >= n and n else 0), r.y, 2, r.height)


def clip(s, n=70):
    s = " ".join((s or "").split())
    return s if len(s) <= n else s[:n - 1] + "…"


class Eyes:
    def __init__(self, own_pids=()):
        self.own_pids = set(own_pids)       # processes the AI must never act on (the shell)
        self.window_offsets = {}            # (pid, title) -> (x, y), from KWin on Wayland
        self.wayland = bool(os.environ.get("WAYLAND_DISPLAY"))

    def apps(self):
        desk = Atspi.get_desktop(0)
        out = []
        for i in range(_safe(desk.get_child_count, 0) or 0):
            app = _safe(lambda i=i: desk.get_child_at_index(i))
            if app is None:
                continue
            pid = _safe(app.get_process_id, -1)
            out.append((app, pid, _safe(app.get_name, "") or "?"))
        return out

    def windows(self):
        """Top-level windows that are on screen, newest app last."""
        wins = []
        for app, pid, name in self.apps():
            if pid in self.own_pids or pid == os.getpid():
                continue
            for j in range(_safe(app.get_child_count, 0) or 0):
                w = _safe(lambda j=j: app.get_child_at_index(j))
                if w is None:
                    continue
                st = _safe(w.get_state_set)
                if st is None or not (st.contains(S.SHOWING) or st.contains(S.VISIBLE)):
                    continue
                title = _safe(w.get_name, "") or name
                wins.append(Window(acc=w, app=name, pid=pid, title=title,
                                   active=st.contains(S.ACTIVE), bounds=None, lines=[], nodes=[]))
        return wins

    def snapshot(self, detail_limit=2, start_id=1):
        """Windows with numbered elements. The active window (and a few others) get full detail."""
        wins = self.windows()
        wins.sort(key=lambda w: (not w.active,))
        nodes = {}
        nid = start_id
        for k, w in enumerate(wins):
            w.id = "w%d" % (k + 1)
            off = self.window_offsets.get((w.pid, w.title), (0, 0))
            w.bounds = extents(w.acc, off)
            if k >= detail_limit:
                continue
            nid = self._walk(w, w.acc, 0, nid, nodes, off)
        return wins, nodes

    def _walk(self, win, acc, depth, nid, nodes, off):
        if depth > MAX_DEPTH or len(win.nodes) >= MAX_NODES:
            win.truncated = True
            return nid
        n = _safe(acc.get_child_count, 0) or 0
        for i in range(min(n, 400)):
            c = _safe(lambda i=i: acc.get_child_at_index(i))
            if c is None:
                continue
            st = _safe(c.get_state_set)
            if st is None or not st.contains(S.SHOWING):
                # closed menus, hidden tabs: the AI sees what you see, then opens them like you would
                continue
            role = _safe(c.get_role, R.UNKNOWN)
            name = clip(_safe(c.get_name, "") or "", 80)
            acts = action_names(c)
            editable = st.contains(S.EDITABLE) and bool(_safe(c.get_editable_text_iface))
            show = bool(acts) or editable or st.contains(S.EDITABLE) or (role in READABLE and (name or role in (R.TERMINAL, R.TEXT, R.ENTRY, R.DOCUMENT_TEXT)))
            if role in GROUPS and not name and not acts and not editable:
                show = False
            if show:
                b = extents(c, off)
                text = None
                if role in (R.TEXT, R.ENTRY, R.PASSWORD_TEXT, R.DOCUMENT_TEXT, R.TERMINAL, R.PARAGRAPH) or editable:
                    text = "•••" if role == R.PASSWORD_TEXT else text_of(c, 300)
                node = Node(id=nid, acc=c, role=role_name(c), name=name, app=win.app, pid=win.pid, win=win,
                            bounds=b, states=st, actions=acts, editable=editable, text=text)
                nodes[nid] = node
                win.nodes.append(node)
                nid += 1
            if role not in (R.MENU_ITEM, R.PUSH_BUTTON, R.CHECK_BOX, R.RADIO_BUTTON, R.LINK) or not acts:
                nid = self._walk(win, c, depth + 1, nid, nodes, off)
            if len(win.nodes) >= MAX_NODES:
                win.truncated = True
                break
        return nid


def describe(node):
    st = node.states
    flags = []
    # editable: takes text directly (EditableText), or by keyboard when the app only says it's editable
    if node.editable or (st is not None and st.contains(S.EDITABLE)):
        flags.append("editable")
    for s, word in ((S.FOCUSED, "focused"), (S.CHECKED, "checked"), (S.SELECTED, "selected"),
                    (S.EXPANDED, "open"), (S.PRESSED, "pressed")):
        if st is not None and st.contains(s):
            flags.append(word)
    if st is not None and not st.contains(S.ENABLED) and not st.contains(S.SENSITIVE):
        flags.append("disabled")
    line = "[%d] %s" % (node.id, node.role)
    if node.name:
        line += ' "%s"' % node.name
    if flags:
        line += " " + " ".join(flags)
    if node.text:
        line += ' = "%s"' % clip(node.text, 160)
    return line


def render(wins, shell_lines=None):
    """The screen as text for the brain: app windows (the active one first), then Firelamp's own UI."""
    out = []
    if not wins:
        out.append("(no app windows are open)")
    for w in wins:
        head = '[%s] %s: "%s"' % (w.id, pretty_app(w.app), clip(w.title, 70))
        if w.active:
            head += " (active)"
        if not w.nodes:
            head += " (in the background; focus it to see inside)"
        out.append(head)
        for n in w.nodes:
            out.append("  " + describe(n))
        if w.truncated:
            out.append("  … (more below; the window is large)")
    if shell_lines:
        out.extend(shell_lines)
    return "\n".join(out)


def wait_for_window(eyes, match, timeout=10.0):
    """Poll until an app window whose app name or title contains `match` shows up."""
    m = match.lower()
    end = time.time() + timeout
    while time.time() < end:
        for w in eyes.windows():
            if m in w.app.lower() or m in w.title.lower():
                return w
        time.sleep(0.25)
    return None
