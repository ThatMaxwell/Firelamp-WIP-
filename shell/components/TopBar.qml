// The menu bar: Firelamp menu, the focused app's menus, and status items on the right.
import QtQuick

Rectangle {
    id: bar
    property string appName: "Desktop"
    property var openFor: null
    property Item menuLayer
    property string aiApp: "menubar"
    height: Theme.menubarH
    color: Qt.rgba(0.063, 0.047, 0.04, 0.55)
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 0.5; color: Qt.rgba(1, 0.93, 0.87, 0.06) }

    property var menu: null
    function closeMenu() { if (menu) menu.destroy(); menu = null; openFor = null; }
    function openMenu(btn, items, right) {
        closeMenu();
        var p = btn.mapToItem(menuLayer, 0, btn.height + 4);
        menu = menuComp.createObject(menuLayer, { items: items });
        menu.x = right ? Math.min(menuLayer.width - menu.width - 4, p.x + btn.width - menu.width) : Math.max(4, p.x);
        menu.y = p.y;
        menu.picked.connect(closeMenu);
        openFor = btn;
    }
    Component { id: menuComp; MenuPopup {} }

    readonly property var appMenus: ({
        "File": [{ label: "New Window", sc: "⌘N" }, { label: "Open…", sc: "⌘O" }, "-", { label: "Close Window", sc: "⌘W", action: function () { Os.desktop.closeFocused(); } }],
        "Edit": [{ label: "Undo", sc: "⌘Z" }, { label: "Redo", sc: "⇧⌘Z" }, "-", { label: "Cut", sc: "⌘X" }, { label: "Copy", sc: "⌘C" }, { label: "Paste", sc: "⌘V" }, { label: "Select All", sc: "⌘A" }],
        "View": [{ label: "Show what the AI sees", sc: "⌥⌘V", action: function () { Os.vision = !Os.vision; } }, { label: "Show Activity Timeline", sc: "⌥⌘T", action: function () { Os.timelineToggle(undefined); } }, "-", { label: "Enter Full Screen", sc: "⌃⌘F" }],
        "Window": [{ label: "Minimize", sc: "⌘M", action: function () { Os.desktop.minimizeFocused(); } }, { label: "Zoom", action: function () { Os.desktop.zoomFocused(); } }, "-", { label: "Bring All to Front" }],
        "Help": [{ label: "Firelamp Help" }, { label: "Keyboard Shortcuts" }]
    })
    function itemsFor(key) {
        if (key === "logo") return [
            { label: "About Firelamp OS", action: function () { Os.desktop.open("about"); } }, "-",
            { label: "System Settings…", action: function () { Os.desktop.open("settings"); } },
            { label: "Activity Timeline", sc: "⌥⌘T", action: function () { Os.timelineToggle(undefined); } }, "-",
            { label: "Sleep" }, { label: "Restart…" }, { label: "Shut Down…" }, "-", { label: "Lock Screen", sc: "⌃⌘Q" }];
        if (key === "app") return [{ label: "About " + appName }, "-", { label: "Settings…", sc: "⌘,", action: function () { Os.desktop.open("settings"); } }, "-", { label: "Hide " + appName, sc: "⌘H" }, { label: "Quit " + appName, sc: "⌘Q", action: function () { Os.desktop.closeFocused(); } }];
        if (key === "control") return [{ label: "Focus", sc: "Off" }, { label: "Screen Mirroring" }, "-", { label: "Pause " + Os.name, sc: "⌃Space", action: function () { Os.agent.togglePause(); } }, { label: "Stop " + Os.name, sc: "Esc", action: function () { Os.agent.stop(); } }];
        if (key === "wifi") return [{ label: "Wi-Fi", sc: "On" }, "-", { label: "Hearth", sc: "●" }, { label: "Kitchen 5G" }, "-", { label: "Network Settings…" }];
        if (key === "battery") return [{ label: "Battery 87%", disabled: true }, { label: "Power Source: Battery", disabled: true }, "-", { label: "Battery Settings…" }];
        return appMenus[key];
    }

    component BarItem: Rectangle {
        id: bi
        property string key
        property string label: key
        property bool alignRight: false
        default property alias content: inner.data
        property string aiName: label
        property string aiRole: "button"
        function aiActivate() { if (bar.openFor === bi) bar.closeMenu(); else bar.openMenu(bi, bar.itemsFor(key), alignRight); }
        Accessible.role: Accessible.Button
        Accessible.name: label
        height: 22; radius: 5
        width: inner.childrenRect.width + 18
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: bar.openFor === bi || ma.containsMouse ? Qt.rgba(1, 0.94, 0.9, 0.12) : "transparent"
        Item { id: inner; x: 9; height: parent.height; width: childrenRect.width }
        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true
            onPressed: bi.aiActivate()
            onContainsMouseChanged: if (containsMouse && bar.openFor && bar.openFor !== bi) bar.openMenu(bi, bar.itemsFor(bi.key), bi.alignRight)
        }
    }
    component BarText: Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text; font.family: Theme.font; font.pixelSize: 13
    }

    Row {
        x: 8; height: parent.height
        BarItem { key: "logo"; label: "Firelamp menu"; width: 34; Logo { width: 14; height: 16; y: 3; x: 1 } }
        BarItem { key: "app"; label: "App menu"; BarText { text: bar.appName; font.weight: Font.Bold } }
        Repeater {
            model: ["File", "Edit", "View", "Window", "Help"]
            BarItem { required property string modelData; key: modelData; label: modelData + " menu"; BarText { text: modelData } }
        }
    }

    Row {
        anchors.right: parent.right; anchors.rightMargin: 8
        height: parent.height
        spacing: 2
        // the assistant's status pill
        Rectangle {
            id: ai
            property string aiName: "Assistant status"
            property string aiRole: "button"
            function aiActivate() { Os.timelineToggle(undefined); }
            readonly property string st: Os.agent ? Os.agent.mode : "idle"
            anchors.verticalCenter: parent.verticalCenter
            height: 22; radius: 11
            width: aiRow.width + 16
            color: st === "running" ? Qt.rgba(1, 0.48, 0.2, 0.16) : Qt.rgba(1, 0.94, 0.9, 0.06)
            Row {
                id: aiRow; x: 7; spacing: 6; anchors.verticalCenter: parent.verticalCenter
                Logo { width: 12; height: 14; animated: ai.st !== "idle" }
                BarText { text: Os.name; font.pixelSize: 12; font.weight: Font.DemiBold }
                Rectangle {
                    width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter
                    color: ai.st === "running" ? Theme.orange : ai.st === "paused" ? Theme.amber : Theme.text4
                    SequentialAnimation on opacity { running: ai.st === "running"; loops: Animation.Infinite; NumberAnimation { to: 0.35; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
                }
            }
            MouseArea { anchors.fill: parent; onClicked: ai.aiActivate() }
        }
        BarItem { key: "battery"; label: "Battery"; alignRight: true
            Row { spacing: 5; height: parent.height
                BarText { text: "87%"; font.pixelSize: 12; color: Theme.text2 }
                Glyph { name: "battery"; width: 25; height: 12; anchors.verticalCenter: parent.verticalCenter } } }
        BarItem { key: "wifi"; label: "Wi-Fi"; alignRight: true; Glyph { name: "wifi"; width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter } }
        Rectangle {
            property string aiName: "Ask"
            property string aiRole: "button"
            function aiActivate() { Os.askOpen(); }
            width: 33; height: 22; radius: 5; anchors.verticalCenter: parent.verticalCenter
            color: sma.containsMouse ? Qt.rgba(1, 0.94, 0.9, 0.12) : "transparent"
            Glyph { name: "search"; width: 15; height: 15; anchors.centerIn: parent }
            MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: Os.askOpen() }
        }
        BarItem { key: "control"; label: "Control Center"; alignRight: true; Glyph { name: "control"; width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter } }
        BarText {
            id: clock
            leftPadding: 8; rightPadding: 8
            font.features: { "tnum": 1 }
            function tick() { var d = new Date(); text = Os.days[d.getDay()] + " " + Os.months[d.getMonth()].slice(0, 3) + " " + d.getDate() + "  " + Os.clock(d); }
            Component.onCompleted: tick()
            Timer { interval: 5000; running: true; repeat: true; onTriggered: clock.tick() }
        }
    }
}
