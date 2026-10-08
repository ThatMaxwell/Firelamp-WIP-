// Firelamp's login screen (SDDM, Qt 6). The time, the user, one password field. The session
// sits in the lower-left corner as plain text, so picking GNOME or niri is a click away
// without competing with the field. Colours match the shell's tokens (shell/components/Theme.qml).
import QtQuick

Rectangle {
    id: root
    width: 1440; height: 900
    color: "#121110"

    readonly property color text1: "#EFEAE4"
    readonly property color text2: "#ABA49C"
    readonly property color text3: "#76706A"
    readonly property color surface: "#1F1D1B"
    readonly property color hairline: Qt.rgba(1, 244 / 255, 232 / 255, 0.10)
    readonly property string font: "Instrument Sans"
    FontLoader { source: "fonts/InstrumentSans-Regular.ttf" }
    FontLoader { source: "fonts/InstrumentSans-Medium.ttf" }
    FontLoader { source: "fonts/InstrumentSans-SemiBold.ttf" }

    // the models, copied into plain lists so bindings follow them
    property var userList: []
    property var sessionList: []
    function put(list, i, v) { var a = list.slice(); a[i] = v; return a; }
    property int sessionIndex: {
        // the last session used, else the theme's default (Plasma)
        if (sessionModel.lastIndex >= 0) return sessionModel.lastIndex;
        for (var i = 0; i < sessionList.length; i++)
            if (sessionList[i] && sessionList[i].file.indexOf(config.defaultSession || "plasma") === 0) return i;
        return 0;
    }
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property bool failed: false

    function login() {
        if (!userName.text) return;
        root.failed = false;
        sddm.login(userName.text, pw.text, root.sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() { root.failed = true; pw.text = ""; shake.restart(); pw.forceActiveFocus(); }
    }

    // graphite, with the same faint lamp glow low on the left as the desktop
    gradient: Gradient {
        GradientStop { position: 0; color: "#141312" }
        GradientStop { position: 1; color: "#0f0e0d" }
    }
    Image {
        width: root.height * 2.2; height: root.height * 1.7
        x: -width / 2 + root.width * 0.08; y: -height / 2 + root.height * 1.05
        sourceSize: Qt.size(256, 200)
        source: "data:image/svg+xml;utf8," + encodeURIComponent(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 200"><defs><radialGradient id="g" cx=".5" cy=".5" r=".5">'
            + '<stop offset="0" stop-color="#2a221c" stop-opacity="1"/><stop offset=".35" stop-color="#2a221c" stop-opacity=".62"/>'
            + '<stop offset=".7" stop-color="#2a221c" stop-opacity=".18"/><stop offset="1" stop-color="#2a221c" stop-opacity="0"/>'
            + '</radialGradient></defs><rect width="256" height="200" fill="url(#g)"/></svg>')
    }
    Image { anchors.fill: parent; source: "grain.png"; fillMode: Image.Tile; opacity: 0.06; smooth: false }

    // the time, large and light, like the lock screen
    Column {
        anchors.horizontalCenter: parent.horizontalCenter; y: root.height * 0.13; spacing: 4
        Text { id: clock; anchors.horizontalCenter: parent.horizontalCenter; color: root.text1; font.family: root.font; font.pixelSize: 84; font.weight: Font.Normal; font.letterSpacing: -2 }
        Text { id: date; anchors.horizontalCenter: parent.horizontalCenter; color: root.text2; font.family: root.font; font.pixelSize: 17; font.weight: Font.Medium }
        Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: { var d = new Date(); clock.text = ((d.getHours() + 11) % 12 + 1) + Qt.formatTime(d, ":mm"); date.text = Qt.formatDate(d, "dddd, MMMM d"); } }
    }

    // who is signing in: the last user, with a quiet way to switch when there are several
    Repeater { id: users; model: userModel
        Item { required property int index; required property string name; required property string realName; required property string icon; visible: false
               Component.onCompleted: root.userList = root.put(root.userList, index, { name: name, realName: realName, icon: icon }) } }
    Column {
        id: who
        anchors.horizontalCenter: parent.horizontalCenter; y: root.height * 0.56; spacing: 14
        readonly property var u: root.userList[root.userIndex]
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72; height: 72; radius: 36; color: root.surface; border.color: root.hairline; border.width: 1; clip: true
            Text { anchors.centerIn: parent; visible: face.status !== Image.Ready
                   text: (who.u ? (who.u.realName || who.u.name) : "?").charAt(0).toUpperCase()
                   color: root.text1; font.family: root.font; font.pixelSize: 28; font.weight: Font.Medium }
            Image { id: face; anchors.fill: parent; source: who.u && who.u.icon ? "file://" + who.u.icon : ""; fillMode: Image.PreserveAspectCrop }
        }
        Text {
            id: userName
            readonly property string full: who.u ? (who.u.realName || who.u.name) : ""
            text: who.u ? who.u.name : ""
            visible: false
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: userName.full; color: root.text1; font.family: root.font; font.pixelSize: 17; font.weight: Font.DemiBold
            MouseArea { anchors.fill: parent; enabled: root.userList.length > 1; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.userIndex = (root.userIndex + 1) % root.userList.length }
        }
        // the one field
        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: 240; height: 34; radius: 17
            color: Qt.rgba(1, 1, 1, 0.07); border.color: pw.activeFocus ? Qt.rgba(1, 244 / 255, 232 / 255, 0.22) : root.hairline; border.width: 1
            SequentialAnimation on anchors.horizontalCenterOffset {
                id: shake; running: false
                NumberAnimation { to: -7; duration: 60; easing.type: Easing.OutQuad }
                NumberAnimation { to: 6; duration: 80; easing.type: Easing.InOutQuad }
                NumberAnimation { to: -3; duration: 80; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0; duration: 90; easing.type: Easing.OutQuad }
            }
            TextInput {
                id: pw
                x: 16; width: parent.width - 52; anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password; passwordCharacter: "●"; font.letterSpacing: text ? 2 : 0
                color: root.text1; font.family: root.font; font.pixelSize: 14
                selectionColor: Qt.rgba(1, 1, 1, 0.2); clip: true; focus: true
                onAccepted: root.login()
                onTextChanged: if (text) root.failed = false
                Text { visible: !pw.text; anchors.verticalCenter: parent.verticalCenter; text: "Password"; color: root.text3; font: pw.font }
            }
            // enter: a small cream disc with an arrow, only once something is typed
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter
                width: 24; height: 24; radius: 12; color: root.text1
                opacity: pw.text ? 1 : 0; scale: pw.text ? 1 : 0.8
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -1; text: "→"; color: "#121110"; font.family: root.font; font.pixelSize: 14; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; onClicked: root.login() }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.failed ? "That password didn’t work." : keyboard && keyboard.capsLock ? "Caps Lock is on" : " "
            color: root.text2; font.family: root.font; font.pixelSize: 12
        }
    }

    // the session, as plain text in the corner; it opens upward into a short list
    Repeater { model: sessionModel
        Item { required property int index; required property string name; required property string file; visible: false
               Component.onCompleted: root.sessionList = root.put(root.sessionList, index, { name: name, file: file }) } }
    Item {
        id: sess
        x: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        width: Math.max(cur.width, menu.width); height: cur.height
        property bool open: false
        Row {
            id: cur; spacing: 6
            Text { text: root.sessionList[root.sessionIndex] ? root.sessionList[root.sessionIndex].name : ""; color: root.text2; font.family: root.font; font.pixelSize: 13 }
            Text { text: sess.open ? "⌃" : "⌄"; color: root.text3; font.family: root.font; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: sess.open ? 3 : -3 }
        }
        MouseArea { anchors.fill: cur; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: { sess.open = !sess.open; pw.forceActiveFocus(); } }
        Column {
            id: menu
            anchors.bottom: cur.top; anchors.bottomMargin: 12; spacing: 9
            opacity: sess.open ? 1 : 0; visible: opacity > 0
            transform: Translate { y: sess.open ? 0 : 6; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Repeater {
                model: sessionModel
                Text {
                    required property string name
                    required property int index
                    text: name
                    color: index === root.sessionIndex ? root.text1 : root.text3
                    font.family: root.font; font.pixelSize: 13; font.weight: index === root.sessionIndex ? Font.Medium : Font.Normal
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.sessionIndex = parent.index; sess.open = false; pw.forceActiveFocus(); } }
                }
            }
        }
    }

    // power, the same way, lower right
    Row {
        anchors.right: parent.right; anchors.rightMargin: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 24; spacing: 22
        Text { visible: sddm.canReboot; text: "Restart"; color: root.text3; font.family: root.font; font.pixelSize: 13
               MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: sddm.reboot() } }
        Text { visible: sddm.canPowerOff; text: "Shut Down"; color: root.text3; font.family: root.font; font.pixelSize: 13
               MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: sddm.powerOff() } }
    }

    Component.onCompleted: pw.forceActiveFocus()
}
