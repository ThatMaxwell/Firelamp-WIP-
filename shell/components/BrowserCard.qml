// First boot, after Packs: "Pick your browser". Firefox comes with Firelamp and starts picked;
// anything else installs in the background and becomes the default once it's in.
import QtQuick
import "../js/browsers.js" as B

Item {
    id: bc
    objectName: "browserCard"
    property bool shown: false
    property bool aiHidden: !shown
    readonly property var pick: B.byId(picker.selected)
    signal done()
    anchors.fill: parent
    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
    onShownChanged: if (shown) { picker.selected = Os.defaultBrowser; picker.showAll = false; Os.fetchBrowsers(); }

    function finish(useIt) {
        var id = useIt ? picker.selected : "firefox";
        if (id !== Os.defaultBrowser) {
            Os.pickBrowser(id);
            var b = B.byId(id), st = Os.browserStatus[id] || {};
            if (!b.included && !st.installed)
                Os.toast("downloads", "Installing " + b.name, "It becomes your default when it's done.");
        }
        Os.settings.browserAsked = true;
        shown = false;
        done();
    }

    Wallpaper { anchors.fill: parent }
    MouseArea { anchors.fill: parent }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.47 - implicitHeight / 2)
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Pick your browser"
            color: Theme.text; font.family: Theme.font; font.pixelSize: 30; font.weight: Font.DemiBold
        }
        Item { width: 1; height: 10 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Firefox comes with Firelamp. Pick any other and it installs and becomes your default."
            color: Theme.text2; font.family: Theme.font; font.pixelSize: 15
        }
        Item { width: 1; height: 36 }
        BrowserPicker {
            id: picker
            objectName: "browserPicker"
            curated: ["firefox", "chrome", "brave", "zen", "vivaldi", "edge", "librewolf", "opera"]
            width: Math.min(bc.width - 160, 1080)
            height: showAll ? Math.min(bc.height - 360, 6 * 74 + 46) : gridHeight
            Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        }
        Item { width: 1; height: 14 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            property string aiName: picker.showAll ? "Show fewer" : "Show all browsers"; property string aiRole: "button"
            function aiActivate() { picker.showAll = !picker.showAll; }
            text: picker.showAll ? "Show fewer" : "Show all " + B.BROWSERS.length
            color: Theme.text2; font.family: Theme.font; font.pixelSize: 13
            MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: parent.aiActivate() }
        }
        Item { width: 1; height: 24 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22
            Text {
                visible: picker.selected !== "firefox"
                property string aiName: "Keep Firefox"; property string aiRole: "button"
                function aiActivate() { bc.finish(false); }
                anchors.verticalCenter: parent.verticalCenter
                text: "Keep Firefox"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13
                MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: parent.aiActivate() }
            }
            FButton {
                text: bc.pick ? "Use " + bc.pick.name : "Continue"
                label: "Use browser"; primary: true; width: Math.max(150, implicitWidth); height: 34
                onClicked: bc.finish(true)
            }
        }
    }
}
