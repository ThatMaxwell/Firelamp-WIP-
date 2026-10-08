// A sidebar row: glyph, label, optional count.
import QtQuick

Rectangle {
    id: s
    property string glyph: "folder"
    property string text
    property string count: ""
    property bool selected: false
    property string aiName: text
    property string aiRole: "button"
    signal clicked()
    function aiActivate() { clicked(); }
    Accessible.role: Accessible.Button
    Accessible.name: text
    width: parent ? parent.width : 190; height: 28; radius: 7
    color: selected ? Theme.selStrong : ma.containsMouse ? Theme.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }
    Glyph { x: 10; anchors.verticalCenter: parent.verticalCenter; name: s.glyph; color: s.selected ? Theme.text : Theme.text3 }
    Text { x: 35; anchors.verticalCenter: parent.verticalCenter; text: s.text; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
    Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: s.count; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: s.clicked() }
}
