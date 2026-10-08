// The wallpaper: graphite, with one faint lamp glow low in the corner, like a room
// lit by a single lamp. Static by default; `breathe` lets the glow drift very slowly.
import QtQuick

Rectangle {
    id: wp
    property bool still: true
    property bool breathe: false
    gradient: Gradient {
        GradientStop { position: 0; color: "#141312" }
        GradientStop { position: 1; color: "#0f0e0d" }
    }

    // the lamp: a radial falloff drawn once, so it never bands or costs a frame
    Image {
        id: glow
        readonly property real d: wp.height * 1.7
        width: d * 1.28; height: d
        x: -width / 2 + wp.width * 0.08 + drift * wp.width * 0.02
        y: -height / 2 + wp.height * 1.05
        property real drift: 0
        sourceSize: Qt.size(256, 200)
        smooth: true
        source: "data:image/svg+xml;utf8," + encodeURIComponent(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 200"><defs><radialGradient id="g" cx=".5" cy=".5" r=".5">'
            + '<stop offset="0" stop-color="#2a221c" stop-opacity="1"/>'
            + '<stop offset=".35" stop-color="#2a221c" stop-opacity=".62"/>'
            + '<stop offset=".7" stop-color="#2a221c" stop-opacity=".18"/>'
            + '<stop offset="1" stop-color="#2a221c" stop-opacity="0"/></radialGradient></defs>'
            + '<rect width="256" height="200" fill="url(#g)"/></svg>')
        SequentialAnimation on drift {
            running: wp.breathe && !wp.still; loops: Animation.Infinite
            NumberAnimation { to: 1; duration: 40000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 40000; easing.type: Easing.InOutSine }
        }
    }

    // a photo wallpaper, when one is picked: it crossfades in and is dimmed a little so the
    // widgets and dock stay legible on it
    property string pick: Os.settings.wallpaper
    Image {
        id: photo
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(1920, 1200)
        source: wp.pick && wp.pick !== "graphite" ? Qt.resolvedUrl("../assets/photos/" + wp.pick + ".jpg") : ""
        opacity: wp.pick !== "graphite" && status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.22 }
    }
    // film grain, so the dark gradients never band and the screen feels like a material
    Image {
        anchors.fill: parent
        source: "../assets/grain.png"
        fillMode: Image.Tile
        opacity: 0.06          // the png's own alpha is sparse, so this lands at ~2–3% visible grain
        smooth: false
    }
}
