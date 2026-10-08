// The Ask bar: summon the assistant from anywhere (Alt+Space or Ctrl+K), like a launcher.
import QtQuick
import QtQuick.Effects
import "../js/plans.js" as Plans

Item {
    id: ask
    property bool shown: false
    property int sel: -1
    property bool aiHidden: true
    signal go(string text)
    anchors.fill: parent
    visible: shown
    function open() { shown = true; field.text = ""; sel = -1; field.input.forceActiveFocus(); }
    function close() { shown = false; }
    function submit(t) { if (!t.trim()) return; close(); go(t.trim()); }

    MouseArea { anchors.fill: parent; onPressed: ask.close() }
    Item {
        id: box
        width: Math.min(640, parent.width - 40)
        height: 58 + sugs.height + 1
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22
        scale: ask.shown ? 1 : 0.97
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        RectangularShadow { anchors.fill: bg; radius: 16; blur: 80; offset.y: 30; color: Qt.rgba(0, 0, 0, 0.7) }
        Rectangle { id: bg; anchors.fill: parent; radius: 16; color: Qt.rgba(0.125, 0.125, 0.12, 0.97); border.color: Qt.rgba(1, 1, 1, 0.14); border.width: 0.5 }
        MouseArea { anchors.fill: parent }
        Row {
            x: 16; height: 58; spacing: 12
            Logo { width: 22; height: 26; animated: ask.shown; anchors.verticalCenter: parent.verticalCenter }
            Field {
                id: field
                width: box.width - 110; height: 58
                pixelSize: 21
                placeholder: "Ask " + Os.name + " to do anything…"
                input.font.weight: Font.Light
                onAccepted: ask.submit(ask.sel >= 0 && !text ? Plans.SUGGESTIONS[ask.sel].text : text)
                input.Keys.onEscapePressed: ask.close()
                input.Keys.onDownPressed: ask.sel = (ask.sel + 1) % Plans.SUGGESTIONS.length
                input.Keys.onUpPressed: ask.sel = (ask.sel + Plans.SUGGESTIONS.length - 1) % Plans.SUGGESTIONS.length
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 20; radius: 5; color: Qt.rgba(1, 1, 1, 0.07); border.color: Theme.line2; border.width: 0.5
                Text { anchors.centerIn: parent; text: "esc"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11 }
            }
        }
        Rectangle { y: 58; width: parent.width; height: 0.5; color: Theme.line2 }
        Column {
            id: sugs
            y: 59; x: 6; width: parent.width - 12
            topPadding: 6; bottomPadding: 6
            Repeater {
                model: Plans.SUGGESTIONS
                Rectangle {
                    required property var modelData
                    required property int index
                    width: sugs.width; height: 38; radius: 8
                    color: ask.sel === index ? Theme.selStrong : "transparent"
                    Glyph { x: 10; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; color: Theme.text2 }
                    Text { x: 36; anchors.verticalCenter: parent.verticalCenter; text: modelData.text; color: ask.sel === index ? Theme.text : Theme.text2; font.family: Theme.font; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: ask.sel = index; onClicked: ask.submit(modelData.text) }
                }
            }
        }
    }
}
