// Firelamp OS design tokens: ember palette from the logo, warm darks, Mac-like metrics.
pragma Singleton
import QtQuick

QtObject {
    // Ember lives in the logo and the fire cursor. Everywhere else it is a rare accent:
    // primary buttons, switches that are on, today's date, an unread dot. Nothing more.
    readonly property color ember: "#E2402A"
    readonly property color orange: "#FF8A3D"
    readonly property color amber: "#FFB547"
    readonly property color cream: "#FFD08A"
    readonly property color accent: "#F0703A"
    readonly property color accentSoft: Qt.rgba(0.94, 0.44, 0.23, 0.16)

    // selection and ink are neutral
    readonly property color sel: Qt.rgba(1, 1, 1, 0.085)
    readonly property color selStrong: Qt.rgba(1, 1, 1, 0.14)
    readonly property color ink: Qt.rgba(0.96, 0.94, 0.92, 0.5)
    readonly property color success: "#7fcf95"
    readonly property color danger: "#ff7b68"

    // graphite with the faintest warmth, never brown
    readonly property color bg: "#0f0f0f"
    readonly property color win: "#1c1c1b"
    readonly property color win2: "#222221"
    readonly property color win3: "#2a2a29"
    readonly property color win4: "#353534"
    readonly property color side: "#191918"
    readonly property color line: Qt.rgba(1, 1, 1, 0.06)
    readonly property color line2: Qt.rgba(1, 1, 1, 0.1)
    readonly property color line3: Qt.rgba(1, 1, 1, 0.18)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.055)

    readonly property color text: "#f3f1ef"
    readonly property color text2: "#bdb9b5"
    readonly property color text3: "#87837f"
    readonly property color text4: "#5c5956"

    // the dock is plain dark grey, on purpose
    readonly property color dock: Qt.rgba(0.165, 0.157, 0.153, 0.86)
    readonly property color glass: Qt.rgba(0.11, 0.11, 0.105, 0.92)

    readonly property string font: "Inter"
    readonly property string mono: "JetBrains Mono"

    readonly property int menubarH: 30
    readonly property int rWin: 12

    // traffic lights stay exactly Mac
    readonly property color lightClose: "#ff5f57"
    readonly property color lightMin: "#febc2e"
    readonly property color lightZoom: "#28c840"

    // a little "spring" every Mac animation has
    readonly property int springCurve: Easing.OutBack
}
