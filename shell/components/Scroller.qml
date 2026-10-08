// A thin, warm scroll indicator for any Flickable.
import QtQuick

Rectangle {
    property Flickable flick
    visible: flick && flick.contentHeight > flick.height + 1
    anchors.right: flick ? flick.right : undefined
    anchors.rightMargin: 3
    width: 4; radius: 2
    color: Qt.rgba(1, 1, 1, 0.22)
    opacity: flick && flick.moving ? 1 : 0.35
    Behavior on opacity { NumberAnimation { duration: 300 } }
    y: flick ? flick.y + flick.visibleArea.yPosition * flick.height : 0
    height: flick ? Math.max(24, flick.visibleArea.heightRatio * flick.height) : 0
}
