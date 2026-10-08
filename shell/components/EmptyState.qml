// What an app shows before it has anything of yours in it: a quiet glyph, a line, a hint.
import QtQuick

Column {
    property string glyph: "doc"
    property string title
    property string hint
    property string action: ""            // one button under the hint, when there is something to do
    signal acted()
    anchors.centerIn: parent
    spacing: 8
    Glyph { anchors.horizontalCenter: parent.horizontalCenter; name: parent.glyph; width: 28; height: 28; color: Theme.text4 }
    Item { width: 1; height: 4 }
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.title; color: Theme.text2; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold }
    Text { anchors.horizontalCenter: parent.horizontalCenter; visible: !!text; text: parent.hint; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
    Item { visible: !!parent.action; width: 1; height: 6 }
    FButton { visible: !!parent.action; anchors.horizontalCenter: parent.horizontalCenter; text: parent.action; height: 28; width: Math.max(110, implicitWidth); onClicked: parent.acted() }
}
