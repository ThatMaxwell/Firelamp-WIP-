// Firelamp OS design tokens (design/DIRECTION.md §4). Graphite surfaces, cream text.
// Ember belongs to the AI only: the fire cursor, its target tag, the Assistant, a live dot.
pragma Singleton
import QtQuick

QtObject {
    // ---- surfaces ----
    readonly property color bg: "#121110"
    readonly property color surface0: "#181716"
    readonly property color surface1: "#1F1D1B"
    readonly property color surface2: "#272422"
    readonly property color surface3: "#312E2B"
    readonly property color hairline: Qt.rgba(1, 244 / 255, 232 / 255, 0.07)
    readonly property color hairline2: Qt.rgba(1, 244 / 255, 232 / 255, 0.12)

    // ---- text ----
    readonly property color text: "#EFEAE4"
    readonly property color text2: "#ABA49C"
    readonly property color text3: "#76706A"
    readonly property color text4: "#57524D"

    // ---- the AI's colours ----
    readonly property color ember: "#F26A2E"
    readonly property color emberSoft: Qt.rgba(242 / 255, 106 / 255, 46 / 255, 0.14)
    readonly property color amber: "#FFB65C"

    // ---- status ----
    readonly property color danger: "#E5484D"
    readonly property color ok: "#3FB97A"
    readonly property color focusRing: Qt.rgba(239 / 255, 234 / 255, 228 / 255, 0.4)

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
    readonly property color line3: Qt.rgba(1, 244 / 255, 232 / 255, 0.2)
    readonly property color hover: Qt.rgba(1, 244 / 255, 232 / 255, 0.05)
    readonly property color ink: Qt.rgba(239 / 255, 234 / 255, 228 / 255, 0.4)
    readonly property color success: ok
    readonly property color accent: text             // primary actions are cream, not orange
    readonly property color onAccent: bg

    readonly property color dock: Qt.rgba(0x23 / 255, 0x21 / 255, 0x20 / 255, 0.92)
    readonly property color glass: Qt.rgba(0x1F / 255, 0x1D / 255, 0x1B / 255, 0.96)

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
    readonly property int rWin: 12

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
