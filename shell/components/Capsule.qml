// The control capsule: who is working, what they're doing, and pause / stop.
// Quiet on purpose: a surface, a hairline and one ember dot that says the AI is live.
import QtQuick
import QtQuick.Effects

Item {
    id: cap
    property string what: ""
    property int steps: 0
    property bool paused: false
    property bool shown: false
    property bool aiHidden: true          // the AI can't press its own stop button
    width: row.implicitWidth + 20
    height: 36
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.94
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: shown ? 300 : 180; easing.type: Easing.OutQuint } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    RectangularShadow { anchors.fill: bg; radius: 18; blur: 24; offset.y: 8; color: Qt.rgba(0, 0, 0, 0.35) }
    Rectangle { id: bg; anchors.fill: parent; radius: 18; color: Theme.surface1; border.color: Theme.hairline2; border.width: 1 }

    Row {
        id: row
        x: 14; anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Rectangle { width: 6; height: 6; radius: 3; color: cap.paused ? Theme.text3 : Theme.ember; anchors.verticalCenter: parent.verticalCenter }
        Text { text: Os.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        Text {
            id: whatText
            width: Math.min(implicitWidth, 340)
            text: cap.paused ? "Paused" : cap.what
            elide: Text.ElideRight
            color: cap.paused ? Theme.text3 : Theme.text2
            font.family: Theme.font; font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            Behavior on text { SequentialAnimation { NumberAnimation { target: whatText; property: "opacity"; to: 0; duration: 100 } PropertyAction {} NumberAnimation { target: whatText; property: "opacity"; to: 1; duration: 140 } } }
        }
        Text { text: cap.steps + (cap.steps === 1 ? " step" : " steps"); color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: 24; height: 24; radius: 12; anchors.verticalCenter: parent.verticalCenter
            color: pma.containsMouse ? Theme.surface3 : Theme.surface2
            scale: pma.pressed ? 0.97 : 1
            Glyph { anchors.centerIn: parent; width: 11; height: 11; name: cap.paused ? "play" : "pause" }
            MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; onClicked: Os.agent.togglePause() }
        }
        Rectangle {
            width: 24; height: 24; radius: 12; anchors.verticalCenter: parent.verticalCenter
            color: sma.containsMouse ? Theme.surface3 : Theme.surface2
            scale: sma.pressed ? 0.97 : 1
            Glyph { anchors.centerIn: parent; width: 11; height: 11; name: "stop"; color: Theme.text2 }
            MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: Os.agent.stop() }
        }
    }
}
