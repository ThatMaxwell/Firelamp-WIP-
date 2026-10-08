// The menu bar: Firelamp menu, the focused app's menus, and status items on the right.
import QtQuick
import "../js/logo.js" as L

Rectangle {
    id: bar
    property string appName: "Desktop"
    property var openFor: null
    property Item menuLayer
    property string aiApp: "menubar"
    height: Theme.menubarH
    color: Theme.bar
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.hairline }

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
    // a context menu at a point (right-click on the desktop)
    function openAt(x, y, items) {
        closeMenu();
        menu = menuComp.createObject(menuLayer, { items: items });
        menu.x = Math.min(menuLayer.width - menu.width - 4, x); menu.y = Math.min(menuLayer.height - menu.height - 4, y);
        menu.picked.connect(closeMenu);
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
            { label: "About Firelamp OS", action: function () { Os.desktop.open("about"); } }, "-"].concat(
            Os.live ? [{ label: "Install Firelamp OS…", action: function () { Os.installOS(); } }, "-"] : [], [
            { label: "System Settings…", action: function () { Os.desktop.open("settings"); } },
            { label: "Activity Timeline", sc: "⌥⌘T", action: function () { Os.timelineToggle(undefined); } }, "-",
            { label: "Sleep" }, { label: "Restart…" }, { label: "Shut Down…" }, "-", { label: "Lock Screen", sc: "⌃⌘Q" }]);
        if (key === "app") return [{ label: "About " + appName }, "-", { label: "Settings…", sc: "⌘,", action: function () { Os.desktop.open("settings"); } }, "-", { label: "Hide " + appName, sc: "⌘H" }, { label: "Quit " + appName, sc: "⌘Q", action: function () { Os.desktop.closeFocused(); } }];
        if (key === "control") return [{ label: "Focus", sc: "Off" }, { label: "Screen Mirroring" }, "-", { label: "Pause " + Os.name, sc: "⌃Space", action: function () { Os.agent.togglePause(); } }, { label: "Stop " + Os.name, sc: "Esc", action: function () { Os.agent.stop(); } }];
        if (key === "wifi") return Os.demo ? [{ label: "Wi-Fi", sc: "On" }, "-", { label: "Hearth", sc: "●" }, { label: "Kitchen 5G" }, "-", { label: "Network Settings…" }] : [{ label: "Wi-Fi", sc: "On" }, "-", { label: "Network Settings…" }];
        if (key === "battery") return [{ label: "Battery " + (Os.demo ? 87 : Os.battery) + "%", disabled: true }, { label: "Power Source: " + (Os.demo || !Os.charging ? "Battery" : "Power Adapter"), disabled: true }, "-", { label: "Battery Settings…" }];
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
        function aiActivate() {
            if (key === "control") { bar.closeMenu(); Os.controlToggle(); return; }
            if (bar.openFor === bi) bar.closeMenu(); else bar.openMenu(bi, bar.itemsFor(key), alignRight);
        }
        Accessible.role: Accessible.Button
        Accessible.name: label
        height: 22; radius: 5
        width: inner.childrenRect.width + 18
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: bar.openFor === bi ? Theme.surface3 : ma.containsMouse ? Theme.hover : "transparent"
        Item { id: inner; x: 9; height: parent.height; width: childrenRect.width }
        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true
            onPressed: bi.aiActivate()
            onContainsMouseChanged: if (containsMouse && bar.openFor && bar.openFor !== bi && bi.key !== "control") bar.openMenu(bi, bar.itemsFor(bi.key), bi.alignRight)
        }
    }
    component BarText: Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium
    }

    Row {
        x: 8; height: parent.height
        // the menu-bar mark is a plain cream glyph; colour stays with the AI
        BarItem { key: "logo"; label: "Firelamp menu"; width: 30
            Image { width: 12; height: 17; y: 2; x: 0; sourceSize: Qt.size(24, 34); smooth: true
                source: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="24 26 644 966"><path fill="' + Theme.text + '" d="' + L.PATHS.outer + '"/></svg>') } }
        BarItem { key: "app"; label: "App menu"; BarText { text: bar.appName; font.weight: Font.Bold } }
        Repeater {
            model: ["File", "Edit", "View", "Window", "Help"]
            BarItem { required property string modelData; key: modelData; label: modelData + " menu"; BarText { text: modelData } }
        }
    }

    // the right side, in the order set in Edit home › Dock & bar
    Row {
        anchors.right: parent.right; anchors.rightMargin: 8
        height: parent.height
        spacing: 2
        Repeater {
            model: Os.barItems
            Loader {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                // desktops and VMs have no battery, so no battery item
                visible: modelData !== "battery" || Os.demo || Os.battery >= 0
                sourceComponent: ({ assistant: cAssistant, battery: cBattery, wifi: cWifi, search: cSearch, control: cControl, clock: cClock })[modelData]
            }
        }
    }
    Component { id: cAssistant
        // the assistant's status pill
        Rectangle {
            id: ai
            property string aiName: "Assistant status"
            property string aiRole: "button"
            function aiActivate() { Os.timelineToggle(undefined); }
            readonly property string st: Os.agent ? Os.agent.mode : "idle"
            height: 22; radius: 5
            width: aiRow.width + 18
            color: aim.containsMouse ? Theme.hover : "transparent"
            Row {
                id: aiRow; x: 9; spacing: 6; anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter
                    color: ai.st === "running" ? Theme.ember : ai.st === "paused" ? Theme.text2 : Theme.text4
                    Behavior on color { ColorAnimation { duration: 280 } }
                }
                BarText { text: Os.name; color: Theme.text2; font.weight: Font.Medium }
            }
            MouseArea { id: aim; anchors.fill: parent; hoverEnabled: true; onClicked: ai.aiActivate() }
        }
    }
    Component { id: cBattery
        BarItem { key: "battery"; label: "Battery"; alignRight: true; height: 22
            Row { spacing: 5; height: parent.height
                BarText { text: (Os.demo ? 87 : Os.battery) + "%"; color: Theme.text; font.features: { "tnum": 1 } }
                Glyph { name: "battery"; width: 25; height: 12; anchors.verticalCenter: parent.verticalCenter } } }
    }
    Component { id: cWifi
        BarItem { key: "wifi"; label: "Wi-Fi"; alignRight: true; Glyph { name: "wifi"; width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter } }
    }
    Component { id: cSearch
        Rectangle {
            property string aiName: "Ask"
            property string aiRole: "button"
            function aiActivate() { Os.askOpen(); }
            width: 33; height: 22; radius: 5
            color: sma.containsMouse ? Theme.hover : "transparent"
            Glyph { name: "search"; width: 15; height: 15; anchors.centerIn: parent }
            MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: Os.askOpen() }
        }
    }
    Component { id: cControl
        BarItem { key: "control"; label: "Control Center"; alignRight: true; Glyph { name: "control"; width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter } }
    }
    Component { id: cClock
        Item {
            width: clock.implicitWidth; height: 22
            BarText {
                id: clock
                font.weight: Font.Medium
                leftPadding: 8; rightPadding: 8
                font.features: { "tnum": 1 }
                function tick() { var d = new Date(); text = (Os.settings.barDate ? Os.days[d.getDay()] + " " + Os.months[d.getMonth()].slice(0, 3) + " " + d.getDate() + "  " : "") + Os.clock(d, Os.settings.barSeconds); }
                Component.onCompleted: tick()
                Timer { interval: Os.settings.barSeconds ? 1000 : 5000; running: true; repeat: true; onTriggered: clock.tick() }
                Connections { target: Os.settings; function onBarDateChanged() { clock.tick(); } function onBarSecondsChanged() { clock.tick(); } }
            }
        }
    }
}
