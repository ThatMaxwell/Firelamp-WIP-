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
    function add(who, text, time) { msgs.append({ who: who, text: text, time: time || "" }); Qt.callLater(chat.positionViewAtEnd); }
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
        if (q.who !== "ai") { add(q.who, q.text, q.time); return next(); }
        typer.text = q.text; typer.interval = 420 + Math.min(900, q.text.length * 11); typer.start();
    }
    Timer { id: typer; property string text; onTriggered: { app.add("ai", text); app.next(); } }
    Connections {
        target: Os
        function onSay(t) { app.say(t); }
        function onLog(e) {
            var d = new Date(), two = function (n) { return (n < 10 ? "0" : "") + n; };
            if (e.kind === "done") app.queue.push({ who: "sys", text: "Done · every step is in Activity" });
            else app.queue.push({ who: "step", text: e.title, time: two(d.getHours()) + ":" + two(d.getMinutes()) + ":" + two(d.getSeconds()) });
            if (!app.typing) app.next();
        }
    }

    // ---- header ----
    Item {
        id: head
        width: parent.width; height: 52
        Row {
            x: 84; anchors.verticalCenter: parent.verticalCenter; spacing: 8
            Text { text: Os.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold; anchors.baseline: stateText.baseline }
            Text { id: stateText; text: app.st === "running" ? "working" : app.st === "paused" ? "paused" : "ready"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
        TbButton { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; glyph: "clock"; label: "Activity timeline"; onClicked: Os.timelineToggle(undefined) }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.hairline }
    }

    // ---- hello ----
    Column {
        visible: msgs.count === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: 130; width: parent.width - 70; spacing: 12
        Logo { width: 36; height: 52; anchors.horizontalCenter: parent.horizontalCenter }
        Item { width: 1; height: 4 }
        // no greeting with a name until you have chosen one
        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Os.settings.assistantName ? "Hi, I’m " + Os.name + "." : "What can I do for you?"; color: Theme.text; font.family: Theme.font; font.pixelSize: 20; font.weight: Font.DemiBold }
        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; lineHeight: 1.2
               text: "I use this computer the way you do, just faster. Ask me for something and watch my cursor work. You can pause or stop me any time."
               color: Theme.text2; font.family: Theme.font; font.pixelSize: 13 }
    }

    // ---- conversation ----
    ListModel { id: msgs }
    ListView {
        id: chat
        y: head.height; width: parent.width; height: (chips.visible ? chips.y : composer.y) - y - 6
        clip: true; spacing: 10
        topMargin: 18; bottomMargin: 6
        model: msgs
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutQuint } }
        delegate: Item {
            id: m
            required property string who
            required property string text
            required property string time
            required property int index
            readonly property bool live: who === "step" && index === msgs.count - 1 && app.st !== "idle"
            width: chat.width; height: who === "sys" ? 22 : who === "step" ? stepRow.height : bubble.height
            Text { visible: m.who === "sys"; x: 18; anchors.verticalCenter: parent.verticalCenter; text: m.text; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
            // a step the assistant took: mono time, then what it did
            Row {
                id: stepRow
                visible: m.who === "step"
                x: 18; spacing: 10
                Text { width: 62; text: m.time; color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10; topPadding: 2 }
                Text { visible: m.live; text: "●"; color: Theme.ember; font.pixelSize: 8; topPadding: 3 }
                Text { width: chat.width - 18 - 62 - 10 - 18 - (m.live ? 18 : 0); text: m.text; textFormat: Text.StyledText; wrapMode: Text.WordWrap; color: m.live ? Theme.text : Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
            }
            Rectangle {
                id: bubble
                visible: m.who === "me" || m.who === "ai"
                x: m.who === "me" ? parent.width - width - 16 : 4
                width: Math.min(t.implicitWidth, chat.width * (m.who === "me" ? 0.75 : 0.86)) + 28
                height: t.height + (m.who === "me" ? 18 : 4)
                radius: 12
                // your messages sit in a quiet surface; the assistant just talks, no bubble
                color: m.who === "me" ? Theme.surface2 : "transparent"
                Text { id: t; x: 14; y: m.who === "me" ? 9 : 2; width: Math.min(implicitWidth, chat.width * (m.who === "me" ? 0.75 : 0.86)); text: m.text; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; lineHeight: 1.2 }
            }
        }
        footer: Item {
            width: chat.width; height: app.typing ? 30 : 0
            Item {
                visible: app.typing; x: 18; y: 6; width: 28; height: 20
                Row {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: 5; height: 5; radius: 2.5; color: Theme.text3; opacity: 0.35
                            SequentialAnimation on opacity { running: app.typing; loops: Animation.Infinite
                                PauseAnimation { duration: index * 160 }
                                NumberAnimation { to: 1; duration: 240 } NumberAnimation { to: 0.35; duration: 240 }
                                PauseAnimation { duration: 480 - index * 160 } }
                        }
                    }
                }
            }
        }
    }

    // ---- suggestions: plain rows, not chips ----
    Column {
        id: chips
        visible: app.st === "idle"
        x: 10; width: parent.width - 20
        y: composer.y - height - 8
        Rectangle { x: 8; width: parent.width - 16; height: 1; color: Theme.hairline }
        Item { width: 1; height: 6 }
        Text { x: 8; text: "Try"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; bottomPadding: 4 }
        Repeater {
            model: Plans.SUGGESTIONS
            Rectangle {
                id: chip
                required property var modelData
                property string aiName: modelData.text
                property string aiRole: "button"
                function aiActivate() { app.submit(modelData.text); }
                width: chips.width; height: 32; radius: 6
                color: cma.containsMouse ? Theme.hover : "transparent"
                scale: cma.pressed ? 0.98 : 1
                Row { id: cr; x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                    Glyph { name: chip.modelData.icon; color: Theme.text3; width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: chip.modelData.text; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: chip.aiActivate() }
            }
        }
    }

    // ---- composer ----
    Rectangle {
        id: composer
        x: 14; width: parent.width - 28; height: 40; radius: 10
        anchors.bottom: parent.bottom; anchors.bottomMargin: 14
        color: Theme.surface2; border.color: input.input.activeFocus ? Theme.focusRing : Theme.hairline2; border.width: 1
        Field { id: input; x: 12; width: parent.width - 100; height: parent.height; label: "Message"; placeholder: "Ask " + Os.name + "…"; onAccepted: app.submit(text) }
        TbButton { anchors.right: send.left; anchors.verticalCenter: parent.verticalCenter; glyph: "mic"; label: "Dictate" }
        Rectangle {
            id: send
            property string aiName: "Send message"
            property string aiRole: "button"
            function aiActivate() { app.submit(input.text); }
            anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter
            width: 28; height: 28; radius: 7
            color: input.text.trim() ? Theme.ember : Theme.surface3
            scale: sendMa.pressed ? 0.97 : 1
            Behavior on color { ColorAnimation { duration: 160 } }
            Glyph { anchors.centerIn: parent; name: "send"; color: input.text.trim() ? "white" : Theme.text3; width: 14; height: 14 }
            MouseArea { id: sendMa; anchors.fill: parent; onClicked: send.aiActivate() }
        }
    }
}
