// Mac-style switch, ember when on.
import QtQuick

Rectangle {
    id: t
    property bool checked: false
    property string label
    property string aiName: label
    property string aiRole: "switch"
    signal toggled(bool checked)
    function aiActivate() { checked = !checked; toggled(checked); }
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    width: 38; height: 22; radius: 11
    color: checked ? Theme.accent : Theme.win4
    Behavior on color { ColorAnimation { duration: 180 } }
    Rectangle {
        width: 18; height: 18; radius: 9; y: 2
        x: t.checked ? 18 : 2
        color: "white"
        Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
    }
    MouseArea { anchors.fill: parent; onClicked: t.aiActivate() }
}
