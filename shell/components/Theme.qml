// Firelamp OS design tokens: ember palette from the logo, warm darks, Mac-like metrics.
pragma Singleton
import QtQuick

QtObject {
    // ember palette
    readonly property color ember: "#E2402A"
    readonly property color orange: "#FF8A3D"
    readonly property color amber: "#FFB547"
    readonly property color cream: "#FFD08A"
    readonly property color accent: "#FF7A33"
    readonly property color accentSoft: Qt.rgba(1, 0.48, 0.2, 0.16)

    // warm darks
    readonly property color bg: "#120d0b"
    readonly property color win: "#1b1614"
    readonly property color win2: "#211b18"
    readonly property color win3: "#2a231f"
    readonly property color win4: "#352c27"
    readonly property color line: Qt.rgba(1, 0.93, 0.87, 0.07)
    readonly property color line2: Qt.rgba(1, 0.93, 0.87, 0.12)
    readonly property color line3: Qt.rgba(1, 0.93, 0.87, 0.2)
    readonly property color hover: Qt.rgba(1, 0.94, 0.9, 0.07)

    readonly property color text: "#f7efe9"
    readonly property color text2: "#cdbfb5"
    readonly property color text3: "#93857b"
    readonly property color text4: "#665a52"

    // the dock is plain dark grey, on purpose
    readonly property color dock: Qt.rgba(0.165, 0.157, 0.153, 0.86)
    readonly property color glass: Qt.rgba(0.12, 0.1, 0.09, 0.9)

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
