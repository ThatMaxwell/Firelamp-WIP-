// First boot, after naming: "What do you do?" Five packs as toggle cards, nothing picked.
// Skip is always fine; picked packs install in the background once the desktop is up.
import QtQuick
import "../js/packs.js" as Packs

Item {
    id: pc
    objectName: "packsCard"
    property bool shown: false
    property bool aiHidden: !shown
    property var picked: ({})
    readonly property var included: Packs.PACKS.filter(function (p) { var st = Os.packStatus[p.id]; return st ? !!st.installed : !!p.preinstalled; }).map(function (p) { return p.name; })
    readonly property int count: { var n = 0; for (var k in picked) if (picked[k]) n++; return n; }
    signal done()
    anchors.fill: parent
    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

    function toggle(id) { var p = Object.assign({}, picked); p[id] = !p[id]; picked = p; }
    function finish(install) {
        if (install) {
            var names = [];
            Packs.PACKS.forEach(function (p) {
                if (!pc.picked[p.id]) return;
                names.push(p.name);
                Os.installPack(p.id, false);
            });
            if (names.length) Os.toast("downloads", "Installing " + names.join(", "), "In the background. Settings › Packs shows progress.");
        }
        Os.settings.packsAsked = true;
        shown = false;
        done();
    }

    Wallpaper { anchors.fill: parent }
    MouseArea { anchors.fill: parent }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.45 - implicitHeight / 2)
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "What do you do?"
            color: Theme.text; font.family: Theme.font; font.pixelSize: 30; font.weight: Font.DemiBold
        }
        Item { width: 1; height: 10 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pc.included.length ? pc.included.join(" and ") + " come with Firelamp. Add any of the rest, or none." : "Pick any, or none. You can change this later in Settings › Packs."
            color: Theme.text2; font.family: Theme.font; font.pixelSize: 15
        }
        Item { width: 1; height: 44 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            Repeater {
                model: Packs.PACKS
                Rectangle {
                    id: card
                    required property var modelData
                    // already on the system: shown, never asked about
                    readonly property bool included: { var st = Os.packStatus[modelData.id]; return st ? !!st.installed : !!modelData.preinstalled; }
                    readonly property bool on: !!pc.picked[modelData.id]
                    property string aiName: modelData.name; property string aiRole: included ? "listitem" : "checkbox"
                    function aiActivate() { if (!included) pc.toggle(modelData.id); }
                    width: 168; height: 196; radius: 14
                    color: on ? Theme.surface2 : included ? "transparent" : Qt.rgba(1, 1, 1, 0.03)
                    border.color: on ? Theme.text : Theme.hairline2; border.width: on ? 1.5 : 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    scale: ma.pressed ? 0.98 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    MouseArea { id: ma; anchors.fill: parent; enabled: !card.included; onClicked: card.aiActivate() }
                    Rectangle {
                        x: 18; y: 18; width: 36; height: 36; radius: 9; color: Theme.surface3
                        Glyph { anchors.centerIn: parent; name: card.modelData.glyph; width: 18; height: 18; color: card.on ? Theme.text : Theme.text2 }
                    }
                    // picked: a cream check in the corner
                    Text {
                        visible: card.included
                        anchors.right: parent.right; anchors.rightMargin: 16; y: 16
                        text: "Included"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium
                    }
                    Rectangle {
                        visible: !card.included
                        anchors.right: parent.right; anchors.rightMargin: 14; y: 14
                        width: 20; height: 20; radius: 10
                        color: card.on ? Theme.text : "transparent"; border.color: card.on ? Theme.text : Theme.text4; border.width: 1
                        Glyph { anchors.centerIn: parent; name: "check"; width: 11; height: 11; color: Theme.bg; visible: card.on }
                    }
                    Column {
                        x: 18; y: 74; width: parent.width - 36; spacing: 6
                        Text { text: card.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold }
                        Text { width: parent.width; wrapMode: Text.WordWrap; text: card.modelData.what; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12; lineHeight: 1.15 }
                    }
                    Text {
                        x: 18; anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                        text: card.modelData.packages.slice(0, 3).join(", ") + "…"
                        width: parent.width - 36; elide: Text.ElideRight
                        color: Theme.text3; font.family: Theme.mono; font.pixelSize: 9
                    }
                }
            }
        }
        Item { width: 1; height: 16 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Packs.BASICS
            color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
        }
        Item { width: 1; height: 36 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22
            Text {
                property string aiName: "Skip"; property string aiRole: "button"
                function aiActivate() { pc.finish(false); }
                anchors.verticalCenter: parent.verticalCenter
                text: "Skip"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13
                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: parent.aiActivate() }
            }
            FButton {
                text: pc.count ? "Install " + pc.count + (pc.count === 1 ? " pack" : " packs") : "Continue"
                label: "Continue"; primary: true; implicitWidth: 150; implicitHeight: 34
                onClicked: pc.finish(pc.count > 0)
            }
        }
    }
}
