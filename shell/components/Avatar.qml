import QtQuick

Rectangle {
    property string who: ""
    property int seed: 0
    readonly property var grads: [["#ff8a3d", "#e2402a"], ["#ffb547", "#ff7a33"], ["#c8402f", "#7a1f12"], ["#ffd08a", "#ff9f3d"], ["#8a7a70", "#4e4440"]]
    width: 34; height: 34; radius: width / 2
    gradient: Gradient {
        GradientStop { position: 0; color: grads[seed % 5][0] }
        GradientStop { position: 1; color: grads[seed % 5][1] }
    }
    Text {
        anchors.centerIn: parent
        text: who.split(" ").map(function (s) { return s[0] || ""; }).join("").slice(0, 2).toUpperCase()
        color: "white"; font.family: Theme.font; font.pixelSize: parent.width * 0.38; font.weight: Font.DemiBold
    }
}
