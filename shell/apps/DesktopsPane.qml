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
            { id: "gnome", name: "GNOME", size: "410 MB", what: "Calm and focused, with Activities." },
            { id: "cosmic", name: "COSMIC", size: "190 MB", what: "System76’s Rust desktop, with tiling." },
            { id: "cinnamon", name: "Cinnamon", size: "260 MB", what: "Classic, with a bottom panel." },
            { id: "xfce", name: "Xfce", size: "120 MB", what: "Light and traditional. Runs anywhere." } ] },
        { group: "Window managers", items: [
            { id: "niri", name: "niri", size: "45 MB", what: "Scrollable tiling on an endless strip." },
            { id: "hyprland", name: "Hyprland", size: "70 MB", what: "Dynamic tiling, smooth animations." },
            { id: "sway", name: "Sway", size: "40 MB", what: "i3-style tiling. Plain and fast." } ] }
    ]
    property var status: ({ plasma: { installed: true } })   // id -> { installed, state, log }
    property bool offline: false
    function fetch() {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return;
            if (x.status !== 200) { dp.offline = !Os.demoInstalls; return; }
            var st = {};
            var r = JSON.parse(x.responseText); (r.desktops || r).forEach(function (d) { st[d.id] = d; });
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
    function scrollTo(y) { fl.contentY = Math.max(0, Math.min(y, fl.contentHeight - fl.height)); }
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
                    width: col.width; spacing: 12
                    Text { x: 2; text: grp.modelData.group; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 8 }
                    Grid {
                        columns: 2; columnSpacing: 20; rowSpacing: 22
                        Repeater {
                            model: grp.modelData.items
                            Item {
                                id: card
                                required property var modelData
                                readonly property var st: dp.status[modelData.id] || {}
                                readonly property bool isDefault: modelData.id === "plasma"
                                readonly property bool working: st.state === "installing"
                                readonly property bool have: !!st.installed
                                property string aiName: modelData.name
                                property string aiRole: "listitem"
                                width: (col.width - 20) / 2; height: thumb.height + 62
                                DeskThumb { id: thumb; kind: card.modelData.id; width: parent.width; height: Math.round(width * 10 / 16) }
                                // installing: a quiet hairline sweeps along the thumbnail's lower edge
                                Item {
                                    visible: card.working; clip: true
                                    x: 10; width: parent.width - 20; height: 1; y: thumb.height + 5
                                    Rectangle {
                                        width: parent.width * 0.3; height: 1; color: Theme.text3
                                        SequentialAnimation on x { running: card.working; loops: Animation.Infinite
                                            NumberAnimation { from: -width; to: parent.width; duration: 1400; easing.type: Easing.InOutSine } }
                                    }
                                }
                                Column {
                                    y: thumb.height + 12; x: 2; spacing: 3; width: parent.width - btnBox.width - 12
                                    Row {
                                        spacing: 6
                                        Text { text: card.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { visible: !!card.modelData.size && !card.have; text: "· " + (card.modelData.size || ""); color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                                    }
                                    Text {
                                        width: parent.width; elide: Text.ElideRight
                                        text: card.working ? (card.st.log || "Installing…")
                                            : card.isDefault ? "In use. Firelamp runs on it."
                                            : card.have ? "Installed · pick it on the login screen"
                                            : card.modelData.what
                                        color: card.have && !card.isDefault ? Theme.text2 : Theme.text3; font.family: Theme.font; font.pixelSize: 11
                                    }
                                }
                                Item {
                                    id: btnBox
                                    anchors.right: parent.right; y: thumb.height + 12
                                    width: Math.max(btn.visible ? btn.width : 0, mark.visible ? mark.width : 0); height: 28
                                    FButton {
                                        id: btn
                                        visible: !card.have && !card.working
                                        anchors.right: parent.right
                                        text: card.st.state === "failed" ? "Try Again" : "Install"
                                        label: "Install " + card.modelData.name
                                        enabledState: !dp.offline && !dp.busy
                                        onClicked: dp.install(card.modelData.id)
                                    }
                                    Glyph { id: mark; visible: card.have; anchors.right: parent.right; y: 3; name: "check"; width: 13; height: 13; color: Theme.text2 }
                                }
                            }
                        }
                    }
                }
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap; topPadding: 6
                text: "Firelamp’s assistant, fire cursor, dock and home screen run on Plasma. Other desktops come the way their makers ship them, without Firelamp’s shell. To use the assistant, pick Plasma on the login screen."
                color: Theme.text3; font.family: Theme.font; font.pixelSize: 11
            }
        }
    }
}
