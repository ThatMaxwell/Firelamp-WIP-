// Control Center: neutral surface, one row style, switches green when on. The assistant
// gets a row of its own, with pause and stop, because it is part of the system.
import QtQuick
import QtQuick.Effects

Item {
    id: cc
    objectName: "controlCenter"
    property bool open: false
    property bool aiHidden: true
    width: 320
    height: col.implicitHeight + 16
    visible: opacity > 0
    opacity: open ? 1 : 0
    property real drop: open ? 0 : -4
    transform: Translate { y: cc.drop }
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuint } }
    Behavior on drop { NumberAnimation { duration: 140; easing.type: Easing.OutQuint } }

    property bool wifi: true
    property bool bluetooth: true
    property bool focusMode: false
    property real display: 0.72
    property real sound: 0.45

    RectangularShadow { anchors.fill: bg; radius: 14; blur: 40; offset.y: 14; color: Qt.rgba(0, 0, 0, 0.45) }
    Rectangle { id: bg; anchors.fill: parent; radius: 14; color: Theme.surface1; border.color: Theme.hairline2; border.width: 1 }
    MouseArea { anchors.fill: parent }

    // the one row style, shared with notifications
    component CcRow: Item {
        id: r
        property string glyph
        property string title
        property string sub
        default property alias trailing: tr.data
        width: col.width; height: 48
        Rectangle {
            x: 8; width: 30; height: 30; radius: 15; anchors.verticalCenter: parent.verticalCenter
            color: Theme.surface2
            Glyph { anchors.centerIn: parent; width: 15; height: 15; name: r.glyph; color: Theme.text2 }
        }
        Column {
            x: 50; anchors.verticalCenter: parent.verticalCenter
            Text { text: r.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
            Text { visible: r.sub !== ""; text: r.sub; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
        }
        Item { id: tr; anchors.right: parent.right; anchors.rightMargin: 8; height: parent.height; width: childrenRect.width }
    }
    component Slide: Item {
        id: sl
        property real value
        signal moved(real v)
        width: 120; height: 22; anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Rectangle { y: 9; width: parent.width; height: 4; radius: 2; color: Theme.surface3 }
        Rectangle { y: 9; width: sl.value * parent.width; height: 4; radius: 2; color: Theme.text2 }
        Rectangle { x: sl.value * (parent.width - 16); y: 3; width: 16; height: 16; radius: 8; color: Theme.text }
        MouseArea { anchors.fill: parent
            onPressed: (m) => sl.moved(Math.max(0, Math.min(1, m.x / width)))
            onPositionChanged: (m) => sl.moved(Math.max(0, Math.min(1, m.x / width))) }
    }
    component Sep: Rectangle { x: 14; width: col.width - 28; height: 1; color: Theme.hairline }

    Column {
        id: col
        x: 8; y: 8; width: parent.width - 16
        CcRow { glyph: "wifi"; title: "Wi‑Fi"; sub: cc.wifi ? (Os.demo ? "Hearth" : "On") : "Off"
            Toggle { label: "Wi-Fi"; checked: cc.wifi; anchors.verticalCenter: parent.verticalCenter; onToggled: (c) => cc.wifi = c } }
        CcRow { glyph: "bluetooth"; title: "Bluetooth"; sub: cc.bluetooth ? (Os.demo ? "AirPods" : "On") : "Off"
            Toggle { label: "Bluetooth"; checked: cc.bluetooth; anchors.verticalCenter: parent.verticalCenter; onToggled: (c) => cc.bluetooth = c } }
        CcRow { glyph: "moon"; title: "Focus"; sub: cc.focusMode ? "On until tomorrow" : "Off"
            Toggle { label: "Focus"; checked: cc.focusMode; anchors.verticalCenter: parent.verticalCenter; onToggled: (c) => cc.focusMode = c } }
        Sep {}
        CcRow { glyph: "sun"; title: "Display"
            Slide { value: cc.display; onMoved: (v) => cc.display = v } }
        CcRow { glyph: "volume"; title: "Sound"
            Slide { value: cc.sound; onMoved: (v) => cc.sound = v } }
        Sep {}
        // the assistant, as a system control
        Item {
            readonly property string st: Os.agent ? Os.agent.mode : "idle"
            id: aiRow
            width: col.width; height: 52
            Rectangle {
                x: 8; width: 30; height: 30; radius: 15; anchors.verticalCenter: parent.verticalCenter; color: Theme.surface2
                Logo { anchors.centerIn: parent; width: 12; height: 17 }
            }
            Column {
                x: 50; anchors.verticalCenter: parent.verticalCenter
                Text { text: Os.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                Row { spacing: 6
                    Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: aiRow.st === "running" ? Theme.ember : Theme.text4 }
                    Text { text: aiRow.st === "running" ? "Working" : aiRow.st === "paused" ? "Paused" : "Ready"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 } }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                Repeater {
                    model: [["pause", "⌃Space", function () { Os.agent.togglePause(); }], ["stop", "Esc", function () { Os.agent.stop(); }]]
                    Rectangle {
                        required property var modelData
                        // the emergency controls: always clearly visible
                        width: 28; height: 28; radius: 14
                        color: bm.containsMouse ? Qt.lighter(Theme.surface3, 1.25) : Theme.surface3
                        scale: bm.pressed ? 0.97 : 1
                        Glyph { anchors.centerIn: parent; width: 12; height: 12; name: parent.modelData[0]; color: Theme.text }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; onClicked: parent.modelData[2]() }
                    }
                }
            }
        }
    }
}
