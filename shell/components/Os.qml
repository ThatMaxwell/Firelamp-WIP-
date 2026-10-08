// Shared state and the event bus every part of the shell talks through.
pragma Singleton
import QtQuick
import QtCore

QtObject {
    id: os

    // set by Main.qml once everything exists
    property Item root
    property var desktop
    property var dock
    property var agent
    property var cursor

    // ---- settings (persisted) ----
    property Settings settings: Settings {
        location: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/firelamp/shell.conf"
        property string assistantName: ""      // the user names their assistant; no default
        property bool askBeforeRisky: true
        property real cursorSpeed: 1.0
        property bool idleFade: true
    }
    readonly property string name: settings.assistantName || "Assistant"
    property bool vision: false
    property bool demo: false

    // ---- events ----
    signal say(string text)                       // the assistant says something in chat
    signal log(var entry)                         // {kind, title, why, app} for the timeline
    signal toast(string icon, string title, string body)
    signal submit(string text)                    // a request for the assistant
    signal timelineToggle(var on)
    signal askOpen()
    signal controlToggle()
    signal trashFull()

    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var days: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    function clock(d) {
        var h = d.getHours(), m = d.getMinutes();
        return (h % 12 || 12) + ":" + (m < 10 ? "0" : "") + m + (h < 12 ? " AM" : " PM");
    }
}
