// Photos: a library grid.
import QtQuick
import "../components"

Item {
    id: app
    property var win
    function start(opts) {}
    // a real-looking library: skies, sea, moss, stone, dusk; one warm evening, not twelve
    readonly property var photos: [["#8DA2B4", "#3E4C59"], ["#C9C0B0", "#6E665A"], ["#5E6E58", "#26301F"], ["#2E3A48", "#11161C"], ["#B7C3C8", "#56656C"], ["#7A6C5D", "#2E2822"],
                                   ["#D8A47A", "#4A3428"], ["#3F4A44", "#1B201D"], ["#A7B2A0", "#4F5A4A"], ["#606B78", "#262B31"], ["#D9D2C5", "#9A9183"], ["#4B5563", "#1E232A"]]
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
                Rectangle { x: parent.width * (0.2 + (index * 17 % 50) / 100); y: parent.height * (0.15 + (index * 11 % 40) / 100); width: parent.width * 0.32; height: width; radius: width / 2; color: "#F4EFE6"; opacity: 0.16 }
            }
        }
    }
}
