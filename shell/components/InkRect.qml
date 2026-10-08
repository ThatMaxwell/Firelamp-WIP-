// A hand-drawn outline that boils: the rounded rectangle is re-inked on a three-frame
// loop, each frame nudged by a different smooth noise. Used sparingly, on purpose.
import QtQuick
import QtQuick.Shapes

Shape {
    id: ink
    property real radius: 12
    property color color: Theme.orange
    property real lineWidth: 2
    property real wobble: 1.6
    property bool running: visible
    property int frame: 0
    property var frames: []

    preferredRendererType: Shape.CurveRenderer

    function outline(seed) {
        var w = width, h = height, r = Math.min(radius, w / 2, h / 2), pts = [];
        if (w < 2 || h < 2) return pts;
        // walk the rounded rect perimeter; offset each point along its normal
        var segs = [
            [r, 0, w - r, 0, 0, -1], [w, r, w, h - r, 1, 0],
            [w - r, h, r, h, 0, 1], [0, h - r, 0, r, -1, 0]];
        var corners = [[w - r, r, -Math.PI / 2], [w - r, h - r, 0], [r, h - r, Math.PI / 2], [r, r, Math.PI]];
        var s = 0, n = function (t) {
            return Math.sin(t * 0.05 + seed * 1.7) * 0.6 + Math.sin(t * 0.13 + seed * 4.1) * 0.4;
        };
        for (var i = 0; i < 4; i++) {
            var g = segs[i], len = Math.hypot(g[2] - g[0], g[3] - g[1]), steps = Math.max(2, Math.ceil(len / 8));
            for (var k = 0; k < steps; k++, s += len / steps) {
                var t = k / steps, d = n(s) * wobble;
                pts.push(Qt.point(g[0] + (g[2] - g[0]) * t + g[4] * d, g[1] + (g[3] - g[1]) * t + g[5] * d));
            }
            var c = corners[i];
            for (var a = 0; a < 6; a++, s += r * Math.PI / 12) {
                var ang = c[2] + a / 6 * Math.PI / 2, rr = r + n(s) * wobble;
                pts.push(Qt.point(c[0] + Math.cos(ang) * rr, c[1] + Math.sin(ang) * rr));
            }
        }
        pts.push(pts[0]);
        return pts;
    }
    function rebuild() { frames = [outline(1), outline(7), outline(13)]; }
    onWidthChanged: rebuild()
    onHeightChanged: rebuild()
    Component.onCompleted: rebuild()

    ShapePath {
        strokeColor: ink.color
        strokeWidth: ink.lineWidth
        fillColor: "transparent"
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap
        PathPolyline { path: ink.frames[ink.frame] || [] }
    }
    Timer {
        running: ink.running
        interval: 140; repeat: true
        onTriggered: ink.frame = (ink.frame + 1) % 3
    }
}
