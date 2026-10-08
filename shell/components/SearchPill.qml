// Toolbar search field (decorative in the demo).
import QtQuick

Rectangle {
    width: 170; height: 28; radius: 7
    color: Qt.rgba(1, 1, 1, 0.06)
    border.color: Theme.line; border.width: 0.5
    Glyph { x: 9; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: Theme.text3; width: 13; height: 13 }
    Text { x: 29; anchors.verticalCenter: parent.verticalCenter; text: "Search"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13 }
}
