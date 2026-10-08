// Web: the start page.
import QtQuick
import QtQuick.Effects
import "../components"

Item {
    id: app
    property var win
    function start(opts) {}
    Rectangle {
        id: bar
        width: parent.width; height: 52; color: Theme.win2
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: Theme.line2 }
        Row {
            x: 84; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            TbButton { glyph: "chevronL"; label: "Back" }
            TbButton { glyph: "chevron"; label: "Forward" }
        }
        Rectangle {
            anchors.centerIn: parent; width: Math.min(460, parent.width - 380); height: 30; radius: 8; color: Theme.win3
            property string aiName: "Address bar"; property string aiRole: "textbox"
            Row { anchors.centerIn: parent; spacing: 6
                Glyph { name: "lock"; width: 12; height: 12; color: Theme.text3; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "start.firelamp.os"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13 } }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            TbButton { glyph: "reload"; label: "Reload" }
            TbButton { glyph: "plus"; label: "New tab" }
        }
    }
    Rectangle {
        anchors { top: bar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        gradient: Gradient { GradientStop { position: 0; color: "#232322" } GradientStop { position: 1; color: Theme.win } }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; y: 60; spacing: 22
            Item {
                width: 60; height: 70; anchors.horizontalCenter: parent.horizontalCenter
                GlowLogo { anchors.fill: parent; glow: 0.5 }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Good evening, Carrot"; color: Theme.text; font.family: Theme.font; font.pixelSize: 26; font.weight: Font.Bold }
            Rectangle {
                property string aiName: "Search the web"; property string aiRole: "textbox"
                anchors.horizontalCenter: parent.horizontalCenter; width: 480; height: 44; radius: 22; color: Theme.win3; border.color: Theme.line2; border.width: 0.5
                Glyph { x: 18; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.text3 }
                Text { x: 44; anchors.verticalCenter: parent.verticalCenter; text: "Search or ask anything"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 14 }
            }
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter; columns: 4; columnSpacing: 26; rowSpacing: 16; topPadding: 8
                Repeater {
                    model: [["GitHub", "#2a2320"], ["Jev", "#3b3b3a"], ["Hearth", "#5b5550"], ["Arch Wiki", "#3a7bd5"], ["Maps", "#5aa85a"], ["News", "#8a7a70"], ["Music", "#ff6a4a"], ["Docs", "#ffb547"]]
                    Column {
                        required property var modelData
                        property string aiName: modelData[0]; property string aiRole: "link"
                        spacing: 6; width: 72
                        Rectangle { width: 52; height: 52; radius: 14; color: parent.modelData[1]; anchors.horizontalCenter: parent.horizontalCenter
                            Text { anchors.centerIn: parent; text: parent.parent.modelData[0][0]; color: "white"; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Bold } }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData[0]; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }
            }
        }
    }
}
