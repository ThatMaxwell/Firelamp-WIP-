// Borderless toolbar icon button.
import QtQuick

Rectangle {
    id: b
    property string glyph: "sparkle"
    property string label: glyph
    property color tint: Theme.text2
    property string aiName: label
    property string aiRole: "button"
    signal clicked()
    function aiActivate() { clicked(); }
    Accessible.role: Accessible.Button
    Accessible.name: label
    width: 32; height: 28; radius: 7
    color: ma.containsMouse ? Theme.hover : "transparent"
    Glyph { anchors.centerIn: parent; name: b.glyph; color: ma.containsMouse ? Theme.text : b.tint }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }
}
