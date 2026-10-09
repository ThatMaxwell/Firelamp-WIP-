#!/usr/bin/env python3
"""Real run: a real AI model drives real apps through the real Firelamp shell, on camera.

Test harness, not part of the product. CI (.github/workflows/agent.yml) runs it on Arch with
the ISO's own packages: Xvfb + openbox, the shell from shell/Main.qml, firelamp-agent thinking
with a real model, and Kate. It asks the way a person does (Ctrl+K, types the request, Enter,
clicking Go on the plan), records the screen with ffmpeg, then reads the apps back through
AT-SPI so the result is checked in the app itself, not taken from the agent's word.

    dbus-run-session -- python3 agent/test/real_run.py --out capture "Open a text editor and …"

Nothing here answers for the model: the brain is whatever firelamp-agent picks from its
settings and FIRELAMP_* variables. A permission sheet is refused: only a person allows. When
it gets stuck, nobody can do the step for it, so Stop is pressed.
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AGENT = "http://127.0.0.1:7342"
W, H = 1440, 900
TASK = "Open a text editor and write a to-do list for this weekend: groceries, laundry, call mom"


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


def run(*argv, **kw):
    return subprocess.run(argv, capture_output=True, text=True, **kw)


def bg(argv, logfile, env=None, stdin=None):
    return subprocess.Popen(argv, stdout=open(logfile, "w"), stderr=subprocess.STDOUT, env=env or os.environ,
                            stdin=stdin if stdin is not None else subprocess.DEVNULL, start_new_session=True)


def call(path, body=None, timeout=40):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(AGENT + path, data=data, method="POST" if data is not None else "GET")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")


def wait_for(check, timeout, what):
    end = time.time() + timeout
    while time.time() < end:
        try:
            v = check()
            if v:
                return v
        except Exception:
            pass
        time.sleep(0.5)
    raise SystemExit("timed out waiting for " + what)


class Screen:
    def __init__(self, display, out):
        self.display, self.out, self.rec = display, out, None

    def shot(self, name):
        path = os.path.join(self.out, name + ".png")
        run("ffmpeg", "-loglevel", "error", "-y", "-f", "x11grab", "-video_size", "%dx%d" % (W, H),
            "-i", self.display, "-frames:v", "1", path)
        return path

    def record(self):
        self.rec = bg(["ffmpeg", "-loglevel", "error", "-y", "-f", "x11grab", "-framerate", "25", "-draw_mouse", "0",
                       "-video_size", "%dx%d" % (W, H), "-i", self.display, "-c:v", "libx264", "-preset", "veryfast",
                       "-crf", "22", "-pix_fmt", "yuv420p", os.path.join(self.out, "raw.mp4")],
                      os.path.join(self.out, "ffmpeg.log"), stdin=subprocess.PIPE)

    def stop(self):
        if not self.rec:
            return
        try:
            self.rec.stdin.write(b"q")
            self.rec.stdin.flush()
            self.rec.wait(30)
        except Exception:
            self.rec.kill()


def shell_window():
    r = run("xdotool", "search", "--name", "^Firelamp OS$")
    ids = r.stdout.split()
    return ids[0] if ids else None


def to_shell():
    """Click-free focus on the shell, the way alt-tab would."""
    wid = shell_window()
    if wid:
        run("xdotool", "windowactivate", "--sync", wid, timeout=10)
        time.sleep(0.3)


def key(*keys):
    run("xdotool", "key", "--clearmodifiers", *keys, timeout=10)


def shell_button(name):
    """Where a button of the shell is on screen, found on the accessibility bus the way a
    screen reader finds it."""
    import gi
    gi.require_version("Atspi", "2.0")
    from gi.repository import Atspi

    def find(acc, depth):
        if depth > 40:
            return None
        for k in range(acc.get_child_count() or 0):
            c = acc.get_child_at_index(k)
            if c is None:
                continue
            if c.get_role() == Atspi.Role.PUSH_BUTTON and (c.get_name() or "") == name \
                    and c.get_state_set().contains(Atspi.StateType.SHOWING):
                e = Atspi.Component.get_extents(c, Atspi.CoordType.SCREEN)
                return e.x + e.width // 2, e.y + e.height // 2
            hit = find(c, depth + 1)
            if hit:
                return hit
        return None
    d = Atspi.get_desktop(0)
    for i in range(d.get_child_count()):
        app = d.get_child_at_index(i)
        for j in range(app.get_child_count() if app else 0):
            w = app.get_child_at_index(j)
            if w is not None and w.get_name() == "Firelamp OS":
                hit = find(w, 0)
                if hit:
                    return hit
    return None


def click(name):
    """Click a shell button like a person, then move the mouse out of the way."""
    at = wait_for(lambda: shell_button(name), 10, "the %s button" % name)
    run("xdotool", "mousemove", "--sync", str(at[0]), str(at[1]), "click", "1", timeout=10)
    time.sleep(0.3)
    run("xdotool", "mousemove", str(W // 2), "12", timeout=10)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("task", nargs="?", default=TASK)
    ap.add_argument("--out", default="capture")
    ap.add_argument("--display", default=":99")
    ap.add_argument("--name", default="Juno")      # the user names the assistant; this one is the test's
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--shell-cmd", default="/usr/lib/qt6/bin/qml -I {root}/shell {root}/shell/Main.qml -- --nosplash --name={name}")
    a = ap.parse_args()
    out = os.path.abspath(a.out)
    os.makedirs(out, exist_ok=True)

    home = os.path.expanduser("~")
    env = os.environ
    env.update(DISPLAY=a.display, QT_LINUX_ACCESSIBILITY_ALWAYS_ON="1", QT_ACCESSIBILITY="1",
               QML_XHR_ALLOW_FILE_READ="1", QML_XHR_ALLOW_FILE_WRITE="1", QSG_RENDER_LOOP="basic",
               XDG_CONFIG_HOME=env.get("XDG_CONFIG_HOME") or os.path.join(home, ".config"))
    env.setdefault("XDG_RUNTIME_DIR", "/tmp/runtime-%d" % os.getuid())
    os.makedirs(env["XDG_RUNTIME_DIR"], mode=0o700, exist_ok=True)
    env.pop("NO_AT_BRIDGE", None)
    # Qt Quick renders with OpenGL (Mesa's llvmpipe under Xvfb); its software renderer drops
    # shader effects, which leaves the dock and the chat blank
    procs = []

    # ---- a desktop: X, a window manager, a compositor (the AI layer is a see-through window) ----
    if run("xdotool", "getdisplaygeometry").returncode != 0:
        procs.append(bg(["Xvfb", a.display, "-screen", "0", "%dx%dx24" % (W, H), "-nolisten", "tcp"], os.path.join(out, "xvfb.log")))
        wait_for(lambda: run("xdotool", "getdisplaygeometry").returncode == 0, 20, "X")
        procs.append(bg(["openbox"], os.path.join(out, "openbox.log")))
        procs.append(bg(["xcompmgr"], os.path.join(out, "xcompmgr.log")))
    # the accessibility bus, as firelamp-session-start turns it on
    run("busctl", "--user", "set-property", "org.a11y.Bus", "/org/a11y/bus", "org.a11y.Status", "IsEnabled", "b", "true")
    run(sys.executable, "-c", "import dbus;b=dbus.SessionBus();p=dbus.Interface(b.get_object('org.a11y.Bus','/org/a11y/bus'),"
        "'org.freedesktop.DBus.Properties');p.Set('org.a11y.Status','IsEnabled',True)")
    time.sleep(1)

    # ---- the shell, named like after first boot ----
    cfgdir = os.path.join(env["XDG_CONFIG_HOME"], "firelamp")
    os.makedirs(cfgdir, exist_ok=True)
    conf = os.path.join(cfgdir, "shell.conf")
    if not os.path.exists(conf):
        with open(conf, "w") as f:
            f.write("[General]\nassistantName=%s\npacksAsked=true\nbrowserAsked=true\n" % a.name)
    cmd = a.shell_cmd.format(root=ROOT, name=a.name)
    log("shell:", cmd)
    procs.append(bg(["bash", "-c", cmd], os.path.join(out, "shell.log")))
    wait_for(shell_window, 90, "the Firelamp shell window")

    # ---- the agent, thinking with whatever it's set up for ----
    procs.append(bg([sys.executable, os.path.join(ROOT, "agent", "firelamp-agent"), "serve"], os.path.join(out, "agent.log")))
    st = wait_for(lambda: call("/status", timeout=5)[1], 30, "firelamp-agent")
    brain = st.get("brain") or {}
    log("brain:", json.dumps(brain))
    if not brain.get("ready"):
        raise SystemExit("firelamp-agent has no brain: " + str(brain.get("why")))
    wait_for(lambda: call("/status", timeout=5)[1].get("shell"), 60, "the shell to connect to the agent")
    time.sleep(3)
    scr = Screen(a.display, out)
    scr.shot("00-desktop")

    # ---- ask, like a person ----
    last = call("/events?after=-1")[1]["last"]
    scr.record()
    time.sleep(2)
    to_shell()
    key("ctrl+k")
    time.sleep(0.8)
    run("xdotool", "type", "--delay", "45", "--", a.task, timeout=60)
    time.sleep(0.7)
    key("Return")
    log("asked:", a.task)

    events, says, acts, how, model = [], [], [], None, ""
    t0, n_shot = time.time(), 0
    with open(os.path.join(out, "events.jsonl"), "w") as ev:
        while how is None and time.time() - t0 < a.timeout:
            try:
                _, r = call("/events?after=%d" % last, timeout=40)
            except TimeoutError:
                continue
            except (urllib.error.URLError, OSError) as e:
                # the agent died: say so, and still keep the film and the summary
                how = "agent crashed (%s)" % e
                log(how)
                break
            last = r["last"]
            for e in r["events"]:
                ev.write(json.dumps(dict(e, t=round(time.time() - t0, 1)), ensure_ascii=False) + "\n")
                ev.flush()
                events.append(e)
                k = e["kind"]
                if k == "start":
                    model = "%s (%s)" % (e.get("model"), e.get("provider"))
                    log("thinking with", model)
                elif k == "say":
                    says.append(e["text"])
                    log("says:", e["text"])
                elif k == "log":
                    en = e["entry"]
                    acts.append(en)
                    log("activity:", en["kind"], en["title"], "|", en.get("why", ""))
                    n_shot += 1
                    scr.shot("%02d-%s" % (n_shot, en["kind"]))
                elif k == "plan":
                    log("plan:", " / ".join(e["lines"]))
                    time.sleep(2.5)          # long enough to read it
                    n_shot += 1
                    scr.shot("%02d-plan" % n_shot)
                    click("Go")
                    log("pressed Go")
                elif k == "ask":
                    n_shot += 1
                    scr.shot("%02d-ask" % n_shot)
                    log("permission sheet:", e.get("title"))
                    time.sleep(2)
                    click(e.get("deny") or "Don’t")
                    log("refused")
                elif k == "stuck":
                    n_shot += 1
                    time.sleep(1.5)
                    scr.shot("%02d-stuck" % n_shot)
                    log("stuck:", e.get("line"))
                    time.sleep(3)            # nobody here can do the step for it
                    click("Stop")
                    log("pressed Stop")
                elif k == "done":
                    how = e["how"]
    elapsed = time.time() - t0
    time.sleep(3)
    scr.shot("99-final")
    scr.stop()
    log("finished:", how, "in %.0f s" % elapsed)

    # ---- check the result in the apps themselves ----
    tree = run(sys.executable, os.path.join(ROOT, "agent", "firelamp-agent"), "tree", timeout=60).stdout
    with open(os.path.join(out, "tree.txt"), "w") as f:
        f.write(tree)

    # ---- the film and a summary ----
    raw = os.path.join(out, "raw.mp4")
    if os.path.exists(raw):
        run("ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-c", "copy", "-movflags", "+faststart", os.path.join(out, "capture.mp4"))
        run("ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-vf",
            "fps=8,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer",
            os.path.join(out, "capture.gif"))
        os.remove(raw)
    final = os.path.join(out, "99-final.png")
    if os.path.exists(final):
        jpg = os.path.join(out, "final.jpg")
        run("ffmpeg", "-loglevel", "error", "-y", "-i", final, "-q:v", "6", jpg)
        if os.path.exists(jpg):
            print("BEGIN_FINAL_JPEG")
            print(base64.b64encode(open(jpg, "rb").read()).decode())
            print("END_FINAL_JPEG", flush=True)
    lines = ["# Firelamp assistant: real run", "",
             "- Asked: %s" % a.task, "- Thinking with: %s" % (model or "?"),
             "- Result: **%s** in %.0f s, %d actions" % (how or "timed out", elapsed, len(acts)), "",
             "## What it said", ""] + ["> " + s.replace("\n", " ") for s in says] + \
            ["", "## Activity (as logged for the user)", ""] + \
            ["- %s: %s%s" % (x["kind"], x["title"], (" (%s)" % x["why"]) if x.get("why") else "") for x in acts] + \
            ["", "## The screen afterwards, read back through AT-SPI", "", "```", tree.strip()[:6000], "```", ""]
    if how and how.startswith("agent crashed"):
        with open(os.path.join(out, "agent.log"), errors="replace") as f:
            lines += ["## The agent's last words", "", "```", "".join(f.readlines()[-30:]).strip(), "```", ""]
    with open(os.path.join(out, "summary.md"), "w") as f:
        f.write("\n".join(lines))
    print("\n".join(lines[:6]))
    for p in procs:
        try:
            p.terminate()
        except Exception:
            pass
    return 0 if how == "done" else 1


if __name__ == "__main__":
    sys.exit(main())
