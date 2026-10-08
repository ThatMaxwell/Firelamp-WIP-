// Edit home's chrome: a pill under the menu bar (Reset, Done) and a bottom sheet above the
// dock with four tabs. Every change previews live on the desktop; there is no Apply.
import QtQuick
import QtQuick.Effects
import QtQuick.Dialogs
import QtCore
import "../js/walls.js" as Walls

Item {
    id: eh
    property var home                       // Desktop's Home layer, for free spots
    property string tab: "Widgets"
    property real k: Os.editingHome ? 1 : 0
    Behavior on k { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    visible: k > 0

    readonly property var gallery: [
        { kind: "clock", name: "Clock", sizes: ["S", "M", "L"] },
        { kind: "upnext", name: "Up next", sizes: ["S", "M", "L"] },
        { kind: "weather", name: "Weather", sizes: ["S", "M"] },
        { kind: "nowplaying", name: "Now playing", sizes: ["S", "M"] },
        { kind: "notes", name: "Notes", sizes: ["S", "M", "L"] },
        { kind: "folder", name: "Folder", sizes: ["S", "M"] },
        { kind: "photo", name: "Photo frame", sizes: ["S", "M", "L"] },
        { kind: "system", name: "System", sizes: ["S", "M"] },
        { kind: "assistant", name: Os.name, sizes: ["S", "M"] },
        { kind: "quick", name: "Quick actions", sizes: ["S", "M"] } ]

    // ---- Looks ----
    readonly property var presets: [
        { name: "Graphite", what: "The default", look: "graphite", winRadius: 12, dockSize: 1, dockMag: 2, dockBacking: true },
        { name: "Paper", what: "Light", look: "paper", winRadius: 12, dockSize: 1, dockMag: 2, dockBacking: true },
        { name: "Midnight", what: "True black, for OLED", look: "midnight", winRadius: 12, dockSize: 1, dockMag: 1, dockBacking: true },
        { name: "Moss", what: "Green-grey", look: "moss", winRadius: 12, dockSize: 1, dockMag: 2, dockBacking: true },
        { name: "Studio", what: "Dense and square", look: "studio", winRadius: 0, dockSize: 0, dockMag: 0, dockBacking: true } ]
    readonly property var lookKeys: ["look", "winRadius", "dockSize", "dockMag", "dockBacking", "wallpaper", "accent"]
    property var mine: { try { return JSON.parse(Os.settings.myLooks); } catch (e) { return []; } }
    readonly property var allLooks: presets.concat(mine)
    function applyLook(l) { lookKeys.forEach(function (k) { if (l[k] !== undefined) Os.settings[k] = l[k]; }); }
    function isCurrent(l) {
        for (var i = 0; i < lookKeys.length; i++) { var k = lookKeys[i]; if (l[k] !== undefined && Os.settings[k] !== l[k]) return false; }
        return true;
    }
    // "Save as Look" captures the setup as it is now, home layout included
    function saveLook() {
        var l = { name: "My Look" + (mine.length ? " " + (mine.length + 1) : ""), what: "Saved just now", home: Os.settings.homeLayout };
        lookKeys.forEach(function (k) { l[k] = Os.settings[k]; });
        Os.settings.myLooks = JSON.stringify(mine.concat([l]));
    }

    function add(kind, size) {
        var p = home.freeSpot(size);
        Os.addWidget(kind, size, p.x, p.y);
    }

    // ---- the pill ----
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.menubarH + 12 - 8 * (1 - eh.k)
        opacity: eh.k
        width: pillRow.width + 14; height: 38; radius: 19
        color: Theme.surface2; border.color: Theme.hairline2; border.width: 1
        RectangularShadow { anchors.fill: parent; z: -1; radius: parent.radius; blur: 24; offset.y: 8; color: Qt.rgba(0, 0, 0, 0.4) }
        Row {
            id: pillRow
            x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Editing home"; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "· drag, resize, or add widgets"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12; rightPadding: 4 }
            Rectangle {
                property string aiName: "Reset home"; property string aiRole: "button"
                function aiActivate() { Os.resetHome(); }
                width: rt.implicitWidth + 24; height: 26; radius: 13; color: Theme.surface3
                Text { id: rt; anchors.centerIn: parent; text: "Reset"; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
                MouseArea { anchors.fill: parent; onClicked: parent.aiActivate() }
            }
            Rectangle {
                property string aiName: "Done"; property string aiRole: "button"
                function aiActivate() { Os.editingHome = false; }
                width: dt.implicitWidth + 26; height: 26; radius: 13; color: Theme.text
                Text { id: dt; anchors.centerIn: parent; text: "Done"; color: Theme.bg; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; onClicked: parent.aiActivate() }
            }
        }
    }

    // ---- the sheet ----
    Rectangle {
        id: sheet
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 120, 1000); height: 262
        y: parent.height - 100 - height + 40 * (1 - eh.k)
        opacity: eh.k
        radius: 16; color: Theme.surface2; border.color: Theme.hairline2; border.width: 1
        RectangularShadow { anchors.fill: parent; z: -1; radius: parent.radius; blur: 40; offset.y: 14; color: Qt.rgba(0, 0, 0, 0.5) }
        // clicks on the sheet never reach the desktop under it
        MouseArea { anchors.fill: parent }

        Segmented {
            id: tabs
            x: 18; y: 16
            options: ["Widgets", "Wallpaper", "Dock & bar", "Looks"]
            current: options.indexOf(eh.tab)
            onPicked: (i) => eh.tab = options[i]
        }
        Rectangle {
            visible: eh.tab === "Widgets"
            anchors.right: parent.right; anchors.rightMargin: 18; y: 16
            width: 220; height: 26; radius: 7; color: Theme.surface0; border.color: search.input.activeFocus ? Theme.line3 : Theme.hairline; border.width: 1
            Field { id: search; x: 10; width: parent.width - 20; height: parent.height; pixelSize: 12; label: "Search widgets"; placeholder: "Search widgets" }
        }

        Item {
            id: pane
            x: 18; y: 58; width: parent.width - 36; height: parent.height - 58 - 16

            // Widgets: a strip of live previews; pick a size, click to add
            ListView {
                id: strip
                visible: eh.tab === "Widgets"
                anchors.fill: parent
                orientation: ListView.Horizontal; spacing: 12; clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: eh.gallery.filter(function (g) { return !search.text || g.name.toLowerCase().indexOf(search.text.toLowerCase()) >= 0; })
                footer: Item {
                    width: 168 + 12; height: strip.height
                    Rectangle {
                        x: 12; width: 168; height: parent.height; radius: 12
                        color: "transparent"; border.color: Theme.hairline2; border.width: 1
                        Column { anchors.centerIn: parent; spacing: 4
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "More from KDE Store"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Plasma widgets ›"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 } }
                    }
                }
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    property string size: modelData.sizes.indexOf("M") >= 0 ? "M" : modelData.sizes[0]
                    property string aiName: "Add " + modelData.name + " widget"; property string aiRole: "button"
                    function aiActivate() { eh.add(modelData.kind, size); }
                    width: 210; height: strip.height; radius: 12
                    color: Qt.rgba(1, 1, 1, 0.03); border.color: Theme.hairline; border.width: 1
                    MouseArea { anchors.fill: parent; onClicked: card.aiActivate() }
                    // the widget itself, scaled into the card
                    Item {
                        id: well
                        x: 10; y: 10; width: parent.width - 20; height: parent.height - 48
                        HomeWidget {
                            id: pv
                            kind: card.modelData.kind; size: card.size; preview: true
                            anchors.centerIn: parent
                            scale: Math.min(well.width / width, well.height / height, 0.6)
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }
                    Text { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: card.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; spacing: 3
                        Repeater {
                            model: card.modelData.sizes
                            Rectangle {
                                required property string modelData
                                property string aiName: card.modelData.name + " size " + modelData; property string aiRole: "radio"
                                function aiActivate() { card.size = modelData; }
                                width: 18; height: 18; radius: 4
                                color: card.size === modelData ? Theme.surface3 : "transparent"
                                border.color: card.size === modelData ? Theme.line3 : Theme.hairline; border.width: 1
                                Text { anchors.centerIn: parent; text: parent.modelData; color: card.size === parent.modelData ? Theme.text : Theme.text3; font.family: Theme.font; font.pixelSize: 9; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; anchors.margins: -2; onClicked: parent.aiActivate() }
                            }
                        }
                    }
                }
            }

            // Wallpaper: ours (drawn), Dynamic (follows the time of day), two photos, then yours
            ListView {
                id: walls
                visible: eh.tab === "Wallpaper"
                anchors.fill: parent
                orientation: ListView.Horizontal; spacing: 12; clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Walls.LIST
                footer: Item {
                    width: 144 + 12; height: walls.height
                    Column {
                        x: 12; spacing: 8
                        property string aiName: "Your photos"; property string aiRole: "button"
                        function aiActivate() { picker.open(); }
                        Rectangle {
                            width: 144; height: 90; radius: 10; color: "transparent"; border.color: Theme.hairline2; border.width: 1
                            Text { anchors.centerIn: parent; text: "+"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 20 }
                            MouseArea { anchors.fill: parent; onClicked: picker.open() }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Your photos…"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }
                delegate: Column {
                    id: wpc
                    required property var modelData
                    readonly property bool on: Os.settings.wallpaper === modelData[0]
                    property string aiName: modelData[1] + " wallpaper"; property string aiRole: "radio"
                    function aiActivate() { Os.settings.wallpaper = modelData[0]; }
                    spacing: 8
                    Rectangle {
                        width: 144; height: 90; radius: 10; color: "transparent"
                        border.color: wpc.on ? Theme.text : "transparent"; border.width: 2
                        Item {
                            anchors.fill: parent; anchors.margins: 4
                            layer.enabled: true
                            layer.effect: MultiEffect { maskEnabled: true; maskSource: wpMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1 }
                            Wallpaper { anchors.fill: parent; pick: wpc.modelData[0]; Rectangle { anchors.fill: parent; color: "transparent" } }
                        }
                        Rectangle { id: wpMask; anchors.fill: parent; anchors.margins: 4; radius: 7; visible: false; layer.enabled: true }
                        // Dynamic shows its four lights as a strip along the bottom
                        Row {
                            visible: wpc.modelData[0] === "dynamic"
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; spacing: 3
                            Repeater { model: ["dawn", "day", "dusk", "night"]
                                Rectangle { required property string modelData; width: 14; height: 4; radius: 2; color: Walls.LIGHTS[modelData].sky[1]; border.color: Qt.rgba(1, 1, 1, 0.25); border.width: 0.5 } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: wpc.aiActivate() }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: wpc.modelData[1]; color: wpc.on ? Theme.text : Theme.text2; font.family: Theme.font; font.pixelSize: 12; font.weight: wpc.on ? Font.Medium : Font.Normal }
                }
            }
            FileDialog {
                id: picker
                title: "Choose a wallpaper"
                nameFilters: ["Images (*.jpg *.jpeg *.png *.webp)"]
                currentFolder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                onAccepted: Os.settings.wallpaper = selectedFile.toString()
            }

            // Dock & bar: the few things people actually change, live
            Row {
                visible: eh.tab === "Dock & bar"
                spacing: 36
                component Opt: Item {
                    property string title
                    default property alias control: slot.data
                    width: 300; height: 36
                    Text { anchors.verticalCenter: parent.verticalCenter; text: parent.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
                    Item { id: slot; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: childrenRect.width; height: childrenRect.height }
                }
                component Head: Text { color: Theme.text3; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.8; font.capitalization: Font.AllUppercase; bottomPadding: 4 }
                Column {
                    Head { text: "Dock" }
                    Opt { title: "Size"; Segmented { options: ["Small", "Medium", "Large"]; current: Os.settings.dockSize; onPicked: (i) => Os.settings.dockSize = i } }
                    Opt { title: "Magnification"; Segmented { options: ["Off", "Subtle", "Full"]; current: Os.settings.dockMag; onPicked: (i) => Os.settings.dockMag = i } }
                    Opt { title: "Backing"; Segmented { options: ["Dark grey", "None"]; current: Os.settings.dockBacking ? 0 : 1; onPicked: (i) => Os.settings.dockBacking = i === 0 } }
                    Opt { title: "Hide automatically"; Toggle { label: "Hide the dock automatically"; checked: Os.settings.dockAutohide; onToggled: (c) => Os.settings.dockAutohide = c } }
                }
                Column {
                    Head { text: "Top bar and windows" }
                    Opt { title: "Show the date"; Toggle { label: "Show the date"; checked: Os.settings.barDate; onToggled: (c) => Os.settings.barDate = c } }
                    Opt { title: "Show seconds"; Toggle { label: "Show seconds"; checked: Os.settings.barSeconds; onToggled: (c) => Os.settings.barSeconds = c } }
                    Opt { title: "Window corners"; Segmented { options: ["Square", "Soft", "Round"]; current: [0, 8, 12].indexOf(Os.settings.winRadius); onPicked: (i) => Os.settings.winRadius = [0, 8, 12][i] } }
                    Opt { title: "More in KDE System Settings ›"; Item { width: 1; height: 1 } }
                }
            }

            // Looks: one click changes the palette, corners and dock together, live on the
            // desktop behind the sheet. Your color is separate, and is never the AI's ember.
            Column {
                visible: eh.tab === "Looks"
                spacing: 16
                Row {
                    spacing: 12
                    Repeater {
                        model: eh.allLooks
                        Rectangle {
                            id: lk
                            required property var modelData
                            readonly property var pal: Theme.looks[modelData.look]
                            readonly property bool on: eh.isCurrent(modelData)
                            property string aiName: modelData.name + " look"; property string aiRole: "radio"
                            function aiActivate() { eh.applyLook(modelData); }
                            width: 138; height: 140; radius: 12
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.color: on ? Theme.text : Theme.hairline2; border.width: on ? 2 : 1
                            MouseArea { anchors.fill: parent; onClicked: lk.aiActivate() }
                            // a diagram of the Look in its own colours: top bar, one window, the dock
                            Rectangle {
                                id: plan
                                x: 12; y: 12; width: parent.width - 24; height: 50; radius: 6
                                color: lk.pal.wall[0]; border.color: Theme.hairline2; border.width: 1
                                readonly property real r: (lk.modelData.winRadius !== undefined ? lk.modelData.winRadius : 12) / 4
                                Rectangle { width: parent.width; height: 4; radius: 0; color: lk.pal.bg; opacity: 0.9 }
                                Rectangle { x: 14; y: 9; width: parent.width * 0.58; height: 27; radius: plan.r; color: lk.pal.s[0]; border.color: Qt.rgba(lk.pal.line[0] / 255, lk.pal.line[1] / 255, lk.pal.line[2] / 255, 0.16); border.width: 1
                                    Rectangle { x: 5; y: 6; width: parent.width * 0.5; height: 2; radius: 1; color: lk.pal.t[0] }
                                    Rectangle { x: 5; y: 11; width: parent.width * 0.35; height: 2; radius: 1; color: lk.pal.t[2] } }
                                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 3
                                            width: parent.width * (lk.modelData.dockSize === 0 ? 0.32 : 0.42); height: 6; radius: Math.min(3, plan.r + 1)
                                            color: Qt.rgba(lk.pal.dock[0] / 255, lk.pal.dock[1] / 255, lk.pal.dock[2] / 255, 1) }
                            }
                            // the palette itself, as swatches: background, surfaces, text
                            Row {
                                x: 12; y: 70; spacing: -4
                                Repeater {
                                    model: [lk.pal.bg, lk.pal.s[1], lk.pal.s[3], lk.pal.t[2], lk.pal.t[0]]
                                    Rectangle { required property var modelData; width: 16; height: 16; radius: 8; color: modelData; border.color: Theme.hairline2; border.width: 1 }
                                }
                            }
                            Column {
                                x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; spacing: 2
                                Text { text: lk.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium }
                                Text { text: lk.modelData.what; color: Theme.text3; font.family: Theme.font; font.pixelSize: 10 }
                            }
                        }
                    }
                    Rectangle {
                        property string aiName: "Save as Look"; property string aiRole: "button"
                        function aiActivate() { eh.saveLook(); }
                        width: 112; height: 140; radius: 12; color: "transparent"; border.color: Theme.hairline2; border.width: 1
                        Column { anchors.centerIn: parent; spacing: 6
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "+"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 20 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Save as Look"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.Medium } }
                        MouseArea { anchors.fill: parent; onClicked: parent.aiActivate() }
                    }
                }
                Row {
                    spacing: 14
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Your color"; color: Theme.text; font.family: Theme.font; font.pixelSize: 12; font.weight: Font.Medium; rightPadding: 4 }
                    Repeater {
                        // no oranges or reds: those read as the AI
                        model: [["", "None"], ["#5B8CFF", "Blue"], ["#7C6CFF", "Indigo"], ["#A67BFF", "Purple"], ["#E46FB0", "Pink"],
                                ["#3DB5AE", "Teal"], ["#3FB97A", "Green"], ["#9CBF4A", "Lime"], ["#8A939C", "Slate"]]
                        Rectangle {
                            id: sw
                            required property var modelData
                            readonly property bool on: Os.settings.accent === modelData[0]
                            property string aiName: modelData[1] + " color"; property string aiRole: "radio"
                            function aiActivate() { Os.settings.accent = modelData[0]; }
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22; height: 22; radius: 11
                            color: modelData[0] || "transparent"
                            border.color: modelData[0] ? "transparent" : Theme.text3; border.width: 1
                            Rectangle { visible: !sw.modelData[0]; width: 14; height: 1.5; rotation: -45; anchors.centerIn: parent; color: Theme.text3 }
                            Rectangle { anchors.fill: parent; anchors.margins: -4; radius: 15; color: "transparent"; border.color: Theme.text; border.width: 1.5; visible: sw.on }
                            MouseArea { anchors.fill: parent; anchors.margins: -3; onClicked: sw.aiActivate() }
                        }
                    }
                    Text { anchors.verticalCenter: parent.verticalCenter; leftPadding: 8; text: "For focus, selection and switches. The assistant keeps its ember."; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                }
            }
        }
    }
}
