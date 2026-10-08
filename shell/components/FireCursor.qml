// The fire cursor: the AI's own pointer, independent of yours (design/DIRECTION.md §7).
// It travels on a Fitts path with minimum-jerk easing, settles, shows one small tag naming
// what it is about to touch, then acts. It never outlines what it passes over, and it
// fades out when it has been idle for a moment.
import QtQuick
import QtQuick.Effects

Item {
    id: fc
    anchors.fill: parent

    readonly property real h: 30
    readonly property real s: h / 980
    readonly property real hotX: (118 - 20) * s
    readonly property real hotY: (202 - 20) * s
    property real px: parent ? parent.width / 2 : 0     // hotspot position
    property real py: parent ? parent.height - 140 : 0
    property bool shown: false
    property bool paused: false
    property bool pressed: false     // held down while dragging
    property bool busy: false        // the agent is typing or reading in place
    property string verb: ""         // kept for the agent; not drawn
    property string target: ""       // the label on the target tag
    property string note: ""         // overrides the tag while paused (e.g. why it's stuck)
    property bool idle: false

    // ---- movement: Fitts time, minimum-jerk easing, a very slight arc ----
    property real sx; property real sy; property real cx; property real cy; property real tx; property real ty
    property real u: 0
    property var onArrive: null
    onUChanged: {
        var t = u * u * u * (10 - 15 * u + 6 * u * u);      // minimum jerk
        var a = 1 - t;
        px = a * a * sx + 2 * a * t * cx + t * t * tx;
        py = a * a * sy + 2 * a * t * cy + t * t * ty;
    }
    NumberAnimation {
        id: mover
        target: fc; property: "u"; from: 0; to: 1
        easing.type: Easing.Linear
        onFinished: settle.restart()
    }
    // arrive, settle 40 ms, then hand back
    // every pause runs on the animation clock, so the cursor's rhythm holds at any frame rate
    SequentialAnimation { id: settle; PauseAnimation { duration: 40 } ScriptAction { script: { var cb = fc.onArrive; fc.onArrive = null; if (cb) cb(); } } }

    function moveTo(x, y, done, w) {
        wake();
        var dx = x - px, dy = y - py, dist = Math.hypot(dx, dy);
        if (dist < 1) { onArrive = done; settle.restart(); return; }
        var width = Math.max(12, w || 32);
        var ms = Math.max(140, Math.min(520, 110 + 90 * Math.log2(1 + dist / width)));
        var bow = (dx >= 0 ? 1 : -1) * Math.min(36, dist * 0.08);
        sx = px; sy = py; tx = x; ty = y;
        cx = sx + dx / 2 - (dy / dist) * bow; cy = sy + dy / 2 + (dx / dist) * bow;
        onArrive = done;
        mover.duration = ms / (Os.settings.cursorSpeed || 1);
        mover.restart();
    }
    // a deliberate stroke at a set pace (used when the cursor signs its name)
    function glide(x, y, ms, done) {
        wake();
        sx = px; sy = py; tx = x; ty = y; cx = (sx + tx) / 2; cy = (sy + ty) / 2 + 3;
        onArrive = done;
        mover.duration = ms;
        mover.restart();
    }
    onPausedChanged: { if (paused && mover.running) mover.pause(); else if (!paused && mover.paused) mover.resume(); wake(); }

    function show(from) {
        if (from) { px = from.x; py = from.y; }
        shown = true; wake();
    }
    function hide() { shown = false; target = ""; }
    // the tag appears ~150 ms before the action, then the action runs
    function aim(label, k) {
        target = label; wake();
        tagWait.k = k; tagWait.restart();
    }
    SequentialAnimation { id: tagWait; property var k; PauseAnimation { duration: 150 } ScriptAction { script: { var f = tagWait.k; tagWait.k = null; if (f) f(); } } }
    function clearTarget() { target = ""; }
    function click(done) {
        wake();
        squash.restart();
        ring.restart();
        clickTimer.done = done;
        clickTimer.restart();
    }
    SequentialAnimation { id: clickTimer; property var done; PauseAnimation { duration: 120 } ScriptAction { script: { if (clickTimer.done) clickTimer.done(); } } }

    // idle: no move, click or tag for 1.2 s, and not working in place
    function wake() { idle = false; idler.restart(); }
    SequentialAnimation { id: idler; PauseAnimation { duration: 1200 } ScriptAction { script: if (Os.settings.idleFade && !fc.busy && !mover.running && !fc.paused) fc.idle = true } }
    onBusyChanged: wake()

    // hand-drawn boil for the tag and ring: three fixed poses, ≤1.5 px
    property int boil: 0
    readonly property var poses: [[0, 0, 0], [1, -0.5, 0.6], [-0.5, 1, -0.5]]
    Timer { running: fc.shown && (fc.target !== "" || fc.paused || ring.running); interval: 130; repeat: true; onTriggered: fc.boil = (fc.boil + 1) % 3 }

    // click ring: one soft ring, 0→18 px over 180 ms
    Rectangle {
        id: ringInk
        property real r: 0
        width: r * 2; height: r * 2; radius: r
        x: fc.px - r + fc.poses[fc.boil][0] * 0.5; y: fc.py - r + fc.poses[fc.boil][1] * 0.5
        color: "transparent"
        border.color: Theme.ember; border.width: 1.5
        opacity: 0
        ParallelAnimation {
            id: ring
            NumberAnimation { target: ringInk; property: "r"; from: 2; to: 18; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: ringInk; property: "opacity"; from: 0.7; to: 0; duration: 180; easing.type: Easing.InQuad }
        }
    }

    // ---- the pointer itself ----
    Item {
        id: pointer
        x: fc.px - fc.hotX; y: fc.py - fc.hotY
        width: fc.h * 660 / 980; height: fc.h
        opacity: fc.shown && !fc.idle ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: fc.idle ? 400 : 160; easing.type: Easing.OutQuint } }
        // an 8% squash on click, pinned at the tip
        transform: Scale {
            id: sq; origin.x: fc.hotX; origin.y: fc.hotY
            xScale: 1 + (1 - yScale) * 0.6; yScale: fc.pressed ? 0.94 : 1
        }
        SequentialAnimation {
            id: squash
            NumberAnimation { target: sq; property: "yScale"; to: 0.92; duration: 60; easing.type: Easing.OutQuad }
            NumberAnimation { target: sq; property: "yScale"; to: 1; duration: 140; easing.type: Easing.OutQuint }
        }

        Logo {
            anchors.fill: parent
            animated: true
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowBlur: 0.35; shadowColor: Theme.ember; shadowOpacity: 0.45; shadowVerticalOffset: 1
                saturation: fc.paused ? -0.8 : 0
                brightness: fc.paused ? -0.1 : 0
                autoPaddingEnabled: true
            }
        }
    }

    // the target tag: the label of the one thing the cursor is about to touch
    Rectangle {
        id: tag
        objectName: "targetTag"
        x: fc.px + 14 + fc.poses[fc.boil][0]; y: fc.py + 24 + fc.poses[fc.boil][1]
        rotation: fc.poses[fc.boil][2]
        height: 20; radius: 6
        width: tagText.implicitWidth + 16
        color: "#2B1E17"
        border.color: Qt.rgba(242 / 255, 106 / 255, 46 / 255, 0.35); border.width: 1
        opacity: fc.shown && (fc.target !== "" || fc.paused) ? 1 : 0
        scale: opacity > 0 ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuint } }
        Text {
            id: tagText
            anchors.centerIn: parent
            text: fc.paused ? (fc.note || "Paused") : fc.target
            color: Theme.text; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 200)
        }
    }
}
