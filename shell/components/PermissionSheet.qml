// OS-level permission sheet. Drawn by the shell and hidden from the AI's UI tree, so only
// a human can answer it: the AI can never click "Allow" for itself.
import QtQuick
import QtQuick.Effects

Item {
    id: ps
    property bool aiHidden: true
    property var request: ({})
    property var callback: null
    property bool shown: false
    anchors.fill: parent
    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: ps.shown ? 300 : 180; easing.type: Easing.OutQuint } }

    function ask(req, cb) { request = req; callback = cb; place(); shown = true; card.forceActiveFocus(); }
    function answer(ok) { if (!shown) return; shown = false; var cb = callback; callback = null; if (cb) cb(ok); }

    // the window that asked; the sheet hangs from under its toolbar, like a Mac sheet
    property var host: null
    property rect hr: Qt.rect(0, 0, 0, 0)
    function place() {
        host = request.app && Os.desktop ? Os.desktop.get(request.app) : null;
        if (host && !host.minimized) { var p = host.mapToItem(ps, 0, 0); hr = Qt.rect(p.x, p.y, host.width, host.height); }
        else hr = Qt.rect(0, Theme.menubarH, ps.width, ps.height - Theme.menubarH);
    }
    readonly property bool attached: host !== null
    readonly property int bar: attached ? 52 : 60

    // swallow clicks everywhere while it waits; dim only the window that asked
    MouseArea { anchors.fill: parent; hoverEnabled: true }
    Rectangle {
        x: ps.hr.x; y: ps.hr.y; width: ps.hr.width; height: ps.hr.height
        radius: ps.attached ? Theme.rWin : 0
        color: Qt.rgba(0, 0, 0, ps.attached ? 0.38 : 0.45)
    }

    Item {
        id: slot
        x: ps.hr.x; y: ps.hr.y + ps.bar
        width: ps.hr.width; height: card.height + 40
        clip: true

    Item {
        id: card
        width: Math.min(420, ps.hr.width - 40); height: col.implicitHeight + 42
        x: (slot.width - width) / 2
        property real slide: ps.shown ? 0 : 1
        Behavior on slide { NumberAnimation { duration: ps.shown ? 260 : 180; easing.type: Easing.OutQuint } }
        y: -slide * (height + 2)
        Keys.onEscapePressed: ps.answer(false)

        RectangularShadow { anchors.fill: bg; radius: 12; blur: 30; offset.y: 12; color: Qt.rgba(0, 0, 0, 0.5) }
        Rectangle { id: bg; anchors.fill: parent; radius: 12; color: Theme.surface1; border.color: Theme.hairline2; border.width: 1 }
        // square top edge: the sheet is attached to the toolbar
        Rectangle { visible: ps.attached; width: parent.width; height: 14; color: Theme.surface1
            Rectangle { x: 0; width: 1; height: parent.height; color: Theme.hairline2 }
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline2 } }

        Column {
            id: col
            x: 24; y: 24; width: parent.width - 48
            spacing: 0
            // the only ember on the sheet: who is asking
            Rectangle {
                height: 22; radius: 6; width: badge.implicitWidth + 18
                color: Theme.emberSoft; border.color: Qt.rgba(242 / 255, 106 / 255, 46 / 255, 0.3); border.width: 1
                Row {
                    id: badge; anchors.centerIn: parent; spacing: 6
                    Rectangle { width: 6; height: 6; radius: 3; color: Theme.ember; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: Os.name + " wants to"; color: Theme.text; font.family: Theme.font; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
            }
            Item { width: 1; height: 14 }
            Text { width: parent.width; text: (ps.request.title || "").replace("{name}", Os.name); wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 17; font.weight: Font.DemiBold; lineHeight: 1.1 }
            Item { width: 1; height: 6 }
            Text { width: parent.width; text: ps.request.body || ""; wrapMode: Text.WordWrap; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13; lineHeight: 1.15 }
            Item { width: 1; height: 16 }
            Rectangle {
                width: parent.width; height: det.implicitHeight + 20; radius: 10
                color: Theme.surface0; border.color: Theme.hairline; border.width: 1
                visible: !!ps.request.details
                Column {
                    id: det; x: 12; y: 10; width: parent.width - 24; spacing: 4
                    Repeater {
                        model: ps.request.details || []
                        Row {
                            required property var modelData
                            Text { width: 64; text: modelData[0]; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12 }
                            Text { width: det.width - 64; text: modelData[1]; elide: Text.ElideRight; color: Theme.text; font.family: Theme.font; font.pixelSize: 12 }
                        }
                    }
                }
            }
            Item { width: 1; height: 12 }
            Row {
                spacing: 7; visible: !!ps.request.why
                Text { text: ps.request.why || ""; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
            }
            Item { width: 1; height: 18 }
            Row {
                spacing: 8
                FButton { width: (col.width - 8) / 2; height: 32; text: ps.request.deny || "Don’t Allow"; onClicked: ps.answer(false) }
                FButton { objectName: "permAllow"; width: (col.width - 8) / 2; height: 32; primary: true; text: ps.request.allow || "Allow Once"; onClicked: ps.answer(true) }
            }
            Item { width: 1; height: 12 }
            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Only you can answer this."; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
        }
    }
    }
}
