"""The reflexes: TypeSafe's Jev, a fast decision model that returns typed answers, not prose.

At Instant effort the brain names its next click ("the Save button in Kate") and Jev picks
which element on the new screen that is, saving a whole brain turn. At every effort Jev gives a
second, independent opinion on whether an action is risky. When no key is set, or Jev is slow
or unsure, the brain decides as usual.

Keys: a TypeSafe key (api.typesafe.ai) or an OpenRouter key (sk-or-…), which reaches the same
model through OpenRouter's System One endpoint.
"""
import json
import os
import ssl
import urllib.error
import urllib.request


class Jev:
    def __init__(self, key):
        self.key = key
        if key.startswith("sk-or-"):
            self.url, self.model = "https://openrouter.ai/api/v1/systemone", "typesafe/jev-1.13"
        else:
            self.url, self.model = "https://api.typesafe.ai/v1/systemone", "jev-latest"
        # a proxy or a test server can stand in for the endpoint
        self.url = os.environ.get("FIRELAMP_JEV_URL") or self.url
        self.failed = 0
        self.last_error = ""

    @property
    def ok(self):
        return bool(self.key) and self.failed < 3

    def _ask(self, state, questions):
        body = json.dumps({"state": state, "model": self.model, "questions": questions}).encode()
        req = urllib.request.Request(self.url, data=body, method="POST")
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", "Bearer " + self.key)
        try:
            with urllib.request.urlopen(req, timeout=6, context=ssl.create_default_context()) as resp:
                self.failed = 0
                return json.loads(resp.read().decode()).get("answers", {})
        except urllib.error.HTTPError as e:
            self.failed += 1
            self.last_error = f"HTTP {e.code}"
        except (urllib.error.URLError, TimeoutError, OSError, ValueError) as e:
            self.failed += 1
            self.last_error = str(getattr(e, "reason", e))
        return None

    def choose(self, state, instructions, options):
        """options: {key: description}. Returns (key, confidence) or (None, 0)."""
        if not self.ok or not options:
            return None, 0.0
        opts = dict(list(options.items())[:255])
        a = self._ask(state, {"pick": {"type": "choice", "instructions": instructions, "criteria": opts}})
        if not a or "pick" not in a:
            return None, 0.0
        return a["pick"].get("choice"), float(a["pick"].get("confidence") or 0)

    def risky(self, state):
        """Probability that the described action can't be undone or affects other people."""
        if not self.ok:
            return None
        a = self._ask(state, {"risky": {
            "type": "noul",
            "instructions": "Is this computer action risky: does it delete something, send or publish something "
                            "to other people, spend money, share private data, change system software, or "
                            "otherwise can't be undone?",
            "criteria": {"true": "Risky or irreversible; a person should approve it first",
                         "false": "Routine and reversible: opening, reading, typing a draft, saving a new file, navigating"},
        }})
        if not a or "risky" not in a:
            return None
        return float(a["risky"].get("noul") or 0)
