// Mail: mailboxes, a message list, a reading pane and a compose sheet.
import QtQuick
import QtQuick.Effects
import "../components"

Item {
    id: app
    property var win
    property string folder: "Inbox"
    property int sel: 0
    property int rev: 0
    property var boxes: ({
        Inbox: [
            { from: "Ana Souza", sub: "Launch sync tomorrow?", pre: "Hey! Could you send me the notes from today’s meeting when you get a sec? I want to prep the deck.", time: "11:02 PM", unread: true,
              body: "Hey!\n\nCould you send me the notes from today’s meeting when you get a sec? I want to prep the launch deck tonight.\n\nThanks,\nAna" },
            { from: "TypeSafe", sub: "Your Jev early access is live", pre: "Welcome aboard. Jev is ready to make fast, typed decisions for your agents.", time: "6:40 PM", unread: true,
              body: "Welcome aboard.\n\nJev is ready to make fast, typed decisions for your agents. Your keys are in the dashboard.\n\n— The TypeSafe team" },
            { from: "Leo Martins", sub: "Dock icons v3", pre: "Pushed the new tiles. Graphite reads so much calmer.", time: "4:15 PM",
              body: "Pushed the new tiles. Graphite reads so much calmer. Let me know about the calendar one." },
            { from: "Hearth Weekly", sub: "Cozy computing, issue 42", pre: "Warm neutrals, and why calm software wins.", time: "Yesterday",
              body: "Warm neutrals, and why calm software wins." },
            { from: "GitHub", sub: "[Firelamp-WIP-] New star", pre: "Someone starred ThatMaxwell/Firelamp-WIP-.", time: "Yesterday",
              body: "Someone starred ThatMaxwell/Firelamp-WIP-." }
        ],
        Sent: []
    })
    readonly property var list: { rev; return (boxes[folder] || []).slice(); }
    readonly property var cur: list[sel]
    function start(opts) {}
    function unreadIn(f) { rev; return (boxes[f] || []).filter(function (m) { return m.unread; }).length; }
    function open(i) { sel = i; if (list[i]) list[i].unread = false; rev++; }
    function send() {
        boxes.Sent.unshift({ to: to.text || "someone", sub: subject.text || "(no subject)", pre: msg.text.slice(0, 120), body: msg.text, time: "Now", fresh: true });
        boxes.Inbox.forEach(function (m) { if (m.from === "Ana Souza") m.unread = false; });
        Os.toast("mail", "Message sent", "To " + to.text + " · “" + subject.text + "”");
        compose.leave();
        rev++;
    }

    // ---- mailboxes ----
    Sidebar {
        id: side
        width: 190
        SideHeader { text: "Hearth Mail" }
        Repeater {
            model: [["Inbox", "inbox"], ["Starred", "star"], ["Sent", "sent"], ["Drafts", "doc"], ["Trash", "trash"]]
            SideItem {
                required property var modelData
                text: modelData[0]; glyph: modelData[1]
                aiName: modelData[0] + " mailbox"
                selected: app.folder === modelData[0]
                count: app.unreadIn(modelData[0]) || ""
                onClicked: { app.folder = modelData[0]; app.sel = 0; app.rev++; }
            }
        }
    }

    // ---- message list ----
    Rectangle {
        id: listPane
        anchors { left: side.right; top: parent.top; bottom: parent.bottom }
        width: 320
        color: "transparent"
        Rectangle { anchors.right: parent.right; width: 0.5; height: parent.height; color: Theme.line2 }
        Column {
            x: 18; y: 14
            Text { text: app.folder; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
            Text { text: app.list.length + " message" + (app.list.length === 1 ? "" : "s"); color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
        }
        ListView {
            id: lv
            y: 58; width: parent.width; height: parent.height - 58
            clip: true
            model: app.list.length
            delegate: Rectangle {
                id: mi
                required property int index
                readonly property var m: app.list[index]
                readonly property bool unread: { app.rev; return !!(m && m.unread); }
                property string aiName: m ? (m.to ? "To " + m.to : m.from) + ": " + m.sub : ""
                property string aiRole: "listitem"
                function aiActivate() { app.open(index); }
                width: lv.width - 12; x: 6; height: 84; radius: 9
                color: app.sel === index ? Theme.selStrong : mma.containsMouse ? Theme.hover : "transparent"
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 400 } }
                Rectangle { visible: mi.unread; x: 6; y: 16; width: 7; height: 7; radius: 4; color: Theme.accent }
                Avatar { x: 18; y: 12; who: mi.m ? (mi.m.to || mi.m.from) : ""; seed: mi.index }
                Column {
                    x: 62; y: 10; width: parent.width - 72; spacing: 2
                    Item {
                        width: parent.width; height: 18
                        Text { text: mi.m ? (mi.m.to ? "To: " + mi.m.to : mi.m.from) : ""; width: parent.width - 70; elide: Text.ElideRight; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { anchors.right: parent.right; text: mi.m ? mi.m.time : ""; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                    }
                    Text { width: parent.width; text: mi.m ? mi.m.sub : ""; elide: Text.ElideRight; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
                    Text { width: parent.width; text: mi.m ? mi.m.pre : ""; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12; lineHeight: 1.1 }
                }
                MouseArea { id: mma; anchors.fill: parent; hoverEnabled: true; onClicked: mi.aiActivate() }
            }
        }
    }

    // ---- reading pane ----
    Item {
        id: readPane
        anchors { left: listPane.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12; y: 12; spacing: 4
            TbButton { glyph: "inbox"; label: "Archive" }
            TbButton { glyph: "trash"; label: "Delete message" }
            TbButton { glyph: "compose"; label: "Compose"; onClicked: compose.enter() }
            SearchPill { width: 140 }
        }
        Column {
            visible: !!app.cur
            x: 28; y: 70; width: parent.width - 56; spacing: 16
            Text { width: parent.width; text: app.cur ? app.cur.sub : ""; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.Bold }
            Row {
                spacing: 10
                Avatar { who: app.cur ? (app.cur.to || app.cur.from) : ""; seed: app.sel; width: 36; height: 36 }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: app.cur ? (app.cur.to ? "To: " + app.cur.to : app.cur.from) : ""; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                    Text { text: app.cur ? app.cur.time : ""; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                }
            }
            Rectangle { width: parent.width; height: 0.5; color: Theme.line2 }
            Text { width: parent.width; text: app.cur ? app.cur.body : ""; wrapMode: Text.WordWrap; color: Theme.text2; font.family: Theme.font; font.pixelSize: 14; lineHeight: 1.25 }
        }
        Text { visible: !app.cur; anchors.centerIn: parent; text: "No message selected"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13 }

        // ---- compose sheet ----
        Item {
            id: compose
            property bool shown: false
            function enter() { if (shown) return; to.text = ""; subject.text = ""; msg.text = ""; shown = true; to.aiActivate(); }
            function leave() { shown = false; }
            x: 14; width: parent.width - 28; height: parent.height - 62
            y: shown ? 52 : parent.height + 20
            visible: y < parent.height
            Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            RectangularShadow { anchors.fill: cbg; radius: 12; blur: 50; offset.y: 14; color: Qt.rgba(0, 0, 0, 0.6) }
            Rectangle { id: cbg; anchors.fill: parent; radius: 12; color: Theme.win3; border.color: Theme.line2; border.width: 0.5 }
            Item {
                id: chead
                width: parent.width; height: 50
                Text { x: 18; anchors.verticalCenter: parent.verticalCenter; text: "New Message"; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Bold }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                    TbButton { glyph: "trash"; label: "Discard draft"; onClicked: compose.leave() }
                    FButton { text: "Send"; glyph: "sent"; primary: true; onClicked: app.send() }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: Theme.line2 }
            }
            Column {
                anchors.top: chead.bottom; width: parent.width
                Repeater {
                    model: 2
                    Item {
                        required property int index
                        width: compose.width; height: 40
                        Text { x: 18; anchors.verticalCenter: parent.verticalCenter; text: index === 0 ? "To:" : "Subject:"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13 }
                        Rectangle { anchors.bottom: parent.bottom; x: 18; width: parent.width - 36; height: 0.5; color: Theme.line2 }
                    }
                }
            }
            Field { id: to; label: "To"; x: 50; y: 56; width: parent.width - 70 }
            Field { id: subject; label: "Subject"; x: 80; y: 96; width: parent.width - 100 }
            TextArea2 { id: msg; label: "Message body"; placeholder: "Write something warm…"; x: 18; y: 144; width: parent.width - 36; height: parent.height - 160 }
        }
    }
}
