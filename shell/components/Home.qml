// The home screen: widgets on the desktop, under every window. In Edit home the wallpaper
// dims 12%, a hairline 8px grid fades in, and widgets lift with an ✕ and a resize corner.
// Drags snap to the grid with a 120ms settle. No wobble, no jiggle.
import QtQuick
import QtQuick.Effects

Item {
    id: home
    property real edit: Os.editingHome ? 1 : 0
    Behavior on edit { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    readonly property int snap: 8
    function px(w) { return w.x < 0 ? width + w.x : w.x; }

    // a free spot for a new widget: scan the grid top-left first, avoiding the others
    function freeSpot(size) {
        var s = Os.widgetSizes[size], gap = 24;
        for (var y = 64; y + s[1] < height - 120; y += 8)
            for (var x = 72; x + s[0] < width - 72; x += 8) {
                var hit = false;
                for (var i = 0; i < Os.widgets.length && !hit; i++) {
                    var o = Os.widgets[i], os = Os.widgetSizes[o.size], ox = px(o);
                    hit = x < ox + os[0] + gap && ox < x + s[0] + gap && y < o.y + os[1] + gap && o.y < y + s[1] + gap;
                }
                if (!hit) return Qt.point(x, y);
            }
        return Qt.point(72, 64);
    }

    Rectangle { anchors.fill: parent; anchors.topMargin: -Theme.menubarH; color: "black"; opacity: 0.12 * home.edit }
    Canvas {
        id: grid
        anchors.fill: parent
        opacity: home.edit * 0.6; visible: opacity > 0
        onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
        Connections { target: Os.settings; function onLookChanged() { grid.requestPaint(); } }
        onPaint: {
            var c = getContext("2d");
            c.reset();
            c.fillStyle = Theme.hairline;
            for (var x = 0; x < width; x += home.snap) c.fillRect(x, 0, 1, height);
            for (var y = 0; y < height; y += home.snap) c.fillRect(0, y, width, 1);
        }
    }

    Repeater {
        model: Os.widgets
        Item {
            id: host
            required property var modelData
            property string size: modelData.size
            property bool dragging: mover.drag.active || resizing
            property bool resizing: false
            property bool leaving: false
            property string aiName: modelData.kind + " widget"; property string aiRole: "widget"
            x: home.px(modelData); y: modelData.y
            width: hw.width; height: hw.height
            z: dragging ? 5 : 1
            Behavior on x { enabled: !host.dragging; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !host.dragging; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            // arrival from the gallery, and leaving when ✕ is pressed
            property real k: modelData.fresh ? 0 : 1
            Component.onCompleted: if (modelData.fresh) arrive.start()
            NumberAnimation { id: arrive; target: host; property: "k"; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            opacity: leaving ? 0 : Math.min(1, k * 1.5)
            scale: leaving ? 0.92 : 0.9 + 0.1 * k
            Behavior on opacity { enabled: host.leaving; NumberAnimation { duration: 160 } }
            Behavior on scale { enabled: host.leaving; NumberAnimation { duration: 160; easing.type: Easing.InQuad } }
            Timer { id: gone; interval: 170; onTriggered: Os.removeWidget(host.modelData.uid) }

            // in edit mode the widget lifts 2px onto a soft shadow
            transform: Translate { y: -2 * home.edit - (host.dragging ? 2 : 0) }
            RectangularShadow {
                anchors.fill: hw; radius: 18; blur: host.dragging ? 34 : 22; offset.y: host.dragging ? 12 : 8
                color: Qt.rgba(0, 0, 0, 0.45); opacity: home.edit
            }
            HomeWidget { id: hw; kind: host.modelData.kind; size: host.size }

            MouseArea {
                id: mover
                anchors.fill: parent
                enabled: Os.editingHome
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: host
                drag.threshold: 2
                drag.minimumX: 0; drag.maximumX: home.width - host.width
                drag.minimumY: 0; drag.maximumY: home.height - host.height
                onReleased: {
                    var nx = Math.round(host.x / home.snap) * home.snap, ny = Math.round(host.y / home.snap) * home.snap;
                    host.x = nx; host.y = ny;
                    settle.start();
                }
            }
            Timer { id: settle; interval: 130; onTriggered: Os.updateWidget(host.modelData.uid, { x: host.x, y: host.y, fresh: false }) }

            // ✕: remove
            Rectangle {
                property string aiName: "Remove " + host.modelData.kind + " widget"; property string aiRole: "button"
                function aiActivate() { host.leaving = true; gone.start(); }
                x: -7; y: -7; width: 20; height: 20; radius: 10
                color: Theme.light ? Theme.surface2 : Theme.surface3; border.color: Theme.hairline2; border.width: 1
                opacity: home.edit; visible: opacity > 0
                scale: 0.6 + 0.4 * home.edit
                Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -1; text: "×"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; anchors.margins: -4; enabled: Os.editingHome; onClicked: parent.aiActivate() }
            }
            // resize corner: drag it, and the widget steps between S, M and L
            Item {
                property string aiName: "Resize " + host.modelData.kind + " widget"; property string aiRole: "handle"
                anchors.right: parent.right; anchors.bottom: parent.bottom; width: 22; height: 22
                opacity: home.edit; visible: opacity > 0
                Rectangle { x: 9; y: 15; width: 8; height: 1.5; radius: 1; color: Theme.text3 }
                Rectangle { x: 15.5; y: 9; width: 1.5; height: 8; radius: 1; color: Theme.text3 }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -4
                    enabled: Os.editingHome; cursorShape: Qt.SizeFDiagCursor
                    onPressed: host.resizing = true
                    onPositionChanged: (m) => {
                        var p = mapToItem(host, m.x, m.y);
                        host.size = p.x < 240 ? "S" : p.y < 240 ? "M" : "L";
                    }
                    onReleased: { host.resizing = false; Os.updateWidget(host.modelData.uid, { size: host.size, x: host.x, fresh: false }); }
                }
            }
        }
    }
}
