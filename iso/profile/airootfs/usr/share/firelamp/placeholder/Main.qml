// Firelamp OS placeholder desktop.
// Shown when no shell is installed in /usr/share/firelamp/shell, so the base
// image boots to something on-brand instead of an empty screen.
import QtQuick
import QtQuick.Shapes
import QtQuick.Window

Window {
    id: root
    visible: true
    visibility: Window.FullScreen
    width: 1280
    height: 800
    color: "#140d0b"
    title: "Firelamp"

    // Lava-lamp blobs drifting behind everything.
    component Blob: Shape {
        id: blob
        property color tint: "#ff6a2b"
        property real size: 600
        property real driftX: 80
        property real driftY: 60
        property int period: 14000
        property real baseX: 0
        property real baseY: 0
        width: size; height: size
        x: baseX; y: baseY
        opacity: 0.55
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: blob.size / 2; centerY: blob.size / 2
                focalX: centerX; focalY: centerY
                centerRadius: blob.size / 2; focalRadius: 0
                GradientStop { position: 0.0; color: Qt.rgba(blob.tint.r, blob.tint.g, blob.tint.b, 0.55) }
                GradientStop { position: 0.55; color: Qt.rgba(blob.tint.r, blob.tint.g, blob.tint.b, 0.12) }
                GradientStop { position: 1.0; color: Qt.rgba(blob.tint.r, blob.tint.g, blob.tint.b, 0.0) }
            }
            PathAngleArc {
                centerX: blob.size / 2; centerY: blob.size / 2
                radiusX: blob.size / 2; radiusY: blob.size / 2
                startAngle: 0; sweepAngle: 360
            }
        }
        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { to: blob.baseX + blob.driftX; duration: blob.period; easing.type: Easing.InOutSine }
            NumberAnimation { to: blob.baseX - blob.driftX; duration: blob.period; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { to: blob.baseY - blob.driftY; duration: blob.period * 1.3; easing.type: Easing.InOutSine }
            NumberAnimation { to: blob.baseY + blob.driftY; duration: blob.period * 1.3; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1b1210" }
            GradientStop { position: 1.0; color: "#0f0a09" }
        }
    }

    Blob { tint: "#ff5a1f"; size: root.height * 1.1; baseX: -root.width * 0.15; baseY: root.height * 0.35; period: 17000 }
    Blob { tint: "#ffb347"; size: root.height * 0.8; baseX: root.width * 0.62; baseY: -root.height * 0.2; period: 21000; driftX: 120 }
    Blob { tint: "#d9361c"; size: root.height * 0.9; baseX: root.width * 0.55; baseY: root.height * 0.55; period: 19000; opacity: 0.4 }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.height * 0.04
        spacing: 18

        Image {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl("../firelamp-logo.svg")
            sourceSize: Qt.size(Math.round(root.height * 0.2), Math.round(root.height * 0.2))
            smooth: true
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.04; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.04; to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Firelamp OS"
            color: "#f7ebe2"
            font.family: "Inter"
            font.pixelSize: Math.round(root.height * 0.065)
            font.weight: Font.DemiBold
            font.letterSpacing: -1
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "The base system is up. The desktop shell lands here next."
            color: "#b89f91"
            font.family: "Inter"
            font.pixelSize: Math.round(root.height * 0.022)
        }
    }

    // Small status pill, bottom centre, where the dock will live.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(root.height * 0.04)
        height: hint.implicitHeight + 22
        width: hint.implicitWidth + 40
        radius: height / 2
        color: "#cc231a17"
        border.color: "#3a2a24"
        border.width: 1

        Row {
            id: hint
            anchors.centerIn: parent
            spacing: 22
            Repeater {
                model: [
                    ["Super", "Enter", "Terminal"],
                    ["Alt", "Tab", "Switch windows"],
                    ["Right click", "", "Menu"]
                ]
                delegate: Row {
                    required property var modelData
                    spacing: 6
                    Repeater {
                        model: modelData.slice(0, 2).filter(k => k.length > 0)
                        delegate: Rectangle {
                            required property string modelData
                            width: keyText.implicitWidth + 14
                            height: keyText.implicitHeight + 6
                            radius: 6
                            color: "#2f231f"
                            border.color: "#4a3730"
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: "#ffcf9a"
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }
                    }
                    Text {
                        text: modelData[2]
                        color: "#d8c4b8"
                        font.family: "Inter"
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 18
        text: "Made with care, Firelamp."
        color: "#6e5a50"
        font.family: "Inter"
        font.pixelSize: 12
    }
}
