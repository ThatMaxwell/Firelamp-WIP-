// A small, faithful sketch of what a desktop looks like: its wallpaper, its bars and how it
// lays out windows. Used on Settings › Desktops until real screenshots come from the ISO build.
import QtQuick
import QtQuick.Effects

Item {
    id: t
    property string kind: "plasma"
    property real radius: 8
    // each spec: wallpaper top/bottom, bars [x, y, w, h, color, radius], windows [x, y, w, h, focused],
    // window radius and gap style; everything in fractions of the thumbnail
    readonly property var specs: ({
        plasma:   { wp: ["#2A2522", "#14110F"], winR: 5, title: true,
                    bars: [[0, 0, 1, 0.045, "#0E0C0B", 0], [0.3, 0.88, 0.4, 0.085, "#2B2928", 6]],
                    wins: [[0.12, 0.13, 0.5, 0.62, true], [0.5, 0.22, 0.38, 0.5, false]] },
        gnome:    { wp: ["#1F3B5A", "#0B1626"], winR: 6, title: true,
                    bars: [[0, 0, 1, 0.05, "#000000", 0]], clock: true,
                    wins: [[0.2, 0.14, 0.6, 0.72, true]] },
        cosmic:   { wp: ["#1B3A3E", "#0B1A1C"], winR: 6, title: true,
                    bars: [[0, 0, 1, 0.05, "#16191A", 0], [0.32, 0.9, 0.36, 0.07, "#1E2324", 6]],
                    wins: [[0.03, 0.08, 0.465, 0.79, true], [0.505, 0.08, 0.465, 0.79, false]] },
        xfce:     { wp: ["#3A4A5C", "#1C2530"], winR: 2, title: true, icons: true,
                    bars: [[0, 0, 1, 0.055, "#2E3136", 0]],
                    wins: [[0.28, 0.17, 0.56, 0.62, true]] },
        cinnamon: { wp: ["#33402F", "#171E15"], winR: 4, title: true, icons: true,
                    bars: [[0, 0.93, 1, 0.07, "#202322", 0]], start: true,
                    wins: [[0.24, 0.12, 0.58, 0.68, true]] },
        niri:     { wp: ["#1C1C22", "#101014"], winR: 6, ring: true,
                    bars: [[0, 0, 1, 0.045, "#0A0A0C", 0]],
                    wins: [[-0.18, 0.08, 0.3, 0.88, false], [0.15, 0.08, 0.42, 0.88, true], [0.6, 0.08, 0.32, 0.42, false], [0.6, 0.54, 0.32, 0.42, false], [0.95, 0.08, 0.3, 0.88, false]] },
        hyprland: { wp: ["#2A2340", "#121022"], winR: 7, ring: true,
                    bars: [[0.02, 0.025, 0.96, 0.055, "#14121E", 5]],
                    wins: [[0.02, 0.11, 0.47, 0.86, true], [0.51, 0.11, 0.47, 0.42, false], [0.51, 0.55, 0.47, 0.42, false]] },
        sway:     { wp: ["#2F3B44", "#1A2229"], winR: 0, title: true,
                    bars: [[0, 0.95, 1, 0.05, "#000000", 0]], workspaces: true,
                    wins: [[0, 0, 0.5, 0.95, true], [0.5, 0, 0.5, 0.475, false], [0.5, 0.475, 0.5, 0.475, false]] }
    })
    readonly property var s: specs[kind] || specs.plasma
    // the picture is clipped to the rounded card, so bars meet the corners cleanly
    Rectangle { id: mask; anchors.fill: parent; radius: t.radius; visible: false; layer.enabled: true }
    Rectangle { anchors.fill: parent; radius: t.radius; color: "transparent"; border.color: Theme.hairline; border.width: 1; z: 2 }
    Rectangle {
    anchors.fill: parent
    layer.enabled: true
    layer.effect: MultiEffect { maskEnabled: true; maskSource: mask; maskThresholdMin: 0.5; maskSpreadAtMin: 1 }
    gradient: Gradient {
        GradientStop { position: 0; color: t.s.wp[0] }
        GradientStop { position: 1; color: t.s.wp[1] }
    }
    // desktop icons, for the desktops that keep them
    Column {
        visible: !!t.s.icons; x: t.width * 0.03; y: t.height * 0.1; spacing: t.height * 0.05
        Repeater { model: 3; Rectangle { width: t.width * 0.045; height: width; radius: 2; color: Qt.rgba(1, 1, 1, 0.22) } }
    }
    Repeater {
        model: t.s.wins
        Rectangle {
            required property var modelData
            x: modelData[0] * t.width; y: modelData[1] * t.height
            width: modelData[2] * t.width; height: modelData[3] * t.height
            radius: t.s.winR
            color: modelData[4] ? "#2E2C2B" : "#262423"
            border.width: t.s.ring ? (modelData[4] ? 1.5 : 0) : 0.5
            border.color: t.s.ring ? "#B9C3D6" : Qt.rgba(1, 1, 1, 0.08)
            // title strip with traffic dots, then a few lines of content
            Rectangle { visible: !!t.s.title; width: parent.width; height: Math.max(5, t.height * 0.045); radius: t.s.winR; color: Qt.rgba(1, 1, 1, 0.05) }
            Column {
                x: parent.width * 0.08; y: parent.height * (t.s.title ? 0.2 : 0.12); spacing: Math.max(3, t.height * 0.03)
                Repeater { model: 4
                    Rectangle { required property int index; width: parent.parent.width * [0.7, 0.5, 0.62, 0.38][index]; height: Math.max(2, t.height * 0.016); radius: 1; color: Qt.rgba(1, 1, 1, 0.12) } }
            }
        }
    }
    Repeater {
        model: t.s.bars
        Rectangle {
            required property var modelData
            x: modelData[0] * t.width; y: modelData[1] * t.height
            width: modelData[2] * t.width; height: modelData[3] * t.height
            color: modelData[4]; radius: modelData[5]
        }
    }
    // the details that make each one recognisable
    Rectangle { visible: !!t.s.clock; x: t.width * 0.46; y: t.height * 0.017; width: t.width * 0.08; height: t.height * 0.016; radius: 1; color: Qt.rgba(1, 1, 1, 0.55) }
    Rectangle { visible: !!t.s.start; x: t.width * 0.015; y: t.height * 0.945; width: t.height * 0.04; height: width; radius: width / 2; color: Qt.rgba(1, 1, 1, 0.5) }
    Row {
        visible: !!t.s.workspaces; x: 3; y: t.height * 0.957; spacing: 2
        Repeater { model: 3; Rectangle { required property int index; width: t.height * 0.05; height: t.height * 0.036; color: index === 0 ? "#3B5F7A" : "#222222" } }
    }
    Row {
        visible: t.kind === "plasma" || t.kind === "cosmic"
        anchors.horizontalCenter: parent.horizontalCenter
        y: t.height * (t.kind === "plasma" ? 0.9 : 0.912); spacing: t.width * 0.014
        Repeater { model: t.kind === "plasma" ? 7 : 6
            Rectangle { width: t.height * 0.05; height: width; radius: width * 0.25; color: Qt.rgba(1, 1, 1, 0.3) } }
    }
}
}
