// About Firelamp OS.
import QtQuick
import QtQuick.Effects
import "../components"
import "../js/art.js" as Art

Item {
    id: app
    property var win
    function start(opts) {}
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 46; width: parent.width - 60; spacing: 6
        Item {
            width: 80; height: 93; anchors.horizontalCenter: parent.horizontalCenter
            GlowLogo { anchors.fill: parent; glow: 0.5 }
        }
        Item { width: 1; height: 8 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Firelamp OS"; color: Theme.text; font.family: Theme.font; font.pixelSize: 22; font.weight: Font.Bold }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "The best OS for AI automation"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
        Item { width: 1; height: 14 }
        Repeater {
            model: [["Version", "0.1 “Kindling”"], ["Base", "Arch Linux"], ["Assistant", Os.name], ["Brain", "Large language model"], ["Reflexes", "Jev by TypeSafe"], ["UI tree", "AT-SPI2, live"]]
            Row {
                required property var modelData
                spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
                Text { width: 110; horizontalAlignment: Text.AlignRight; text: modelData[0]; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                Text { width: 140; text: modelData[1]; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
            }
        }
        Item { width: 1; height: 18 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 7
            Image { width: 16; height: 16; sourceSize: Qt.size(32, 32); source: Art.maxwell("#cdbfb5"); anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Made with care by <b>ThatMaxwell</b>"; textFormat: Text.StyledText; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
