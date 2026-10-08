// Packs (DIRECTION §13): optional software, grouped by what you do. Nothing is pre-selected.
// The package lists match firelamp-desktops' PACKS; sizes are rough download sizes.
.pragma library

var PACKS = [
    { id: "dev", name: "Dev", glyph: "type", what: "Code, containers and the usual toolchains", size: "1.2 GB",
      packages: ["git", "base-devel", "neovim", "code", "podman", "nodejs", "npm", "python", "rustup", "go"] },
    { id: "make", name: "Make", glyph: "image", what: "Photos, drawing, video and streaming", size: "950 MB",
      packages: ["gimp", "krita", "inkscape", "kdenlive", "obs-studio"] },
    { id: "rice", name: "Rice", glyph: "moon", what: "Theming and a terminal that shows off", size: "40 MB",
      packages: ["kvantum", "fastfetch", "starship", "btop", "cava"] },
    { id: "play", name: "Play", glyph: "play", what: "Steam, Lutris and smoother frames", size: "650 MB",
      packages: ["steam", "lutris", "gamemode", "mangohud"] },
    { id: "office", name: "Office", glyph: "doc", what: "Documents, sheets, slides and mail", size: "700 MB",
      packages: ["libreoffice-fresh", "thunderbird"] }
];

var BASICS = "Firefox, mpv, Dolphin, Ark, Flatpak and snapshots are always installed.";
var API = "http://127.0.0.1:7341";
