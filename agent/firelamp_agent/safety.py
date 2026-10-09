"""When the assistant has to stop and ask you first.

Three independent signals, any one of which is enough:
  1. the brain marks the step risky,
  2. these rules recognise it (a Send/Delete/Buy button, a command that changes the system),
  3. Jev, when it has a key, judges it risky.
Deleting, sending, paying and sharing always ask, whatever the per-app setting says.
"""
import re
import shlex

ALWAYS = re.compile(r"\b(send|delete|remove|erase|trash|discard|pay|payment|purchase|buy|checkout|check out|order|"
                    r"subscribe|transfer|wire|donate|post|publish|share|tweet|reply all|forward|upload|"
                    r"uninstall|format|wipe|empty|overwrite|replace|permanently|destroy|revoke|unsubscribe)\b", re.I)
SOFT = re.compile(r"\b(install|submit|confirm|sign out|log ?out|reset|restart|shut ?down|reboot|apply|accept|agree)\b", re.I)

# commands that only look at things
READ_ONLY = {
    "ls", "cat", "head", "tail", "wc", "df", "du", "free", "uname", "whoami", "id", "date", "uptime", "hostname",
    "pwd", "echo", "printf", "which", "type", "file", "stat", "grep", "egrep", "rg", "ps", "lsblk", "lscpu",
    "lsusb", "lspci", "nproc", "printenv", "locale", "cal", "sort", "uniq", "cut", "tr", "basename", "dirname",
    "realpath", "readlink", "tree", "fastfetch", "neofetch", "sensors", "column", "md5sum",
    "sha256sum", "diff", "cmp", "jq", "true", "test", "seq", "xdg-user-dir", "getent", "groups", "last", "w", "who",
    "env", "nmcli", "lsmod", "dmesg", "journalctl", "glxinfo", "inxi", "upower", "acpi", "timedatectl", "hostnamectl",
    "localectl", "loginctl", "findmnt", "mount", "blkid", "find", "ip", "ss", "systemctl", "pacman",
    "flatpak", "git", "python3", "pip", "node", "npm", "top", "ping", "dig",
}
# for the ones above that can also change things, what makes them read-only
QUERY = {
    "find": lambda a: not any(x in ("-delete", "-exec", "-execdir", "-ok", "-okdir", "-fprint", "-fls") for x in a),
    "ip": lambda a: not any(x in ("add", "del", "delete", "set", "flush", "change", "replace") for x in a),
    "ss": lambda a: "-K" not in a,
    "systemctl": lambda a: bool(a) and a[0] in ("status", "list-units", "list-unit-files", "is-active", "is-enabled", "show", "cat", "list-timers"),
    "pacman": lambda a: bool(a) and (a[0].startswith("-Q") or a[0].startswith("-Ss") or a[0].startswith("-Si") or a[0].startswith("-Fs") or a[0] == "-F"),
    "flatpak": lambda a: bool(a) and a[0] in ("list", "info", "search", "remotes", "--version"),
    "git": lambda a: bool(a) and a[0] in ("status", "log", "diff", "show", "branch", "remote", "rev-parse", "ls-files", "blame", "--version"),
    "python3": lambda a: a in (["--version"], ["-V"]),
    "pip": lambda a: bool(a) and a[0] in ("list", "show", "--version"),
    "node": lambda a: a in (["--version"], ["-v"]),
    "npm": lambda a: bool(a) and a[0] in ("ls", "list", "view", "--version", "-v"),
    "top": lambda a: "-b" in a or any(x.startswith("-bn") for x in a),
    "mount": lambda a: not a,
    "env": lambda a: all(re.match(r"^-?\w+=|^-0$|^-u$", x) for x in a),
    "nmcli": lambda a: not any(x in ("connect", "disconnect", "delete", "modify", "add", "up", "down", "on", "off") for x in a),
    "journalctl": lambda a: not any(x.startswith("--vacuum") or x == "--rotate" for x in a),
    "timedatectl": lambda a: not a or a[0] in ("status", "show", "list-timezones"),
    "hostnamectl": lambda a: not a or a[0] in ("status",),
    "localectl": lambda a: not a or a[0] in ("status", "list-locales", "list-keymaps"),
    "loginctl": lambda a: not a or a[0] in ("list-sessions", "show-session", "session-status", "list-users", "user-status"),
}
DESTRUCTIVE = re.compile(r"(^|[\s;&|(])(rm|rmdir|shred|dd|mkfs\S*|wipefs|truncate|fdisk|parted|sgdisk|kill|pkill|killall|"
                         r"shutdown|reboot|poweroff|halt|chmod|chown|chgrp|mv|crontab|userdel|passwd|git\s+push|"
                         r"git\s+reset|git\s+clean|pacman\s+-R\S*|pacman\s+-S\S*|yay|paru|flatpak\s+(un)?install|"
                         r"systemctl\s+(stop|disable|mask|kill|reboot|poweroff))(\s|$)")


def command_risk(cmd):
    """(level, reason): level 0 read-only, 1 changes something, 2 destructive or system-wide."""
    if re.search(r"\bsudo\b|\bpkexec\b|\bdoas\b", cmd):
        return 2, "it runs as administrator"
    if DESTRUCTIVE.search(cmd):
        return 2, "it can delete or change things that are hard to get back"
    if re.search(r"\$\(|`|<\(|\beval\b|\bexec\b|\bsource\b|(^|[;&|]\s*)\.\s", cmd):
        return 1, "it runs other commands inside it"
    if re.search(r"curl[^|]*\|\s*(ba|z)?sh|wget[^|]*\|\s*(ba|z)?sh", cmd):
        return 2, "it runs a script from the internet"
    if re.search(r"(^|[^<>&2])>{1,2}\s*[^&\s]", cmd.replace("2>/dev/null", "").replace(">/dev/null", "")):
        return 1, "it writes to a file"
    for seg in re.split(r"\|\||&&|[;|]", cmd):
        seg = seg.strip()
        if not seg:
            continue
        try:
            words = shlex.split(seg)
        except ValueError:
            return 1, "I couldn't read the command"
        while words and re.match(r"^\w+=", words[0]):
            words = words[1:]
        if not words:
            continue
        prog = words[0].split("/")[-1]
        if prog not in READ_ONLY:
            return 1, "it changes something on this computer"
        if prog in QUERY and not QUERY[prog](words[1:]):
            return 1, "it changes something on this computer"
    return 0, ""


def element_risk(name, role=""):
    """2 for always-ask words (send, delete, buy…), 1 for softer ones (install, submit…)."""
    if ALWAYS.search(name or ""):
        return 2
    if SOFT.search(name or ""):
        return 1
    return 0


# which per-app trust setting covers a real app
APP_IDS = [
    ("terminal", r"konsole|terminal|kitty|alacritty|foot|xterm|wezterm|tilix|yakuake|ghostty"),
    ("web", r"firefox|chrom|brave|vivaldi|opera|edge|librewolf|zen|floorp|waterfox|falkon|konqueror|epiphany|tor browser|mullvad|helium|thorium"),
    ("files", r"dolphin|nautilus|thunar|nemo|pcmanfm|files"),
    ("mail", r"thunderbird|kmail|evolution|geary|mail|betterbird"),
    ("calendar", r"korganizer|calendar|merkuro"),
    ("notes", r"notes|joplin|obsidian|kjots"),
]


def app_id(app_name):
    n = (app_name or "").lower()
    for aid, pat in APP_IDS:
        if re.search(pat, n):
            return aid
    return n
