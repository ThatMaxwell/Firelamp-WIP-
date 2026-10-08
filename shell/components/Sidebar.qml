// The translucent sidebar most apps have, with room at the top for the traffic lights.
import QtQuick

Rectangle {
    id: sb
    default property alias content: col.data
    property int topPad: 52
    width: 200
    height: parent ? parent.height : 0
    color: Qt.rgba(1, 1, 1, 0.035)
    Rectangle { anchors.right: parent.right; width: 0.5; height: parent.height; color: Theme.line2 }
    Column { id: col; x: 10; y: sb.topPad; width: sb.width - 20; spacing: 1 }
}
