"""The agent loop: look, think, act, repeat, until the job is done.

Each turn the brain gets what you asked, the live accessibility tree and the result of the last
action, and answers with one JSON action. The loop checks it against the safety rules (asking
you through the permission sheet when needed), moves the fire cursor there, performs it on the
real app, logs it to Activity with the brain's reason, and looks again.
"""
import itertools
import json
import os
import subprocess
import threading
import time

from . import brain as brains
from . import eyes as eyes_mod
from . import hands, safety
from .jev import Jev

MAX_STEPS = 40
KEEP_SCREENS = 3

SYSTEM = """You are {name}, the assistant built into Firelamp OS, a Linux desktop (KDE Plasma on Arch).
You use the computer the way a person does, with your own visible cursor (the fire cursor), while the user watches. You can also run bash commands.
You never see screenshots. Each turn you get the live accessibility tree instead: every open window and its controls, each with a number like [12], its role, its label and its text.

Answer with exactly ONE JSON object and nothing else:
{{"say": "short message to the user (optional)",
 "plan": ["short step", "..."],
 "step": 0,
 "do": "click", "id": 12,
 "why": "short reason, shown in the activity log",
 "risky": false}}
"plan" goes only in your first answer, and only when the task needs 3 or more steps. "step" is the plan line this action belongs to.

Actions ("do"):
 open   {{"do":"open","app":"Kate"}}  start an installed app (or one of Firelamp's own apps)
 click  {{"do":"click","id":12}}  press a button, menu, menu item, tab, link, list item or checkbox
 type   {{"do":"type","id":7,"text":"hello","replace":false}}  write into a text field ("replace": true clears it first)
 key    {{"do":"key","keys":"ctrl+s"}}  press keys in the active window: Return, Tab, Escape, ctrl+s, alt+F4…
 focus  {{"do":"focus","window":"w2"}}  bring a window to the front and see inside it
 read   {{"do":"read","id":7}}  get the full text of an element
 run    {{"do":"run","command":"df -h"}}  run a bash command and get its output
 wait   {{"do":"wait","seconds":2}}  let something load
 done   {{"do":"done","say":"..."}}  finish: say what you did, or answer the question

Rules:
- One action per answer. After each one you get its result and the new tree.
- Only use ids from the latest tree. If what you need isn't there, open or focus the right window, or open the menu that holds it.
- Menus show their items only once opened: click the menu first, then the item.
- For facts about this computer (disk, memory, files, packages), use run. For general questions, answer with done.
- Set "risky": true on anything that deletes, sends, publishes, buys, shares, installs or removes software, or can't be undone. The user approves those first.
- Don't type passwords or personal details the user didn't give you.
- If you are stuck after two tries, use done and say plainly what blocked you. Never guess.
- Keep "say" and "why" short and friendly, in the language the user wrote in.
"""

# with Jev at Instant: the brain names its next click, Jev finds it on the new screen
REFLEX = """
- When your next step will just be clicking something you can name, add "then": "the Save button in Kate". If it's on the next screen, it gets clicked right away and you get both results."""

NEEDS_BRAIN = ("I can't think yet: no AI model is set up. Sign in to Puter in Settings › Assistant "
               "(free, it opens your browser), or add your own API key or a local Ollama model there.")


class Stop(Exception):
    pass


class Agent:
    def __init__(self, events, eyes, kwin=None):
        self.events = events
        self.eyes = eyes
        self.kwin = kwin
        self.task = None
        self.paused = False
        self.stopped = False
        self.lock = threading.Lock()
        self.ids = itertools.count(1)
        self.nodes = {}
        self.wins = []
        self.shell_wins = []
        self.asked_apps = set()

    # ---- control from the shell ----
    @property
    def busy(self):
        return self.task is not None

    def ask(self, text, cfg):
        with self.lock:
            if self.task:
                return None
            tid = "t%d" % next(self.ids)
            self.task = {"id": tid, "text": text, "cfg": cfg}
            self.paused = self.stopped = False
            self.asked_apps = set()
        threading.Thread(target=self._run, args=(self.task,), name="task-" + tid, daemon=True).start()
        return tid

    def pause(self, on):
        if self.task:
            self.paused = bool(on)
            self.events.emit("paused", on=self.paused)

    def stop(self):
        if self.task:
            self.stopped = True
            self.paused = False
            self.events.cancel_waits()

    def checkpoint(self):
        while self.paused and not self.stopped:
            time.sleep(0.1)
        if self.stopped:
            raise Stop()

    # ---- the loop ----
    def _run(self, task):
        how = "done"
        try:
            how = self._loop(task)
        except Stop:
            how = "stopped"
            self.log("denied", "Stopped by you", "You pressed stop, so I stopped right away.", "Firelamp")
            self.say("Stopped. Nothing else was changed.")
        except Exception as e:  # report, never hide
            how = "error"
            self.log("stuck", "Something went wrong", str(e)[:200], "Firelamp")
            self.say("Something went wrong on my side, so I stopped: " + str(e)[:160])
        finally:
            self.events.emit("done", how=how, task=task["id"])
            with self.lock:
                self.task = None

    def _loop(self, task):
        cfg = task["cfg"]
        try:
            brain = brains.pick(cfg)
        except brains.BrainError:
            self.say(NEEDS_BRAIN)
            self.events.emit("needs", what="brain")
            return "error"
        jev = Jev(cfg["jev_key"]) if cfg.get("jev_key") else None
        self.events.emit("start", task=task["id"], text=task["text"], model=brain.label, provider=brain.provider, jev=bool(jev))
        apps = hands.installed_apps()
        shell_apps = self.events.shell_apps()
        name = cfg.get("name") or "the assistant"
        intro = "The user asked: %s\n\nInstalled apps: %s\n" % (task["text"], ", ".join(sorted(apps)[:80]) or "(none found)")
        if shell_apps:
            intro += "Firelamp's own apps (in the dock): %s\n" % ", ".join(a["title"] for a in shell_apps)
        intro += "Home folder: %s. Now: %s.\n" % (os.path.expanduser("~"), time.strftime("%A %d %B %Y, %H:%M"))
        reflexes = bool(jev) and int(cfg.get("effort") or 0) == 0
        system = SYSTEM.format(name=name) + (REFLEX if reflexes else "")
        messages = [{"role": "system", "content": system},
                    {"role": "user", "content": intro + "\nScreen now:\n" + self.look()}]
        plan, bad = [], 0
        for turn in range(MAX_STEPS):
            self.checkpoint()
            self.events.emit("think", text="Thinking" if turn else "Reading the screen")
            raw = self.think(brain, messages)
            try:
                act = brains.parse(raw)
            except brains.BrainError:
                bad += 1
                if bad > 2:
                    self.say("My AI model kept answering in a way I couldn't use, so I stopped.")
                    return "error"
                messages.append({"role": "assistant", "content": raw[:1500]})
                messages.append({"role": "user", "content": "That wasn't a single JSON object. Answer again with exactly one JSON object."})
                continue
            bad = 0
            messages.append({"role": "assistant", "content": json.dumps(act, ensure_ascii=False)})
            do = str(act.get("do") or act.get("action") or "").lower()
            if turn == 0 and isinstance(act.get("plan"), list) and len(act["plan"]) >= 3 and do != "done":
                plan = [str(p)[:90] for p in act["plan"][:8]]
                if act.get("say"):
                    self.say(act["say"])
                if not self.propose(task, plan):
                    self.say("Okay, I won't do that. Tell me what to change.")
                    return "edited"
            elif act.get("say") and do != "done":
                self.say(act["say"])
            if plan and isinstance(act.get("step"), int) and 0 <= act["step"] < len(plan):
                self.events.emit("step", i=act["step"])
            if do == "done":
                self.say(act.get("say") or act.get("text") or "Done.")
                self.log("done", "Done", task["text"], "Firelamp")
                return "done"
            result = self.execute(act, do, cfg, jev, task)
            if result.startswith("DENIED"):
                return "denied"
            time.sleep(0.35)
            screen = self.look()
            if reflexes and act.get("then"):
                extra = self.reflex(str(act["then"])[:120], task, cfg, jev)
                if extra == "DENIED":
                    return "denied"
                if extra:
                    result += "\nThen (Jev, for \"%s\"): %s" % (eyes_mod.clip(str(act["then"]), 60), extra)
                    time.sleep(0.35)
                    screen = self.look()
            messages.append({"role": "user", "content": "Result: %s\n\nScreen now:\n%s" % (result, screen)})
            self.trim(messages, brain.budget)
        self.say("That took more steps than I allow myself, so I stopped here. Everything I did is in Activity.")
        return "stuck"

    def reflex(self, then, task, cfg, jev):
        """Jev picks the element the brain named for its next click, without another brain turn.
        Only when it's sure; otherwise the brain decides as usual."""
        self.checkpoint()
        opts = {}
        for i, n in self.nodes.items():
            if isinstance(n, dict):
                if n.get("role") in ("button", "item", "menu item", "tab", "link") and n.get("name"):
                    opts[str(i)] = '%s "%s" in %s' % (n["role"], n["name"], n.get("appTitle") or "Firelamp")
            elif n.actions and n.label:
                opts[str(i)] = '%s "%s" in %s' % (n.role, n.label, eyes_mod.pretty_app(n.app))
        if not opts:
            return ""
        opts["none"] = "None of these is it"
        self.events.emit("think", text="Finding " + eyes_mod.clip(then, 36))
        pick, conf = jev.choose("The user asked: %s\nNext step: click %s" % (task["text"], then),
                                "Which element on screen is the one to click for the next step?", opts)
        if not pick or pick == "none" or conf < 0.8 or self.node(pick) is None:
            return ""
        try:
            return self.do_click({"id": int(pick)}, then, cfg, jev)
        except PermissionDenied:
            return "DENIED"
        except hands.HandsError as e:
            return "Error: %s." % e

    def think(self, brain, messages):
        """Ask the brain on a side thread, so Stop works even while it's thinking."""
        box = {}

        def call():
            try:
                box["text"] = brain.chat(messages)
            except Exception as e:
                box["err"] = e
        t = threading.Thread(target=call, daemon=True)
        t.start()
        while t.is_alive():
            t.join(0.1)
            if self.stopped:
                raise Stop()
        if "err" in box:
            raise RuntimeError("my AI model (%s) didn't answer: %s" % (brain.label, box["err"]))
        return box.get("text", "")

    def trim(self, messages, budget=60000):
        """Keep the last few screens in full; older turns keep only their result line. When it
        still doesn't fit the model's context, keep fewer screens, then drop the oldest turns."""
        def size():
            return sum(len(m["content"]) for m in messages)

        def screens():
            return [i for i, m in enumerate(messages) if m["role"] == "user" and "\nScreen now:\n" in m["content"]]
        full = screens()
        for k, i in enumerate(full):
            if k < len(full) - KEEP_SCREENS or (size() > budget and k < len(full) - 1):
                head = messages[i]["content"].split("\nScreen now:\n")[0]
                messages[i] = {"role": "user", "content": head + "\n(older screen left out)"}
        # the system prompt, the request and the latest exchange always stay
        while size() > budget and len(messages) > 5:
            del messages[2:4]

    # ---- eyes ----
    def look(self):
        if self.kwin and self.kwin.ok:
            ws = self.kwin.windows() or []
            self.eyes.window_offsets = {(w["pid"], w["caption"]): (w["x"], w["y"]) for w in ws}
        wins, nodes = self.eyes.snapshot()
        shell = self.events.shell_snapshot(start_id=len(nodes) + 1)
        self.shell_wins = shell
        shell_lines = []
        if shell:
            for w in shell:
                head = '[%s] Firelamp: "%s"' % (w["id"], w["title"])
                if w.get("active") and not any(x.active for x in wins):
                    head += " (active)"
                shell_lines.append(head)
                for n in w["nodes"]:
                    nodes[n["id"]] = n
                    shell_lines.append('  [%d] %s "%s"%s' % (n["id"], n["role"], n["name"],
                                                            (' = "%s"' % eyes_mod.clip(n["text"], 160)) if n.get("text") else ""))
        self.nodes, self.wins = nodes, wins
        return eyes_mod.render(wins, shell_lines)

    def node(self, i):
        try:
            return self.nodes.get(int(i))
        except (TypeError, ValueError):
            return None

    # ---- talking to the shell ----
    def say(self, text):
        self.events.emit("say", text=text)

    def log(self, kind, title, why="", app=""):
        self.events.emit("log", entry={"kind": kind, "title": title, "why": why or "", "app": app or ""})

    def propose(self, task, plan):
        r = self.events.request("plan", timeout=None, task=task["id"], lines=plan, text=task["text"])
        if self.stopped:
            raise Stop()
        return bool(r and r.get("ok"))

    def point(self, bounds, label, verb="clicking"):
        """Move the fire cursor onto the element and wait until it gets there."""
        if not bounds:
            return
        x, y, w, h = bounds
        self.events.request("point", timeout=3.0, x=x, y=y, w=w, h=h, label=label, verb=verb)
        self.checkpoint()

    def permission(self, title, body, details, allow, deny, app):
        self.log("ask", "Asked before: " + title.rstrip("?"), body, "Firelamp")
        self.events.emit("think", text="Waiting for your OK")
        self.raise_shell()
        r = self.events.request("ask", timeout=None, title=title, body=body, details=details, allow=allow, deny=deny, app=app)
        if self.stopped:
            raise Stop()
        ok = bool(r and r.get("ok"))
        if not ok:
            self.log("denied", "You said no, so I stopped there", "", "Firelamp")
            self.say("Okay, I didn't do it, and I stopped there.")
        return ok

    def raise_shell(self):
        pid = self.events.shell_pid
        if not pid:
            return
        if self.kwin and self.kwin.ok:
            self.kwin.activate(pid, "Firelamp OS")
        else:
            hands.activate_x11(pid)

    def activate(self, win):
        if win is None or win.active:
            return
        if self.kwin and self.kwin.ok:
            self.kwin.activate(win.pid, win.title)
        else:
            hands.activate_x11(win.pid)
        time.sleep(0.25)

    # ---- safety ----
    def gate(self, act, what, app, level, cfg, jev, details):
        """Ask first when the rules, the brain or Jev call this risky, or the app is set to always ask."""
        aid = safety.app_id(app)
        trust = (cfg.get("trust") or {}).get(aid, "risky")
        brain_says = bool(act.get("risky"))
        jev_p = None
        if level < 2 and jev:
            jev_p = jev.risky("Action: %s. App: %s. User's request: %s" % (what, app, self.task["text"] if self.task else ""))
        risky = level >= 2 or ((brain_says or level >= 1 or (jev_p or 0) > 0.7) and trust != "never")
        if level >= 1 and not cfg.get("ask_before_risky", True) and level < 2:
            risky = False
        if not risky and trust == "all" and aid not in self.asked_apps:
            self.asked_apps.add(aid)
            return self.permission("Let %s work in %s?" % (cfg.get("name") or "the assistant", app),
                                   "You set %s to ask before anything. Change this in Settings › Assistant." % app,
                                   details, "Allow", "Not Now", aid)
        if not risky:
            return True
        why = act.get("why") or ""
        return self.permission(what[0].upper() + what[1:] + "?", why or "This can't be undone, so Firelamp checks with you first.",
                               details, "Allow", "Don’t", aid)

    # ---- hands ----
    def execute(self, act, do, cfg, jev, task):
        why = str(act.get("why") or "")[:200]
        try:
            if do == "open":
                return self.do_open(str(act.get("app") or ""), why)
            if do in ("click", "press", "tap"):
                return self.do_click(act, why, cfg, jev)
            if do == "type":
                return self.do_type(act, why, cfg, jev)
            if do in ("key", "keys", "press_keys"):
                return self.do_key(act, why, cfg, jev)
            if do == "focus":
                return self.do_focus(act, why)
            if do == "read":
                n = self.node(act.get("id"))
                if not n:
                    return "Error: there's no element %s on screen now." % act.get("id")
                if isinstance(n, dict):
                    return 'Text of [%s]: "%s"' % (n["id"], n.get("text") or n["name"])
                self.point(n.bounds, n.label, "reading")
                text = eyes_mod.text_of(n.acc, 6000) or n.name
                self.log("look", "Read “%s”" % eyes_mod.clip(n.label, 40), why, eyes_mod.pretty_app(n.app))
                return 'Text of [%d]: "%s"' % (n.id, text)
            if do == "run":
                return self.do_run(act, why, cfg, jev)
            if do == "wait":
                secs = min(10.0, float(act.get("seconds") or 1))
                end = time.time() + secs
                while time.time() < end:
                    self.checkpoint()
                    time.sleep(0.1)
                return "Waited %.0f s." % secs
            return "Error: unknown action %r. Use one of: open, click, type, key, focus, read, run, wait, done." % do
        except hands.HandsError as e:
            return "Error: %s." % e
        except PermissionDenied:
            return "DENIED"

    def do_open(self, name, why):
        if not name:
            return "Error: say which app to open."
        for a in self.events.shell_apps():
            if a["title"].lower() == name.lower() or a["id"] == name.lower():
                self.events.emit("think", text="Opening " + a["title"])
                r = self.events.shell_act("open", app=a["id"])
                if r and r.get("ok"):
                    self.log("open", "Opened " + a["title"], why, a["title"])
                    return "Opened Firelamp's %s." % a["title"]
                break
        title, app = hands.find_app(name)
        if not app:
            return "Error: no installed app called %r. Installed apps are listed at the top." % name
        self.events.emit("think", text="Opening " + title)
        self.events.request("opening", timeout=3.0, app=title, dock=self.dock_id(title, app))
        self.checkpoint()
        before = {(w.pid, w.title) for w in self.eyes.windows()}
        hands.launch(app)
        end = time.time() + 12
        win = None
        while time.time() < end and win is None:
            self.checkpoint()
            time.sleep(0.3)
            for w in self.eyes.windows():
                if (w.pid, w.title) not in before and (title.lower().split()[0] in (w.app + w.title).lower()
                                                       or app["id"].split(".")[-1].lower() in w.app.lower()):
                    win = w
                    break
        self.log("open", "Opened " + title, why, title)
        if not win:
            return "Started %s, but its window hasn't appeared yet (it may still be loading)." % title
        time.sleep(0.6)
        return "Opened %s." % title

    def dock_id(self, title, app):
        aid = safety.app_id(title + " " + app["id"])
        return aid if aid in ("terminal", "web", "files", "mail") else ""

    def do_click(self, act, why, cfg, jev):
        n = self.node(act.get("id"))
        if n is None:
            return "Error: there's no element %s on screen now." % act.get("id")
        if isinstance(n, dict):
            return self.shell_do("click", n, act, why, cfg, jev)
        app = eyes_mod.pretty_app(n.app)
        what = 'press “%s” in %s' % (n.label, app)
        if not self.gate(act, what, app, safety.element_risk(n.name, n.role), cfg, jev,
                         [["Button", n.label], ["App", app]]):
            raise PermissionDenied()
        self.activate(n.win)
        self.events.emit("think", text="Clicking “%s”" % eyes_mod.clip(n.label, 30))
        self.point(n.bounds, n.label)
        self.events.emit("press")
        how = hands.press(n)
        self.log("click", "Clicked “%s”" % eyes_mod.clip(n.label, 50), why, app)
        return "%s “%s”." % (how.capitalize(), n.label)

    def do_type(self, act, why, cfg, jev):
        n = self.node(act.get("id"))
        text = str(act.get("text") or "")
        if n is None:
            return "Error: there's no element %s on screen now." % act.get("id")
        if not text:
            return "Error: nothing to type."
        if isinstance(n, dict):
            return self.shell_do("type", n, act, why, cfg, jev)
        aid = safety.app_id(n.app)
        app = eyes_mod.pretty_app(n.app)
        if not self.gate(act, 'type “%s” into %s' % (eyes_mod.clip(text, 40), app), app,
                         0, cfg, jev, [["Text", eyes_mod.clip(text, 60)], ["App", app]]):
            raise PermissionDenied()
        self.activate(n.win)
        self.events.emit("think", text="Typing in %s" % eyes_mod.clip(n.label, 30))
        self.point(eyes_mod.caret_point(n.acc) or n.bounds, n.label, "typing in")
        self.events.emit("press")
        self.events.emit("busy", on=True)
        try:
            if n.editable and aid != "terminal":
                hands.set_text(n, text, bool(act.get("replace")), cancelled=lambda: self.stopped or self.paused)
                self.checkpoint()
            else:
                hands.focus(n)
                if aid == "terminal":
                    level, reason = safety.command_risk(text.strip())
                    if level and not self.gate(dict(act, risky=True), "run `%s` in the terminal" % eyes_mod.clip(text, 50),
                                               app, level, cfg, jev, [["Command", eyes_mod.clip(text, 70)], ["Why ask", reason]]):
                        raise PermissionDenied()
                hands.type_keys(text)
        finally:
            self.events.emit("busy", on=False)
        self.log("type", "Typed into %s" % (("“%s”" % eyes_mod.clip(n.name, 40)) if n.name else n.label), why, app)
        return "Typed %d characters into “%s”." % (len(text), n.label)

    def do_key(self, act, why, cfg, jev):
        keys = str(act.get("keys") or act.get("key") or "")
        if not keys:
            return "Error: say which keys."
        active = next((w for w in self.wins if w.active), None)
        app = eyes_mod.pretty_app(active.app) if active else "the active window"
        lvl = 2 if keys.lower() in ("shift+delete",) else 0
        if not self.gate(act, "press %s in %s" % (keys, app), app, lvl, cfg, jev, [["Keys", keys], ["App", app]]):
            raise PermissionDenied()
        hands.press_keys(keys)
        self.log("click", "Pressed %s" % keys, why, app)
        return "Pressed %s in %s." % (keys, app)

    def do_focus(self, act, why):
        wid = str(act.get("window") or "")
        win = next((w for w in self.wins if w.id == wid), None)
        if not win:
            for w in self.shell_wins:
                if w["id"] == wid:
                    self.raise_shell()
                    self.events.shell_act("focus", app=w["app"])
                    return "Brought Firelamp's %s to the front." % w["title"]
            return "Error: there's no window %s." % wid
        self.activate(win)
        app = eyes_mod.pretty_app(win.app)
        if win.bounds:
            self.point((win.bounds[0] + win.bounds[2] // 2, win.bounds[1] + 12, 1, 1), app, "looking at")
        self.log("look", "Looked at %s" % app, why, app)
        return "Brought %s to the front." % app

    def do_run(self, act, why, cfg, jev):
        cmd = str(act.get("command") or "").strip()
        if not cmd:
            return "Error: no command."
        level, reason = safety.command_risk(cmd)
        if level and not self.gate(dict(act, risky=True), "run `%s`" % eyes_mod.clip(cmd, 60), "Terminal", level, cfg, jev,
                                   [["Command", eyes_mod.clip(cmd, 80)], ["Why ask", reason]]):
            raise PermissionDenied()
        self.events.emit("think", text="Running " + eyes_mod.clip(cmd, 40))
        try:
            p = subprocess.run(["bash", "-lc", cmd], capture_output=True, text=True, timeout=60,
                               cwd=os.path.expanduser("~"), stdin=subprocess.DEVNULL,
                               env=dict(os.environ, PAGER="cat", SYSTEMD_PAGER="", GIT_PAGER="cat", TERM="dumb"))
            out = (p.stdout + ("\n" + p.stderr if p.stderr.strip() else "")).strip()
            code = p.returncode
        except subprocess.TimeoutExpired:
            out, code = "(still running after 60 s, so I stopped it)", -1
        self.log("run", "Ran `%s`" % eyes_mod.clip(cmd, 32), why, "Terminal")
        if len(out) > 3500:
            out = out[:3500] + "\n… (cut)"
        return "Exit code %d. Output:\n%s" % (code, out or "(no output)")

    def shell_do(self, op, n, act, why, cfg, jev):
        """An element of Firelamp's own UI: the shell performs it with the fire cursor."""
        level = safety.element_risk(n["name"]) if op == "click" else 0
        app = n.get("appTitle") or "Firelamp"
        what = ('press “%s” in %s' % (n["name"], app)) if op == "click" else ('type “%s” into %s' % (eyes_mod.clip(str(act.get("text")), 40), app))
        if not self.gate(act, what, app, level, cfg, jev, [["Item", n["name"]], ["App", app]]):
            raise PermissionDenied()
        self.raise_shell()
        r = self.events.shell_act(op, i=n["i"], text=str(act.get("text") or ""), replace=bool(act.get("replace")))
        if not r or not r.get("ok"):
            return "Error: %s." % ((r or {}).get("error") or "Firelamp didn't answer")
        self.log("click" if op == "click" else "type",
                 ("Clicked “%s”" % n["name"]) if op == "click" else ("Typed into “%s”" % n["name"]), why, app)
        return ("Pressed “%s”." % n["name"]) if op == "click" else ("Typed into “%s”." % n["name"])


class PermissionDenied(Exception):
    pass
