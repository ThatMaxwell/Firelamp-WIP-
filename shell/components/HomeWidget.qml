// One home-screen widget (DIRECTION §13): surface at 72% with a hairline, 18px radius, 14px
// padding, the type scale. Each kind draws itself for S, M or L. The only ember allowed is the
// Assistant widget's status dot. Everything shown is real (your notes, your Downloads, this
// machine); the sample content only appears with --demo.
import QtQuick
import QtCore
import Qt.labs.folderlistmodel
import "../js/art.js" as Art

Item {
    id: hw
    property string kind: "clock"
    property string size: "M"
    property bool preview: false            // drawn in the gallery: no live data, no input
    property bool bare: false               // inside a stack: the stack draws the surface
    property var items: []                  // kind "stack": the widgets, top to bottom
    property int page: 0
    property int uid: -1
    property real contentOpacity: 1         // dimmed while held over another widget to stack
    Behavior on contentOpacity { NumberAnimation { duration: 140 } }
    signal paged(int i)
    readonly property bool small: size === "S"
    readonly property bool large: size === "L"
    width: Os.widgetSizes[size][0]; height: Os.widgetSizes[size][1]

    Rectangle {
        visible: !hw.bare
        anchors.fill: parent; radius: 18
        color: Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.72)
        border.color: Theme.hairline2; border.width: 1
    }

    component Label: Text {
        color: Theme.text3; font.family: Theme.font; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.8
        font.capitalization: Font.AllUppercase
    }
    component Line: Text { color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight }
    // nothing to show yet: one quiet line where the content would be
    component Empty: Text { y: 24; width: body.width; wrapMode: Text.WordWrap; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
    component Sub: Text { color: Theme.text3; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight }

    property date now: new Date()
    Timer { interval: 1000; running: !hw.preview && (hw.kind === "clock" || hw.kind === "system"); repeat: true; onTriggered: hw.now = new Date() }

    Loader {
        id: body
        x: 14; y: 14; width: parent.width - 28; height: parent.height - 28
        visible: hw.kind !== "stack"
        opacity: hw.contentOpacity
        sourceComponent: hw.kind === "stack" ? null : ({ clock: clock, weather: weather, upnext: upnext, nowplaying: nowplaying, notes: notes, folder: folder,
                            photo: photo, system: system, assistant: assistant, quick: quick })[hw.kind] || clock
    }

    // a stack: widgets of one size on top of each other; scroll (or swipe) to cycle, like iOS
    Loader { anchors.fill: parent; active: hw.kind === "stack"; sourceComponent: stack; opacity: hw.contentOpacity }
    Component { id: stack
        Item {
            ListView {
                id: lv
                anchors.fill: parent; clip: true
                model: hw.items
                orientation: ListView.Vertical
                snapMode: ListView.SnapOneItem
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: 380
                boundsBehavior: Flickable.StopAtBounds
                interactive: !hw.preview && !Os.editingHome
                currentIndex: hw.page
                Component.onCompleted: positionViewAtIndex(hw.page, ListView.Beginning)
                onCurrentIndexChanged: hw.paged(currentIndex)
                // loaded by URL: a widget type can't name itself
                delegate: Loader {
                    required property string modelData
                    width: hw.width; height: hw.height
                    Component.onCompleted: setSource(Qt.resolvedUrl("HomeWidget.qml"), { kind: modelData, size: hw.size, bare: true, preview: hw.preview })
                }
                // one wheel notch = one widget, with a short rest so a trackpad fling doesn't skip three
                WheelHandler {
                    enabled: !hw.preview && !Os.editingHome
                    property real acc: 0
                    onWheel: (e) => {
                        acc += e.angleDelta.y;
                        if (Math.abs(acc) < 90 || rest.running) return;
                        var n = Math.max(0, Math.min(lv.count - 1, lv.currentIndex + (acc < 0 ? 1 : -1)));
                        acc = 0; rest.start();
                        lv.currentIndex = n;
                    }
                }
                Timer { id: rest; interval: 320 }
                Connections { target: Os; function onPageStack(u, i) { if (u === hw.uid) lv.currentIndex = i; } }
            }
            // where you are in the stack: small dots on the right edge
            Column {
                anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Repeater {
                    model: hw.items.length
                    Rectangle { required property int index; width: 4; height: 4; radius: 2
                                color: index === lv.currentIndex ? Theme.text2 : Theme.text4
                                Behavior on color { ColorAnimation { duration: 200 } } }
                }
            }
        }
    }
    Component { id: clock
        Item {
            Label { text: Qt.formatDate(hw.now, "dddd") }
            Text {
                y: hw.small ? 30 : 20
                text: ((hw.now.getHours() + 11) % 12 + 1) + Qt.formatTime(hw.now, ":mm")
                color: Theme.text; font.family: Theme.font; font.weight: Font.Bold
                font.pixelSize: hw.small ? 44 : hw.large ? 88 : 64; font.letterSpacing: hw.small ? -1 : -2
            }
            Sub { anchors.bottom: parent.bottom; text: Qt.formatDate(hw.now, hw.small ? "MMM d" : "MMMM d, yyyy"); color: Theme.text2; font.pixelSize: 12 }
        }
    }
    Component { id: weather
        Item {
            Label { text: "Weather" }
            Empty { visible: !Os.demo; text: "No location set" }
            Item { visible: Os.demo; anchors.fill: parent
            Text { y: 22; text: "18°"; color: Theme.text; font.family: Theme.font; font.pixelSize: hw.small ? 44 : 52; font.weight: Font.Bold; font.letterSpacing: -1 }
            Column {
                anchors.bottom: parent.bottom; spacing: 2
                Text { text: "Clear"; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
                Sub { text: "H 22  L 14" }
            }
            Row {
                visible: !hw.small; anchors.right: parent.right; anchors.bottom: parent.bottom; spacing: 14
                Repeater {
                    model: [["Fri", "19°"], ["Sat", "16°"], ["Sun", "21°"]]
                    Column { required property var modelData; spacing: 4
                        Sub { text: modelData[0]; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: modelData[1]; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium } }
                }
            }
            }
        }
    }
    Component { id: upnext
        Item {
            Label { text: "Up next" }
            Empty { visible: !list.length; text: "Nothing coming up" }
            readonly property var list: (Os.demo ? [["Jev onboarding", "Tomorrow · 10:00 AM"], ["Site goes live", "Wed, Oct 14 · all day"], ["Firelamp 0.1", "Wed, Oct 21"], ["Dock review", "Thu, Oct 22 · 2:00 PM"], ["Van for the move", "Sat, Oct 24 · 9:00 AM"]]
                : (function () { var out = [], n = new Date(); Object.keys(Os.events).map(Number).sort(function (a, b) { return a - b; }).forEach(function (d) {
                    if (d >= n.getDate()) Os.events[d].forEach(function (e) { out.push([e[0], d === n.getDate() ? "Today" : Qt.formatDate(new Date(n.getFullYear(), n.getMonth(), d), "ddd, MMM d")]); }); }); return out; })())
            Column {
                y: 24; width: parent.width; spacing: 12
                Repeater {
                    model: parent.parent.list.slice(0, hw.small ? 1 : hw.large ? 5 : 2)
                    Row { required property var modelData; spacing: 10; width: parent.width
                        Rectangle { width: 2; height: 32; radius: 1; color: Theme.text3 }
                        Column { spacing: 2; width: parent.width - 12
                            Line { text: modelData[0]; width: parent.width }
                            Sub { text: modelData[1]; width: parent.width } } }
                }
            }
        }
    }
    Component { id: nowplaying
        Item {
            Label { visible: !Os.demo; text: "Now playing" }
            Empty { visible: !Os.demo; text: "Nothing playing" }
            Item { visible: Os.demo; anchors.fill: parent
            Image {
                id: cover
                width: hw.small ? 64 : 76; height: width; fillMode: Image.PreserveAspectCrop
                source: Qt.resolvedUrl("../assets/photos/deep-field.jpg"); sourceSize: Qt.size(160, 160)
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: Theme.hairline; border.width: 1; radius: 2 }
            }
            Column {
                visible: !hw.small
                x: cover.width + 14; width: parent.width - x; spacing: 2
                Label { text: "Now playing"; bottomPadding: 6 }
                Line { text: "Night Shift"; width: parent.width; font.pixelSize: 15; font.weight: Font.DemiBold }
                Sub { text: "Hearth Tapes"; width: parent.width; font.pixelSize: 12; color: Theme.text2 }
            }
            Column {
                visible: hw.small; anchors.bottom: parent.bottom; width: parent.width; spacing: 1
                Line { text: "Night Shift"; width: parent.width }
                Sub { text: "Hearth Tapes"; width: parent.width }
            }
            Rectangle {
                visible: !hw.small; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; width: parent.width; height: 3; radius: 1.5; color: Theme.surface3
                Rectangle { width: parent.width * 0.34; height: 3; radius: 1.5; color: Theme.text2 }
            }
            }
        }
    }
    Component { id: notes
        Item {
            Label { text: "Notes" }
            Empty { visible: !Os.demo && !Os.notes.length; text: "No notes yet" }
            Column {
                y: 24; spacing: 6
                Repeater { model: (Os.demo ? ["Buy oat milk", "Reply to Leo", "Book the van for Saturday", "Dock icon sizes"] : Os.notes.map(Os.noteTitle)).slice(0, hw.small ? 2 : hw.large ? 4 : 3)
                    Line { required property string modelData; text: modelData; width: body.width; font.weight: Font.Normal; color: Theme.text2 } }
            }
        }
    }
    Component { id: folder
        Item {
            Label { text: "Downloads" }
            FolderListModel { id: dl; folder: Os.demo || hw.preview ? "" : StandardPaths.writableLocation(StandardPaths.DownloadLocation); sortField: FolderListModel.Time; showDirsFirst: false }
            readonly property var list: { if (Os.demo) return [["iso", "firelamp-0.2.iso"], ["pdf", "Invoice 0412.pdf"], ["jpg", "dusk.jpg"], ["gz", "dotfiles.tar.gz"]];
                var out = []; for (var i = 0; i < Math.min(dl.count, 4); i++) { var n = dl.get(i, "fileName"); out.push([dl.get(i, "fileIsDir") ? "folder" : n.split(".").pop(), n]); } return out; }
            Empty { visible: !parent.list.length; text: "Downloads is empty" }
            Grid {
                y: 26; columns: hw.small ? 2 : 4; rowSpacing: 10; columnSpacing: (body.width - columns * 52) / (columns - 1)
                Repeater {
                    model: parent.parent.list.slice(0, hw.small ? 2 : 4)
                    Column { required property var modelData; spacing: 4; width: 52
                        Image { width: 32; height: 32; anchors.horizontalCenter: parent.horizontalCenter; sourceSize: Qt.size(64, 64); source: Art.fileIcon(modelData[0]) }
                        Sub { text: modelData[1]; width: 52; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 9 } }
                }
            }
        }
    }
    Component { id: photo
        Item {
            // the newest picture in ~/Pictures (a sample with --demo); full-bleed, so it ignores the padding
            FolderListModel { id: pics; folder: Os.demo || hw.preview ? "" : StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                              nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"]; showDirs: false; sortField: FolderListModel.Time }
            Label { visible: !Os.demo && !pics.count; text: "Photo" }
            Empty { visible: !Os.demo && !pics.count; text: "No photos in Pictures" }
            Image {
                visible: Os.demo || pics.count > 0
                x: -14; y: -14; width: hw.width; height: hw.height; fillMode: Image.PreserveAspectCrop
                source: Os.demo ? Qt.resolvedUrl("../assets/photos/chelsea.jpg") : pics.count ? pics.get(0, "fileUrl") : ""; sourceSize: Qt.size(hw.width * 2, hw.height * 2)
                layer.enabled: true
                Rectangle { anchors.fill: parent; radius: 18; color: "transparent"; border.color: Theme.hairline2; border.width: 1 }
            }
        }
    }
    Component { id: system
        Item {
            Label { text: "System" }
            Column {
                y: 24; spacing: 8; width: parent.width
                Repeater {
                    readonly property var rows: Os.demo ? [["CPU", "12%"], ["RAM", "5.1/32G"], ["TEMP", "46°C"]]
                        : [["CPU", Os.sys.cpu + "%"], ["RAM", Os.sys.used.toFixed(1) + "/" + Math.round(Os.sys.total) + "G"]].concat(Os.sys.temp >= 0 ? [["TEMP", Os.sys.temp + "°C"]] : [])
                    model: rows.slice(0, hw.small ? 2 : 3)
                    Row { required property var modelData; required property int index; spacing: 10
                        Text { width: 40; text: modelData[0]; color: Theme.text3; font.family: Theme.mono; font.pixelSize: 10 }
                        Text { width: 64; text: modelData[1]; color: Theme.text; font.family: Theme.mono; font.pixelSize: 11 }
                        // a mono sparkline, bars only
                        Row {
                            visible: !hw.small && (Os.demo || parent.index === 0); spacing: 2; height: 14
                            Repeater { model: 22
                                Rectangle { required property int index; anchors.bottom: parent.bottom; width: 3; radius: 1; color: Theme.text3
                                    height: Os.demo || parent.parent.index !== 0 ? 3 + 11 * Math.abs(Math.sin((index + 1) * 1.7 + parent.parent.index * 2.3 + hw.now.getSeconds() * 0.35))
                                        : 3 + 11 * (Os.sys.hist[Os.sys.hist.length - 22 + index] || 0) / 100 } }
                        }
                    }
                }
            }
        }
    }
    Component { id: assistant
        Item {
            Row {
                spacing: 7
                Rectangle { width: 6; height: 6; radius: 3; color: Theme.ember; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Os.name }
            }
            Empty { visible: !Os.demo && !Os.activity.count; y: 22; text: "Nothing done yet. Ask me anything." }
            Column {
                y: 22; spacing: 5; width: parent.width
                Repeater {
                    model: { if (Os.demo) return ["Sorted 3 documents", "Emailed Ana the notes", "Opened Downloads"].slice(0, hw.small ? 2 : 3);
                             var out = []; for (var i = 0; i < Os.activity.count && out.length < (hw.small ? 2 : 3); i++) if (!Os.activity.get(i).live && !Os.activity.get(i).undone) out.push(Os.activity.get(i).title); return out; }
                    Row { required property string modelData; spacing: 6
                        Text { text: "✓"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
                        Line { text: modelData; font.weight: Font.Normal; color: Theme.text2; font.pixelSize: 12 } }
                }
            }
            Rectangle {
                visible: !hw.small
                property string aiName: "Ask " + Os.name; property string aiRole: "button"
                function aiActivate() { Os.askOpen(); }
                anchors.bottom: parent.bottom; width: parent.width; height: 28; radius: 8
                color: Qt.rgba(1, 1, 1, 0.04); border.color: Theme.hairline2; border.width: 1
                Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "Ask " + Os.name + "…"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; enabled: !hw.preview && !Os.editingHome; onClicked: parent.aiActivate() }
            }
        }
    }
    Component { id: quick
        Grid {
            columns: hw.small ? 2 : 4; spacing: 8
            readonly property real cell: (body.width - (columns - 1) * 8) / columns
            Repeater {
                model: [["moon", "Focus"], ["eye", "Screenshot"], ["lock", "Lock"], ["sparkle", "Ask"]]
                Rectangle {
                    required property var modelData
                    width: parent.cell; height: hw.small ? parent.cell : body.height; radius: 12; color: Qt.rgba(1, 1, 1, 0.05)
                    Column { anchors.centerIn: parent; spacing: 6
                        Glyph { name: modelData[0]; width: 18; height: 18; color: Theme.text2; anchors.horizontalCenter: parent.horizontalCenter }
                        Sub { visible: !hw.small; text: modelData[1]; anchors.horizontalCenter: parent.horizontalCenter } }
                }
            }
        }
    }
}
