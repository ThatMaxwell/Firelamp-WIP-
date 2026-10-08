// Calendar: this month. Events come from Os.events (empty on a fresh install).
import QtQuick
import "../components"

Item {
    id: app
    property var win
    function start(opts) {}
    readonly property var now: new Date()
    readonly property int first: new Date(now.getFullYear(), now.getMonth(), 1).getDay()
    readonly property int days: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    readonly property int prev: new Date(now.getFullYear(), now.getMonth(), 0).getDate()
    readonly property var events: Os.events
    Row {
        x: 92; y: 12; spacing: 8
        Text { text: Os.months[app.now.getMonth()]; color: Theme.text; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Bold }
        Text { text: app.now.getFullYear(); color: Theme.text2; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Light }
    }
    Row {
        anchors.right: parent.right; anchors.rightMargin: 12; y: 12; spacing: 4
        TbButton { glyph: "chevronL"; label: "Previous month" }
        FButton { text: "Today" }
        TbButton { glyph: "chevron"; label: "Next month" }
    }
    Grid {
        id: g
        x: 10; y: 56; columns: 7
        readonly property real cw: (app.width - 20) / 7
        readonly property real chh: (app.height - 56 - 30 - 10) / 6
        Repeater { model: Os.days; Text { required property string modelData; width: g.cw; height: 26; horizontalAlignment: Text.AlignRight; rightPadding: 10; text: modelData; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 } }
        Repeater {
            model: 42
            Rectangle {
                id: cell
                required property int index
                readonly property int d: index - app.first + 1
                readonly property bool inMonth: d >= 1 && d <= app.days
                readonly property bool today: inMonth && d === app.now.getDate()
                width: g.cw; height: g.chh
                color: "transparent"
                border.color: Theme.line; border.width: 0.5
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 6; y: 5
                    width: 24; height: 22; radius: 11; color: cell.today ? Theme.accent : "transparent"
                    Text { anchors.centerIn: parent; text: cell.inMonth ? cell.d : cell.d < 1 ? app.prev + cell.d : cell.d - app.days
                           color: cell.today ? Theme.bg : cell.inMonth ? Theme.text : Theme.text4; font.family: Theme.font; font.pixelSize: 12; font.weight: cell.today ? Font.Bold : Font.Normal }
                }
                Column {
                    x: 4; y: 30; width: parent.width - 8; spacing: 2
                    Repeater {
                        model: cell.inMonth ? (app.events[cell.d] || []) : []
                        Rectangle { required property var modelData; width: parent.width; height: 18; radius: 4
                            color: Theme.sel
                            Rectangle { width: 3; height: parent.height; radius: 1.5; color: modelData[1] ? "#8AA0B8" : "#B9A58A" }
                            Text { x: 7; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 10; elide: Text.ElideRight; text: modelData[0]; color: Theme.text; font.family: Theme.font; font.pixelSize: 11 } }
                    }
                }
            }
        }
    }
}
