"""Local API the Firelamp shell (and the `firelamp-agent` command) talk to: 127.0.0.1:7342.

Same shape as firelamp-desktops: plain HTTP on localhost, JSON in and out, and one long-poll
event stream the shell listens to.

    POST /ask       {text, settings}     start a task           -> {task} or 409 while busy
    POST /reply     {req, ...}           answer a request from an event (Go, Allow, cursor arrived, …)
    POST /pause     {on}                 pause or resume between steps
    POST /stop                           stop now
    POST /config    {…}                  settings and keys (keys are stored only here, mode 0600)
    GET  /status                         {busy, brain, jev, puter_user, keyboard}
    POST /puter/signin                   opens Puter's sign-in page in your browser
    POST /puter/signout
    GET  /events?after=N                 {last, events:[…]}; waits up to 25 s (long poll)
    POST /hello     {pid, apps}          the shell says it's here (its pid, its built-in apps)

Events the shell acts on (kind): start, say, think, plan*, step, point*, press, busy, opening*,
log, ask*, shell*, paused, done, needs. Starred ones carry `req` and wait for POST /reply.
"""
import itertools
import json
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from . import config

PORT = 7342


class Events:
    def __init__(self):
        self.cv = threading.Condition()
        self.events = []
        self.n = 0
        self.reqs = itertools.count(1)
        self.replies = {}
        self.waiting = set()
        self.last_poll = 0.0
        self.shell_pid = 0
        self._shell_apps = []
        self.listeners = 0

    # ---- outgoing ----
    def emit(self, kind, **fields):
        with self.cv:
            self.n += 1
            e = dict(fields, kind=kind, n=self.n)
            self.events.append(e)
            del self.events[:-200]
            self.cv.notify_all()
            return e

    def after(self, n, wait=25.0):
        with self.cv:
            self.last_poll = time.time()
            self.listeners += 1
            try:
                if n >= 0:
                    self.cv.wait_for(lambda: self.n > n, timeout=wait)
            finally:
                self.listeners -= 1
                self.last_poll = time.time()
            return {"last": self.n, "events": [e for e in self.events if e["n"] > n]}

    @property
    def shell_here(self):
        return self.listeners > 0 or time.time() - self.last_poll < 30

    # ---- requests that wait for an answer ----
    def request(self, kind, timeout=10.0, **fields):
        """Emit an event and wait for POST /reply with its req. timeout=None waits until answered
        (or until cancel_waits). Without anyone listening, visual waits return at once."""
        req = next(self.reqs)
        if timeout is not None and not self.shell_here:
            self.emit(kind, req=req, **fields)
            return None
        with self.cv:
            self.waiting.add(req)
        self.emit(kind, req=req, **fields)
        with self.cv:
            self.cv.wait_for(lambda: req in self.replies or req not in self.waiting, timeout=timeout)
            self.waiting.discard(req)
            return self.replies.pop(req, None)

    def reply(self, req, body):
        with self.cv:
            if req in self.waiting:
                self.replies[req] = body
                self.cv.notify_all()
                return True
            return False

    def cancel_waits(self):
        with self.cv:
            self.waiting.clear()
            self.cv.notify_all()

    # ---- the shell's own UI (dock, built-in apps) ----
    def shell_apps(self):
        return self._shell_apps if self.shell_here else []

    def shell_snapshot(self, start_id):
        if not self.shell_here or not self._shell_apps:
            return []
        r = self.request("shell", timeout=2.0, op="snapshot")
        if not r:
            return []
        out, nid = [], start_id
        for k, w in enumerate(r.get("windows") or []):
            nodes = []
            for nd in (w.get("nodes") or [])[:90]:
                nodes.append({"id": nid, "i": nd.get("i"), "name": str(nd.get("name", ""))[:80],
                              "role": str(nd.get("role", "item")), "text": nd.get("text") or "",
                              "appTitle": "Firelamp " + str(w.get("title", "")), "shell": True})
                nid += 1
            out.append({"id": "f%d" % (k + 1), "app": w.get("app", ""), "title": w.get("title", ""),
                        "active": bool(w.get("active")), "nodes": nodes})
        return out

    def shell_act(self, op, **kw):
        if not self.shell_here:
            return {"ok": False, "error": "the Firelamp shell isn't running"}
        return self.request("shell", timeout=30.0, op=op, **kw) or {"ok": False, "error": "Firelamp didn't answer"}


def make_handler(app):
    class Api(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def reply(self, code, body):
            data = json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)

        def body(self):
            n = int(self.headers.get("Content-Length") or 0)
            if not n:
                return {}
            try:
                return json.loads(self.rfile.read(n).decode() or "{}")
            except ValueError:
                return {}

        def do_GET(self):
            u = urllib.parse.urlparse(self.path)
            q = urllib.parse.parse_qs(u.query)
            if u.path == "/events":
                try:
                    after = int(q.get("after", ["-1"])[0])
                except ValueError:
                    after = -1
                return self.reply(200, app.events.after(after))
            if u.path == "/status":
                return self.reply(200, app.status())
            self.reply(404, {"error": "not found"})

        def do_POST(self):
            u = urllib.parse.urlparse(self.path)
            b = self.body()
            if u.path == "/ask":
                text = str(b.get("text") or "").strip()
                if not text:
                    return self.reply(400, {"error": "empty"})
                tid = app.ask(text, b.get("settings") or {})
                return self.reply(200 if tid else 409, {"task": tid} if tid else {"error": "busy"})
            if u.path == "/reply":
                try:
                    req = int(b.get("req"))
                except (TypeError, ValueError):
                    return self.reply(400, {"error": "req"})
                return self.reply(200, {"ok": app.events.reply(req, b)})
            if u.path == "/pause":
                app.agent.pause(bool(b.get("on", True)))
                return self.reply(200, {"ok": True})
            if u.path == "/stop":
                app.agent.stop()
                return self.reply(200, {"ok": True})
            if u.path == "/config":
                app.configure(b)
                return self.reply(200, app.status())
            if u.path == "/hello":
                app.events.last_poll = time.time()
                try:
                    app.shell_hello(int(b.get("pid") or 0), [a for a in (b.get("apps") or []) if isinstance(a, dict) and a.get("id")])
                except Exception as e:
                    print("firelamp-agent: hello:", e)
                return self.reply(200, app.status())
            if u.path == "/puter/signin":
                return self.reply(200, app.puter_signin())
            if u.path == "/puter/signout":
                config.save({"puter_token": "", "puter_user": ""})
                return self.reply(200, app.status())
            self.reply(404, {"error": "not found"})

        def log_message(self, *a):
            pass
    return Api


def serve(app, port=PORT):
    srv = ThreadingHTTPServer(("127.0.0.1", port), make_handler(app))
    srv.daemon_threads = True
    srv.serve_forever()
