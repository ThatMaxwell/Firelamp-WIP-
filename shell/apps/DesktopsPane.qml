// Settings › Desktops. Firelamp runs on KDE Plasma; anything else is one click away and
// installed only when you ask. Installs go through firelamp-desktops (a local helper that
// runs pacman for a fixed list), and each one shows up as a session at login.
import QtQuick
import "../components"

Item {
    id: dp
    property bool active: false
    readonly property string api: "http://127.0.0.1:7341"
    // what the page shows; the helper is the authority on packages and installed state
    readonly property var catalog: [
        { group: "Desktops", items: [
            { id: "plasma", name: "KDE Plasma", what: "The default. Firelamp’s shell sits on top of it." },
            { id: "gnome", name: "GNOME", what: "Calm and focused, with Activities and a top bar." },
            { id: "cosmic", name: "COSMIC", what: "System76’s new desktop, written in Rust, with optional tiling." },
            { id: "xfce", name: "Xfce", what: "Light and classic. Good on older machines." } ] },
        { group: "Window managers", items: [
            { id: "hyprland", name: "Hyprland", what: "Dynamic tiling with smooth animations. A ricer favourite." },
            { id: "niri", name: "niri", what: "Scrollable tiling: windows sit on an endless strip." },
            { id: "sway", name: "Sway", what: "i3-style tiling for Wayland. Plain and fast." } ] }
    ]
    property var status: ({ plasma: { installed: true } })   // id -> { installed, state, log }
    property bool offline: false
    function fetch() {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return;
            if (x.status !== 200) { dp.offline = !Os.demoInstalls; return; }
            var st = {};
            JSON.parse(x.responseText).forEach(function (d) { st[d.id] = d; });
            dp.offline = false; dp.status = st;
        };
        x.open("GET", api + "/desktops"); x.send();
    }
    function install(id) {
        set(id, { state: "installing", log: "" });
        if (!helperSeen && Os.demoInstalls) { demo.id = id; demo.restart(); return; }
        var x = new XMLHttpRequest();
        x.open("POST", api + "/install/" + id); x.send();
    }
    property bool helperSeen: false
    function set(id, f) { var st = Object.assign({}, status); st[id] = Object.assign({}, st[id] || {}, f); status = st; }
    readonly property bool busy: { for (var k in status) if (status[k].state === "installing") return true; return false; }
    onActiveChanged: if (active) fetch()
    Timer { interval: 1500; repeat: true; running: dp.active && dp.busy && dp.helperSeen; onTriggered: dp.fetch() }
    // recorder / dev builds without the helper: a stand-in install so the flow can be seen
    Timer { id: demo; property string id; interval: 6000; onTriggered: dp.set(id, { state: "installed", installed: true }) }
    Component.onCompleted: {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () { if (x.readyState === XMLHttpRequest.DONE) dp.helperSeen = x.status === 200; };
        x.open("GET", api + "/desktops"); x.send();
    }

    Text { x: 24; y: 16; text: "Desktops"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
    Flickable {
        id: fl
        x: 24; y: 50; width: parent.width - 48; height: parent.height - y
        contentHeight: col.height + 24; clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col; width: fl.width; spacing: 14
            Text {
                width: parent.width; wrapMode: Text.WordWrap; bottomPadding: 6
                text: "Firelamp runs on KDE Plasma. Add another desktop or window manager, then pick it when you log in. Nothing is installed until you ask."
                color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
            }
            Text {
                visible: dp.offline; width: parent.width; wrapMode: Text.WordWrap
                text: "Installing needs the firelamp-desktops helper, which runs on Firelamp OS."
                color: Theme.text2; font.family: Theme.font; font.pixelSize: 12
            }
            Repeater {
                model: dp.catalog
                Column {
                    id: grp
                    required property var modelData
                    width: col.width; spacing: 8
                    Text { x: 4; text: grp.modelData.group; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }
                    Rectangle {
                        width: parent.width; height: rows.height; radius: 10
                        color: Qt.rgba(1, 1, 1, 0.04); border.color: Theme.line; border.width: 0.5
                        Column {
                            id: rows; width: parent.width
                            Repeater {
                                model: grp.modelData.items
                                Item {
                                    id: row
                                    required property var modelData
                                    required property int index
                                    readonly property var st: dp.status[modelData.id] || {}
                                    readonly property bool isDefault: modelData.id === "plasma"
                                    readonly property bool working: st.state === "installing"
                                    readonly property bool have: !!st.installed
                                    property string aiName: modelData.name
                                    property string aiRole: "listitem"
                                    width: rows.width; height: 58
                                    Rectangle { visible: row.index > 0; x: 16; width: parent.width - 32; height: 0.5; color: Theme.line }
                                    Column {
                                        x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 2; width: parent.width - 170
                                        Text { text: row.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { width: parent.width; elide: Text.ElideRight; text: row.working && row.st.log ? row.st.log : row.modelData.what; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                                    }
                                    Item {
                                        anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(btn.width, state2.width); height: 28
                                        FButton {
                                            id: btn
                                            visible: !row.have && !row.working
                                            anchors.right: parent.right
                                            text: row.st.state === "failed" ? "Try Again" : "Install"
                                            label: "Install " + row.modelData.name
                                            enabledState: !dp.offline
                                            onClicked: dp.install(row.modelData.id)
                                        }
                                        Row {
                                            id: state2
                                            visible: row.have || row.working
                                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                            Glyph { visible: row.have; name: "check"; width: 12; height: 12; color: Theme.ok; anchors.verticalCenter: parent.verticalCenter }
                                            Text {
                                                text: row.working ? "Installing…" : row.isDefault ? "In use" : "Installed"
                                                color: Theme.text3; font.family: Theme.font; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                    // installing: a quiet hairline that sweeps along the bottom of the row
                                    Item {
                                        visible: row.working
                                        x: 16; width: parent.width - 32; height: 1; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; clip: true
                                        Rectangle {
                                            width: parent.width * 0.3; height: 1; color: Theme.text3
                                            SequentialAnimation on x { running: row.working; loops: Animation.Infinite
                                                NumberAnimation { from: -width; to: parent.width; duration: 1400; easing.type: Easing.InOutSine } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap; topPadding: 4
                text: "Installed desktops appear in the session menu on the login screen. The assistant and fire cursor are built for the default Plasma session."
                color: Theme.text3; font.family: Theme.font; font.pixelSize: 11
            }
        }
    }
}
