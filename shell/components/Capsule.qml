// The control capsule: who is working, what they're doing, and pause / stop.
// Quiet on purpose: a surface, a hairline and one ember dot that says the AI is live.
import QtQuick
import QtQuick.Effects

Item {
    id: cap
    property string what: ""
    property string plan: ""              // the current line of the plan, when there is one
    property int k: 0
    property int total: 0
    property int steps: 0
    property bool paused: false
    property string why: ""               // why it paused itself ("you’re using Mail")
    property string stuck: ""             // what blocked it; the capsule turns neutral
    property bool shown: false
    property bool aiHidden: true          // the AI can't press its own stop button
    readonly property string st: Os.agent ? Os.agent.mode : "idle"
    readonly property bool neutral: stuck !== ""
    width: row.implicitWidth + 20
    height: 36
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.94
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: shown ? 300 : 180; easing.type: Easing.OutQuint } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }

    RectangularShadow { anchors.fill: bg; radius: 18; blur: 24; offset.y: 8; color: Qt.rgba(0, 0, 0, 0.35) }
    Rectangle { id: bg; anchors.fill: parent; radius: 18; color: Theme.surface1; border.color: Theme.hairline2; border.width: 1 }

    component Round: Rectangle {
        id: rb
        property string glyph
        property string tip
        signal clicked()
        width: 24; height: 24; radius: 12; anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: rma.containsMouse ? Theme.surface3 : Theme.surface2
        scale: rma.pressed ? 0.97 : 1
        Accessible.role: Accessible.Button; Accessible.name: tip; Accessible.ignored: !visible; Accessible.onPressAction: rb.clicked()
        Glyph { anchors.centerIn: parent; width: 11; height: 11; name: rb.glyph; color: Theme.text2 }
        MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; onClicked: rb.clicked() }
    }
    // words, not icons, wherever the choice matters: Resume, Show me, Stop
    component Pill: Rectangle {
        id: pb
        property string text
        property bool strong: false
        signal clicked()
        width: pt.implicitWidth + 20; height: 24; radius: 12; anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: strong ? (pma.containsMouse ? "#ffffff" : Theme.text) : (pma.containsMouse ? Theme.surface3 : Theme.surface2)
        scale: pma.pressed ? 0.97 : 1
        Accessible.role: Accessible.Button; Accessible.name: text; Accessible.ignored: !visible; Accessible.onPressAction: pb.clicked()
        Text { id: pt; anchors.centerIn: parent; text: pb.text; color: pb.strong ? Theme.bg : Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold }
        MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; onClicked: pb.clicked() }
    }

    Row {
        id: row
        x: cap.neutral ? 16 : 14; anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        // the ember dot means "working"; stuck or teaching, it goes away
        Rectangle { visible: !cap.neutral; width: 6; height: 6; radius: 3; color: cap.paused ? Theme.text3 : Theme.ember; anchors.verticalCenter: parent.verticalCenter }
        Text { text: Os.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        Text {
            id: whatText
            width: Math.min(implicitWidth, 380)
            text: cap.neutral ? cap.stuck : cap.paused ? (cap.why ? "Paused · " + cap.why : "Paused") : (cap.plan || cap.what)
            elide: Text.ElideRight
            color: cap.paused && !cap.neutral ? Theme.text3 : Theme.text2
            font.family: Theme.font; font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            Behavior on text { SequentialAnimation { NumberAnimation { target: whatText; property: "opacity"; to: 0; duration: 100 } PropertyAction {} NumberAnimation { target: whatText; property: "opacity"; to: 1; duration: 140 } } }
        }
        Text {
            visible: !cap.neutral && !cap.paused
            text: cap.total ? cap.k + " of " + cap.total : cap.steps + (cap.steps === 1 ? " step" : " steps")
            color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter
        }
        Round { visible: !cap.neutral && !cap.paused; glyph: "pause"; tip: "Pause"; onClicked: Os.agent.togglePause() }
        Pill { visible: !cap.neutral && cap.paused; text: "Resume"; strong: true; onClicked: Os.agent.togglePause() }
        Pill { visible: cap.st === "stuck"; text: "Show me"; strong: true; onClicked: Os.agent.showMe() }
        Pill { visible: cap.st === "teaching" && Os.agent.real; text: "Done"; strong: true; onClicked: Os.agent.showedMe() }
        Pill { visible: cap.neutral || cap.paused; text: "Stop"; onClicked: Os.agent.stop() }
        Round { visible: !cap.neutral && !cap.paused; glyph: "stop"; tip: "Stop"; onClicked: Os.agent.stop() }
    }
}
