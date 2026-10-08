import QtQuick

Rectangle {
    property string who: ""
    property int seed: 0
    readonly property var grads: [["#8d8a87", "#5d5a57"], ["#a39a8f", "#6e665d"], ["#7c8590", "#4e5660"], ["#9a8a86", "#62544f"], ["#88908a", "#565e58"]]
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
