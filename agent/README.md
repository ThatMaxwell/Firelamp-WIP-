# firelamp-agent

Firelamp OS's assistant, as a normal Linux program. You ask; it thinks with a real AI model,
reads every open app through the accessibility tree (AT-SPI), and acts on those apps with its
own visible cursor. It checks with you before anything risky and logs every step to Activity.

```
you ──ask──▶ shell (Ask bar, chat)  ──HTTP 127.0.0.1:7342──▶  firelamp-agent
                                                               ├─ brain   an LLM: plans, picks the next action   brain.py
                                                               ├─ Jev     fast typed picks + a risk opinion     jev.py
                                                               ├─ eyes    the live AT-SPI tree of every app      eyes.py
                                                               ├─ hands   AT-SPI actions, text, keys, launch    hands.py
                                                               └─ safety  what needs your OK                    safety.py
shell ◀── events: fire cursor moves, plan card, Activity, permission sheet, answers
```

Each turn the brain gets your request, the live tree of every window (roles, labels, text,
numbered) and the result of the last action, and answers with one JSON action: `open`,
`click`, `type`, `key`, `focus`, `read`, `run`, `wait` or `done`. The agent checks it against
the safety rules, moves the fire cursor there, does it on the real app, logs it with the
brain's reason and looks again. Tasks of three or more steps show a plan first and wait for Go.

## Running it

The session starts it (`firelamp-agent serve`) next to the shell. From a terminal:

```
firelamp-agent serve            run it for this session
firelamp-agent ask "…"          ask from a terminal and watch it work (plan and permission prompts in the terminal)
firelamp-agent status           which brain and reflexes it will use, whether the shell is connected
firelamp-agent tree             print the screen the way the assistant reads it
firelamp-agent puter-signin     sign in to Puter in your browser
```

## Brains

Nothing is canned. With no model set up it says so and tells you what it needs.

| Provider | How you set it up | Notes |
|---|---|---|
| Puter | Settings › Assistant › Puter account › Sign in (opens your browser) | The default. Effort picks the model: Instant, Fast and Balanced are quick models; High, Max and Ultra are Grok 4.5, 4.6 and 4.7 (older Grok when Puter doesn't list those yet). Reasoning is a switch. |
| Your own API | `FIRELAMP_API_BASE`, `FIRELAMP_API_KEY`, `FIRELAMP_API_MODEL`, or `api_*` in the config | Any OpenAI-compatible endpoint: xAI, OpenRouter, OpenAI… |
| On this computer | Settings › Assistant › Local model (an Ollama model, e.g. `qwen2.5:7b`) | Nothing leaves the machine. Its smaller context is respected. |

**Jev** (TypeSafe's decision model, bring your own key in Settings › Assistant) isn't a chat
model, so it never replaces the brain. At Instant, the brain names its next click and Jev picks
that element on the new screen, saving a whole brain turn. At every effort Jev gives a second
opinion on whether an action is risky. A TypeSafe key or an OpenRouter key (`sk-or-…`) works.

The model that actually answered is shown in Settings › Assistant › Thinking with and at the
start of each task.

## Eyes and hands

- Reading: AT-SPI2 through PyGObject. The active window and the next one get full detail.
  Firelamp's own windows (dock, menu bar, Notes, Settings) come from the shell itself.
- Acting: an element's own AT-SPI action (press, click, activate) and EditableText first,
  because they work the same on X11 and Wayland and never miss. Keys, and typing into
  terminals or editors without EditableText, go through xdotool on X11 and ydotool on
  Wayland (needs `ydotoold`). Apps start from their `.desktop` entries.
- Wayland: apps don't know where their windows are, so a small KWin script reports window
  positions and raises windows (`kwin.py`). The shell draws the fire cursor above every app on
  a layer-shell overlay.
- `run` executes bash for facts about this computer (disk, memory, packages), 60 s at most.

## Safety

- Deleting, sending, paying, sharing, installing and anything the brain or Jev flags as risky
  waits for Allow on the permission sheet. Commands are sorted into read-only (runs), changes
  something (asks) and destructive or `sudo` (always asks).
- Per app trust from Settings › Assistant: ask before anything, ask before risky things, or
  never ask (risky ones still ask).
- Stop works at once, even mid-thought. Pause holds it between steps.
- It doesn't guess. Each click names the element it means, and nothing happens when that
  element isn't on screen. Two failed tries at the same step (the element is missing, or a
  click or key changes nothing) stop it with “Couldn’t …”, Show me (it brings the app forward,
  you do the step, then press Done) and Stop. There are also caps of 3 unreadable answers and
  40 steps.
- It never types passwords, and every action is in Activity with the reason.

## Files

- `~/.config/firelamp/agent.json` (mode 0600): settings, the Puter sign-in and API keys.
  The shell sends name, effort and trust with each request; keys stay here.
- The API the shell uses is described at the top of `firelamp_agent/server.py`.
- `packages.x86_64`: the Arch packages it needs.

## Proof it works

`.github/workflows/agent.yml` runs `test/real_run.py` on Arch with the ISO's packages: the real
shell, the agent thinking with a real model (Puter when the `PUTER_AUTH_TOKEN` secret is set,
otherwise an open model in Ollama on the runner), and Kate. It asks like a person (Ctrl+K, type, Enter, click Go),
films the screen, and reads the apps back through AT-SPI afterwards. The film, screenshots and
summary land on the `agent-capture` branch.
