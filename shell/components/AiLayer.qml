// The AI's own layer above every window, so the fire cursor stays visible over real apps.
// It only draws: clicks go straight through it and it never takes focus.
// (On Plasma Wayland, AiLayerShell.qml puts the same layer on the compositor's overlay layer.)
import QtQuick
import QtQuick.Window

Window {
    title: "Firelamp AI layer"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowTransparentForInput
           | Qt.WindowDoesNotAcceptFocus | Qt.BypassWindowManagerHint
    color: "transparent"
    x: 0; y: 0
    width: Screen.width; height: Screen.height
    visible: false
}
