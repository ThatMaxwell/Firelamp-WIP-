// "Show what the AI sees": the live UI tree drawn over the screen. No screenshots, just
// the roles, labels and bounds the AI reads.
import QtQuick
import "../js/uitree.js" as Tree

Item {
    id: vo
    property Item target
    property var list: []
    property int changes: 0
    property bool aiHidden: true
    anchors.fill: parent
    opacity: Os.vision ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 300 } }

    Timer {
        running: vo.visible; interval: 120; repeat: true; triggeredOnStart: true
        onTriggered: { var l = Tree.nodes(vo.target); if (l.length !== vo.list.length) vo.changes++; vo.list = l; }
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0.04, 0.024, 0.016, 0.38) }
    Repeater {
        model: vo.list
        delegate: Rectangle {
            required property var modelData
            readonly property bool win: modelData.role === "window"
            x: modelData.bounds.x; y: modelData.bounds.y; width: modelData.bounds.w; height: modelData.bounds.h
            radius: win ? 12 : 4
            color: win ? "transparent" : Qt.rgba(1, 0.54, 0.24, 0.08)
            border.color: modelData.role === "textbox" ? Qt.rgba(1, 0.82, 0.54, 0.8) : Qt.rgba(1, 0.63, 0.35, win ? 0.55 : 0.85)
            border.width: win ? 1.5 : 1
            Rectangle {
                visible: parent.width > 26 || parent.win
                y: parent.win ? -17 : -15
                height: parent.win ? 16 : 14
                width: Math.min(tag.implicitWidth + 10, 220)
                radius: 3
                color: parent.win ? Theme.ember : Qt.rgba(0.094, 0.063, 0.047, 0.92)
                Text {
                    id: tag; x: 5; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 10; elide: Text.ElideRight
                    text: modelData.role + " · " + modelData.name
                    color: parent.parent.win ? "white" : Theme.cream
                    font.family: Theme.mono; font.pixelSize: 9
                }
            }
        }
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 100
        width: hud.implicitWidth + 28; height: 32; radius: 12
        color: Qt.rgba(0.08, 0.055, 0.043, 0.92); border.color: Theme.line3; border.width: 0.5
        Row {
            id: hud; anchors.centerIn: parent; spacing: 14
            Text { text: "● LIVE"; color: Theme.orange; font.family: Theme.mono; font.pixelSize: 11 }
            Text { text: "<b>" + vo.list.length + "</b> elements"; textFormat: Text.StyledText; color: Theme.text2; font.family: Theme.mono; font.pixelSize: 11 }
            Text { text: "<b>" + vo.changes + "</b> changes"; textFormat: Text.StyledText; color: Theme.text2; font.family: Theme.mono; font.pixelSize: 11 }
            Text { text: "<b>0</b> screenshots"; textFormat: Text.StyledText; color: Theme.text2; font.family: Theme.mono; font.pixelSize: 11 }
        }
    }
}
