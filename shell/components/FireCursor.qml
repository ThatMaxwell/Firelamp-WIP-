// The fire cursor: the AI's own pointer, independent of yours. It glides on soft arcs,
// leaves a trail of embers, and its flame boils like hand-drawn animation.
import QtQuick
import QtQuick.Particles
import QtQuick.Effects

Item {
    id: fc
    anchors.fill: parent

    readonly property real h: 35
    readonly property real s: h / 976
    readonly property real hotX: (118 - 20) * s
    readonly property real hotY: (202 - 20) * s
    property real px: parent ? parent.width / 2 : 0     // hotspot position
    property real py: parent ? parent.height - 140 : 0
    property real tilt: 0
    property bool shown: false
    property bool paused: false
    property bool pressed: false
    property string verb: ""
    property var carry: null        // an item dragged along with the cursor

    // ---- movement: a quadratic arc, eased, pausable ----
    property real sx; property real sy; property real cx; property real cy; property real tx; property real ty
    property real t: 0
    property var onArrive: null
    onTChanged: {
        var u = 1 - t, nx = u * u * sx + 2 * u * t * cx + t * t * tx, ny = u * u * sy + 2 * u * t * cy + t * t * ty;
        tilt += (Math.max(-10, Math.min(10, (nx - px) * 0.9)) - tilt) * 0.2;
        px = nx; py = ny;
    }
    NumberAnimation {
        id: mover
        target: fc; property: "t"; from: 0; to: 1
        easing.type: Easing.InOutCubic
        onFinished: { fc.tilt = 0; var cb = fc.onArrive; fc.onArrive = null; if (cb) cb(); }
    }
    function moveTo(x, y, done) {
        var dx = x - px, dy = y - py, dist = Math.hypot(dx, dy);
        if (dist < 1) { if (done) done(); return; }
        var speed = Os.settings.cursorSpeed || 1;
        var bow = (Math.random() < .5 ? -1 : 1) * Math.min(120, dist * .18);
        sx = px; sy = py; tx = x; ty = y;
        cx = sx + dx / 2 - (dy / dist) * bow; cy = sy + dy / 2 + (dx / dist) * bow;
        onArrive = done;
        mover.duration = Math.min(1100, 260 + dist * .55) / speed;
        mover.restart();
    }
    onPausedChanged: { if (paused && mover.running) mover.pause(); else if (!paused && mover.paused) mover.resume(); }

    function show(from) {
        if (from) { px = from.x; py = from.y; }
        shown = true;
        burst.burst(16, px, py);
    }
    function hide() { shown = false; }
    function click(done) {
        pressed = true;
        ring.restart();
        burst.burst(8, px, py);
        clickTimer.done = done;
        clickTimer.restart();
    }
    Timer { id: clickTimer; property var done; interval: 110; onTriggered: { fc.pressed = false; if (done) done(); } }

    // ---- embers ----
    ParticleSystem { id: sys; running: true }
    ImageParticle {
        system: sys
        source: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><defs><radialGradient id="g"><stop offset="0" stop-color="#ffffff"/><stop offset=".35" stop-color="#ffffff" stop-opacity=".7"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient></defs><circle cx="16" cy="16" r="16" fill="url(#g)"/></svg>')
        color: "#ff9a45"
        colorVariation: 0.18
        alpha: 0.9
        entryEffect: ImageParticle.Scale
    }
    Emitter {
        id: trail
        system: sys
        x: fc.px + 3; y: fc.py + 9
        width: 2; height: 2
        enabled: Os.settings.showTrail && fc.shown && mover.running && !fc.paused
        emitRate: 45
        lifeSpan: 800; lifeSpanVariation: 300
        size: 7; sizeVariation: 4; endSize: 1
        velocity: AngleDirection { angle: 270; angleVariation: 70; magnitude: 26; magnitudeVariation: 18 }
        acceleration: PointDirection { y: -30 }
    }
    Emitter {
        id: burst
        system: sys
        enabled: false
        lifeSpan: 700; lifeSpanVariation: 250
        size: 8; sizeVariation: 4; endSize: 1
        velocity: AngleDirection { angle: 270; angleVariation: 180; magnitude: 70; magnitudeVariation: 40 }
        acceleration: PointDirection { y: -40 }
    }
    Wander { system: sys; xVariance: 30; pace: 60 }

    // click ring: a boiling ink circle that expands and fades
    InkRect {
        id: ringInk
        width: 44; height: 44; radius: 22
        x: fc.px - 22; y: fc.py - 22
        color: Theme.amber
        opacity: 0; scale: 0.25
        running: opacity > 0
        ParallelAnimation {
            id: ring
            NumberAnimation { target: ringInk; property: "scale"; from: 0.25; to: 1.25; duration: 550; easing.type: Easing.OutCubic }
            NumberAnimation { target: ringInk; property: "opacity"; from: 1; to: 0; duration: 550 }
        }
    }

    // ---- the pointer itself ----
    Item {
        id: pointer
        x: fc.px - fc.hotX; y: fc.py - fc.hotY
        width: fc.h * 840 / 976; height: fc.h
        opacity: fc.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 350 } }
        transform: Rotation { origin.x: fc.hotX; origin.y: fc.hotY; angle: fc.tilt }
        scale: fc.pressed ? 0.82 : 1
        transformOrigin: Item.TopLeft
        Behavior on scale { NumberAnimation { duration: 90 } }

        Logo {
            id: art
            anchors.fill: parent
            animated: true
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowBlur: 0.6; shadowColor: "#ff6428"; shadowOpacity: 0.55; shadowVerticalOffset: 1
                saturation: fc.paused ? -0.7 : 0
                brightness: fc.paused ? -0.15 : 0
                autoPaddingEnabled: true
            }
        }

        // name tag
        Rectangle {
            x: 24; y: 29
            height: 22; radius: 11
            width: tagRow.implicitWidth + 17
            gradient: Gradient {
                GradientStop { position: 0; color: fc.paused ? "#8a7a70" : "#ff7f3e" }
                GradientStop { position: 1; color: fc.paused ? "#6a5c54" : "#e8492d" }
            }
            Row {
                id: tagRow; x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                Text { text: Os.name; color: "white"; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold }
                Text { text: fc.verb; visible: fc.verb !== ""; color: Qt.rgba(1, 1, 1, 0.88); font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight; width: Math.min(implicitWidth, 220) }
            }
        }
    }
}
