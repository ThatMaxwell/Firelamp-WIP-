// Boot splash: the logo and a warm progress bar.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: sp
    property bool aiHidden: true
    signal finished()
    color: "#0e0a08"
    Behavior on opacity { NumberAnimation { duration: 700 } }
    visible: opacity > 0
    Column {
        anchors.centerIn: parent
        spacing: 26
        Item {
            width: 88; height: 102; anchors.horizontalCenter: parent.horizontalCenter
            GlowLogo { anchors.fill: parent; glow: 0.5 }
        }
        Rectangle {
            width: 150; height: 4; radius: 2; color: Qt.rgba(1, 1, 1, 0.1)
            Rectangle {
                id: fill; height: parent.height; radius: 2; width: 0
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.55) } GradientStop { position: 1; color: Theme.text } }
                NumberAnimation on width { to: 150; duration: 1600; easing.type: Easing.OutCubic; onFinished: { sp.opacity = 0; sp.finished(); } }
            }
        }
    }
}
