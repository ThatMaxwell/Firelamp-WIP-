// The ordinary system arrow, drawn by the shell. Only used when recording, where the
// screen grab leaves out the real pointer, so videos show both cursors.
import QtQuick
import QtQuick.Shapes

Item {
    id: up
    property bool aiHidden: true
    width: 1; height: 1
    Shape {
        x: -1; y: -1
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "#0d0d0d"; strokeColor: "#ffffff"; strokeWidth: 1.4; joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M1 1 L1 18.5 L5.4 14.4 L8.3 21 L11.2 19.8 L8.4 13.3 L14.4 13.3 Z" }
        }
    }
}
