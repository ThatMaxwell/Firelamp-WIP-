// First boot: you name your assistant, and its fire cursor appears for the first time to
// sign the name. Nothing in the OS has a name before this moment.
import QtQuick
import QtQuick.Shapes

Item {
    id: nc
    objectName: "nameCard"
    property bool shown: false
    property bool aiHidden: true
    property string stage: "ask"            // ask | signing | signed
    signal done()
    anchors.fill: parent
    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: nc.shown ? 500 : 700; easing.type: Easing.OutQuint } }
    onShownChanged: if (shown) { stage = "ask"; pressed = false; waiting = false; field.text = ""; field.input.forceActiveFocus(); }

    readonly property string typed: field.text.trim()
    // the fire cursor appears for the first time only once you've typed, and waits on Continue
    property bool waiting: false
    onTypedChanged: {
        if (stage !== "ask") return;
        if (typed) settle.restart();
        else { settle.stop(); if (flame.shown) { flame.hide(); waiting = false; } }
    }
    Timer { id: settle; interval: 650; onTriggered: nc.toContinue(null) }
    function toContinue(k) {
        var c = cont.mapToItem(nc, cont.width * 0.84, cont.height * 0.78);
        if (waiting) { if (k) k(); return; }
        var fresh = !flame.shown;
        if (fresh) flame.show(mark.mapToItem(nc, mark.width * 0.42, mark.height * 0.86));
        later(fresh ? 260 : 0, function () {
            flame.moveTo(c.x, c.y, function () { nc.waiting = true; if (k) k(); }, cont.width);
        });
    }

    function finish() {
        if (!typed || stage !== "ask") return;
        settle.stop();
        stage = "signing";
        field.input.readOnly = true;
        field.input.focus = false;
        field.input.cursorVisible = false;
        // the flame presses Continue, then goes back up and signs the name
        var a = nameText.mapToItem(nc, 0, 0);
        var y0 = a.y + nameText.height + 12;
        stroke.x = a.x - 10; stroke.y = y0 - 9; stroke.w = nameText.width + 20;
        toContinue(function () {
          cont.down = true;
          flame.click(function () {});
          later(160, function () {
            cont.down = false; nc.waiting = false; nc.pressed = true;
            flame.moveTo(stroke.x + 2, y0, function () {
                flame.click(function () {});
                later(90, function () {
                    flame.glide(stroke.x + stroke.w, y0 - 2, Math.max(520, stroke.w * 3.2), function () {
                        flame.click(function () {
                            Os.settings.assistantName = nc.typed;
                            nc.stage = "signed";
                            later(1500, function () { flame.hide(); nc.shown = false; nc.done(); });
                        });
                    });
                });
            }, 40);
          });
        });
    }
    property bool pressed: false
    function later(ms, k) { if (ms <= 0) return k(); tick.k = k; tick.interval = ms; tick.restart(); }
    Timer { id: tick; property var k; onTriggered: { var f = k; k = null; if (f) f(); } }

    // its own room: the same graphite and lamp as the desktop, without the desktop
    Wallpaper { anchors.fill: parent }
    MouseArea { anchors.fill: parent; onPressed: if (nc.stage === "ask") field.input.forceActiveFocus() }

    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        // one block, optically centred a little above the middle
        y: Math.round(parent.height * 0.45 - implicitHeight / 2)
        width: 640
        spacing: 0

        // the logo, boiling: the only animated thing on screen until you type
        Item {
            id: mark
            width: 54; height: 80; anchors.horizontalCenter: parent.horizontalCenter
            GlowLogo { anchors.fill: parent; glow: 0.35 }
        }
        Item { width: 1; height: 36 }
        // once signed, the hero line becomes the assistant saying its own name
        Text {
            id: headline
            width: parent.width; horizontalAlignment: Text.AlignHCenter
            text: nc.stage === "signed" ? "Hi. I’m " + nc.typed + "." : "Your computer has a second cursor now."
            color: Theme.text; font.family: Theme.font; font.pixelSize: 30; font.weight: Font.DemiBold
            Behavior on text { SequentialAnimation {
                NumberAnimation { target: headline; property: "opacity"; to: 0; duration: 180 }
                PropertyAction {}
                NumberAnimation { target: headline; property: "opacity"; to: 1; duration: 320; easing.type: Easing.OutQuint } } }
        }
        Item { width: 1; height: 10 }
        Text {
            id: sub
            width: parent.width; horizontalAlignment: Text.AlignHCenter
            text: nc.stage === "signed" ? "Ask me to do things on your computer, and watch me do them." : "Give it a name. It’s what you’ll call it, and how it signs its work."
            color: Theme.text2; font.family: Theme.font; font.pixelSize: 15
            Behavior on text { SequentialAnimation {
                NumberAnimation { target: sub; property: "opacity"; to: 0; duration: 140 }
                PropertyAction {}
                NumberAnimation { target: sub; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutQuint } } }
        }
        Item { width: 1; height: 54 }

        // the name: big, centred, no box; a quiet hairline until the cursor signs it
        Item {
            width: 420; height: 64; anchors.horizontalCenter: parent.horizontalCenter
            Field {
                id: field
                objectName: "nameField"
                anchors.fill: parent
                align: TextInput.AlignHCenter
                pixelSize: 40
                placeholder: "Type a name"
                placeholderOnFocus: false
                textColor: Theme.text
                input.font.weight: Font.DemiBold
                input.maximumLength: 20
                input.cursorVisible: nc.stage === "ask"
                onAccepted: nc.finish()
            }
            // invisible twin of the typed name, to measure where the signature goes
            Text { id: nameText; visible: false; anchors.centerIn: parent; text: nc.typed; font.family: Theme.font; font.pixelSize: 40; font.weight: Font.DemiBold }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter; y: parent.height + 4
                width: 300; height: 1; color: Theme.hairline2
                opacity: nc.stage === "ask" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
        Item { width: 1; height: 34 }
        Item {
            width: parent.width; height: 34
            FButton {
                id: cont
                property bool down: false
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Continue"; primary: true; implicitWidth: 128; implicitHeight: 34
                scale: down ? 0.97 : 1
                opacity: nc.typed !== "" && !nc.pressed ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }
                onClicked: nc.finish()
            }
        }
    }

    // the signature: an ember stroke revealed under the pen, boiling like the flame
    Item {
        id: stroke
        property real w: 0
        width: Math.max(0, Math.min(w, flame.px - x + 2)); height: 18
        visible: nc.stage !== "ask"
        clip: true
        Shape {
            id: ink
            property int frame: 0
            width: stroke.w; height: 18
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Theme.ember; strokeWidth: 2.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                scale: Qt.size(stroke.w / 100, 1)
                PathSvg { path: ["M1 10 C 18 6, 34 13, 52 9 S 84 6, 99 8",
                                  "M1 9 C 19 7, 33 12, 51 10 S 85 5, 99 9",
                                  "M1 10 C 17 7, 35 12, 53 8 S 83 7, 99 7"][ink.frame] }
            }
            // the ink boils while it's being written and for 400 ms after the last click, then rests
            Timer { running: nc.shown && (nc.stage === "signing" || inkTail.running); interval: 130; repeat: true; onTriggered: ink.frame = (ink.frame + 1) % 3 }
            Timer { id: inkTail; interval: 400 }
            Connections { target: nc; function onStageChanged() { if (nc.stage === "signed") inkTail.restart(); } }
        }
    }

    FireCursor { id: flame }
}
