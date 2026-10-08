// Settings › Browser: the same picker as first boot. Picking a tile only selects it; "Use"
// installs it if needed and makes it the default, so a stray click never downloads anything.
import QtQuick
import "../components"
import "../js/browsers.js" as B

Item {
    id: bw
    property bool active: false
    readonly property var cur: B.byId(Os.defaultBrowser)
    readonly property var pick: B.byId(picker.selected)
    readonly property bool working: { var st = Os.browserStatus[picker.selected]; return !!st && st.state === "installing"; }
    // select what's in flight, else the default
    function sync() {
        for (var k in Os.browserStatus) if (Os.browserStatus[k].state === "installing") return picker.selected = k;
        picker.selected = Os.defaultBrowser;
    }
    onActiveChanged: if (active) { Os.fetchBrowsers(); sync(); }
    Connections { target: Os; function onDefaultBrowserChanged() { bw.sync(); } }
    function scrollTo(y) { picker.scrollTo(y); }

    Text { x: 24; y: 16; text: "Browser"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
    Text {
        x: 24; y: 44; width: parent.width - 220; elide: Text.ElideRight
        text: "Links open in " + (bw.cur ? bw.cur.name : Os.defaultBrowser) + ". Browsers from Flathub install for you only."
        color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
    }
    FButton {
        anchors.right: parent.right; anchors.rightMargin: 24; y: 38
        visible: bw.pick && picker.selected !== Os.defaultBrowser
        enabledState: !bw.working
        text: bw.working ? "Installing…" : bw.pick ? "Use " + bw.pick.name : ""
        label: "Use browser"; primary: true
        onClicked: Os.pickBrowser(picker.selected)
    }
    BrowserPicker {
        id: picker
        objectName: "browserPicker"
        x: 24; y: 80; width: parent.width - 48; height: parent.height - y - 12
        minTile: 220
    }
    Component.onCompleted: { Os.fetchBrowsers(); sync(); }
}
