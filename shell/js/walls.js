// Firelamp's own wallpapers: calm scenes drawn as SVG, so they are ours, sharp at any size
// and tiny on disk. "Dynamic" is the hills scene in four lights that follow the clock.
.pragma library

var LIGHTS = {
    dawn:  { sky: ["#2f3542", "#6c6f7d", "#b3a499"], sun: "#e9dccd", hills: ["#5a5c66", "#464851", "#33353d", "#22232a"] },
    day:   { sky: ["#5d6f80", "#8c9daa", "#c0c5c2"], sun: "#f3efe6", hills: ["#6d7a74", "#56635d", "#414c47", "#2f3733"] },
    dusk:  { sky: ["#2a2630", "#574850", "#86706a"], sun: "#c9a99a", hills: ["#4a3c40", "#3a2f34", "#2a2327", "#1b1719"] },
    night: { sky: ["#0b0d12", "#131721", "#1c2130"], sun: "#3a4252", hills: ["#161922", "#10131a", "#0b0d12", "#07080b"] }
};

function hills(l) {
    var c = LIGHTS[l] || LIGHTS.dusk;
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice">'
        + '<defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="' + c.sky[0] + '"/>'
        + '<stop offset=".55" stop-color="' + c.sky[1] + '"/><stop offset="1" stop-color="' + c.sky[2] + '"/></linearGradient>'
        + '<radialGradient id="g" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="' + c.sun + '" stop-opacity=".55"/>'
        + '<stop offset="1" stop-color="' + c.sun + '" stop-opacity="0"/></radialGradient></defs>'
        + '<rect width="1600" height="1000" fill="url(#s)"/>'
        + '<circle cx="1060" cy="560" r="260" fill="url(#g)"/><circle cx="1060" cy="560" r="34" fill="' + c.sun + '" opacity=".55"/>'
        + '<path d="M0 640 C200 560 380 600 560 570 S900 520 1100 580 1450 560 1600 600 V1000 H0Z" fill="' + c.hills[0] + '"/>'
        + '<path d="M0 720 C240 660 420 700 640 670 S1020 640 1240 690 1500 680 1600 700 V1000 H0Z" fill="' + c.hills[1] + '"/>'
        + '<path d="M0 800 C260 760 520 790 760 770 S1180 740 1400 790 1560 790 1600 800 V1000 H0Z" fill="' + c.hills[2] + '"/>'
        + '<path d="M0 880 C300 850 560 880 860 860 S1300 850 1600 880 V1000 H0Z" fill="' + c.hills[3] + '"/></svg>';
}

function fog() {
    var band = function (y, o) { return '<ellipse cx="800" cy="' + y + '" rx="1100" ry="70" fill="url(#m)" opacity="' + o + '"/>'; };
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice">'
        + '<defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1d2226"/><stop offset="1" stop-color="#4b5459"/></linearGradient>'
        + '<radialGradient id="m" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#9aa4a8" stop-opacity=".5"/><stop offset="1" stop-color="#9aa4a8" stop-opacity="0"/></radialGradient></defs>'
        + '<rect width="1600" height="1000" fill="url(#s)"/>'
        + '<path d="M0 700 C300 640 520 690 820 650 S1300 620 1600 680 V1000 H0Z" fill="#2c3337"/>'
        + band(640, .7) + band(760, .5)
        + '<path d="M0 820 C380 790 700 830 1040 800 S1450 800 1600 820 V1000 H0Z" fill="#232a2d"/>'
        + band(860, .45) + '</svg>';
}

function lamp() {
    // a dark room at night: one lamp low on the left, a tall window on the right
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice">'
        + '<defs><radialGradient id="l" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#6a5040" stop-opacity=".85"/>'
        + '<stop offset=".4" stop-color="#4a382d" stop-opacity=".45"/><stop offset="1" stop-color="#2a201a" stop-opacity="0"/></radialGradient>'
        + '<linearGradient id="w" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#151a22"/><stop offset="1" stop-color="#222935"/></linearGradient></defs>'
        + '<rect width="1600" height="1000" fill="#14110e"/>'
        + '<rect x="0" y="790" width="1600" height="210" fill="#0f0d0b"/>'
        + '<ellipse cx="420" cy="560" rx="640" ry="520" fill="url(#l)"/>'
        + '<rect x="860" y="230" width="280" height="470" rx="4" fill="url(#w)"/>'
        + '<path d="M1000 230v470M860 465h280" stroke="#14110e" stroke-width="10"/>'
        + '<circle cx="1075" cy="320" r="15" fill="#cfd6df" opacity=".55"/>'
        + '<path d="M420 790v-260" stroke="#0c0a09" stroke-width="9"/><path d="M350 535h140l-28-84h-84z" fill="#6b5240"/>'
        + '<path d="M300 790h240" stroke="#0c0a09" stroke-width="12" stroke-linecap="round"/></svg>';
}

function dune() {
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice">'
        + '<defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d9d2c8"/><stop offset="1" stop-color="#bdb2a4"/></linearGradient></defs>'
        + '<rect width="1600" height="1000" fill="url(#s)"/>'
        + '<path d="M0 620 C260 540 520 520 760 600 S1240 700 1600 560 V1000 H0Z" fill="#a8998a"/>'
        + '<path d="M0 760 C340 660 640 700 900 760 S1360 820 1600 720 V1000 H0Z" fill="#94857a"/>'
        + '<path d="M0 880 C420 820 820 860 1180 880 S1500 870 1600 860 V1000 H0Z" fill="#7e7066"/></svg>';
}

function night() {
    var stars = "";
    var pts = [[180, 140], [420, 90], [610, 210], [880, 120], [1130, 180], [1350, 80], [1490, 230], [300, 300], [980, 300], [760, 60]];
    for (var i = 0; i < pts.length; i++) stars += '<circle cx="' + pts[i][0] + '" cy="' + pts[i][1] + '" r="' + (i % 3 ? 1.6 : 2.4) + '" fill="#c9d1dc" opacity="' + (i % 2 ? .35 : .6) + '"/>';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice">'
        + '<defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#07090d"/><stop offset="1" stop-color="#141a24"/></linearGradient></defs>'
        + '<rect width="1600" height="1000" fill="url(#s)"/>' + stars
        + '<path d="M0 860 C400 830 800 850 1200 835 S1500 840 1600 845 V1000 H0Z" fill="#06070a"/></svg>';
}

// the light for an hour of the day
function lightAt(h) { return h < 5 || h >= 21 ? "night" : h < 9 ? "dawn" : h < 17 ? "day" : "dusk"; }

function svg(name, hour) {
    if (name === "dynamic") return hills(lightAt(hour));
    if (name === "hills") return hills("dusk");
    if (name === "fog") return fog();
    if (name === "lamp") return lamp();
    if (name === "dune") return dune();
    if (name === "night") return night();
    return "";
}
function uri(name, hour) { var s = svg(name, hour); return s ? "data:image/svg+xml;utf8," + encodeURIComponent(s) : ""; }

// what the Wallpaper tab offers, in order; photos come from shell/assets/photos
var LIST = [
    ["graphite", "Graphite"], ["dynamic", "Dynamic"], ["hills", "Hills"], ["lamp", "Lamp"], ["fog", "Fog"],
    ["dune", "Dune"], ["night", "Night"], ["deep-field", "Deep field"]
];
var GENERATED = ["dynamic", "hills", "lamp", "fog", "dune", "night"];
