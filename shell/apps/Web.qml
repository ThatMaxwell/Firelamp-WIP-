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
                Logo { anchors.fill: parent }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Os.demo ? "Good evening, Carrot" : ["Good night", "Good morning", "Good afternoon", "Good evening"][Math.floor(new Date().getHours() / 6)]; color: Theme.text; font.family: Theme.font; font.pixelSize: 26; font.weight: Font.DemiBold }
            Rectangle {
                property string aiName: "Search the web"; property string aiRole: "textbox"
                anchors.horizontalCenter: parent.horizontalCenter; width: 480; height: 44; radius: 12; color: Theme.surface2; border.color: Theme.hairline2; border.width: 1
                Glyph { x: 18; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.text3 }
                Text { x: 44; anchors.verticalCenter: parent.verticalCenter; text: "Search or ask anything"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 14 }
            }
            // where you were, not a wall of letter tiles
            Column {
                visible: Os.demo
                width: 480; spacing: 2; topPadding: 6
                Text { x: 4; text: "Recent"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; bottomPadding: 6 }
                Repeater {
                    model: [["Installation guide", "wiki.archlinux.org", "doc"], ["Jev early access: getting started", "typesafe.ai/jev", "type"], ["ThatMaxwell/Firelamp-WIP-", "github.com", "code"]]
                    Rectangle {
                        id: rr
                        required property var modelData
                        property string aiName: modelData[0]; property string aiRole: "link"
                        width: 480; height: 40; radius: 8
                        color: rma.containsMouse ? Theme.hover : "transparent"
                        Rectangle { x: 8; width: 24; height: 24; radius: 6; anchors.verticalCenter: parent.verticalCenter; color: Theme.surface2; border.color: Theme.hairline; border.width: 1
                            Glyph { anchors.centerIn: parent; width: 12; height: 12; name: "globe"; color: Theme.text3 } }
                        Text { x: 44; anchors.verticalCenter: parent.verticalCenter; text: rr.modelData[0]; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
                        Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: rr.modelData[1]; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                        MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }
    }
}
