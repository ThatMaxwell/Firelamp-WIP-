// The dock. Mac-style magnification: a smoothed pointer drives a cosine falloff over about
// three icons each side, every frame, so neighbours swell together and push apart.
// The slab grows with the icons; one label names the icon under the pointer.
import QtQuick
import QtQuick.Effects
import "../js/art.js" as Art

Item {
    id: dock
    property var items: []            // [{id, icon, title}] or "-" for the separator
    property real base: [44, 54, 64][Os.settings.dockSize] || 54
    property real maxScale: [1, 1.25, 1.6][Os.settings.dockMag] || 1
    property real reach: 3                // icons each side the falloff spans
    property real mouseX: -1              // raw pointer, in the un-magnified layout
    property real mx: -1                  // smoothed pointer
    property real amount: 0               // 0 = resting, 1 = fully magnified
    property real pointerX: -1         // pointer x over the plate, for the label bubble
    property var running: ({})
    property var bouncing: ({})
    property string aiActiveId: ""
    property string trashIcon: Art.icon("trash")
    property string aiApp: "dock"
    // left and right docks are the same dock turned on its side (and, on the right, mirrored so
    // the first app is still at the top); icons and the label turn back upright
    readonly property real turn: Os.settings.dockSide === "bottom" ? 0 : 90
    readonly property bool mirrored: Os.settings.dockSide === "right"
    component Upright: Item {
        transform: [ Scale { origin.x: width / 2; origin.y: height / 2; xScale: dock.mirrored ? -1 : 1 },
                     Rotation { origin.x: width / 2; origin.y: height / 2; angle: -dock.turn } ]
    }
    signal launch(string id)

    // one per-frame step: ease the pointer and the amount toward their targets (critically damped)
    FrameAnimation {
        running: dock.mouseX >= 0 || dock.amount > 0.001
        onTriggered: {
            var k = 1 - Math.exp(-frameTime * 22);
            if (dock.mouseX >= 0) dock.mx = dock.mx < 0 ? dock.mouseX : dock.mx + (dock.mouseX - dock.mx) * k;
            var want = dock.mouseX >= 0 ? 1 : 0;
            dock.amount += (want - dock.amount) * (1 - Math.exp(-frameTime * 14));
            if (want === 0 && dock.amount < 0.002) { dock.amount = 0; dock.mx = -1; }
        }
    }
    readonly property real tallest: base * (1 + (maxScale - 1) * amount)

    width: plate.width
    height: base + 14

    function iconRect(id) {
        for (var i = 0; i < rep.count; i++) {
            var it = rep.itemAt(i);
            if (it && it.appId === id) {
                var a = it.mapToItem(Os.root, 0, it.height - it.size), b = it.mapToItem(Os.root, it.size, it.height);
                return Qt.rect(Math.min(a.x, b.x), Math.min(a.y, b.y), it.size, it.size);
            }
        }
        return null;
    }
    function setRunning(id, on) { var r = Object.assign({}, running); r[id] = on; running = r; }
    function bounce(id) {
        for (var i = 0; i < rep.count; i++) { var it = rep.itemAt(i); if (it && it.appId === id) it.bounce(); }
    }

    // centre of each item in the un-magnified layout, so the falloff never feeds back
    function baseCenter(index) {
        var x = 6;
        for (var i = 0; i < index; i++) x += items[i] === "-" ? 15 : base + 4;
        return x + 2 + base / 2;
    }

    // the backing can be switched off for floating icons; it is never glass
    RectangularShadow { anchors.fill: plate; radius: plate.radius; blur: 22; offset.y: 8; color: Qt.rgba(0, 0, 0, 0.35); opacity: plate.opacity }
    Rectangle {
        id: plate
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        // the slab rises a little with the icons, so they never float off it
        height: dock.base + 14 + (dock.tallest - dock.base) * 0.35
        width: row.width + 12
        radius: 22
        color: Theme.dock
        opacity: Os.settings.dockBacking ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        border.color: Theme.hairline; border.width: 1
        Rectangle { x: 20; width: parent.width - 40; height: 1; y: 1; color: Qt.rgba(1, 1, 1, 0.06) }
    }

    // tracks the pointer over the whole dock; it takes no buttons, so clicks reach the icons
    MouseArea {
        anchors.fill: plate
        anchors.topMargin: -40
        z: 5
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: (m) => { dock.pointerX = m.x; dock.mouseX = m.x - (plate.width - dock.baseWidth()) / 2; }
        onExited: { dock.mouseX = -1; dock.pointerX = -1; }
    }
    function baseWidth() { var w = 12; for (var i = 0; i < items.length; i++) w += items[i] === "-" ? 15 : base + 4; return w; }

    Row {
        id: row
        anchors.bottom: plate.bottom
        anchors.bottomMargin: 7
        anchors.horizontalCenter: plate.horizontalCenter
        Repeater {
            id: rep
            model: dock.items
            delegate: Item {
                id: di
                required property var modelData
                required property int index
                readonly property bool sep: modelData === "-"
                readonly property string appId: sep ? "" : modelData.id
                readonly property real size: {
                    if (sep || dock.mx < 0 || dock.amount <= 0) return dock.base;
                    var d = Math.abs(dock.mx - dock.baseCenter(index)) / ((dock.base + 4) * dock.reach);
                    return d >= 1 ? dock.base : dock.base * (1 + (dock.maxScale - 1) * dock.amount * (Math.cos(d * Math.PI) + 1) / 2);
                }
                property string aiName: sep ? "" : modelData.title
                property string aiRole: "button"
                function aiActivate() { dock.launch(appId); }
                function bounce() { bounceAnim.restart(); }
                Accessible.role: Accessible.Button
                Accessible.name: aiName
                width: sep ? 15 : size + 4
                height: dock.base

                Rectangle { visible: di.sep; width: 1; height: dock.base * 0.82; anchors.centerIn: parent; color: Theme.hairline2 }

                Item {
                    id: iconBox
                    visible: !di.sep
                    width: di.size; height: di.size
                    x: 2; anchors.bottom: parent.bottom
                    property real lift: 0
                    transform: Translate { y: -iconBox.lift }
                    Upright {
                        anchors.fill: parent
                        Image {
                            id: img
                            anchors.fill: parent
                            source: di.sep ? "" : di.appId === "trash" ? dock.trashIcon : Art.icon(di.modelData.icon)
                            sourceSize: Qt.size(176, 176)
                            smooth: true; mipmap: true
                            visible: false
                        }
                        MultiEffect {
                            anchors.fill: img; source: img
                            shadowEnabled: true; shadowBlur: 0.5; shadowVerticalOffset: 3; shadowOpacity: 0.45
                            brightness: ima.pressed ? -0.3 : 0
                        }
                    }
                    SequentialAnimation {
                        id: bounceAnim
                        loops: 2
                        NumberAnimation { target: iconBox; property: "lift"; to: dock.base * 0.34; duration: 280; easing.type: Easing.OutQuad }
                        NumberAnimation { target: iconBox; property: "lift"; to: 0; duration: 340; easing.type: Easing.OutBounce }
                    }
                }
                // running indicator
                Rectangle {
                    visible: !di.sep
                    width: 4; height: 4; radius: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom; anchors.topMargin: 1.5
                    color: dock.aiActiveId === di.appId ? Theme.ember : Theme.text2
                    opacity: dock.running[di.appId] ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }
                MouseArea {
                    id: ima
                    enabled: !di.sep
                    x: 0; width: parent.width
                    y: parent.height - di.size; height: di.size
                    onClicked: dock.launch(di.appId)
                }
            }
        }
    }

    // the one label: the icon under the pointer, as a small pill
    // the label follows the same smoothed pointer as the magnification, so it names the icon that is largest
    readonly property var hovered: {
        if (pointerX < 0 || mx < 0) return null;
        var best = null, bd = 1e9;
        for (var i = 0; i < rep.count; i++) {
            var it = rep.itemAt(i);
            if (!it || it.sep) continue;
            var d = Math.abs(mx - baseCenter(i));
            if (d < bd) { bd = d; best = it; }
        }
        return bd < (base + 4) / 2 + 2 ? best : null;
    }
    Rectangle {
        id: tip
        property var at: dock.hovered
        opacity: at ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuint } }
        onAtChanged: if (at) tipText.text = at.aiName
        Binding on x { when: tip.at !== null; value: tip.at ? row.x + tip.at.x + tip.at.width / 2 - tip.width / 2 : 0 }
        y: plate.y + plate.height - 7 - dock.tallest - height - 8 - (dock.turn ? (width - height) / 2 : 0)
        transform: [ Scale { origin.x: tip.width / 2; origin.y: tip.height / 2; xScale: dock.mirrored ? -1 : 1 },
                     Rotation { origin.x: tip.width / 2; origin.y: tip.height / 2; angle: -dock.turn } ]
        width: tipText.implicitWidth + 18; height: 22; radius: 11
        color: Theme.surface1
        border.color: Theme.hairline2; border.width: 1
        Text { id: tipText; anchors.centerIn: parent; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
    }
}
