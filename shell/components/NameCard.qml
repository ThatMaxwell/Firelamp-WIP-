// First boot: name your assistant. There is no default name.
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

Item {
    id: nc
    property bool shown: false
    property bool aiHidden: true
    signal done()
    anchors.fill: parent
    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } }
    onShownChanged: if (shown) field.input.forceActiveFocus()
    function finish() {
        if (!field.text.trim()) return;
        Os.settings.assistantName = field.text.trim();
        shown = false;
        done();
    }

    Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.02, 0.55) }
    MouseArea { anchors.fill: parent }
    Item {
        width: 420; height: 380
        anchors.centerIn: parent
        scale: nc.shown ? 1 : 0.96
        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
        RectangularShadow { anchors.fill: bg; radius: 18; blur: 80; offset.y: 30; color: Qt.rgba(0, 0, 0, 0.8) }
        Rectangle { id: bg; anchors.fill: parent; radius: 18; color: Qt.rgba(0.125, 0.125, 0.12, 0.97); border.color: Qt.rgba(1, 1, 1, 0.12); border.width: 0.5 }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 34; width: 352; spacing: 0
            Logo { width: 64; height: 74; animated: nc.shown; anchors.horizontalCenter: parent.horizontalCenter }
            Item { width: 1; height: 18 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Name your assistant"; color: Theme.text; font.family: Theme.font; font.pixelSize: 21; font.weight: Font.DemiBold }
            Item { width: 1; height: 8 }
            Text { width: 300; anchors.horizontalCenter: parent.horizontalCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: "It will answer to this name, and you’ll see it on its fire cursor whenever it’s working."; color: Theme.text2; font.family: Theme.font; font.pixelSize: 13 }
            Item { width: 1; height: 18 }
            Item {
                width: 250; height: 50; anchors.horizontalCenter: parent.horizontalCenter
                Field { id: field; anchors.fill: parent; align: TextInput.AlignHCenter; pixelSize: 26; textColor: Theme.text; placeholder: "Type a name"; input.font.weight: Font.DemiBold; input.maximumLength: 24; onAccepted: nc.finish() }
                // a hand-drawn underline that boils
                Shape {
                    id: ul
                    property int frame: 0
                    y: 46; width: 250; height: 10
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.ink; strokeWidth: 2.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                        PathSvg { path: ["M3 6 C 60 2, 120 9, 180 5 S 240 4, 247 6", "M3 5 C 62 3, 118 8, 181 6 S 238 3, 247 5", "M3 6 C 58 4, 122 8, 179 4 S 241 5, 247 7"][ul.frame] }
                    }
                    Timer { running: nc.shown; interval: 140; repeat: true; onTriggered: ul.frame = (ul.frame + 1) % 3 }
                }
            }
            Item { width: 1; height: 26 }
            FButton { width: 352; height: 34; primary: true; text: "Continue"; enabledState: field.text.trim() !== ""; onClicked: nc.finish() }
        }
    }
}
