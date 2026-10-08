// Push button. primary = cream with dark text; ember = the Assistant's own primary.
import QtQuick

Rectangle {
    id: b
    property string text
    property string label: text
    property bool primary: false
    property bool ember: false
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
    readonly property color fg: ember ? "#ffffff" : primary ? Theme.bg : Theme.text
    color: ember ? Theme.ember : primary ? Theme.text : Theme.surface2
    border.color: primary || ember ? "transparent" : Theme.hairline2
    border.width: 1
    scale: ma.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Rectangle { anchors.fill: parent; radius: parent.radius; color: b.primary ? "black" : "white"; opacity: ma.containsMouse ? 0.06 : 0 }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Glyph { visible: b.glyph !== ""; name: b.glyph; color: b.fg; width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter }
        Text { text: b.text; color: b.fg; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: if (b.enabledState) b.clicked() }
}
