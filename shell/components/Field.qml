// Single-line text field the AI can find and type into.
import QtQuick

Item {
    id: f
    property alias text: input.text
    property string placeholder
    property string label: placeholder
    property alias input: input
    property int pixelSize: 13
    property color textColor: Theme.text
    property int align: TextInput.AlignLeft
    property string aiName: label
    property string aiRole: "textbox"
    signal accepted()
    function aiActivate() { input.forceActiveFocus(); }
    function aiType(ch) { input.insert(input.length, ch); }
    function aiKey(k) { if (k === "Enter") accepted(); }
    Accessible.role: Accessible.EditableText
    Accessible.name: label
    implicitHeight: 28

    TextInput {
        id: input
        anchors.fill: parent
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: f.align
        color: f.textColor
        font.family: Theme.font
        font.pixelSize: f.pixelSize
        selectionColor: Qt.rgba(1, 244 / 255, 232 / 255, 0.2)
        selectedTextColor: Theme.text
        cursorDelegate: Rectangle {
            width: 2; color: Os.agent && Os.agent.mode !== "idle" ? Theme.amber : Theme.text
        }
        clip: true
        onAccepted: f.accepted()
        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: f.align === TextInput.AlignHCenter ? Text.AlignHCenter : Text.AlignLeft
            text: f.placeholder
            color: Theme.text3
            font: input.font
            visible: !input.text && !input.preeditText
        }
    }
}
