// Photos: a warm library grid.
import QtQuick
import "../components"

Item {
    id: app
    property var win
    function start(opts) {}
    readonly property var photos: [["#ffb547", "#e2402a"], ["#3a1a10", "#ff8a3d"], ["#ffd08a", "#ff6a3a"], ["#2a1f1b", "#c8402f"], ["#ff9f6b", "#6a1f10"], ["#ffe3b8", "#ffb547"],
                                   ["#e2402a", "#2a0f08"], ["#ffc27a", "#8a3a1a"], ["#5a2a1a", "#ffd08a"], ["#ff7a33", "#ffd08a"], ["#1c0f0a", "#e2402a"], ["#ffb547", "#fff1d6"]]
    Row {
        x: 92; y: 15; spacing: 10
        Text { text: "Library"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
        Text { text: "Oct 2026"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13; anchors.baseline: parent.children[0].baseline }
    }
    SearchPill { anchors.right: parent.right; anchors.rightMargin: 12; y: 12 }
    Grid {
        id: g
        x: 14; y: 54; columns: 4; spacing: 4
        readonly property real cell: (app.width - 28 - 12) / 4
        Repeater {
            model: app.photos.length
            Rectangle {
                required property int index
                property string aiName: "Photo " + (index + 1)
                property string aiRole: "image"
                width: g.cell; height: g.cell * 0.72; radius: 3
                gradient: Gradient { GradientStop { position: 0; color: app.photos[index][0] } GradientStop { position: 1; color: app.photos[index][1] } }
                Rectangle { x: parent.width * (0.2 + (index * 17 % 50) / 100); y: parent.height * (0.15 + (index * 11 % 40) / 100); width: parent.width * 0.32; height: width; radius: width / 2; color: "#fff4d6"; opacity: 0.22 }
            }
        }
    }
}
