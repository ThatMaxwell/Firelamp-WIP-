// The assistant: talk to it, and it does the work with its own cursor.
import QtQuick
import QtQuick.Effects
import "../components"
import "../js/plans.js" as Plans

Rectangle {
    id: app
    property var win
    color: Theme.win
    readonly property string st: Os.agent ? Os.agent.mode : "idle"
    property bool typing: false
    property var queue: []

    function start(opts) { if (opts && opts.prompt) Qt.callLater(function () { submit(opts.prompt); }); }
    function add(who, text) { msgs.append({ who: who, text: text }); Qt.callLater(chat.positionViewAtEnd); }
    function submit(t) {
        t = t.trim(); if (!t) return;
        input.text = "";
        add("me", t);
        Os.submit(t);
    }
    // the assistant "types" for a moment before each message lands
    function say(t) { queue.push({ who: "ai", text: t }); if (!typing) next(); }
    function next() {
        if (!queue.length) { typing = false; return; }
        typing = true; Qt.callLater(chat.positionViewAtEnd);
        var q = queue.shift();
        if (q.who === "sys") { add("sys", q.text); return next(); }
        typer.text = q.text; typer.interval = 420 + Math.min(900, q.text.length * 11); typer.start();
    }
    Timer { id: typer; property string text; onTriggered: { app.add("ai", text); app.next(); } }
    Connections {
        target: Os
        function onSay(t) { app.say(t); }
        function onLog(e) { if (e.kind === "done") { app.queue.push({ who: "sys", text: "Task finished · see Activity for every step" }); if (!app.typing) app.next(); } }
    }

    // ---- header ----
    Item {
        id: head
        width: parent.width; height: 64
        Row {
            x: 84; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Logo { width: 24; height: 28; animated: true; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: Os.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: Font.Bold }
                Row {
                    spacing: 5
                    Rectangle {
                        width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter
                        color: app.st === "idle" ? Theme.success : Theme.accent
                        SequentialAnimation on opacity { running: app.st === "running"; loops: Animation.Infinite; NumberAnimation { to: 0.3; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                    }
                    Text { text: app.st === "running" ? "Working…" : app.st === "paused" ? "Paused" : "Ready"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                }
            }
        }
        TbButton { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; glyph: "clock"; label: "Activity timeline"; onClicked: Os.timelineToggle(undefined) }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: Theme.line2 }
    }

    // ---- hello ----
    Column {
        visible: msgs.count === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: 120; width: parent.width - 70; spacing: 14
        Item {
            width: 72; height: 84; anchors.horizontalCenter: parent.horizontalCenter
            GlowLogo { anchors.fill: parent; glow: 0.45 }
        }
        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Hi, I'm " + Os.name + "."; color: Theme.text; font.family: Theme.font; font.pixelSize: 21; font.weight: Font.Bold }
        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; lineHeight: 1.2
               text: "I use this computer the way you do, just faster. Ask me for something and watch my cursor work. You can pause or stop me any time."
               color: Theme.text2; font.family: Theme.font; font.pixelSize: 13 }
    }

    // ---- conversation ----
    ListModel { id: msgs }
    ListView {
        id: chat
        y: head.height; width: parent.width; height: chips.y - y - 6
        clip: true; spacing: 8
        topMargin: 14; bottomMargin: 6
        model: msgs
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260 } NumberAnimation { property: "y"; from: chat.contentHeight; duration: 420; easing.type: Easing.OutQuint } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 380; easing.type: Easing.OutQuint } }
        delegate: Item {
            id: m
            required property string who
            required property string text
            width: chat.width; height: who === "sys" ? 22 : bubble.height
            Text { visible: m.who === "sys"; anchors.centerIn: parent; text: m.text; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
            Rectangle {
                id: bubble
                visible: m.who !== "sys"
                x: m.who === "me" ? parent.width - width - 14 : 4
                width: Math.min(t.implicitWidth, chat.width * 0.78) + 26
                height: t.height + 18
                radius: 16
                // your messages sit in a soft pill; the assistant just talks, no bubble
                color: m.who === "me" ? Theme.win4 : "transparent"
                Text { id: t; x: 13; y: 9; width: Math.min(implicitWidth, chat.width * 0.78); text: m.text; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; lineHeight: 1.15 }
            }
        }
        footer: Item {
            width: chat.width; height: app.typing ? 44 : 0
            Rectangle {
                visible: app.typing; x: 14; y: 8; width: 58; height: 32; radius: 16; color: Theme.win3
                Row {
                    anchors.centerIn: parent; spacing: 5
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: 6; height: 6; radius: 3; color: Theme.text3
                            SequentialAnimation on y { running: app.typing; loops: Animation.Infinite
                                PauseAnimation { duration: index * 140 }
                                NumberAnimation { to: -4; duration: 220; easing.type: Easing.OutQuad } NumberAnimation { to: 0; duration: 220; easing.type: Easing.InQuad }
                                PauseAnimation { duration: 420 - index * 140 } }
                        }
                    }
                }
            }
        }
    }

    // ---- suggestions ----
    Flow {
        id: chips
        visible: app.st === "idle"
        x: 14; width: parent.width - 28
        y: composer.y - height - 10
        spacing: 6
        Repeater {
            model: Plans.SUGGESTIONS
            Rectangle {
                id: chip
                required property var modelData
                property string aiName: modelData.text
                property string aiRole: "button"
                function aiActivate() { app.submit(modelData.text); }
                width: cr.implicitWidth + 22; height: 30; radius: 15
                color: cma.containsMouse ? Theme.selStrong : Theme.sel
                border.color: Theme.line2; border.width: 0.5
                Row { id: cr; anchors.centerIn: parent; spacing: 6
                    Glyph { name: chip.modelData.icon; color: Theme.text3; width: 13; height: 13; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: chip.modelData.text; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: chip.aiActivate() }
            }
        }
    }

    // ---- composer ----
    Rectangle {
        id: composer
        x: 12; width: parent.width - 24; height: 42; radius: 21
        anchors.bottom: parent.bottom; anchors.bottomMargin: 12
        color: Theme.win3; border.color: input.input.activeFocus ? Theme.line3 : Theme.line2; border.width: 1
        Field { id: input; x: 16; width: parent.width - 100; height: parent.height; label: "Message"; placeholder: "Ask " + Os.name + " to do something…"; onAccepted: app.submit(text) }
        TbButton { anchors.right: send.left; anchors.verticalCenter: parent.verticalCenter; glyph: "mic"; label: "Dictate" }
        Rectangle {
            id: send
            property string aiName: "Send message"
            property string aiRole: "button"
            function aiActivate() { app.submit(input.text); }
            anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter
            width: 32; height: 32; radius: 16
            color: input.text.trim() ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
            Behavior on color { ColorAnimation { duration: 160 } }
            Glyph { anchors.centerIn: parent; name: "send"; color: "white"; width: 15; height: 15 }
            MouseArea { anchors.fill: parent; onClicked: send.aiActivate() }
        }
    }
}
