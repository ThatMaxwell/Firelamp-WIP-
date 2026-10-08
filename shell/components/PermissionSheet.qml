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

    function ask(req, cb) { request = req; callback = cb; shown = true; card.forceActiveFocus(); }
    function answer(ok) { if (!shown) return; shown = false; var cb = callback; callback = null; if (cb) cb(ok); }

    // dim + blur everything behind
    Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.02, 0.5) }
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Item {
        id: card
        width: 420; height: col.implicitHeight + 42
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.menubarH + 80 + (ps.shown ? 0 : -8)
        scale: ps.shown ? 1 : 0.94
        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Keys.onEscapePressed: ps.answer(false)

        RectangularShadow { anchors.fill: bg; radius: 14; blur: 60; offset.y: 24; color: Qt.rgba(0, 0, 0, 0.6) }
        Rectangle { id: bg; anchors.fill: parent; radius: 14; color: Theme.surface1; border.color: Theme.hairline2; border.width: 1 }

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
