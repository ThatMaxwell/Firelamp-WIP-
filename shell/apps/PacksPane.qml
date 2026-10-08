// Settings › Packs: the same five packs as first boot, as a list. Each one installs or
// removes with one click through firelamp-desktops, and opens to show its packages.
import QtQuick
import "../components"
import "../js/packs.js" as Packs

Item {
    id: pp
    property bool active: false
    readonly property var status: Os.packStatus
    readonly property bool helperSeen: Os.packHelper
    property string open: ""
    function fetch() {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return;
            Os.packHelper = x.status === 200;
            if (x.status !== 200) return;
            var st = {};
            JSON.parse(x.responseText).forEach(function (d) { st[d.id] = d; });
            Os.packStatus = st;
        };
        x.open("GET", Packs.API + "/packs"); x.send();
    }
    function act(id, remove) { Os.installPack(id, remove); }
    readonly property bool busy: { for (var k in status) if (status[k].state === "installing") return true; return false; }
    onActiveChanged: if (active) fetch()
    Timer { interval: 1500; repeat: true; running: pp.active && pp.busy && pp.helperSeen; onTriggered: pp.fetch() }

    Text { x: 24; y: 16; text: "Packs"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
    Flickable {
        x: 24; y: 50; width: parent.width - 48; height: parent.height - y
        contentHeight: col.height + 24; clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col; width: parent.width; spacing: 14
            Text {
                width: parent.width; wrapMode: Text.WordWrap
                text: "Optional software, grouped by what you do. " + Packs.BASICS
                color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
            }
            Rectangle {
                width: parent.width; height: rows.height; radius: 10
                color: Qt.rgba(1, 1, 1, 0.04); border.color: Theme.line; border.width: 0.5
                Column {
                    id: rows; width: parent.width
                    Repeater {
                        model: Packs.PACKS
                        Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property var st: pp.status[modelData.id] || (modelData.preinstalled ? { installed: true } : {})
                            readonly property bool working: st.state === "installing"
                            readonly property bool have: !!st.installed
                            readonly property bool expanded: pp.open === modelData.id
                            property string aiName: modelData.name + " pack"; property string aiRole: "listitem"
                            width: rows.width; height: 62 + (expanded ? pkgs.height + 14 : 0)
                            clip: true
                            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Rectangle { visible: row.index > 0; x: 16; width: parent.width - 32; height: 0.5; color: Theme.line }
                            MouseArea { width: parent.width; height: 62; onClicked: pp.open = row.expanded ? "" : row.modelData.id }
                            Rectangle {
                                x: 16; y: 15; width: 32; height: 32; radius: 8; color: Theme.surface3
                                Glyph { anchors.centerIn: parent; name: row.modelData.glyph; width: 16; height: 16; color: Theme.text2 }
                            }
                            Column {
                                x: 60; y: 14; spacing: 2; width: parent.width - 260
                                Row { spacing: 6
                                    Text { text: row.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                                    Text { text: "›"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 13; rotation: row.expanded ? 90 : 0
                                           Behavior on rotation { NumberAnimation { duration: 180 } } } }
                                Text { width: parent.width; elide: Text.ElideRight; text: row.working && row.st.log ? row.st.log : row.modelData.what; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                            }
                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 14; y: 17; spacing: 14
                                Text { anchors.verticalCenter: parent.verticalCenter; text: row.working ? (row.st.removing ? "Removing…" : "Installing…") : row.have ? "Installed" : row.modelData.size
                                       color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                                FButton {
                                    visible: !row.working
                                    text: row.have ? "Remove" : "Install"
                                    label: (row.have ? "Remove " : "Install ") + row.modelData.name + " pack"
                                    enabledState: pp.helperSeen || Os.demoInstalls
                                    onClicked: pp.act(row.modelData.id, row.have)
                                }
                            }
                            // installing: the same quiet hairline as Desktops
                            Item {
                                visible: row.working; clip: true
                                x: 16; width: parent.width - 32; height: 1; y: 60
                                Rectangle { width: parent.width * 0.3; height: 1; color: Theme.text3
                                    SequentialAnimation on x { running: row.working; loops: Animation.Infinite
                                        NumberAnimation { from: -width; to: parent.width; duration: 1400; easing.type: Easing.InOutSine } } }
                            }
                            Flow {
                                id: pkgs
                                x: 60; y: 62; width: parent.width - 76; spacing: 6
                                Repeater {
                                    model: row.modelData.packages
                                    Rectangle {
                                        required property string modelData
                                        width: pt.implicitWidth + 14; height: 20; radius: 5; color: Theme.surface0; border.color: Theme.hairline; border.width: 1
                                        Text { id: pt; anchors.centerIn: parent; text: parent.modelData; color: Theme.text2; font.family: Theme.mono; font.pixelSize: 10 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Text {
                visible: !pp.helperSeen && !Os.demoInstalls; width: parent.width; wrapMode: Text.WordWrap
                text: "Installing needs the firelamp-desktops helper, which runs on Firelamp OS."
                color: Theme.text2; font.family: Theme.font; font.pixelSize: 12
            }
        }
    }
    Component.onCompleted: fetch()
}
