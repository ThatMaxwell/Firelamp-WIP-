// The activity timeline: a readable log of everything the AI did, and why.
import QtQuick
import QtQuick.Effects

Item {
    id: tl
    property bool open: false
    property bool aiHidden: true
    width: 372
    ListModel { id: entries }
    Connections {
        target: Os
        function onLog(e) {
            var d = new Date(), h = d.getHours(), m = d.getMinutes(), s = d.getSeconds();
            var two = function (n) { return (n < 10 ? "0" : "") + n; };
            var t = two(h) + ":" + two(m);
            entries.insert(0, { kind: e.kind, title: e.title, why: e.why || "", app: e.app || "", time: t });
        }
        function onTimelineToggle(on) { tl.open = on === undefined ? !tl.open : on; }
    }

    transform: Translate { x: tl.open ? 0 : tl.width + 24; Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } } }

    RectangularShadow { anchors.fill: bg; radius: 12; blur: 40; offset.y: 14; color: Qt.rgba(0, 0, 0, 0.45) }
    Rectangle { id: bg; anchors.fill: parent; radius: 12; color: Theme.surface0; border.color: Theme.hairline; border.width: 1 }

    Row {
        x: 18; y: 16; spacing: 10
        Column {
            Text { text: "Activity"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
            Text { text: "What " + Os.name + " did, and why"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
        }
    }
    TbButton { anchors.right: parent.right; anchors.rightMargin: 14; y: 20; glyph: "x"; label: "Close timeline"; onClicked: tl.open = false }

    Text {
        visible: entries.count === 0
        anchors.centerIn: parent
        width: parent.width - 60
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "Nothing yet. When " + Os.name + " does something, it shows up here with the reason why."
        color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
    }
    Text { visible: entries.count > 0; x: 18; y: 70; text: "TODAY"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 0.4 }

    ListView {
        id: list
        x: 14; y: 92
        width: parent.width - 28
        height: parent.height - y - 52
        clip: true
        model: entries
        spacing: 0
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutQuint } }
        delegate: Item {
            id: row
            required property int index
            required property string kind
            required property string title
            required property string why
            required property string app
            required property string time
            width: list.width
            height: card.implicitHeight + 14
            Text { x: 4; y: 6; width: 40; text: row.time; color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10; font.weight: Font.Light }
            Column {
                id: card
                x: 50; y: 4
                width: parent.width - 54
                spacing: 2
                Text { width: parent.width; text: row.title; textFormat: Text.StyledText; wrapMode: Text.WordWrap; color: row.kind === "denied" ? Theme.danger : Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                Text { visible: row.why !== ""; width: parent.width; text: row.why; wrapMode: Text.WordWrap; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                Text { visible: row.app !== ""; text: row.app; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; topPadding: 2 }
            }
        }
    }
    Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 44; width: parent.width; height: 1; color: Theme.hairline }
    Row {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 15; x: 18; spacing: 8
        Glyph { name: "shield"; width: 14; height: 14; color: Theme.text3 }
        Text { text: "Every action is logged. Risky ones always ask you first."; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
    }
}
