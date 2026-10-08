// Plain choices side by side; the selected one is a raised surface.
import QtQuick

Rectangle {
    id: sg
    property var options: []
    property int current: 0
    signal picked(int i)
    width: segRow.implicitWidth + 4; height: 26; radius: 7; color: Theme.surface0; border.color: Theme.hairline; border.width: 1
    Row {
        id: segRow; x: 2; y: 2
        Repeater {
            model: sg.options
            Rectangle {
                id: seg
                required property string modelData
                required property int index
                property string aiName: modelData; property string aiRole: "radio"
                function aiActivate() { sg.picked(index); }
                width: st.implicitWidth + 16; height: 22; radius: 5
                color: sg.current === index ? Theme.surface3 : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }
                Text { id: st; anchors.centerIn: parent; text: seg.modelData; color: sg.current === seg.index ? Theme.text : Theme.text2; font.family: Theme.font; font.pixelSize: 11; font.weight: sg.current === seg.index ? Font.Medium : Font.Normal }
                MouseArea { id: sm; anchors.fill: parent; onClicked: seg.aiActivate() }
            }
        }
    }
}
