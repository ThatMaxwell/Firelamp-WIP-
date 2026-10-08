// The browser grid first boot and Settings › Browser share: group chips, a search field, and
// a tile per browser. Tiles are neutral monograms, never brand logos and never orange. When
// the filter changes, tiles glide to their new places instead of popping.
import QtQuick
import "../js/browsers.js" as B

Item {
    id: bp
    property string selected: "firefox"
    property int group: 0
    property string query: search.text.toLowerCase().trim()
    property int minTile: 236
    readonly property int cols: Math.max(2, Math.floor((width + gap) / (minTile + gap)))
    readonly property int gap: 10
    readonly property real tileW: (width - (cols - 1) * gap) / cols
    readonly property int tileH: 64
    readonly property var shown: B.BROWSERS.filter(function (b) {
        if (bp.group > 0 && b.group !== B.GROUPS[bp.group]) return false;
        if (!bp.query) return true;
        return (b.name + " " + b.what + " " + b.group).toLowerCase().indexOf(bp.query) >= 0;
    }).map(function (b) { return b.id; })
    signal chosen(string id)
    function select(id) { selected = id; chosen(id); }
    function scrollTo(y) { fl.contentY = Math.max(0, Math.min(y, fl.contentHeight - fl.height)); }

    Segmented {
        id: chips
        options: B.GROUPS; current: bp.group
        onPicked: (i) => bp.group = i
    }
    Rectangle {
        id: box
        anchors.right: parent.right; width: Math.min(220, bp.width - chips.width - 16); height: 26; radius: 7
        color: Theme.surface0; border.color: search.input.activeFocus ? Theme.line2 : Theme.hairline; border.width: 1
        Glyph { x: 8; anchors.verticalCenter: parent.verticalCenter; name: "search"; width: 12; height: 12; color: Theme.text3 }
        Field { id: search; x: 26; width: parent.width - 34; height: parent.height; pixelSize: 12; label: "Search browsers"; placeholder: "Search 22 browsers" }
    }

    Flickable {
        id: fl
        y: 42; width: parent.width; height: parent.height - y
        contentHeight: Math.ceil(bp.shown.length / bp.cols) * (bp.tileH + bp.gap) + 4
        clip: true; boundsBehavior: Flickable.StopAtBounds
        Behavior on contentHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Repeater {
            model: B.BROWSERS
            Rectangle {
                id: tile
                required property var modelData
                readonly property int slot: bp.shown.indexOf(modelData.id)
                readonly property var st: Os.browserStatus[modelData.id] || {}
                readonly property bool on: bp.selected === modelData.id
                readonly property bool working: st.state === "installing"
                readonly property bool isDefault: Os.defaultBrowser === modelData.id
                readonly property bool have: !!modelData.included || !!st.installed
                property string aiName: modelData.name; property string aiRole: "radio"
                function aiActivate() { bp.select(modelData.id); }
                // hidden tiles keep their last slot so they fade where they were
                property int lastSlot: 0
                onSlotChanged: if (slot >= 0) lastSlot = slot
                Component.onCompleted: lastSlot = Math.max(0, slot)
                x: (lastSlot % bp.cols) * (bp.tileW + bp.gap)
                y: Math.floor(lastSlot / bp.cols) * (bp.tileH + bp.gap)
                width: bp.tileW; height: bp.tileH; radius: 12
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                opacity: slot >= 0 ? 1 : 0; visible: opacity > 0
                scale: (slot >= 0 ? 1 : 0.96) * (ma.pressed ? 0.985 : 1)
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                color: on ? Theme.surface2 : Qt.rgba(1, 1, 1, 0.03)
                border.color: on ? Theme.text : Theme.hairline2; border.width: on ? 1.5 : 1
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on border.color { ColorAnimation { duration: 160 } }
                MouseArea { id: ma; anchors.fill: parent; enabled: tile.slot >= 0; onClicked: tile.aiActivate() }

                Rectangle {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; width: 40; height: 40; radius: 10
                    color: Theme.surface3; border.color: Theme.hairline; border.width: 1
                    Text { anchors.centerIn: parent; text: B.mono(tile.modelData); color: tile.on ? Theme.text : Theme.text2
                           font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold; font.letterSpacing: -0.3 }
                }
                Column {
                    x: 64; anchors.verticalCenter: parent.verticalCenter; width: parent.width - x - 12; spacing: 3
                    Text { width: parent.width - 44; elide: Text.ElideRight; text: tile.modelData.name; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: tile.working ? (tile.st.log || "Installing…")
                            : tile.isDefault ? "Your default"
                            : tile.modelData.what
                        color: Theme.text3; font.family: Theme.font; font.pixelSize: 11
                    }
                }
                // corner: a check when picked, else where it comes from
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 10; y: 10
                    width: 16; height: 16; radius: 8
                    color: tile.on ? Theme.text : "transparent"; border.color: tile.on ? Theme.text : Theme.text4; border.width: 1
                    opacity: tile.on || ma.pressed ? 1 : 0.0
                    scale: tile.on ? 1 : 0.7
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Glyph { anchors.centerIn: parent; name: "check"; width: 9; height: 9; color: Theme.bg }
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 12; y: 8
                    visible: !tile.on
                    text: tile.modelData.included ? "Included" : tile.have ? "Installed" : ({ flatpak: "Flathub", aur: "AUR", repo: "" })[tile.modelData.via]
                    color: Theme.text4; font.family: Theme.font; font.pixelSize: 9; font.weight: Font.Medium; font.letterSpacing: 0.3
                }
                // installing: the quiet hairline used across Settings
                Item {
                    visible: tile.working; clip: true
                    x: 12; width: parent.width - 24; height: 1; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                    Rectangle { width: parent.width * 0.3; height: 1; color: Theme.text3
                        SequentialAnimation on x { running: tile.working; loops: Animation.Infinite
                            NumberAnimation { from: -width; to: parent.width; duration: 1400; easing.type: Easing.InOutSine } } }
                }
            }
        }
        Text {
            visible: bp.shown.length === 0
            y: 24; width: fl.width; horizontalAlignment: Text.AlignHCenter
            text: "No browser called “" + search.text + "”. The AUR has more: paru -Ss " + search.text
            color: Theme.text3; font.family: Theme.font; font.pixelSize: 12
        }
    }
}
