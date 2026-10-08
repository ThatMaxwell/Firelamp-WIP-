// The fire cursor: the AI's own pointer, independent of yours. It glides on soft arcs,
// leaves a trail of embers, and its flame boils like hand-drawn animation.
import QtQuick
import QtQuick.Particles
import QtQuick.Effects

Item {
    id: fc
    anchors.fill: parent

    readonly property real h: 35
    readonly property real s: h / 980
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
        burst.burst(10, px, py);
    }
    function hide() { shown = false; }
    function click(done) {
        pressed = true;
        ring.restart();
        burst.burst(5, px, py);
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
        alpha: 0.75
        entryEffect: ImageParticle.Scale
    }
    Emitter {
        id: trail
        system: sys
        x: fc.px + 3; y: fc.py + 9
        width: 2; height: 2
        enabled: Os.settings.showTrail && fc.shown && mover.running && !fc.paused
        emitRate: 16
        lifeSpan: 650; lifeSpanVariation: 250
        size: 5; sizeVariation: 3; endSize: 1
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

    // click ring: a thin ripple, like a trackpad tap
    Rectangle {
        id: ringInk
        width: 40; height: 40; radius: 20
        x: fc.px - 20; y: fc.py - 20
        color: Qt.rgba(1, 1, 1, 0.06)
        border.color: Qt.rgba(1, 1, 1, 0.7); border.width: 1.2
        opacity: 0; scale: 0.3
        ParallelAnimation {
            id: ring
            NumberAnimation { target: ringInk; property: "scale"; from: 0.3; to: 1.15; duration: 480; easing.type: Easing.OutQuint }
            NumberAnimation { target: ringInk; property: "opacity"; from: 0.9; to: 0; duration: 480; easing.type: Easing.InQuad }
        }
    }

    // ---- the pointer itself ----
    Item {
        id: pointer
        x: fc.px - fc.hotX; y: fc.py - fc.hotY
        width: fc.h * 660 / 980; height: fc.h
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

        // name tag: a small dark glass pill that follows the flame
        Item {
            x: 22; y: 30
            width: tag.width; height: tag.height
            RectangularShadow { anchors.fill: tag; radius: 11; blur: 14; offset.y: 4; color: Qt.rgba(0, 0, 0, 0.5) }
            Rectangle {
                id: tag
                height: 22; radius: 11
                width: tagRow.implicitWidth + 18
                color: Qt.rgba(0.13, 0.13, 0.125, 0.94)
                border.color: Qt.rgba(1, 1, 1, 0.12); border.width: 0.5
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                clip: true
                Row {
                    id: tagRow; x: 9; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                    Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: fc.paused ? Theme.text3 : Theme.accent }
                    Text { text: Os.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Text { text: fc.verb; visible: fc.verb !== ""; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight; width: Math.min(implicitWidth, 220) }
                }
            }
        }
    }
}
