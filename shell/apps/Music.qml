// Music: now playing.
import QtQuick
import QtQuick.Effects
import "../components"

Rectangle {
    id: app
    property var win
    property bool playing: true
    function start(opts) {}
    gradient: Gradient { GradientStop { position: 0; color: "#262524" } GradientStop { position: 0.6; color: "#1a1a19" } GradientStop { position: 1; color: "#151514" } }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 60; width: parent.width - 60; spacing: 18
        Rectangle {
            width: parent.width; height: width; radius: 14
            gradient: Gradient { GradientStop { position: 0; color: "#3a3836" } GradientStop { position: 1; color: "#1e1d1c" } }
            scale: app.playing ? 1 : 0.88
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            Logo { anchors.centerIn: parent; width: parent.width * 0.42; height: width * 1.16; animated: app.playing }
        }
        Column {
            spacing: 2
            Text { text: "Ember Hours"; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.Bold }
            Text { text: "Lo-Fi Hearth · Warm Static"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13 }
        }
        Column {
            width: parent.width; spacing: 4
            Rectangle { width: parent.width; height: 4; radius: 2; color: Qt.rgba(1, 1, 1, 0.12)
                Rectangle { height: 4; radius: 2; color: Theme.text2; width: parent.width * 0.34
                    NumberAnimation on width { running: app.playing; to: parent.width; duration: 140000 } } }
            Item { width: parent.width; height: 14
                Text { text: "1:12"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 10 }
                Text { anchors.right: parent.right; text: "-2:21"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 10 } }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 34
            Glyph { name: "chevronL"; width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                property string aiName: app.playing ? "Pause" : "Play"
                property string aiRole: "button"
                function aiActivate() { app.playing = !app.playing; }
                width: 52; height: 52; radius: 26; color: Theme.text
                Glyph { anchors.centerIn: parent; name: app.playing ? "pause" : "play"; color: "#1b1210"; width: 22; height: 22 }
                MouseArea { anchors.fill: parent; onClicked: parent.aiActivate() }
            }
            Glyph { name: "chevron"; width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
