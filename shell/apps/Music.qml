// Music: now playing, and what's next. Covers are real photographs with simple type.
import QtQuick
import "../components"

Rectangle {
    id: app
    property var win
    property bool playing: true
    function start(opts) {}
    color: Theme.surface0

    // an album cover: a photograph, the title set small in the corner
    component Cover: Item {
        id: cv
        property string photo
        property string title
        property string artist
        property real type: 1
        clip: true
        Image { anchors.fill: parent; source: "../assets/photos/" + cv.photo + ".jpg"; fillMode: Image.PreserveAspectCrop; smooth: true; mipmap: true; asynchronous: true }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.55; color: "transparent" } GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.45) } } }
        Column {
            visible: cv.type > 0.5
            x: 14 * cv.type; anchors.bottom: parent.bottom; anchors.bottomMargin: 12 * cv.type; spacing: 1
            Text { text: cv.title; color: "#F4EFE6"; font.family: Theme.font; font.pixelSize: 15 * cv.type; font.weight: Font.DemiBold }
            Text { text: cv.artist; color: Qt.rgba(244 / 255, 239 / 255, 230 / 255, 0.7); font.family: Theme.font; font.pixelSize: 11 * cv.type }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 56; width: parent.width - 48; spacing: 16
        Cover {
            width: parent.width; height: width
            photo: "deep-field"; title: "Slow Rooms"; artist: "Hearth Tapes"
            scale: app.playing ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            layer.enabled: true
            Rectangle { anchors.fill: parent; color: "transparent"; border.color: Theme.hairline; border.width: 1 }
        }
        Column {
            spacing: 2
            Text { text: "Night Shift"; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.Bold }
            Text { text: "Hearth Tapes · Slow Rooms"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13 }
        }
        Column {
            width: parent.width; spacing: 4
            Rectangle { width: parent.width; height: 4; radius: 2; color: Theme.surface3
                Rectangle { height: 4; radius: 2; color: Theme.text2; width: parent.width * 0.34
                    NumberAnimation on width { running: app.playing; to: parent.width; duration: 140000 } } }
            Item { width: parent.width; height: 14
                Text { text: "1:12"; color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10 }
                Text { anchors.right: parent.right; text: "-2:21"; color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10 } }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 34
            Glyph { name: "chevronL"; width: 20; height: 20; color: Theme.text2; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                property string aiName: app.playing ? "Pause" : "Play"
                property string aiRole: "button"
                function aiActivate() { app.playing = !app.playing; }
                width: 48; height: 48; radius: 24; color: Theme.text
                Glyph { anchors.centerIn: parent; name: app.playing ? "pause" : "play"; color: Theme.bg; width: 20; height: 20 }
                MouseArea { anchors.fill: parent; onClicked: parent.aiActivate() }
            }
            Glyph { name: "chevron"; width: 20; height: 20; color: Theme.text2; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.hairline }
        Column {
            width: parent.width; spacing: 8
            Text { text: "Up next"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
            Repeater {
                model: [["launch-dusk", "Launch Window", "Pad Lights"], ["espresso", "Second Cup", "Pikolo Sessions"], ["gravel", "Gravel Hours", "Hearth Tapes"]]
                Row {
                    required property var modelData
                    property string aiName: modelData[1]; property string aiRole: "listitem"
                    spacing: 12
                    Cover { width: 36; height: 36; type: 0; photo: parent.modelData[0] }
                    Column { anchors.verticalCenter: parent.verticalCenter; spacing: 1
                        Text { text: parent.parent.modelData[1]; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
                        Text { text: parent.parent.modelData[2]; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 } }
                }
            }
        }
    }
}
