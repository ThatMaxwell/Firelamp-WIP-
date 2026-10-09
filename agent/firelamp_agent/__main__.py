"""firelamp-agent: Firelamp OS's assistant, as a normal Linux program.

    firelamp-agent serve            run the agent for this session (the shell talks to it)
    firelamp-agent ask "…"          ask it something from a terminal and watch what it does
    firelamp-agent status           which brain and reflexes it will use
    firelamp-agent tree             print the screen the way the assistant reads it
    firelamp-agent puter-signin     sign in to Puter (opens your browser)
"""
import http.server
import json
import os
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

from . import brain as brains
from . import config, hands, server

BASE = "http://127.0.0.1:%d" % server.PORT

# settings the shell owns and sends with each request (its names -> ours)
SHELL_KEYS = {"name": "name", "effort": "effort", "reasoning": "reasoning", "modelFast": "model_fast",
              "modelBalanced": "model_balanced", "askBeforeRisky": "ask_before_risky", "trust": "trust"}


class App:
    def __init__(self):
        from .agent import Agent
        from .eyes import Eyes
        from .kwin import KWin, start_mainloop
        start_mainloop()
        self.events = server.Events()
        self.kwin = KWin() if os.environ.get("WAYLAND_DISPLAY") else None
        self.eyes = Eyes()
        self.agent = Agent(self.events, self.eyes, self.kwin)
        self.signin = None

    def settings_from_shell(self, s):
        out = {}
        for k, ours in SHELL_KEYS.items():
            if k in s:
                v = s[k]
                if k == "trust" and isinstance(v, str):
                    try:
                        v = json.loads(v or "{}")
                    except ValueError:
                        v = {}
                out[ours] = v
        if "jevKey" in s:
            out["jev_key"] = s["jevKey"] or ""
        return out

    def shell_hello(self, pid, apps):
        """The shell says it's here. Its pid comes from its window on the accessibility bus
        (QML can't see its own pid); its windows are never the AI's to act on through AT-SPI."""
        if not pid:
            for app, apid, name in self.eyes.apps():
                for j in range(app.get_child_count() or 0):
                    w = app.get_child_at_index(j)
                    if w is not None and (w.get_name() or "") in ("Firelamp OS", "Firelamp AI layer"):
                        pid = apid
        self.events.shell_pid = pid
        self.events._shell_apps = apps
        self.eyes.own_pids = {pid} if pid else set()

    def ask(self, text, shell_settings):
        changes = self.settings_from_shell(shell_settings)
        if changes:
            config.save(changes)
        # the shell's own windows never count as "the AI's" to act on through AT-SPI
        if self.events.shell_pid:
            self.eyes.own_pids = {self.events.shell_pid}
        return self.agent.ask(text, config.load())

    def configure(self, b):
        changes = self.settings_from_shell(b)
        for k in ("api_base", "api_key", "api_model", "local_model", "provider", "jev_key"):
            if k in b:
                changes[k] = b[k]
        if changes:
            config.save(changes)
            brains._puter_cache.clear()

    def status(self):
        cfg = config.load()
        st = {"busy": self.agent.busy, "shell": self.events.shell_here, "puter_user": cfg.get("puter_user", ""), "jev": bool(cfg.get("jev_key")),
              "keyboard": hands.keyboard_ready(), "signing_in": bool(self.signin and self.signin.is_alive()),
              "local_models": brains.ollama_models(), "api": bool(cfg.get("api_base"))}
        try:
            b = brains.pick(cfg)
            st["brain"] = {"ready": True, "provider": b.provider, "model": b.label}
        except brains.BrainError as e:
            st["brain"] = {"ready": False, "why": str(e)}
        return st

    def puter_signin(self):
        """Puter's own browser sign-in: it sends the token back to a one-shot local page."""
        if self.signin and self.signin.is_alive():
            return {"url": self.signin.url}
        srv = http.server.HTTPServer(("127.0.0.1", 0), _TokenPage)
        srv.token = None
        port = srv.server_address[1]
        url = "https://puter.com/?action=authme&redirectURL=" + urllib.parse.quote("http://localhost:%d" % port, safe="")

        def wait():
            srv.timeout = 1
            end = time.time() + 600
            while srv.token is None and time.time() < end:
                srv.handle_request()
            srv.server_close()
            if srv.token:
                user = ""
                try:
                    user = (brains._http("https://api.puter.com/whoami", key=srv.token, timeout=15) or {}).get("username", "")
                except brains.BrainError:
                    pass
                config.save({"puter_token": srv.token, "puter_user": user or "Signed in"})
                brains._puter_cache.clear()
                self.events.emit("puter", user=user or "Signed in")
        t = threading.Thread(target=wait, daemon=True)
        t.url = url
        t.start()
        self.signin = t
        _open_url(url)
        return {"url": url}


class _TokenPage(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        tok = (q.get("token") or [""])[0]
        if tok:
            self.server.token = tok
        page = ("<!doctype html><meta charset=utf-8><title>Firelamp</title><body style='background:#121110;color:#EFEAE4;"
                "font:16px system-ui;display:grid;place-items:center;height:90vh'><div><h2>%s</h2><p>You can close this tab.</p></div>"
                % ("You're signed in to Puter." if tok else "Puter didn't send a sign-in. Try again from Settings."))
        data = page.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *a):
        pass


def _open_url(url):
    for cmd in (["xdg-open", url], ["kde-open", url], ["gio", "open", url]):
        try:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            return
        except OSError:
            continue


# ---- command line ----
def _call(path, body=None, timeout=30):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method="POST" if data is not None else "GET")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")


def _yes(prompt):
    try:
        return input(prompt + " [y/N] ").strip().lower() in ("y", "yes")
    except EOFError:
        return False


def cli_ask(text):
    try:
        code, r = _call("/events?after=-1")
    except OSError:
        print("firelamp-agent isn't running. Start it with: firelamp-agent serve", file=sys.stderr)
        return 1
    last = r["last"]
    code, r = _call("/ask", {"text": text})
    if code != 200:
        print("busy: it's still working on something else", file=sys.stderr)
        return 1
    while True:
        _, r = _call("/events?after=%d" % last, timeout=40)
        last = r["last"]
        for e in r["events"]:
            k = e["kind"]
            if k == "say":
                print("\033[38;5;209m●\033[0m", e["text"])
            elif k == "start":
                print("\033[2m(brain: %s%s)\033[0m" % (e["model"], ", reflexes: Jev" if e.get("jev") else ""))
            elif k == "log":
                en = e["entry"]
                print("  \033[2m%s\033[0m %s%s" % (en["kind"], en["title"], ("  — " + en["why"]) if en.get("why") else ""))
            elif k == "plan":
                print("Plan:\n" + "\n".join("  %d. %s" % (i + 1, l) for i, l in enumerate(e["lines"])))
                _call("/reply", {"req": e["req"], "ok": _yes("Go?")})
            elif k == "ask":
                print("\n\033[1m%s\033[0m\n%s" % (e["title"], e.get("body", "")))
                for d in e.get("details") or []:
                    print("  %s: %s" % (d[0], d[1]))
                _call("/reply", {"req": e["req"], "ok": _yes(e.get("allow", "Allow") + "?")})
            elif k in ("point", "opening"):
                _call("/reply", {"req": e["req"], "ok": True})
            elif k == "shell":
                _call("/reply", {"req": e["req"], "ok": False, "error": "no shell"})
            elif k == "done":
                return 0 if e["how"] == "done" else 2


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    cmd = argv[0] if argv else "serve"
    if cmd == "serve":
        app = App()
        try:
            server.serve(app)
        except OSError as e:
            print("firelamp-agent: can't listen on 127.0.0.1:%d (%s); is it already running?" % (server.PORT, e), file=sys.stderr)
            return 1
    elif cmd == "ask":
        return cli_ask(" ".join(argv[1:]))
    elif cmd == "status":
        try:
            print(json.dumps(_call("/status")[1], indent=2))
        except OSError:
            cfg = config.load()
            try:
                b = brains.pick(cfg)
                print("not running; would use %s (%s)" % (b.label, b.provider))
            except brains.BrainError as e:
                print("not running;", e)
    elif cmd == "tree":
        from .eyes import Eyes, render
        wins, _ = Eyes().snapshot(detail_limit=99)
        print(render(wins))
    elif cmd == "puter-signin":
        try:
            r = _call("/puter/signin", {})[1]
            print("Opened Puter's sign-in page:", r.get("url"))
        except OSError:
            print("Start the agent first: firelamp-agent serve", file=sys.stderr)
            return 1
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
