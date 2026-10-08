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
                    id: brain
                    title: "Effort"
                    // one list, one choice: Jev answers instantly, each step down trades speed for a bigger model
                    readonly property var tiers: [
                        { name: "Instant", model: "Jev by TypeSafe", hint: "Decides in milliseconds" },
                        { name: "Fast", pick: "modelFast", hint: "Your pick of a fast model, with web search" },
                        { name: "Balanced", pick: "modelBalanced", hint: "Your pick of a second model" },
                        { name: "High", model: "Grok 4.5", hint: "Fast and smart, sounds human" },
                        { name: "Max", model: "Grok 4.6", hint: "More careful on long tasks" },
                        { name: "Ultra", model: "Grok 4.7", hint: "The most capable, the slowest" } ]
                    Repeater {
                        model: brain.tiers
                        Item {
                            id: tr
                            required property var modelData
                            required property int index
                            readonly property bool on: Os.settings.effort === index
                            readonly property bool jev: index === 0
                            readonly property bool needsKey: jev && !Os.settings.jevKey
                            property string aiName: modelData.name + " effort"; property string aiRole: "radio"
                            function aiActivate() { Os.settings.effort = index; }
                            width: parent ? parent.width : 0; height: jev ? 88 : 52
                            Rectangle { visible: tr.index > 0; width: parent.width - 32; x: 16; height: 0.5; color: Theme.line }
                            MouseArea { anchors.fill: parent; onClicked: tr.aiActivate() }
                            Column {
                                x: 16; y: 10; spacing: 2
                                Text { text: tr.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: tr.on ? Font.DemiBold : Font.Medium }
                                Row {
                                    spacing: 6
                                    Text { visible: !!tr.modelData.model; text: tr.needsKey ? "Needs a key" : tr.modelData.model || ""; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11 }
                                    Text { visible: !!tr.modelData.model; text: "·"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                                    Text { text: tr.modelData.hint; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                                }
                            }
                            // Jev is bring-your-own-key: the key lives in its row
                            Row {
                                visible: tr.jev; x: 16; y: 52; spacing: 10
                                Rectangle {
                                    width: 220; height: 26; radius: 6; color: Theme.surface0; border.color: jk.input.activeFocus ? Theme.line3 : Theme.hairline; border.width: 1
                                    Field {
                                        id: jk; x: 8; width: parent.width - 16; height: parent.height; pixelSize: 11
                                        label: "Jev API key"; placeholder: "Paste your Jev API key"
                                        input.echoMode: TextInput.Password
                                        Component.onCompleted: text = Os.settings.jevKey
                                        onTextChanged: Os.settings.jevKey = text.trim()
                                    }
                                }
                                Text {
                                    property string aiName: "Get a Jev key"; property string aiRole: "link"
                                    function aiActivate() { Qt.openUrlExternally("https://typesafe.ai"); }
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Get a key ›"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11
                                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: parent.aiActivate() }
                                }
                            }
                            // the right side holds the check, or the field for an open tier
                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 16; y: tr.jev ? 14 : (parent.height - height) / 2; spacing: 10
                                Text { visible: tr.on; anchors.verticalCenter: parent.verticalCenter; text: "✓"; color: Theme.text; font.family: Theme.font; font.pixelSize: 13 }
                                Rectangle {
                                    visible: !!tr.modelData.pick
                                    width: 150; height: 26; radius: 6; color: Theme.surface0; border.color: mf.input.activeFocus ? Theme.line3 : Theme.hairline; border.width: 1
                                    Field {
                                        id: mf; x: 8; width: parent.width - 16; height: parent.height; pixelSize: 11
                                        label: tr.modelData.name + " model"; placeholder: "Any model"
                                        Component.onCompleted: if (tr.modelData.pick) text = Os.settings[tr.modelData.pick]
                                        onTextChanged: if (tr.modelData.pick) Os.settings[tr.modelData.pick] = text.trim()
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { width: parent.width - 32; x: 16; height: 0.5; color: Theme.line }
                    // Fast to Ultra go through Puter.js, signed in as the user
                    Row2 {
                        title: "Puter account"; hint: "Fast to Ultra run on your Puter account."
                        Text {
                            property string aiName: Os.settings.puterUser ? "Puter account" : "Sign in to Puter"; property string aiRole: "link"
                            function aiActivate() { if (!Os.settings.puterUser) Qt.openUrlExternally("https://puter.com"); }
                            text: Os.settings.puterUser || "Sign in ›"; color: Os.settings.puterUser ? Theme.text2 : Theme.text; font.family: Theme.font; font.pixelSize: 12
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: parent.aiActivate() }
                        }
                    }
                    Rectangle { width: parent.width - 32; x: 16; height: 0.5; color: Theme.line }
                    Row2 {
                        title: "Reasoning"
                        hint: Os.settings.effort === 0 ? "Not used on Instant: Jev decides without a reasoning pass" : "Think it through before acting. Slower; off by default"
                        Toggle { label: "Reasoning"; checked: Os.settings.reasoning; enabled: Os.settings.effort > 0; opacity: enabled ? 1 : 0.4
                                 onToggled: (c) => Os.settings.reasoning = c }
                    }
                }
                Item {
                    width: parent.width; height: 1
                    Text { x: 4; y: -40; text: "Higher effort is slower and may cost more."; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                }
                Group {
                    id: safety
                    title: "Safety"
                    Row2 {
                        id: askLink
                        title: "When to ask, per app"; hint: "Deleting, sending, paying and sharing always ask"
                        property string aiName: title; property string aiRole: "link"
                        function aiActivate() { app.scrollTo(perApp.y - 40); }
                        Text { text: "›"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 15 }
                        MouseArea { parent: askLink; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: askLink.aiActivate() }
                    }
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
