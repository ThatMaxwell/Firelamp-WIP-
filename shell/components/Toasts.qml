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
            width: 344; height: 64
            property real slide: 380
            Component.onCompleted: { slide = 0; life.start(); }
            transform: Translate { x: t.slide; Behavior on x { NumberAnimation { duration: 520; easing.type: Easing.OutBack } } }
            Timer { id: life; interval: 4200; onTriggered: { t.slide = 400; gone.start(); } }
            Timer { id: gone; interval: 400; onTriggered: model.remove(t.index) }
            RectangularShadow { anchors.fill: tb; radius: 16; blur: 40; offset.y: 10; color: Qt.rgba(0, 0, 0, 0.55) }
            Rectangle { id: tb; anchors.fill: parent; radius: 16; color: Qt.rgba(0.14, 0.118, 0.106, 0.96); border.color: Qt.rgba(1, 0.93, 0.87, 0.12); border.width: 0.5 }
            Image { x: 14; anchors.verticalCenter: parent.verticalCenter; width: 34; height: 34; sourceSize: Qt.size(68, 68); source: Art.icon(t.icon) }
            Column {
                x: 59; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 110
                Text { text: t.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                Text { width: parent.width; text: t.body; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; color: Theme.text2; font.family: Theme.font; font.pixelSize: 12 }
            }
            Text { anchors.right: parent.right; anchors.rightMargin: 14; y: 12; text: "now"; color: Theme.text3; font.family: Theme.font; font.pixelSize: 11 }
        }
    }
}
