// The browsers first boot and Settings › Browser offer. `via` says how firelamp-desktops gets
// each one: "repo" (Arch/CachyOS packages), "flatpak" (Flathub, per user) or "aur" (through
// paru, only where it is installed). Firefox ships with Firelamp and is the default until you
// pick another. Tiles are plain monograms: no brand logos, and no orange.
.pragma library

var GROUPS = ["All", "Popular", "Private", "Firefox family", "Chromium family", "Different"];

var BROWSERS = [
    { id: "firefox", name: "Firefox", what: "Fast, open and the default", group: "Popular", via: "repo", included: true },
    { id: "chrome", name: "Chrome", what: "Google's browser, synced to your account", group: "Popular", via: "flatpak" },
    { id: "brave", name: "Brave", what: "Blocks ads and trackers out of the box", group: "Popular", via: "flatpak" },
    { id: "edge", name: "Edge", what: "Microsoft's Chromium browser", group: "Popular", via: "flatpak" },
    { id: "vivaldi", name: "Vivaldi", what: "Tabs, panels, every setting there is", group: "Popular", via: "repo" },
    { id: "opera", name: "Opera", what: "Sidebar messengers and a free VPN", group: "Popular", via: "flatpak" },
    { id: "helium", name: "Helium", what: "Light Chromium, nothing phones home", group: "Private", via: "aur" },
    { id: "librewolf", name: "LibreWolf", what: "Firefox, hardened for privacy", group: "Private", via: "flatpak" },
    { id: "mullvad", name: "Mullvad Browser", what: "Tor's privacy, without Tor", group: "Private", via: "flatpak" },
    { id: "tor", name: "Tor Browser", what: "Browses through the Tor network", group: "Private", via: "repo" },
    { id: "ungoogled", name: "Ungoogled Chromium", what: "Chromium with Google taken out", group: "Private", via: "flatpak" },
    { id: "zen", name: "Zen", what: "Calm Firefox with vertical tabs", group: "Firefox family", via: "flatpak" },
    { id: "floorp", name: "Floorp", what: "Firefox with workspaces and sidebars", group: "Firefox family", via: "flatpak" },
    { id: "waterfox", name: "Waterfox", what: "Independent Firefox, privacy first", group: "Firefox family", via: "flatpak" },
    { id: "chromium", name: "Chromium", what: "The open source base of Chrome", group: "Chromium family", via: "repo", mono: "Cr" },
    { id: "thorium", name: "Thorium", what: "Chromium tuned for speed", group: "Chromium family", via: "aur" },
    { id: "falkon", name: "Falkon", what: "KDE's light Qt browser", group: "Different", via: "repo" },
    { id: "konqueror", name: "Konqueror", what: "KDE's browser and file viewer", group: "Different", via: "repo" },
    { id: "epiphany", name: "GNOME Web", what: "Simple and clean, WebKit inside", group: "Different", via: "repo" },
    { id: "qutebrowser", name: "qutebrowser", what: "Keyboard-driven, Vim-style", group: "Different", via: "repo" },
    { id: "nyxt", name: "Nyxt", what: "Hackable, Lisp all the way down", group: "Different", via: "repo" },
    { id: "ladybird", name: "Ladybird", what: "A new engine from scratch. Early days", group: "Different", via: "aur" }
];

function byId(id) { for (var i = 0; i < BROWSERS.length; i++) if (BROWSERS[i].id === id) return BROWSERS[i]; return null; }
// two letters for the tile: "Ungoogled Chromium" → "UC", "qutebrowser" → "qb"
function mono(b) {
    if (b.mono) return b.mono;
    var w = b.name.split(" ");
    if (w.length > 1) return (w[0][0] + w[1][0]).toUpperCase();
    return b.name[0] + b.name[1].toLowerCase();
}
var API = "http://127.0.0.1:7341";
