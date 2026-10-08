// The activity timeline: a readable log of everything the AI did, and why.
import QtQuick
import QtQuick.Effects

Item {
    id: tl
    property bool open: false
    property bool aiHidden: true
    width: 372
    // newest first; each milestone holds its routine steps, collapsed until you open it
    ListModel { id: entries }
    property real now: Date.now()
    Timer { interval: 1000; repeat: true; running: tl.open; onTriggered: tl.now = Date.now() }
    function expand(i) { var n = 0; for (var j = 0; j < entries.count; j++) if (entries.get(j).kind === "milestone" && n++ === i) return entries.setProperty(j, "expanded", true); }
    function indexOf(gid) { for (var i = 0; i < entries.count; i++) if (entries.get(i).gid === gid) return i; return -1; }
    Connections {
        target: Os
        function onLog(e) {
            var d = new Date(), two = function (n) { return (n < 10 ? "0" : "") + n; };
            var t = two(d.getHours()) + ":" + two(d.getMinutes());
            if (e.gid && e.kind !== "milestone") {
                var i = tl.indexOf(e.gid);
                if (i >= 0) {
                    var st = JSON.parse(entries.get(i).steps);
                    st.push({ title: e.title, time: t });
                    entries.setProperty(i, "steps", JSON.stringify(st));
                    entries.setProperty(i, "n", st.length);
                    if (e.app) entries.setProperty(i, "app", e.app);
                    return;
                }
            }
            entries.insert(0, { gid: e.gid || "", kind: e.kind, title: e.title, why: e.why || "", app: e.app || "", time: t,
                                live: !!e.live, undo: false, until: 0, undone: false, steps: "[]", n: 0, expanded: false });
        }
        function onLogUpdate(gid, f) {
            var i = tl.indexOf(gid); if (i < 0) return;
            for (var k in f) entries.setProperty(i, k, f[k]);
            // a milestone lands in time order when it finishes, after any asks inside it
            if (f.live === false && i > 0) entries.move(i, 0, 1);
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
        // opacity: 1 in displaced/move, so an add that gets interrupted never leaves a row dimmed
        displaced: Transition { NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutQuint } NumberAnimation { property: "opacity"; to: 1; duration: 120 } }
        move: Transition { NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutQuint } NumberAnimation { property: "opacity"; to: 1; duration: 120 } }
        delegate: Item {
            id: row
            required property int index
            required property string gid
            required property string kind
            required property string title
            required property string why
            required property string app
            required property string time
            required property bool live
            required property bool undo
            required property real until
            required property bool undone
            required property string steps
            required property int n
            required property bool expanded
            readonly property bool group: kind === "milestone"
            // asks, refusals and stops always stand out from the routine
            readonly property bool loud: kind === "ask" || kind === "stuck" || kind === "denied"
            readonly property bool canUndo: undo && tl.now < until
            width: list.width
            height: body.implicitHeight + (loud ? 18 : 14)

            Rectangle {
                visible: row.loud
                x: 0; y: 2; width: parent.width; height: body.implicitHeight + 12; radius: 8
                color: Theme.surface1; border.color: Theme.hairline2; border.width: 1
            }
            Text { x: 6; y: row.loud ? 9 : 6; width: 40; text: row.time; color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10; font.weight: Font.Light }
            Column {
                id: body
                x: 50; y: row.loud ? 8 : 4
                width: parent.width - 58
                spacing: 3
                Item {
                    width: parent.width; height: titleText.height
                    Row {
                        id: titleRow
                        spacing: 7
                        Glyph { visible: row.loud; y: 2; width: 13; height: 13; name: row.kind === "ask" ? "shield" : row.kind === "stuck" ? "eye" : "x"; color: row.kind === "denied" ? Theme.danger : Theme.text2 }
                        Text {
                            id: titleText
                            width: body.width - (row.loud ? 20 : 0) - (undoLink.visible ? undoLink.width + 10 : 0)
                            text: row.title; textFormat: Text.StyledText; wrapMode: Text.WordWrap
                            color: row.kind === "denied" ? Theme.danger : row.kind === "done" ? Theme.text3 : row.group || row.loud ? Theme.text : Theme.text2
                            font.family: Theme.font; font.pixelSize: 13; font.weight: row.group || row.loud ? Font.Medium : Font.Normal
                        }
                    }
                    Text {
                        id: undoLink
                        visible: row.canUndo
                        anchors.right: parent.right
                        text: "Undo"; color: uma.containsMouse ? Theme.text : Theme.text2
                        font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium; font.underline: uma.containsMouse
                        MouseArea { id: uma; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Os.agent.undo(row.gid) }
                    }
                }
                Text { visible: row.why !== "" && !row.group; width: parent.width; text: row.why; wrapMode: Text.WordWrap; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                // the milestone's summary line doubles as the toggle for its steps
                Row {
                    id: sumRow
                    visible: row.group
                    spacing: 6
                    MouseArea { parent: row; x: body.x + sumRow.x - 4; y: body.y + sumRow.y - 4; width: sumRow.width + 12; height: sumRow.height + 8; visible: row.group
                                enabled: row.n > 0; cursorShape: Qt.PointingHandCursor; onClicked: entries.setProperty(row.index, "expanded", !row.expanded) }
                    Rectangle { visible: row.live; width: 5; height: 5; radius: 2.5; color: Theme.ember; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: (row.live ? "Working" : row.undone ? "Undone" : row.n + (row.n === 1 ? " step" : " steps")) + (row.app ? " · " + row.app : "")
                        color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                    }
                    Glyph { visible: row.n > 0; name: "chevron"; width: 10; height: 10; color: Theme.text3; anchors.verticalCenter: parent.verticalCenter
                            rotation: row.expanded ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutQuint } } }
                    Item { width: 1; height: 1 }
                }
                Column {
                    visible: row.group && row.expanded
                    width: parent.width; spacing: 3; topPadding: 3
                    Repeater {
                        model: row.expanded ? JSON.parse(row.steps) : []
                        Text { required property var modelData; width: body.width; text: modelData.title.replace(/<[^>]+>/g, ""); wrapMode: Text.WordWrap
                               color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }
                Text { visible: !row.group && !row.loud && row.app !== "" && row.kind !== "done"; text: row.app; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; topPadding: 1 }
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
