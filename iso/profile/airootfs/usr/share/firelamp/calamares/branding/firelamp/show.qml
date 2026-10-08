import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() { presentation.goToNextSlide(); }
    Timer { interval: 8000; running: presentation.activatedInCalamares; repeat: true; onTriggered: nextSlide() }

    component Card: Slide {
        property string heading
        property string body
        Rectangle { anchors.fill: parent; color: "#140d0b" }
        Column {
            anchors.centerIn: parent
            width: parent.width * 0.75
            spacing: 14
            Image { source: "logo.png"; width: 72; height: 72; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: heading; color: "#f7ebe2"; font.pixelSize: 26; font.weight: Font.DemiBold
                   anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: body; color: "#b89f91"; font.pixelSize: 15; wrapMode: Text.WordWrap
                   width: parent.width; horizontalAlignment: Text.AlignHCenter }
        }
    }

    Card { heading: "Welcome to Firelamp OS"; body: "An operating system built so your AI can use the computer the way you do, with its own fire cursor beside yours." }
    Card { heading: "You stay in control"; body: "The AI asks before anything risky, logs every action in a timeline, and stops the moment you say so." }
    Card { heading: "Fast underneath"; body: "The CachyOS kernel and tuned defaults keep everything snappy, and KDE Plasma is yours to customise." }
    Card { heading: "Make it yours"; body: "Try GNOME, COSMIC, Hyprland, niri or Sway from Settings > Desktops with one click." }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }
}
