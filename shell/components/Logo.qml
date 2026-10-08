// The fire-cursor logo. When animated, the flame redraws itself on a three-frame loop
// (hand-drawn "moving static"); the frames are pre-jittered paths from js/logo.js.
import QtQuick
import "../js/logo.js" as L

Item {
    id: logo
    property bool animated: false
    property int frame: 0
    implicitWidth: 34
    implicitHeight: 49

    Image {
        anchors.fill: parent
        visible: !logo.animated
        source: L.uri(-1)
        sourceSize: Qt.size(logo.width * 2, logo.height * 2)
        smooth: true; mipmap: true; fillMode: Image.PreserveAspectFit
    }
    Repeater {
        model: logo.animated ? 3 : 0
        Image {
            anchors.fill: parent
            visible: logo.frame === index
            source: L.uri(index)
            sourceSize: Qt.size(logo.width * 2, logo.height * 2)
            smooth: true; mipmap: true; fillMode: Image.PreserveAspectFit
        }
    }
    Timer {
        running: logo.animated
        interval: 140; repeat: true
        onTriggered: logo.frame = (logo.frame + 1) % 3
    }
}
