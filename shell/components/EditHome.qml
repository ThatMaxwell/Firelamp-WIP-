// Edit home's chrome: a pill under the menu bar (Reset, Done) and a bottom sheet above the
// dock with four tabs. Every change previews live on the desktop; there is no Apply.
import QtQuick
import QtQuick.Effects

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

            // Wallpaper: ours, then the photos that ship with Firelamp
            Row {
                visible: eh.tab === "Wallpaper"
                spacing: 14
                Repeater {
                    model: [["graphite", "Graphite"], ["launch-dusk", "Dusk"], ["deep-field", "Deep field"], ["gravel", "Gravel"], ["brick", "Brick"], ["espresso", "Espresso"]]
                    Column {
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
                                Wallpaper { anchors.fill: parent; visible: wpc.modelData[0] === "graphite"; pick: "graphite" }
                                Image { anchors.fill: parent; visible: wpc.modelData[0] !== "graphite"; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(280, 180)
                                        source: wpc.modelData[0] !== "graphite" ? Qt.resolvedUrl("../assets/photos/" + wpc.modelData[0] + ".jpg") : "" }
                            }
                            Rectangle { id: wpMask; anchors.fill: parent; anchors.margins: 4; radius: 7; visible: false; layer.enabled: true }
                            MouseArea { anchors.fill: parent; onClicked: wpc.aiActivate() }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: wpc.modelData[1]; color: wpc.on ? Theme.text : Theme.text2; font.family: Theme.font; font.pixelSize: 12; font.weight: wpc.on ? Font.Medium : Font.Normal }
                    }
                }
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

            Text {
                visible: eh.tab === "Looks"
                text: "Looks are next: Graphite, Paper, Midnight, Moss and Studio."
                color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
            }
        }
    }
}
