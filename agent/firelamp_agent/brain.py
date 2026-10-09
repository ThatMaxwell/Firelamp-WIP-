"""The brain: a large language model that talks with you and decides the next step.

Every provider is reached through the OpenAI-compatible chat API, so one client covers them:

    puter   Puter.js's OpenAI endpoint, signed in as you (Settings › Assistant › Puter account).
            Effort picks the model: Fast and Balanced are yours to choose, High to Ultra are Grok.
    api     any OpenAI-compatible endpoint with your own key (OpenRouter, xAI, OpenAI, …)
    local   Ollama on this computer: no account, nothing leaves the machine

Nothing here is canned: if no provider is set up, `pick()` says so and the assistant tells you
what it needs instead of pretending.
"""
import json
import os
import re
import ssl
import urllib.error
import urllib.request

PUTER_API = "https://api.puter.com/puterai/openai/v1"
OLLAMA = "http://127.0.0.1:11434"

# What each effort level asks Puter for, best first. Puter's catalog changes, so the names are
# matched loosely against its live model list and the first one it has wins; the model that
# actually answered is always reported back (timeline, Settings), never assumed.
TIERS = [
    ("Instant", ["grok-4-fast", "grok-4.1-fast", "gpt-5-nano", "gpt-5-mini", "gemini-2.5-flash-lite", "gpt-4.1-nano", "gpt-4o-mini"]),
    ("Fast", ["grok-4-fast", "grok-4.1-fast", "gpt-5-mini", "gemini-2.5-flash", "gpt-4o-mini"]),
    ("Balanced", ["claude-sonnet-4-5", "claude-sonnet", "gpt-5", "gemini-2.5-pro", "gpt-4.1"]),
    ("High", ["grok-4.5", "grok-4-1", "grok-4.1", "grok-4"]),
    ("Max", ["grok-4.6", "grok-4.5", "grok-4-1", "grok-4.1", "grok-4"]),
    ("Ultra", ["grok-4.7", "grok-4.6", "grok-4.5", "grok-4-1", "grok-4.1", "grok-4"]),
]


class BrainError(Exception):
    pass


def _norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower().split("/")[-1])


def _http(url, body=None, key="", timeout=60, method=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method or ("POST" if data else "GET"))
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "firelamp-agent/0.1")
    if key:
        req.add_header("Authorization", "Bearer " + key)
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
            return json.loads(resp.read().decode() or "null")
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:400]
        raise BrainError(f"HTTP {e.code}: {detail}") from None
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise BrainError(f"can't reach {url.split('/')[2]}: {getattr(e, 'reason', e)}") from None


class Brain:
    def __init__(self, provider, base, key, model, label, timeout=90):
        self.provider, self.base, self.key, self.model, self.label = provider, base.rstrip("/"), key, model, label
        self.timeout = timeout
        self.json_mode = provider in ("local", "api")
        self.reasoning = False
        # how much conversation fits: local models default to small context windows
        self.budget = int(os.environ.get("FIRELAMP_CONTEXT_CHARS") or (14000 if provider == "local" else 60000))

    def chat(self, messages, max_tokens=700, temperature=0.2):
        body = {"model": self.model, "messages": messages, "max_tokens": max_tokens, "temperature": temperature}
        if self.json_mode:
            body["response_format"] = {"type": "json_object"}
        if self.reasoning:
            body["reasoning_effort"] = "medium"
        try:
            r = _http(self.base + "/chat/completions", body, self.key, self.timeout)
        except BrainError as e:
            # some endpoints refuse the optional knobs; retry once without them
            if "HTTP 400" in str(e) and (self.json_mode or self.reasoning):
                self.json_mode = self.reasoning = False
                return self.chat(messages, max_tokens, temperature)
            raise
        try:
            msg = r["choices"][0]["message"]
            text = msg.get("content") or ""
            if isinstance(text, list):  # some providers return content parts
                text = "".join(p.get("text", "") for p in text if isinstance(p, dict))
            if r.get("model"):
                self.label = r["model"]
            return text
        except (KeyError, IndexError, TypeError):
            raise BrainError("unexpected answer: " + json.dumps(r)[:300]) from None


def _puter_models(token):
    try:
        r = _http(PUTER_API + "/models", key=token, timeout=15)
        return [m.get("id", "") for m in (r.get("data") or [])]
    except BrainError:
        return []


def _choose(wanted, available):
    """First wanted name that the provider lists (loose match), else the first wanted name."""
    if not available:
        return wanted[0]
    avail = {_norm(a): a for a in available}
    for w in wanted:
        n = _norm(w)
        if n in avail:
            return avail[n]
        for k, a in avail.items():
            if k.startswith(n):
                return a
    return wanted[0]


def ollama_models():
    try:
        r = _http(OLLAMA + "/api/tags", timeout=3)
        return [m["name"] for m in r.get("models", [])]
    except BrainError:
        return []


_puter_cache = {}


def pick(cfg):
    """The brain for these settings, or raise BrainError saying what's missing."""
    effort = max(0, min(5, int(cfg.get("effort") or 0)))
    order = [cfg["provider"]] if cfg.get("provider") else ["puter", "api", "local"]
    for p in order:
        if p == "puter" and cfg.get("puter_token"):
            tok = cfg["puter_token"]
            if tok not in _puter_cache:
                _puter_cache[tok] = _puter_models(tok)
            wanted = TIERS[effort][1]
            if effort == 1 and cfg.get("model_fast"):
                wanted = [cfg["model_fast"]]
            elif effort == 2 and cfg.get("model_balanced"):
                wanted = [cfg["model_balanced"]]
            model = _choose(wanted, _puter_cache[tok])
            b = Brain("puter", PUTER_API, tok, model, model)
        elif p == "api" and cfg.get("api_base") and cfg.get("api_model"):
            b = Brain("api", cfg["api_base"], cfg.get("api_key", ""), cfg["api_model"], cfg["api_model"])
        elif p == "local":
            have = ollama_models()
            model = cfg.get("local_model") or (have[0] if have else "")
            if not have or (cfg.get("local_model") and cfg["local_model"] not in have and cfg["local_model"] + ":latest" not in have):
                continue
            b = Brain("local", OLLAMA + "/v1", "ollama", model, model + " (on this computer)", timeout=600)
        else:
            continue
        b.reasoning = bool(cfg.get("reasoning")) and effort > 0
        return b
    raise BrainError("no brain set up")


def parse(text):
    """The first JSON object in a model's answer (models sometimes wrap it in prose or fences)."""
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```[a-zA-Z]*\s*|\s*```$", "", text)
    try:
        return json.loads(text)
    except ValueError:
        pass
    start = text.find("{")
    while start >= 0:
        depth, instr, esc = 0, False, False
        for i in range(start, len(text)):
            c = text[i]
            if instr:
                if esc:
                    esc = False
                elif c == "\\":
                    esc = True
                elif c == '"':
                    instr = False
            elif c == '"':
                instr = True
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(text[start:i + 1])
                    except ValueError:
                        break
        start = text.find("{", start + 1)
    raise BrainError("the model didn't answer with an action")
