// Notification banners, top right.
import QtQuick
import QtQuick.Effects
import "../js/art.js" as Art

Column {
    id: toasts
    spacing: 10
    property bool aiHidden: true
    width: 344
    ListModel { id: model }
    Connections {
        target: Os
        function onToast(icon, title, body) { model.insert(0, { icon: icon, title: title, body: body }); }
    }
    Repeater {
        model: model
        delegate: Item {
            id: t
            required property int index
            required property string icon
            required property string title
            required property string body
            width: 344; height: Math.max(60, txt.implicitHeight + 24)
            property real slide: 24
            Component.onCompleted: { slide = 0; life.start(); }
            // in: slide 24px and fade, 300 ms; out: fade, 180 ms
            opacity: slide === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: t.slide === 0 ? 300 : 180; easing.type: Easing.OutQuint } }
            transform: Translate { x: t.slide; Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } } }
            Timer { id: life; interval: 4200; onTriggered: { t.slide = 12; gone.start(); } }
            Timer { id: gone; interval: 220; onTriggered: model.remove(t.index) }
            RectangularShadow { anchors.fill: tb; radius: 14; blur: 30; offset.y: 10; color: Qt.rgba(0, 0, 0, 0.4) }
            Rectangle { id: tb; anchors.fill: parent; radius: 14; color: Theme.surface1; border.color: Theme.hairline2; border.width: 1 }
            // the same row as Control Center: a 30 px mark, a title, one line under it
            Image { x: 16; y: 14; width: 30; height: 30; sourceSize: Qt.size(60, 60); source: Art.icon(t.icon) }
            Column {
                id: txt
                x: 58; y: 12; width: parent.width - 58 - 54
                Text { text: t.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Medium }
                Text { width: parent.width; text: t.body; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; color: Theme.text3; font.family: Theme.font; font.pixelSize: 12; lineHeight: 1.1 }
            }
            Text { anchors.right: parent.right; anchors.rightMargin: 14; y: 13; text: "now"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
        }
    }
}
