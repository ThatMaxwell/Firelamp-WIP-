// "Show what the AI sees": the live UI tree drawn over the screen. No screenshots, just
// the roles, labels and bounds the AI reads.
import QtQuick
import "../js/uitree.js" as Tree

Item {
    id: vo
    property Item target
    property var list: []
    property int changes: 0
    property bool aiHidden: true
    anchors.fill: parent
    opacity: Os.vision ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 300 } }

    Timer {
        running: vo.visible; interval: 120; repeat: true; triggeredOnStart: true
        onTriggered: { var l = Tree.nodes(vo.target); if (l.length !== vo.list.length) vo.changes++; vo.list = l; }
    }
    // the menu bar and dock stay clean; only app content is drawn, as quiet hairlines
    // window chrome is skipped; a field drawn inside a box takes the box's shape, and the box's
    // other controls fold into it; every hairline uses the element's own corner radius
    readonly property var shownList: {
        var out = [], frames = [];
        for (var i = 0; i < list.length; i++) {
            var n = list[i], it = n.item;
            if (n.app === "menubar" || n.app === "dock" || it.aiChrome === true) continue;
            if (it.aiFrame) {
                var f = it.aiFrame, p = f.mapToItem(vo.target, 0, 0);
                frames.push(f);
                out.push({ item: it, role: n.role, name: n.name, app: n.app, radius: f.radius || 0,
                           bounds: { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(f.width), h: Math.round(f.height) } });
                continue;
            }
            out.push({ item: it, role: n.role, name: n.name, app: n.app, bounds: n.bounds,
                       radius: n.role === "window" ? Theme.rWin : (it.radius !== undefined ? it.radius : 4) });
        }
        return out.filter(function (n) {
            if (n.item.aiFrame) return true;
            for (var j = 0; j < frames.length; j++) if (n.item.parent === frames[j]) return false;
            return true;
        });
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0.04, 0.04, 0.035, 0.25) }
    MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    // the one element under your pointer (or the fire cursor) gets its label; the smallest wins
    readonly property var hotNode: {
        var c = Os.cursor, px = -1, py = -1;
        if (hov.containsMouse) { px = hov.mouseX; py = hov.mouseY; }
        else if (c && c.shown) { px = c.px; py = c.py; }
        var best = null, area = 1e12;
        for (var i = 0; i < shownList.length; i++) {
            var b = shownList[i].bounds;
            if (shownList[i].role === "window" || px < b.x || px > b.x + b.w || py < b.y || py > b.y + b.h) continue;
            if (b.w * b.h < area) { area = b.w * b.h; best = shownList[i]; }
        }
        return best;
    }
    Repeater {
        model: vo.shownList
        delegate: Rectangle {
            id: box
            required property var modelData
            readonly property bool win: modelData.role === "window"
            readonly property bool hot: vo.hotNode !== null && vo.hotNode.item === modelData.item
            x: modelData.bounds.x; y: modelData.bounds.y; width: modelData.bounds.w; height: modelData.bounds.h
            radius: modelData.radius
            color: hot ? Qt.rgba(1, 244 / 255, 232 / 255, 0.05) : "transparent"
            border.color: Qt.rgba(1, 244 / 255, 232 / 255, hot ? 0.5 : 0.25)
            border.width: 1
            Rectangle {
                visible: box.hot
                y: -height - 4
                height: 18
                width: Math.min(tag.implicitWidth + 12, 260)
                radius: 5
                color: Theme.surface2
                border.color: Theme.hairline2; border.width: 1
                Text {
                    id: tag; x: 6; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 12; elide: Text.ElideRight
                    text: box.modelData.role + " · " + box.modelData.name
                    color: Theme.text2
                    font.family: Theme.mono; font.pixelSize: 9
                }
            }
        }
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 100
        width: hud.implicitWidth + 28; height: 32; radius: 10
        color: Theme.surface1; border.color: Theme.hairline2; border.width: 1
        Row {
            id: hud; anchors.centerIn: parent; spacing: 14
            Text { text: "UI tree"; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold }
            Text { text: "<b>" + vo.list.length + "</b> elements"; textFormat: Text.StyledText; color: Theme.text2; font.family: Theme.mono; font.pixelSize: 11 }
            Text { text: "<b>" + vo.changes + "</b> changes"; textFormat: Text.StyledText; color: Theme.text2; font.family: Theme.mono; font.pixelSize: 11 }
            Text { text: "<b>0</b> screenshots"; textFormat: Text.StyledText; color: Theme.text2; font.family: Theme.mono; font.pixelSize: 11 }
        }
    }
}
