// The dock. Mac-style magnification: icons swell with a cosine falloff around the
// pointer and push their neighbours apart. Dark grey backing, running dots, bounce.
import QtQuick
import QtQuick.Effects
import "../js/art.js" as Art

Item {
    id: dock
    property var items: []            // [{id, icon, title}] or "-" for the separator
    property real base: 54
    property real maxScale: 1.62
    property real reach: 2.9
    property real mouseX: -1
    property real pointerX: -1         // pointer x over the plate, for the label bubble
    property var running: ({})
    property var bouncing: ({})
    property string aiActiveId: ""
    property string trashIcon: Art.icon("trash")
    property string aiApp: "dock"
    signal launch(string id)

    width: plate.width
    height: base + 14

    function iconRect(id) {
        for (var i = 0; i < rep.count; i++) {
            var it = rep.itemAt(i);
            if (it && it.appId === id) { var p = it.mapToItem(Os.root, 0, it.height - it.size); return Qt.rect(p.x, p.y, it.size, it.size); }
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

    RectangularShadow { anchors.fill: plate; radius: 22; blur: 40; offset.y: 12; spread: -6; color: Qt.rgba(0, 0, 0, 0.55) }
    Rectangle {
        id: plate
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: dock.base + 14
        width: row.width + 12
        radius: 22
        color: Theme.dock
        border.color: Qt.rgba(1, 1, 1, 0.11); border.width: 0.5
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
                readonly property real target: {
                    if (sep || dock.mouseX < 0) return dock.base;
                    var d = Math.abs(dock.mouseX - dock.baseCenter(index)) / (dock.base * dock.reach);
                    return d >= 1 ? dock.base : dock.base * (1 + (dock.maxScale - 1) * (Math.cos(d * Math.PI) + 1) / 2);
                }
                property real size: target
                Behavior on size { SmoothedAnimation { velocity: 900; duration: 110 } }
                property string aiName: sep ? "" : modelData.title
                property string aiRole: "button"
                function aiActivate() { dock.launch(appId); }
                function bounce() { bounceAnim.restart(); }
                Accessible.role: Accessible.Button
                Accessible.name: aiName
                width: sep ? 15 : size + 4
                height: dock.base

                Rectangle { visible: di.sep; width: 1; height: dock.base * 0.82; anchors.centerIn: parent; color: Qt.rgba(1, 1, 1, 0.17) }

                Item {
                    id: iconBox
                    visible: !di.sep
                    width: di.size; height: di.size
                    x: 2; anchors.bottom: parent.bottom
                    property real lift: 0
                    transform: Translate { y: -iconBox.lift }
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
                    color: dock.aiActiveId === di.appId ? Theme.orange : Qt.rgba(1, 1, 1, 0.78)
                    opacity: dock.running[di.appId] ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }
                // label bubble
                Rectangle {
                    id: tip
                    visible: !di.sep
                    opacity: dock.pointerX >= 0 && plate.x + dock.pointerX >= row.x + di.x && plate.x + dock.pointerX < row.x + di.x + di.width ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - di.size - 14 - height
                    width: tipText.implicitWidth + 20; height: 26; radius: 7
                    color: Qt.rgba(0.15, 0.15, 0.145, 0.94)
                    border.color: Qt.rgba(1, 1, 1, 0.14); border.width: 0.5
                    Text { id: tipText; anchors.centerIn: parent; text: di.aiName; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                }
                MouseArea {
                    id: ima
                    enabled: !di.sep
                    x: 0; width: parent.width
                    y: parent.height - di.size; height: di.size
                    hoverEnabled: true
                    onClicked: dock.launch(di.appId)
                }
            }
        }
    }
}
