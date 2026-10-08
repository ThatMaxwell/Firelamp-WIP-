// Notes: a list of notes and an editor. The AI reads the open note through "Note body".
import QtQuick
import "../components"

Item {
    id: app
    property var win
    // your notes live in Os.notes and are saved as you type; a fresh install has none
    property int sel: Os.notes.length ? (Os.demo ? 1 : 0) : -1
    readonly property var cur: sel >= 0 ? Os.notes[sel] : null
    function start(opts) {}
    function when(n) {
        if (n.date) return n.date;
        var d = new Date(n.at), now = new Date();
        return d.toDateString() === now.toDateString() ? Qt.formatTime(d, "h:mm AP") : Qt.formatDate(d, d.getFullYear() === now.getFullYear() ? "MMM d" : "MMM d, yyyy");
    }
    function save() {
        if (sel < 0 || !cur || cur.body === body.text) return;
        var n = Os.notes.slice(); n[sel] = Object.assign({}, n[sel], { body: body.text, at: Date.now() });
        Os.saveNotes(n);
    }
    // leaving a note you never wrote in drops it, like Notes on a Mac
    function dropEmpty() {
        if (sel < 0 || !cur || cur.body.trim() || cur.title) return false;
        var n = Os.notes.slice(); n.splice(sel, 1); Os.saveNotes(n); return true;
    }
    function pick(i) { save(); if (dropEmpty() && i > sel) i--; sel = i; load(); }
    function load() { body.text = cur ? cur.body : ""; body.deselect(); }
    function newNote() {
        save(); dropEmpty();
        Os.saveNotes([{ body: "", at: Date.now() }].concat(Os.notes));
        sel = 0; load(); body.forceActiveFocus();
    }
    function deleteNote() {
        if (sel < 0) return;
        var n = Os.notes.slice(); n.splice(sel, 1); Os.saveNotes(n);
        sel = Math.min(sel, n.length - 1); load();
    }
    Component.onCompleted: load()

    Sidebar {
        id: side
        width: 260
        topPad: 48
        Repeater {
            model: Os.notes.length
            Rectangle {
                id: ni
                required property int index
                readonly property var note: Os.notes[index] || { body: "" }
                property string aiName: Os.noteTitle(note)
                property string aiRole: "listitem"
                function aiActivate() { app.pick(index); }
                Accessible.role: Accessible.ListItem
                Accessible.name: aiName
                width: parent.width; height: 62; radius: 8
                color: app.sel === index ? Theme.selStrong : nma.containsMouse ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }
                Column {
                    x: 12; y: 11; width: parent.width - 24; spacing: 4
                    Text { width: parent.width; text: ni.aiName; elide: Text.ElideRight; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                    Row {
                        spacing: 7; width: parent.width
                        Text { text: app.when(ni.note); color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
                        Text { width: parent.width - 80; text: (ni.note.title ? ni.note.body.split("\n")[0] : (ni.note.body.split("\n").filter(function (l) { return l.trim(); })[1] || "No additional text")).replace("• ", ""); elide: Text.ElideRight; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
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
            TbButton { glyph: "compose"; label: "New note"; onClicked: app.newNote() }
            TbButton { glyph: "trash"; label: "Delete note"; visible: !!app.cur; onClicked: app.deleteNote() }
            SearchPill {}
        }
        Text {
            y: 58; anchors.horizontalCenter: parent.horizontalCenter
            visible: !!app.cur
            text: !app.cur ? "" : app.cur.date ? (/[AP]M$/.test(app.cur.date) ? "October 7, 2026 at " : "") + app.cur.date
                : Qt.formatDateTime(new Date(app.cur.at), "MMMM d, yyyy 'at' h:mm AP")
            color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
        }
        Flickable {
            id: fl
            visible: !!app.cur
            x: 40; y: 90; width: parent.width - 80; height: parent.height - 110
            contentHeight: col.height; clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: col; width: fl.width; spacing: 14
                Text { visible: !!(app.cur && app.cur.title); width: parent.width; text: app.cur ? app.cur.title || "" : ""; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 24; font.weight: Font.Bold }
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
        EmptyState { visible: !app.cur; glyph: "compose"; title: "No notes yet"; hint: "Start one with the pencil above. Notes save as you type." }
    }
}
