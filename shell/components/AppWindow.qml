// A window: Mac chrome (traffic lights, drag, resize, zoom), warm dark material,
// and open / close / minimize-to-dock animations.
import QtQuick
import QtQuick.Effects

Item {
    id: w
    property var app                     // registry entry {id, title, source, titled}
    property alias content: loader.item
    property bool focused: false
    property bool minimized: false
    property var restoreRect: null
    property var opts: ({})
    property string aiName: app ? app.title : ""
    property string aiRole: "window"
    property string aiApp: app ? app.id : ""
    readonly property string title: app ? app.title : ""
    signal closed()
    signal activated()

    // where the window flies from/to: the app's dock icon
    property point dockPoint: Qt.point(x + width / 2, y + height)
    function dockOrigin() {
        var r = Os.dock.iconRect(app.id);
        if (r) { var p = w.parent.mapFromItem(Os.root, r.x + r.width / 2, r.y + r.height / 2); dockPoint = Qt.point(p.x, p.y); }
    }

    // animation helpers: scale around the window centre, offset toward the dock
    property real k: 1          // 0 = at the dock, 1 = in place
    readonly property real dx: (dockPoint.x - (x + width / 2)) * (1 - k)
    readonly property real dy: (dockPoint.y - (y + height / 2)) * (1 - k)
    property real appear: 1     // opening: 0.94 → 1 with a fade, 300 ms
    // Edit home: each window slides off toward its nearer side edge
    readonly property real away: parent && parent.away !== undefined ? parent.away : 0
    readonly property real awayX: {
        if (!parent || away === 0) return 0;
        var left = x + width / 2 < parent.width / 2;
        return (left ? -(x + width + 60) : parent.width - x + 60) * away;
    }
    transform: [
        Translate { x: w.awayX },
        Scale { origin.x: w.width / 2; origin.y: w.height / 2; xScale: (0.08 + 0.92 * w.k) * (0.94 + 0.06 * w.appear); yScale: (0.06 + 0.94 * w.k) * (0.94 + 0.06 * w.appear) },
        Translate { x: w.dx; y: w.dy }
    ]
    opacity: Math.min(1, k * 2.5) * appear

    function openAnim() { k = 1; appearA.start(); }
    function close() { closeA.start(); }
    function minimize() { dockOrigin(); minA.start(); }
    function restore() { visible = true; minimized = false; dockOrigin(); openA.start(); }
    function zoom() {
        var area = Qt.rect(6, 6, w.parent.width - 12, w.parent.height - 92);
        if (restoreRect) { frameA.to = restoreRect; restoreRect = null; }
        else { restoreRect = Qt.rect(x, y, width, height); frameA.to = area; }
        frameA.start();
    }
    NumberAnimation { id: appearA; target: w; property: "appear"; from: 0; to: 1; duration: 300; easing.type: Easing.OutQuint }
    NumberAnimation { id: openA; target: w; property: "k"; from: 0; to: 1; duration: 420; easing.type: Easing.OutQuint }
    ParallelAnimation {
        id: closeA
        NumberAnimation { target: w; property: "opacity"; to: 0; duration: 180 }
        NumberAnimation { target: w; property: "scale"; to: 0.94; duration: 180; easing.type: Easing.InQuad }
        onFinished: w.closed()
    }
    NumberAnimation { id: minA; target: w; property: "k"; to: 0; duration: 420; easing.type: Easing.InQuart; onFinished: { w.visible = false; w.minimized = true; } }
    ParallelAnimation {
        id: frameA
        property rect to
        NumberAnimation { target: w; property: "x"; to: frameA.to.x; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: w; property: "y"; to: frameA.to.y; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: w; property: "width"; to: frameA.to.width; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: w; property: "height"; to: frameA.to.height; duration: 340; easing.type: Easing.OutCubic }
    }

    // shadow
    RectangularShadow {
        anchors.fill: frame
        radius: Theme.rWin
        blur: w.focused ? 70 : 44
        offset.y: w.focused ? 28 : 18
        spread: -10
        color: Qt.rgba(0, 0, 0, w.focused ? 0.75 : 0.55)
        Behavior on blur { NumberAnimation { duration: 200 } }
    }

    Item {
        id: frame
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
        Rectangle { anchors.fill: parent; color: Theme.win }
        Loader {
            id: loader
            anchors.fill: parent
            anchors.topMargin: w.app && w.app.titled ? 38 : 0
            source: w.app ? w.app.source : ""
            onLoaded: { item.win = w; if (item.start) item.start(w.opts); }
        }
        // titled windows get a classic title strip
        Rectangle {
            visible: !!(w.app && w.app.titled)
            width: parent.width; height: 38
            color: Theme.win2
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: Theme.line2 }
            Text { anchors.centerIn: parent; text: w.title; color: w.focused ? Theme.text : Theme.text2; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
        }
    }
    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle { anchors.fill: parent; radius: Theme.rWin; color: "black" }
    }
    Rectangle { anchors.fill: parent; radius: Theme.rWin; color: "transparent"; border.color: Theme.hairline2; border.width: 1 }

    // title bar: drag + double-click zoom
    MouseArea {
        id: dragArea
        width: parent.width; height: w.app && w.app.titled ? 38 : 52
        property point grab
        onPressed: (m) => { w.activated(); grab = Qt.point(m.x, m.y); }
        onPositionChanged: (m) => { if (pressed) { w.x += m.x - grab.x; w.y = Math.max(0, w.y + m.y - grab.y); } }
        onDoubleClicked: w.zoom()
        propagateComposedEvents: true
        z: -1
    }

    // traffic lights
    Row {
        id: lights
        x: 16; y: w.app && w.app.titled ? 13 : 20
        spacing: 8
        z: 10
        property bool hovered: lma.containsMouse
        Repeater {
            model: [["close", Theme.lightClose, "Close"], ["min", Theme.lightMin, "Minimize"], ["zoom", Theme.lightZoom, "Zoom"]]
            Rectangle {
                required property var modelData
                property string aiName: modelData[2]
                property string aiRole: "button"
                property bool aiChrome: true      // window chrome: in the tree, but not drawn in vision mode
                function aiActivate() { if (modelData[0] === "close") w.close(); else if (modelData[0] === "min") w.minimize(); else w.zoom(); }
                width: 12; height: 12; radius: 6
                color: w.focused || lights.hovered ? modelData[1] : Theme.surface3
                border.color: Qt.rgba(0, 0, 0, 0.25); border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    visible: lights.hovered
                    text: modelData[0] === "close" ? "×" : modelData[0] === "min" ? "−" : "+"
                    color: Qt.rgba(0.25, 0.05, 0, 0.75)
                    font.pixelSize: 11; font.bold: true
                    anchors.verticalCenterOffset: -0.5
                }
                MouseArea { anchors.fill: parent; onClicked: parent.aiActivate() }
            }
        }
    }
    MouseArea { id: lma; anchors.fill: lights; z: 11; hoverEnabled: true; acceptedButtons: Qt.NoButton }

    // resize from the edges and corners
    Repeater {
        model: ["e", "s", "se", "w", "sw"]
        MouseArea {
            required property string modelData
            property point grab
            property rect start
            z: 11
            cursorShape: modelData === "e" || modelData === "w" ? Qt.SizeHorCursor : modelData === "s" ? Qt.SizeVerCursor : modelData === "se" ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
            x: modelData.indexOf("e") >= 0 ? w.width - 5 : modelData.indexOf("w") >= 0 ? -3 : 8
            y: modelData.indexOf("s") >= 0 ? w.height - 5 : 8
            width: modelData === "s" ? w.width - 16 : 8
            height: modelData === "e" || modelData === "w" ? w.height - 16 : 8
            onPressed: (m) => { w.activated(); var p = mapToItem(w.parent, m.x, m.y); grab = p; start = Qt.rect(w.x, w.y, w.width, w.height); }
            onPositionChanged: (m) => {
                if (!pressed) return;
                var p = mapToItem(w.parent, m.x, m.y), ddx = p.x - grab.x, ddy = p.y - grab.y;
                if (modelData.indexOf("e") >= 0) w.width = Math.max(320, start.width + ddx);
                if (modelData.indexOf("s") >= 0) w.height = Math.max(200, start.height + ddy);
                if (modelData.indexOf("w") >= 0) { var nw = Math.max(320, start.width - ddx); w.width = nw; w.x = start.x + start.width - nw; }
            }
        }
    }

    // any press inside brings the window forward, then passes through
    MouseArea { anchors.fill: parent; z: 100; onPressed: (m) => { w.activated(); m.accepted = false; } }
}
