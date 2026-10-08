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
            var t = (h % 12 || 12) + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + (h < 12 ? " AM" : " PM");
            entries.insert(0, { kind: e.kind, title: e.title, why: e.why || "", app: e.app || "", time: t });
        }
        function onTimelineToggle(on) { tl.open = on === undefined ? !tl.open : on; }
    }
    readonly property var kindGlyph: ({ open: "open", click: "click", type: "type", ask: "shield", denied: "x", done: "check", look: "eye", move: "folder", think: "sparkle" })

    transform: Translate { x: tl.open ? 0 : tl.width + 24; Behavior on x { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } } }

    RectangularShadow { anchors.fill: bg; radius: 18; blur: 50; offset.y: 14; color: Qt.rgba(0, 0, 0, 0.6) }
    Rectangle { id: bg; anchors.fill: parent; radius: 18; color: Qt.rgba(0.11, 0.11, 0.105, 0.96); border.color: Qt.rgba(1, 1, 1, 0.13); border.width: 0.5 }

    Row {
        x: 18; y: 18; spacing: 10
        Logo { width: 22; height: 26; animated: tl.open }
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
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 } NumberAnimation { property: "y"; from: -10; duration: 420; easing.type: Easing.OutBack } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 300; easing.type: Easing.OutCubic } }
        delegate: Item {
            id: row
            required property int index
            required property string kind
            required property string title
            required property string why
            required property string app
            required property string time
            width: list.width
            height: card.implicitHeight + 16
            readonly property color tint: kind === "ask" ? Theme.accent : kind === "denied" ? Theme.danger : kind === "done" ? Theme.success : Theme.text2
            // the spine: an inked line that boils between entries
            InkRect {
                visible: row.index < entries.count - 1
                x: 14; y: 28; width: 2; height: row.height - 26
                radius: 1; lineWidth: 1.4; wobble: 0.8
                color: Theme.line3
            }
            Rectangle {
                x: 2; y: 2; width: 26; height: 26; radius: 13
                color: Qt.rgba(row.tint.r, row.tint.g, row.tint.b, 0.15)
                Glyph { anchors.centerIn: parent; width: 13; height: 13; name: tl.kindGlyph[row.kind] || "sparkle"; color: row.tint }
                InkRect { anchors.fill: parent; anchors.margins: -1; radius: 14; lineWidth: 1.4; wobble: 0.9; color: Qt.rgba(row.tint.r, row.tint.g, row.tint.b, 0.55) }
            }
            Column {
                id: card
                x: 38; y: 4
                width: parent.width - 42
                spacing: 2
                Text { width: parent.width; text: row.title; textFormat: Text.StyledText; wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                Text { visible: row.why !== ""; width: parent.width; text: row.why; wrapMode: Text.WordWrap; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
                Row {
                    spacing: 6; topPadding: 3
                    Text { text: row.time; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        visible: row.app !== ""
                        height: 17; radius: 8.5; width: chip.implicitWidth + 14
                        color: Qt.rgba(1, 1, 1, 0.07)
                        Text { id: chip; anchors.centerIn: parent; text: row.app; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                }
            }
        }
    }
    Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 44; width: parent.width; height: 0.5; color: Theme.line2 }
    Row {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 15; x: 18; spacing: 8
        Glyph { name: "shield"; width: 14; height: 14; color: Theme.text3 }
        Text { text: "Every action is logged. Risky ones always ask you first."; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
    }
}
