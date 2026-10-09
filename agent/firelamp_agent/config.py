"""Settings and secrets for the agent, kept in ~/.config/firelamp/agent.json (mode 0600).

The shell sends the user-facing settings (name, effort, trust) with every request; keys and
the Puter sign-in live only here. Environment variables override the file, for development
and CI runs:

    FIRELAMP_API_BASE / FIRELAMP_API_KEY / FIRELAMP_API_MODEL   any OpenAI-compatible endpoint
    FIRELAMP_PUTER_TOKEN                                         a Puter auth token
    FIRELAMP_JEV_KEY                                             a TypeSafe (or OpenRouter) key
    FIRELAMP_LOCAL_MODEL                                         an Ollama model, e.g. qwen2.5:7b
"""
import json
import os
import threading

DIR = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "firelamp")
PATH = os.path.join(DIR, "agent.json")

DEFAULTS = {
    "name": "",                 # the user names their assistant; no default
    "effort": 0,                # 0 Instant … 5 Ultra (Settings › Assistant › Effort)
    "reasoning": False,
    "model_fast": "",
    "model_balanced": "",
    "ask_before_risky": True,
    "trust": {},                # app id -> "all" | "risky" | "never"
    "provider": "",             # "" = pick automatically: puter, then api, then local
    "puter_token": "",
    "puter_user": "",
    "jev_key": "",
    "api_base": "",
    "api_key": "",
    "api_model": "",
    "local_model": "",
}
ENV = {
    "api_base": "FIRELAMP_API_BASE",
    "api_key": "FIRELAMP_API_KEY",
    "api_model": "FIRELAMP_API_MODEL",
    "puter_token": "FIRELAMP_PUTER_TOKEN",
    "jev_key": "FIRELAMP_JEV_KEY",
    "local_model": "FIRELAMP_LOCAL_MODEL",
    "provider": "FIRELAMP_PROVIDER",
}
SECRETS = ("puter_token", "jev_key", "api_key")

_lock = threading.Lock()


def load():
    cfg = dict(DEFAULTS)
    try:
        with open(PATH) as fh:
            cfg.update({k: v for k, v in json.load(fh).items() if k in DEFAULTS})
    except (OSError, ValueError):
        pass
    for key, var in ENV.items():
        if os.environ.get(var):
            cfg[key] = os.environ[var]
    return cfg


def save(changes):
    """Merge `changes` into the file. Values that came from the environment are not written."""
    with _lock:
        cur = {}
        try:
            with open(PATH) as fh:
                cur = json.load(fh)
        except (OSError, ValueError):
            pass
        cur.update({k: v for k, v in changes.items() if k in DEFAULTS})
        os.makedirs(DIR, exist_ok=True)
        tmp = PATH + ".tmp"
        fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as fh:
            json.dump(cur, fh, indent=2)
        os.replace(tmp, PATH)


def public(cfg):
    """What the shell may see: secrets become true/false."""
    return {k: (bool(v) if k in SECRETS else v) for k, v in cfg.items()}
