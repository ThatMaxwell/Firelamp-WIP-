// Push button. primary = ember gradient.
import QtQuick

Rectangle {
    id: b
    property string text
    property string label: text
    property bool primary: false
    property string glyph: ""
    property bool enabledState: true
    property string aiName: label
    property string aiRole: "button"
    signal clicked()
    function aiActivate() { if (enabledState) clicked(); }

    Accessible.role: Accessible.Button
    Accessible.name: label
    implicitHeight: 28
    implicitWidth: row.implicitWidth + 28
    radius: 7
    opacity: enabledState ? 1 : 0.4
    color: primary ? "transparent" : Theme.win4
    gradient: primary ? grad : null
    Gradient { id: grad; GradientStop { position: 0; color: "#f47c46" } GradientStop { position: 1; color: "#e8642f" } }
    border.color: Qt.rgba(1, 1, 1, primary ? 0.18 : 0.08)
    border.width: 0.5
    scale: ma.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Rectangle { anchors.fill: parent; radius: parent.radius; color: "white"; opacity: ma.containsMouse ? 0.08 : 0 }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Glyph { visible: b.glyph !== ""; name: b.glyph; color: b.primary ? "#ffffff" : Theme.text; width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter }
        Text { text: b.text; color: b.primary ? "white" : Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: if (b.enabledState) b.clicked() }
}
