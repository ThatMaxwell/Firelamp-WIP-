// The control capsule: who is working, what they're doing, and pause / stop.
// Its outline is hand-inked and boils while the AI works.
import QtQuick
import QtQuick.Effects

Item {
    id: cap
    property string what: ""
    property int steps: 0
    property bool paused: false
    property bool shown: false
    property bool aiHidden: true          // the AI can't press its own stop button
    width: row.implicitWidth + 18
    height: 40
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.5
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 260 } }
    Behavior on scale { NumberAnimation { duration: 480; easing.type: Easing.OutBack } }
    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    RectangularShadow { anchors.fill: bg; radius: 20; blur: 40; offset.y: 12; color: Qt.rgba(0, 0, 0, 0.6) }
    RectangularShadow { anchors.fill: bg; radius: 20; blur: 30; color: Qt.rgba(1, 0.4, 0.15, 0.25) }
    Rectangle { id: bg; anchors.fill: parent; radius: 20; color: Qt.rgba(0.086, 0.063, 0.05, 0.94) }
    InkRect { anchors.fill: parent; anchors.margins: -1; radius: 20; color: Qt.rgba(1, 0.54, 0.24, 0.9); running: cap.shown }

    Row {
        id: row
        x: 12; anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Logo { width: 17; height: 20; animated: cap.shown; anchors.verticalCenter: parent.verticalCenter }
        Text { text: Os.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        Text {
            id: whatText
            width: Math.min(implicitWidth, 340)
            text: cap.paused ? "Paused" : cap.what
            elide: Text.ElideRight
            color: cap.paused ? Theme.amber : Theme.text2
            font.family: Theme.font; font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            Behavior on text { SequentialAnimation { NumberAnimation { target: whatText; property: "opacity"; to: 0; duration: 100 } PropertyAction {} NumberAnimation { target: whatText; property: "opacity"; to: 1; duration: 140 } } }
        }
        Text { text: cap.steps + (cap.steps === 1 ? " step" : " steps"); color: Theme.text3; font.family: Theme.mono; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: 28; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
            color: pma.containsMouse ? Qt.rgba(1, 0.94, 0.9, 0.16) : Qt.rgba(1, 0.94, 0.9, 0.08)
            Glyph { anchors.centerIn: parent; width: 13; height: 13; name: cap.paused ? "play" : "pause" }
            MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; onClicked: Os.agent.togglePause() }
        }
        Rectangle {
            width: 28; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
            color: sma.containsMouse ? Qt.rgba(1, 0.37, 0.27, 0.3) : Qt.rgba(1, 0.37, 0.27, 0.18)
            Glyph { anchors.centerIn: parent; width: 13; height: 13; name: "stop"; color: "#ff8b72" }
            MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: Os.agent.stop() }
        }
    }
}
