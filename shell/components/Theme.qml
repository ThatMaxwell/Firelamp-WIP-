// Firelamp OS design tokens (design/DIRECTION.md §4). Graphite surfaces, cream text.
// Ember belongs to the AI only: the fire cursor, its target tag, the Assistant, a live dot.
pragma Singleton
import QtQuick

QtObject {
    // ---- Looks (§13): one palette each; the ember never changes ----
    readonly property var looks: ({
        graphite: { bg: "#121110", s: ["#181716", "#1F1D1B", "#272422", "#312E2B"], line: [255, 244, 232],
                    t: ["#EFEAE4", "#ABA49C", "#76706A", "#57524D"], dock: [0x23, 0x21, 0x20], wall: ["#141312", "#0f0e0d"], glow: "#2a221c", light: false },
        paper:    { bg: "#ECE8E2", s: ["#F6F3EE", "#F1EDE7", "#FBF9F6", "#E4DFD8"], line: [40, 30, 20],
                    t: ["#1D1B19", "#58524C", "#8A837C", "#ADA69E"], dock: [0xF4, 0xF1, 0xEC], wall: ["#EAE6E0", "#DCD7D0"], glow: "#F6EFE6", light: true },
        midnight: { bg: "#000000", s: ["#0A0A0A", "#101010", "#171717", "#202020"], line: [255, 255, 255],
                    t: ["#EDEDED", "#A3A3A3", "#6E6E6E", "#4E4E4E"], dock: [0x12, 0x12, 0x12], wall: ["#000000", "#000000"], glow: "#0c0c0c", light: false },
        moss:     { bg: "#111410", s: ["#161A15", "#1C211B", "#242A22", "#2D342B"], line: [232, 244, 226],
                    t: ["#E8EDE4", "#A3ACA0", "#717A6E", "#535B51"], dock: [0x20, 0x25, 0x1E], wall: ["#141813", "#0d100c"], glow: "#1f2a1c", light: false },
        studio:   { bg: "#0F1011", s: ["#151617", "#1B1C1E", "#232527", "#2C2F31"], line: [230, 238, 244],
                    t: ["#E6E9EC", "#9EA4AA", "#6C7278", "#50555A"], dock: [0x1C, 0x1E, 0x20], wall: ["#121315", "#0c0d0e"], glow: "#16191c", light: false } })
    readonly property var pal: looks[Os.settings.look] || looks.graphite
    readonly property bool light: pal.light
    function _line(a) { return Qt.rgba(pal.line[0] / 255, pal.line[1] / 255, pal.line[2] / 255, a); }

    // ---- surfaces ----
    readonly property color bg: pal.bg
    readonly property color surface0: pal.s[0]
    readonly property color surface1: pal.s[1]
    readonly property color surface2: pal.s[2]
    readonly property color surface3: pal.s[3]
    readonly property color hairline: _line(light ? 0.10 : 0.07)
    readonly property color hairline2: _line(light ? 0.16 : 0.12)

    // ---- text ----
    readonly property color text: pal.t[0]
    readonly property color text2: pal.t[1]
    readonly property color text3: pal.t[2]
    readonly property color text4: pal.t[3]

    // ---- your color: focus rings, selection, toggles, links. Never the AI's ember. ----
    readonly property string userAccent: Os.settings.accent
    readonly property color toggleOn: userAccent || ok

    // ---- the AI's colours ----
    readonly property color ember: "#F26A2E"
    readonly property color emberSoft: Qt.rgba(242 / 255, 106 / 255, 46 / 255, 0.14)
    readonly property color amber: "#FFB65C"

    // ---- status ----
    readonly property color danger: "#E5484D"
    readonly property color ok: "#3FB97A"
    readonly property color focusRing: userAccent ? Qt.alpha(userAccent, 0.55) : Qt.alpha(text, 0.4)

    // older names, kept so every component reads from the same tokens
    readonly property color win: surface0
    readonly property color side: surface1
    readonly property color win2: surface1
    readonly property color win3: surface2
    readonly property color win4: surface3
    readonly property color sel: surface2
    readonly property color selStrong: surface3
    readonly property color line: hairline
    readonly property color line2: hairline2
    readonly property color line3: userAccent ? Qt.alpha(userAccent, 0.7) : _line(0.2)
    readonly property color hover: _line(0.05)
    readonly property color ink: Qt.alpha(text, 0.4)
    readonly property color success: ok
    readonly property color accent: text             // primary actions are cream, not orange
    readonly property color onAccent: bg

    readonly property color dock: Qt.rgba(pal.dock[0] / 255, pal.dock[1] / 255, pal.dock[2] / 255, 0.92)
    readonly property color glass: Qt.alpha(surface1, 0.96)
    readonly property color bar: Qt.alpha(bg, 0.85)

    // ---- type: Instrument Sans + Martian Mono, bundled (OFL) ----
    // static instances cut from the variable fonts (Martian Mono at normal width), one file per weight,
    // so Qt picks real weights instead of the variable default
    readonly property FontLoader f0: FontLoader { source: Qt.resolvedUrl("../fonts/InstrumentSans-Regular.ttf") }
    readonly property FontLoader f1: FontLoader { source: Qt.resolvedUrl("../fonts/InstrumentSans-Medium.ttf") }
    readonly property FontLoader f2: FontLoader { source: Qt.resolvedUrl("../fonts/InstrumentSans-SemiBold.ttf") }
    readonly property FontLoader f3: FontLoader { source: Qt.resolvedUrl("../fonts/InstrumentSans-Bold.ttf") }
    readonly property FontLoader f4: FontLoader { source: Qt.resolvedUrl("../fonts/MartianMono-Light.ttf") }
    readonly property FontLoader f5: FontLoader { source: Qt.resolvedUrl("../fonts/MartianMono-Regular.ttf") }
    readonly property FontLoader f6: FontLoader { source: Qt.resolvedUrl("../fonts/MartianMono-Medium.ttf") }
    readonly property string font: "Instrument Sans"
    readonly property string mono: "Martian Mono"

    readonly property int menubarH: 28
    readonly property int rWin: Os.settings.winRadius

    // traffic lights, 10% quieter than Mac
    readonly property color lightClose: "#E8574F"
    readonly property color lightMin: "#E6B03A"
    readonly property color lightZoom: "#3BB54E"

    // ---- motion (§6): critically damped, no overshoot ----
    readonly property int ease: Easing.OutQuint
    readonly property int springCurve: Easing.OutQuint
    readonly property int tFast: 140
    readonly property int tBase: 280
    readonly property int tOpen: 300
    readonly property int tClose: 180
}
