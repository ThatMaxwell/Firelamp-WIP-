// A 16px line glyph from js/art.js, tinted.
import QtQuick
import "../js/art.js" as Art

Image {
    property string name: "sparkle"
    property color color: Theme.text
    width: 16; height: 16
    source: Art.glyph(name, color.toString())
    sourceSize: Qt.size(width * 2, height * 2)
    smooth: true
}
