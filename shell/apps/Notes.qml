// Notes: a list of notes and an editor. The AI reads the open note through "Note body".
import QtQuick
import "../components"

Item {
    id: app
    property var win
    property int sel: 1
    property var notes: [
        { title: "Launch sync — Oct 7", date: "10:31 PM", body: "• Site goes live with the intro video, EN + PT.\n• Dock: final icons are in. Trash glass approved.\n• Fire cursor gets the hand-drawn boil on the flame only.\n• Jev early access: wire it up as the reflex layer.\n• Next sync: Thursday, 4pm." },
        { title: "Groceries", date: "Yesterday", body: "Coffee beans, oat milk, lemons, bread, matches for the candle." },
        { title: "Ideas for the dock", date: "Mon", body: "A little ember under the assistant icon while it works. Done!" },
        { title: "Books to read", date: "Sep 28", body: "The Design of Everyday Things\nCalm Technology\nThe Timeless Way of Building" }
    ]
    function start(opts) {}
    function save() { if (sel >= 0) { var n = notes.slice(); n[sel] = Object.assign({}, n[sel], { body: body.text }); notes = n; } }
    function pick(i) { save(); sel = i; body.text = notes[i].body; body.deselect(); }
    Component.onCompleted: body.text = notes[sel].body

    Sidebar {
        id: side
        width: 260
        topPad: 48
        Repeater {
            model: app.notes.length
            Rectangle {
                id: ni
                required property int index
                readonly property var note: app.notes[index]
                property string aiName: note.title
                property string aiRole: "listitem"
                function aiActivate() { app.pick(index); }
                Accessible.role: Accessible.ListItem
                Accessible.name: note.title
                width: parent.width; height: 62; radius: 8
                color: app.sel === index ? Theme.selStrong : nma.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }
                Column {
                    x: 12; y: 11; width: parent.width - 24; spacing: 4
                    Text { width: parent.width; text: ni.note.title; elide: Text.ElideRight; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                    Row {
                        spacing: 7; width: parent.width
                        Text { text: ni.note.date; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
                        Text { width: parent.width - 80; text: ni.note.body.split("\n")[0].replace("• ", ""); elide: Text.ElideRight; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }
                MouseArea { id: nma; anchors.fill: parent; hoverEnabled: true; onClicked: ni.aiActivate() }
            }
        }
    }

    Item {
        anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12; y: 12; spacing: 4
            TbButton { glyph: "compose"; label: "New note" }
            TbButton { glyph: "sent"; label: "Share note" }
            SearchPill {}
        }
        Text {
            y: 58; anchors.horizontalCenter: parent.horizontalCenter
            text: (/[AP]M$/.test(app.notes[app.sel].date) ? "October 7, 2026 at " : "") + app.notes[app.sel].date
            color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
        }
        Flickable {
            id: fl
            x: 40; y: 90; width: parent.width - 80; height: parent.height - 110
            contentHeight: col.height; clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: col; width: fl.width; spacing: 14
                Text { width: parent.width; text: app.notes[app.sel].title; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 24; font.weight: Font.Bold }
                Item {
                    id: bodyBox
                    width: parent.width; height: body.contentHeight + 8
                    property string aiName: "Note body"
                    property string aiRole: "textbox"
                    function aiActivate() { body.forceActiveFocus(); }
                    function aiSelectAll() { body.selectAll(); }
                    function aiText() { return body.text; }
                    function aiType(ch) { body.insert(body.length, ch); }
                    Accessible.role: Accessible.EditableText
                    Accessible.name: "Note body"
                    TextEdit {
                        id: body
                        width: parent.width
                        wrapMode: TextEdit.Wrap
                        color: Theme.text; font.family: Theme.font; font.pixelSize: 15
                        selectionColor: Qt.rgba(1, 244 / 255, 232 / 255, 0.2); selectedTextColor: Theme.text
                        onTextChanged: if (activeFocus) app.save()
                    }
                }
            }
        }
        Scroller { flick: fl }
    }
}
