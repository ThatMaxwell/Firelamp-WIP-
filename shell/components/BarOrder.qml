// The top bar's right side in miniature. Drag an item sideways and the others make room;
// the real top bar follows live.
import QtQuick

Rectangle {
    id: bo
    property var order: Os.barItems
    readonly property var widths: ({ assistant: 60, battery: 40, wifi: 26, search: 26, control: 26, clock: 44 })
    readonly property int gap: 2
    function xOf(k, ord) { var x = 4; for (var i = 0; i < ord.length && ord[i] !== k; i++) x += widths[ord[i]] + gap; return x; }
    width: 4 * 2 + 222 + 5 * gap; height: 26; radius: 7
    color: Theme.bar; border.color: Theme.hairline2; border.width: 1
    Connections { target: Os; function onBarItemsChanged() { bo.order = Os.barItems; } }

    Repeater {
        model: Os.barDefault
        Rectangle {
            id: it
            required property string modelData
            property bool held: false
            property real dx: 0
            property string aiName: ({ assistant: Os.name, battery: "Battery", wifi: "Wi-Fi", search: "Ask", control: "Control Center", clock: "Clock" })[modelData] + " in the top bar"
            property string aiRole: "handle"
            width: bo.widths[modelData]; height: 20; y: 3; radius: 5
            x: held ? dx : bo.xOf(modelData, bo.order)
            z: held ? 2 : 1
            Behavior on x { enabled: !it.held; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            color: held ? Theme.surface3 : "transparent"
            border.color: held ? Theme.hairline2 : "transparent"; border.width: 1
            scale: held ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }

            Row {
                anchors.centerIn: parent; spacing: 4
                Rectangle { visible: it.modelData === "assistant"; width: 5; height: 5; radius: 2.5; color: Theme.text4; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    visible: ["assistant", "battery", "clock"].indexOf(it.modelData) >= 0
                    text: it.modelData === "assistant" ? Os.name : it.modelData === "battery" ? (Os.demo ? "87%" : Os.battery >= 0 ? Os.battery + "%" : "Battery") : Os.clock(new Date(), false)
                    width: Math.min(implicitWidth, it.width - 16); elide: Text.ElideRight
                    color: it.modelData === "assistant" ? Theme.text2 : Theme.text; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.Medium
                }
                Glyph { visible: ["wifi", "search", "control"].indexOf(it.modelData) >= 0; name: it.modelData; width: 11; height: 11; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: it.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real grab: 0
                onPressed: (m) => { grab = m.x; it.dx = it.x; it.held = true; }
                onPositionChanged: (m) => {
                    if (!it.held) return;
                    it.dx = Math.max(0, Math.min(bo.width - it.width, it.x + m.x - grab));
                    // where the dragged item's centre falls among the others
                    var rest = bo.order.filter(function (k) { return k !== it.modelData; }), c = it.dx + it.width / 2, x = 4, at = rest.length;
                    for (var i = 0; i < rest.length; i++) { if (c < x + bo.widths[rest[i]] / 2) { at = i; break; } x += bo.widths[rest[i]] + bo.gap; }
                    rest.splice(at, 0, it.modelData);
                    if (rest.join() !== bo.order.join()) bo.order = rest;
                }
                onReleased: { it.held = false; Os.settings.barOrder = JSON.stringify(bo.order); }
            }
        }
    }
}
