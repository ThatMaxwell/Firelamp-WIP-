// Files: the Downloads folder as an icon grid. Exposes move/remove for the agent's drops.
import QtQuick
import "../components"
import "../js/art.js" as Art

Item {
    id: app
    property var win
    property int selIndex: -1
    function start(opts) {}
    function kindOf(n) { return n.indexOf(".") >= 0 ? n.split(".").pop() : "folder"; }
    function indexOf(name) { for (var i = 0; i < files.count; i++) if (files.get(i).name === name) return i; return -1; }

    ListModel { id: files }
    Component.onCompleted: {
        ["IMG_2041.jpg", "invoice.pdf", "sunset.png", "Launch plan.docx", "firelamp-0.1.iso", "IMG_2042.jpg", "invoice (1).pdf", "ember-hours.mp3", "notes.txt", "jev-sdk.tar.gz"]
            .forEach(function (n) { files.append({ name: n, kind: app.kindOf(n), inside: 0, editing: false }); });
    }

    function newFolder() { files.insert(0, { name: "untitled folder", kind: "folder", inside: 0, editing: true }); }
    function commit(name) {
        for (var i = 0; i < files.count; i++) if (files.get(i).editing) { files.setProperty(i, "name", name.trim() || "untitled folder"); files.setProperty(i, "editing", false); }
    }
    function move(name, folder) {
        var i = indexOf(name), f = indexOf(folder);
        if (i < 0 || f < 0) return;
        files.setProperty(f, "inside", files.get(f).inside + 1);
        files.remove(i);
    }
    function remove(name) { var i = indexOf(name); if (i >= 0) files.remove(i); }

    Sidebar {
        id: side
        width: 180
        SideHeader { text: "Favorites" }
        Repeater {
            model: [["Recents", "clock"], ["Desktop", "grid"], ["Documents", "doc"], ["Downloads", "folder"], ["Pictures", "image"], ["Music", "music"]]
            SideItem { required property var modelData; text: modelData[0]; glyph: modelData[1]; selected: modelData[0] === "Downloads" }
        }
        SideHeader { text: "Locations" }
        SideItem { text: "Firelamp Cloud"; glyph: "globe" }
    }

    Item {
        anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
        Row {
            x: 10; y: 12; spacing: 2
            TbButton { glyph: "chevronL"; label: "Back" }
            TbButton { glyph: "chevron"; label: "Forward" }
            Text { leftPadding: 8; text: "Downloads"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12; y: 12; spacing: 2
            TbButton { glyph: "plus"; label: "New Folder"; onClicked: app.newFolder() }
            TbButton { glyph: "grid"; label: "Icon view" }
            TbButton { glyph: "list"; label: "List view" }
            Item { width: 6; height: 1 }
            SearchPill { width: 150 }
        }
        Rectangle { y: 52; width: parent.width; height: 0.5; color: Theme.line2 }

        GridView {
            id: grid
            x: 14; y: 64; width: parent.width - 28; height: parent.height - 64 - 30
            cellWidth: 112; cellHeight: 112
            clip: true
            model: files
            add: Transition { NumberAnimation { property: "scale"; from: 0.4; to: 1; duration: 380; easing.type: Easing.OutQuint } NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            remove: Transition { NumberAnimation { property: "scale"; to: 0.3; duration: 260; easing.type: Easing.InCubic } NumberAnimation { property: "opacity"; to: 0; duration: 260 } }
            displaced: Transition { NumberAnimation { properties: "x,y"; duration: 380; easing.type: Easing.OutCubic } }
            delegate: Item {
                id: tile
                required property int index
                required property string name
                required property string kind
                required property int inside
                required property bool editing
                property bool aiDropTarget: false
                readonly property string aiIcon: Art.fileIcon(kind)
                property string aiName: editing ? "" : name
                property string aiRole: kind === "folder" ? "folder" : "listitem"
                function aiActivate() { app.selIndex = index; }
                Accessible.role: Accessible.ListItem
                Accessible.name: name
                width: 104; height: 104
                Rectangle {
                    x: 20; y: 4; width: 64; height: 64; radius: 10
                    color: tile.aiDropTarget ? Theme.selStrong : app.selIndex === tile.index ? Theme.sel : "transparent"
                    border.color: tile.aiDropTarget ? Theme.line3 : "transparent"; border.width: 1.5
                    scale: tile.aiDropTarget ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                    Image { anchors.centerIn: parent; width: 52; height: 52; sourceSize: Qt.size(104, 104); source: Art.fileIcon(tile.kind); smooth: true }
                }
                Rectangle {
                    visible: !tile.editing
                    anchors.horizontalCenter: parent.horizontalCenter; y: 72
                    width: Math.min(100, label.implicitWidth + 10); height: label.height + 2; radius: 4
                    color: app.selIndex === tile.index ? Theme.selStrong : "transparent"
                    Text { id: label; anchors.centerIn: parent; width: Math.min(96, implicitWidth); text: tile.name; elide: Text.ElideMiddle; horizontalAlignment: Text.AlignHCenter; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
                }
                Text {
                    visible: tile.kind === "folder" && tile.inside > 0
                    anchors.horizontalCenter: parent.horizontalCenter; y: 89
                    text: tile.inside + " item" + (tile.inside > 1 ? "s" : ""); color: Theme.text3; font.family: Theme.font; font.pixelSize: 10
                }
                Rectangle {
                    visible: tile.editing
                    anchors.horizontalCenter: parent.horizontalCenter; y: 70
                    width: 96; height: 22; radius: 4
                    color: Theme.win3; border.color: Theme.line3; border.width: 1
                    Field { id: nameField; anchors.fill: parent; anchors.margins: 2; label: "Folder name"; pixelSize: 12; align: TextInput.AlignHCenter; onAccepted: app.commit(text) }
                }
                MouseArea { anchors.fill: parent; z: -1; onClicked: tile.aiActivate() }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 30; color: Qt.rgba(1, 1, 1, 0.025)
            Rectangle { width: parent.width; height: 0.5; color: Theme.line2 }
            Text { anchors.centerIn: parent; text: files.count + " items, 214.6 GB available"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
        }
    }
}
