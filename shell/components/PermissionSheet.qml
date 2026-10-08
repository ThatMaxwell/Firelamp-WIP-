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
    Behavior on opacity { NumberAnimation { duration: 260 } }

    function ask(req, cb) { request = req; callback = cb; shown = true; card.forceActiveFocus(); }
    function answer(ok) { if (!shown) return; shown = false; var cb = callback; callback = null; if (cb) cb(ok); }

    // dim + blur everything behind
    Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.02, 0.5) }
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Item {
        id: card
        width: 420; height: col.implicitHeight + 42
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.menubarH + 70 + (ps.shown ? 0 : -24)
        scale: ps.shown ? 1 : 0.95
        Behavior on y { NumberAnimation { duration: 480; easing.type: Easing.OutBack } }
        Behavior on scale { NumberAnimation { duration: 480; easing.type: Easing.OutBack } }
        Keys.onEscapePressed: ps.answer(false)

        RectangularShadow { anchors.fill: bg; radius: 18; blur: 80; offset.y: 30; color: Qt.rgba(0, 0, 0, 0.8) }
        Rectangle { id: bg; anchors.fill: parent; radius: 18; color: Qt.rgba(0.125, 0.125, 0.12, 0.97) }
        InkRect { anchors.fill: parent; anchors.margins: -1; radius: 18; color: Theme.ink; lineWidth: 1.5; running: ps.shown }

        Column {
            id: col
            x: 24; y: 24; width: parent.width - 48
            spacing: 0
            Row {
                spacing: 14
                Rectangle {
                    width: 46; height: 46; radius: 13; color: Theme.win4
                    Logo { anchors.centerIn: parent; width: 30; height: 35; animated: ps.shown }
                }
                Column {
                    width: col.width - 60; spacing: 4
                    Text { width: parent.width; text: (ps.request.title || "").replace("{name}", Os.name); wrapMode: Text.WordWrap; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
                    Text { width: parent.width; text: ps.request.body || ""; wrapMode: Text.WordWrap; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
                }
            }
            Item { width: 1; height: 16 }
            Rectangle {
                width: parent.width; height: det.implicitHeight + 20; radius: 10
                color: Qt.rgba(0, 0, 0, 0.25); border.color: Theme.line2; border.width: 0.5
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
                Glyph { name: "sparkle"; width: 13; height: 13; color: Theme.text3; anchors.verticalCenter: parent.verticalCenter }
                Text { text: ps.request.why || ""; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
            }
            Item { width: 1; height: 18 }
            Row {
                spacing: 8
                FButton { width: (col.width - 8) / 2; height: 32; text: ps.request.deny || "Don't Allow"; onClicked: ps.answer(false) }
                FButton { objectName: "permAllow"; width: (col.width - 8) / 2; height: 32; primary: true; text: ps.request.allow || "Allow Once"; onClicked: ps.answer(true) }
            }
            Item { width: 1; height: 12 }
            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Only you can answer this. " + Os.name + " is waiting."; color: Theme.text4; font.family: Theme.font; font.pixelSize: 11 }
        }
    }
}
