// System Settings, open on the Assistant pane: its name, safety, and the fire cursor.
import QtQuick
import "../components"

Item {
    id: app
    property var win
    function start(opts) {}

    component Row2: Item {
        id: r
        property string title
        property string hint
        default property alias trailing: tr.data
        width: parent ? parent.width : 0; height: 54
        Column { x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 2
            Text { text: r.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
            Text { text: r.hint; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 } }
        Row { id: tr; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6 }
    }
    component Group: Rectangle {
        default property alias rows: groupCol.data
        property string title
        width: parent ? parent.width : 0; height: groupCol.height
        radius: 10; color: Qt.rgba(1, 1, 1, 0.04); border.color: Theme.line; border.width: 0.5
        Column { id: groupCol; width: parent.width }
        Text { y: -26; x: 4; text: parent.title; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
    }
    component Kbd: Rectangle {
        property string k
        width: kt.implicitWidth + 14; height: 22; radius: 5; color: Theme.win4; border.color: Theme.line2; border.width: 0.5
        Text { id: kt; anchors.centerIn: parent; text: parent.k; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11 }
    }

    Sidebar {
        id: side
        Repeater {
            model: [["Assistant", "sparkle"], ["Permissions", "shield"], ["Fire Cursor", "cursor"], ["Activity", "clock"], ["Appearance", "moon"], ["Wi-Fi", "wifi"], ["Sound", "volume"], ["Bluetooth", "bluetooth"]]
            SideItem { required property var modelData; text: modelData[0]; glyph: modelData[1]; selected: modelData[0] === "Assistant" }
        }
    }
    Item {
        anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        Text { x: 24; y: 16; text: "Assistant"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
        Flickable {
            id: fl
            x: 24; y: 56; width: parent.width - 48; height: parent.height - 56
            contentHeight: col.height + 30; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: col; width: fl.width; spacing: 50
                Row {
                    spacing: 18; topPadding: 8
                    Logo { width: 54; height: 63; animated: true }
                    Column {
                        spacing: 6; anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: 260; height: 32; radius: 7; color: Theme.win3; border.color: nameF.input.activeFocus ? Theme.line3 : Theme.line2; border.width: 1
                            Field { id: nameF; x: 10; width: parent.width - 20; height: parent.height; label: "Assistant name"; placeholder: "Name your assistant"; pixelSize: 15
                                    Component.onCompleted: text = Os.settings.assistantName
                                    onAccepted: if (text.trim()) Os.settings.assistantName = text.trim() }
                        }
                        Text { width: 300; wrapMode: Text.WordWrap; text: "The name your assistant answers to. Until you pick one, it is just “Assistant”."; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                    }
                }
                Group {
                    title: "Safety"
                    Row2 { title: "Ask before risky actions"; hint: "Deleting, sending, paying. The OS asks you, never the AI."
                           Toggle { label: "Ask before risky actions"; checked: Os.settings.askBeforeRisky; onToggled: (c) => Os.settings.askBeforeRisky = c } }
                    Rectangle { width: parent.width - 32; x: 16; height: 0.5; color: Theme.line }
                    Row2 { title: "Pause or stop instantly"; hint: "Works from anywhere, even mid-click"; Kbd { k: "⌃ Space" } Kbd { k: "Esc" } }
                }
                Group {
                    title: "Fire cursor"
                    Row2 {
                        title: "Speed"; hint: "How fast it moves between things"
                        Item {
                            id: slider
                            property string aiName: "Cursor speed"
                            property string aiRole: "slider"
                            width: 160; height: 22
                            readonly property real v: (Os.settings.cursorSpeed - 0.5) / 1.5
                            Rectangle { y: 9; width: parent.width; height: 4; radius: 2; color: Theme.win4 }
                            Rectangle { y: 9; width: slider.v * parent.width; height: 4; radius: 2; color: Theme.accent }
                            Rectangle { x: slider.v * (parent.width - 18); width: 18; height: 18; y: 2; radius: 9; color: "white" }
                            MouseArea { anchors.fill: parent
                                function set(mx) { Os.settings.cursorSpeed = Math.round((0.5 + Math.max(0, Math.min(1, mx / width)) * 1.5) * 10) / 10; }
                                onPressed: (m) => set(m.x); onPositionChanged: (m) => set(m.x) }
                        }
                    }
                    Rectangle { width: parent.width - 32; x: 16; height: 0.5; color: Theme.line }
                    Row2 { title: "Fade when idle"; hint: "The fire cursor hides after a moment of rest"
                           Toggle { label: "Fade when idle"; checked: Os.settings.idleFade; onToggled: (c) => Os.settings.idleFade = c } }
                    Rectangle { width: parent.width - 32; x: 16; height: 0.5; color: Theme.line }
                    Row2 { title: "Show what the AI sees"; hint: "Outline every element in the live UI tree"
                           Toggle { label: "Show what the AI sees"; checked: Os.vision; onToggled: (c) => Os.vision = c } }
                }
            }
        }
    }
}
