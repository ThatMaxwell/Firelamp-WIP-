// Multi-line text box the AI can find and type into.
import QtQuick

Item {
    id: ta
    property alias text: edit.text
    property alias edit: edit
    property string placeholder
    property string label: placeholder
    property string aiName: label
    property string aiRole: "textbox"
    function aiActivate() { edit.forceActiveFocus(); }
    function aiType(ch) { edit.insert(edit.length, ch); }
    function aiText() { return edit.text; }
    function aiSelectAll() { edit.selectAll(); }
    Accessible.role: Accessible.EditableText
    Accessible.name: label
    clip: true
    TextEdit {
        id: edit
        width: parent.width
        wrapMode: TextEdit.Wrap
        color: Theme.text; font.family: Theme.font; font.pixelSize: 14
        selectionColor: Qt.rgba(1, 0.55, 0.2, 0.38)
        Text { text: ta.placeholder; visible: !edit.text; color: Theme.text3; font: edit.font }
    }
}
