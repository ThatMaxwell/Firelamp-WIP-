// A Mac-style dropdown menu. items: [{label, sc, action, disabled}] or "-" for a separator.
import QtQuick
import QtQuick.Effects

Item {
    id: m
    property var items: []
    signal picked()
    width: Math.max(232, col.implicitWidth + 10)
    height: col.implicitHeight + 10
    opacity: 0; scale: 0.985; transformOrigin: Item.TopLeft
    Component.onCompleted: { opacity = 1; scale = 1; }
    Behavior on opacity { NumberAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    RectangularShadow { anchors.fill: bg; radius: 10; blur: 30; offset.y: 12; color: Qt.rgba(0, 0, 0, 0.6) }
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(0.14, 0.14, 0.135, 0.96)
        border.color: Qt.rgba(1, 1, 1, 0.14); border.width: 0.5
    }
    Column {
        id: col
        x: 5; y: 5
        width: m.width - 10
        Repeater {
            model: m.items
            delegate: Item {
                id: row
                required property var modelData
                readonly property bool sep: modelData === "-"
                width: col.width
                height: sep ? 11 : 24
                implicitWidth: sep ? 0 : lbl.implicitWidth + sc.implicitWidth + 50
                property string aiName: sep ? "" : modelData.label
                property string aiRole: "menuitem"
                function aiActivate() { if (!sep && !modelData.disabled) { m.picked(); if (modelData.action) modelData.action(); } }
                Rectangle { visible: row.sep; x: 10; width: parent.width - 20; height: 1; y: 5; color: Theme.line2 }
                Rectangle {
                    visible: !row.sep
                    anchors.fill: parent; radius: 5
                    color: ma.containsMouse && !row.modelData.disabled ? Theme.selStrong : "transparent"
                }
                Text {
                    id: lbl
                    visible: !row.sep
                    x: 10; anchors.verticalCenter: parent.verticalCenter
                    text: row.sep ? "" : row.modelData.label
                    color: row.sep ? "transparent" : row.modelData.disabled ? Theme.text4 : ma.containsMouse ? "white" : Theme.text
                    font.family: Theme.font; font.pixelSize: 13
                }
                Text {
                    id: sc
                    visible: !row.sep && !!row.modelData.sc
                    anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                    text: row.sep ? "" : (row.modelData.sc || "")
                    color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.8) : Theme.text3
                    font.family: Theme.font; font.pixelSize: 12
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: !row.sep; onClicked: row.aiActivate() }
            }
        }
    }
}
