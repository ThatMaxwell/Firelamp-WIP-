// The wallpaper: a slow lava lamp. A few warm blobs drift up and down; they are drawn
// into a tiny texture and blurred on the GPU, so the whole thing costs almost nothing.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: wp
    property bool still: false
    gradient: Gradient {
        GradientStop { position: 0; color: "#100b09" }
        GradientStop { position: 0.65; color: "#140d0a" }
        GradientStop { position: 1; color: "#22120c" }
    }

    Item {
        id: lamp
        anchors.fill: parent
        visible: false
        Repeater {
            model: [
                // x, y (0..1), size (of height), colour, rise time (s), sway (s)
                [0.12, 0.85, 0.55, "#7a2414", 46, 23], [0.32, 0.25, 0.38, "#5c1d10", 38, 31],
                [0.55, 0.95, 0.62, "#8a3418", 52, 27], [0.78, 0.40, 0.44, "#6b2212", 41, 19],
                [0.92, 0.90, 0.50, "#94401c", 57, 34], [0.45, 0.55, 0.30, "#4e190e", 35, 22],
                [0.68, 1.05, 0.36, "#a5501f", 44, 29]
            ]
            Rectangle {
                id: blob
                required property var modelData
                required property int index
                readonly property real s: wp.height * modelData[2]
                width: s; height: s * 0.92; radius: s / 2
                color: modelData[3]
                property real fy: modelData[1]
                property real fx: 0
                x: wp.width * modelData[0] - s / 2 + fx * wp.width * 0.06
                y: wp.height * fy - height / 2
                SequentialAnimation on fy {
                    running: !wp.still; loops: Animation.Infinite
                    NumberAnimation { to: blob.modelData[1] - 0.55; duration: blob.modelData[4] * 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: blob.modelData[1]; duration: blob.modelData[4] * 1000; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on fx {
                    running: !wp.still; loops: Animation.Infinite
                    NumberAnimation { to: 1; duration: blob.modelData[5] * 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1; duration: blob.modelData[5] * 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: blob.modelData[5] * 1000; easing.type: Easing.InOutSine }
                }
            }
        }
    }
    ShaderEffectSource {
        id: small
        anchors.fill: parent
        sourceItem: lamp
        textureSize: Qt.size(Math.max(1, wp.width / 28), Math.max(1, wp.height / 28))
        smooth: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: small
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2
        opacity: 0.78
    }
    // a little grain so the gradients never band
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0.06, 0.04, 0.035, 0.55) }
            GradientStop { position: 0.4; color: "transparent" }
        }
    }
}
