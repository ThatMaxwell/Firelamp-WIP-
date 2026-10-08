// The Ask bar: summon it from anywhere (Alt+Space or Ctrl+K). One field; results are plain
// rows, and the first row is always what the assistant would do with what you typed.
import QtQuick
import QtQuick.Effects
import "../js/plans.js" as Plans
import "../js/art.js" as Art

Item {
    id: ask
    objectName: "askBar"
    property bool shown: false
    property int sel: 0
    property bool aiHidden: true
    property var apps: []                   // [{id, title, icon}] from Main
    signal go(string text)
    signal launch(string id)
    anchors.fill: parent
    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: ask.shown ? 160 : 120; easing.type: Easing.OutQuint } }
    function open() { shown = true; field.text = ""; sel = 0; armed = false; firstPos = Qt.point(-1, -1); field.input.forceActiveFocus(); }
    // hover only selects once the pointer has really moved, not when rows slide under a resting pointer
    property bool armed: false
    property point firstPos: Qt.point(-1, -1)
    function track(x, y) {
        if (firstPos.x < 0) firstPos = Qt.point(x, y);
        else if (Math.abs(x - firstPos.x) + Math.abs(y - firstPos.y) > 3) armed = true;
    }
    function close() { shown = false; }
    function typeText(t) { field.text = t; }

    readonly property string q: field.text.trim()
    // rows: the assistant first, then apps, then other things the assistant knows how to do
    readonly property var rows: {
        var out = [], lq = q.toLowerCase();
        if (q) out.push({ kind: "ai", title: q, sub: "Ask " + Os.name });
        else out.push({ kind: "ai", title: Os.suggestions[0].text, sub: "Suggested" });
        apps.forEach(function (a) {
            if (!q || a.title.toLowerCase().indexOf(lq) === 0 || (lq.length > 1 && a.title.toLowerCase().indexOf(lq) > 0))
                out.push({ kind: "app", id: a.id, title: a.title, icon: a.icon, sub: "Application" });
        });
        if (!q) out = out.slice(0, 5);
        Os.suggestions.forEach(function (sg, i) {
            if ((q ? sg.text.toLowerCase().indexOf(lq) >= 0 && sg.text !== q : i > 0) && out.length < 8)
                out.push({ kind: "ai", title: sg.text, sub: "Ask " + Os.name });
        });
        return out;
    }
    onRowsChanged: sel = 0
    function pick(i) {
        var r = rows[i]; if (!r) return;
        close();
        if (r.kind === "app") launch(r.id); else go(r.title);
    }

    // the desktop dims to 85% so the bar reads as the one thing in front
    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.15 }
    MouseArea {
        anchors.fill: parent; hoverEnabled: true; onPressed: ask.close()
        onPositionChanged: (m) => ask.track(m.x, m.y)
    }
    Item {
        id: box
        width: Math.min(620, parent.width - 40)
        height: 52 + list.height + 1
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2 + (ask.shown ? 0 : -4)
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }
        RectangularShadow { anchors.fill: bg; radius: 14; blur: 70; offset.y: 24; color: Qt.rgba(0, 0, 0, 0.55) }
        Rectangle { id: bg; anchors.fill: parent; radius: 14; color: Theme.surface1; border.color: Theme.hairline2; border.width: 1 }
        MouseArea { anchors.fill: parent }

        Glyph { x: 18; y: 18; width: 16; height: 16; name: "search"; color: Theme.text3 }
        Field {
            id: field
            x: 46; width: box.width - 64; height: 52
            pixelSize: 18
            placeholder: "Search, or ask " + Os.name + " to do something"
            onAccepted: ask.pick(ask.sel)
            input.Keys.onEscapePressed: ask.close()
            input.Keys.onDownPressed: ask.sel = Math.min(ask.rows.length - 1, ask.sel + 1)
            input.Keys.onUpPressed: ask.sel = Math.max(0, ask.sel - 1)
        }
        Rectangle { y: 52; width: parent.width; height: 1; color: Theme.hairline }

        Column {
            id: list
            y: 53; x: 6; width: parent.width - 12
            topPadding: 6; bottomPadding: 6
            Repeater {
                model: ask.rows
                Rectangle {
                    id: rowItem
                    required property var modelData
                    required property int index
                    readonly property bool ai: modelData.kind === "ai"
                    width: list.width; height: 36; radius: 7
                    color: ask.sel === index ? Theme.surface2 : "transparent"
                    // the assistant's rows carry its flame; apps carry their tile
                    Item {
                        x: 10; width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter
                        Logo { visible: rowItem.ai; anchors.centerIn: parent; width: 13; height: 19 }
                        Image { visible: !rowItem.ai; anchors.fill: parent; sourceSize: Qt.size(40, 40); source: rowItem.ai ? "" : Art.icon(rowItem.modelData.icon) }
                    }
                    // a typed request reads as a sentence: "Ask Juniper “…”", the verb quieter
                    readonly property bool asking: ai && modelData.sub !== "Suggested"
                    Text {
                        x: 40; width: parent.width - 150; anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.StyledText
                        text: rowItem.asking ? "<font color=\"" + Theme.text2 + "\">Ask " + Os.name + "</font> “" + rowItem.modelData.title.replace(/&/g, "&amp;").replace(/</g, "&lt;") + "”" : rowItem.modelData.title
                        elide: Text.ElideRight
                        color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.weight: rowItem.index === 0 ? Font.Medium : Font.Normal
                    }
                    Text {
                        visible: ask.sel !== rowItem.index
                        anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                        text: rowItem.asking ? "" : rowItem.modelData.sub
                        color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
                    }
                    Rectangle {
                        visible: ask.sel === rowItem.index
                        anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        width: rk.implicitWidth + 12; height: 20; radius: 5; color: Theme.surface2; border.color: Theme.hairline2; border.width: 1
                        Text { id: rk; anchors.centerIn: parent; text: "return"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium }
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onPositionChanged: (m) => { var p = mapToItem(ask, m.x, m.y); ask.track(p.x, p.y); if (ask.armed) ask.sel = rowItem.index; } onClicked: ask.pick(rowItem.index) }
                }
            }
        }
    }
}
