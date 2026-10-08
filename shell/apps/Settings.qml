// System Settings, open on the Assistant pane: its name, safety, and the fire cursor.
import QtQuick
import "../components"
import "../js/art.js" as Art

Item {
    id: app
    property var win
    property string pane: "Assistant"
    function start(opts) { if (opts && opts.pane) pane = opts.pane; }
    function scrollTo(y) { fl.contentY = Math.max(0, Math.min(y, fl.contentHeight - fl.height)); }

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
    // three plain choices, side by side; the selected one is a raised surface
    component Segmented: Rectangle {
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
                    color: sg.current === index ? Theme.surface3 : sm.containsMouse ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text { id: st; anchors.centerIn: parent; text: seg.modelData; color: sg.current === seg.index ? Theme.text : Theme.text2; font.family: Theme.font; font.pixelSize: 11; font.weight: sg.current === seg.index ? Font.Medium : Font.Normal }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: seg.aiActivate() }
                }
            }
        }
    }
    component Kbd: Rectangle {
        property string k
        width: kt.implicitWidth + 14; height: 22; radius: 5; color: Theme.win4; border.color: Theme.line2; border.width: 0.5
        Text { id: kt; anchors.centerIn: parent; text: parent.k; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11 }
    }

    Sidebar {
        id: side
        Repeater {
            model: [["Assistant", "sparkle"], ["Desktops", "grid"], ["Permissions", "shield"], ["Fire Cursor", "cursor"], ["Activity", "clock"], ["Appearance", "moon"], ["Wi-Fi", "wifi"], ["Sound", "volume"], ["Bluetooth", "bluetooth"]]
            SideItem { required property var modelData; text: modelData[0]; glyph: modelData[1]; selected: modelData[0] === app.pane
                       onClicked: if (modelData[0] === "Assistant" || modelData[0] === "Desktops") app.pane = modelData[0] }
        }
    }
    DesktopsPane {
        visible: app.pane === "Desktops"
        active: visible
        anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
    }
    Item {
        visible: app.pane === "Assistant"
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
                    id: perApp
                    title: "When to ask, per app"
                    readonly property var levels: ["all", "risky", "never"]
                    Repeater {
                        model: [["mail", "Mail"], ["files", "Files"], ["notes", "Notes"], ["web", "Web"], ["calendar", "Calendar"], ["terminal", "Terminal"]]
                        Item {
                            id: ar
                            required property var modelData
                            required property int index
                            width: parent ? parent.width : 0; height: 44
                            Rectangle { visible: ar.index > 0; width: parent.width - 32; x: 16; height: 0.5; color: Theme.line }
                            Image { x: 16; width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter; sourceSize: Qt.size(40, 40); source: Art.icon(ar.modelData[0]) }
                            Text { x: 46; anchors.verticalCenter: parent.verticalCenter; text: ar.modelData[1]; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                            Segmented {
                                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                options: ["Ask before anything", "Ask before risky things", "Don’t ask"]
                                current: { Os.settings.appTrust; return perApp.levels.indexOf(Os.trust(ar.modelData[0])); }
                                onPicked: (i) => Os.setTrust(ar.modelData[0], perApp.levels[i])
                            }
                        }
                    }
                }
                // the note hangs right under the group, not a full gap below it
                Item {
                    width: parent.width; height: Math.max(1, trustNote.height - 40)
                    Text { id: trustNote; x: 4; y: -40; width: parent.width - 8; wrapMode: Text.WordWrap; text: "Deleting, sending, paying and sharing always ask, whatever you pick here."; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
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
