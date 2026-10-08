// Terminal: a small shell with `fetch` and `tree`, the live UI tree the AI reads, as text.
import QtQuick
import "../components"
import "../js/uitree.js" as Tree

Rectangle {
    id: app
    property var win
    color: Theme.bg
    readonly property string prompt: "<font color=\"#7FB98A\">carrot@firelamp</font> <font color=\"#ABA49C\">~</font> <font color=\"#76706A\">%</font> "
    function start(opts) {
        echo("<font color=\"#5f5c59\">Last login: " + new Date().toDateString() + " on ttys001</font>");
        run("fetch", true);
        echo("<font color=\"#5f5c59\">Type</font> <font color=\"#e8e4e0\">help</font> <font color=\"#5f5c59\">to see commands.</font>");
    }
    function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
    function echo(html) { out.append({ kind: "text", html: html.replace(/\n/g, "<br>") }); Qt.callLater(lv.positionViewAtEnd); }
    function c(t) { return "<font color=\"#e8e4e0\">" + t + "</font>"; }
    function d(t) { return "<font color=\"#5f5c59\">" + t + "</font>"; }
    function a(t) { return "<font color=\"#9aa6b2\">" + t + "</font>"; }

    function run(line, quiet) {
        if (!quiet) echo(prompt + esc(line));
        var parts = line.trim().split(/\s+/), cmd = parts.shift(), rest = parts.join(" ");
        if (!cmd) return;
        if (cmd === "help") echo(c("fetch") + "   system info          " + c("tree") + "   the live UI tree the AI reads\n" + c("ask") + " …   hand a task to " + esc(Os.name) + "   " + c("whoami") + " " + c("date") + " " + c("clear"));
        else if (cmd === "clear") out.clear();
        else if (cmd === "whoami") echo("carrot");
        else if (cmd === "date") echo(new Date().toString());
        else if (cmd === "fetch") { out.append({ kind: "fetch", html: "" }); Qt.callLater(lv.positionViewAtEnd); }
        else if (cmd === "tree") {
            var lines = [];
            Tree.snapshot(Os.root).forEach(function (g) {
                lines.push(a("app") + " " + c("“" + esc(g.name) + "”") + " " + d(g.children.length + " elements"));
                var n = Math.min(g.children.length, 12);
                for (var j = 0; j < n; j++) {
                    var e = g.children[j], b = e.bounds;
                    lines.push(d(j === n - 1 ? "└─ " : "├─ ") + esc(e.role) + " " + c("“" + esc(e.name) + "”") + " " + d(b.x + "," + b.y + " " + b.w + "×" + b.h));
                }
                if (g.children.length > 12) lines.push(d("   … " + (g.children.length - 12) + " more"));
            });
            echo(lines.join("\n"));
        }
        else if (cmd === "ask") { if (!rest) return echo("usage: ask &lt;something to do&gt;"); Os.submit(rest); echo("<font color=\"#8fe0a0\">→</font> handed to " + esc(Os.name) + ". Watch the fire cursor."); }
        else echo("<font color=\"#ff7b68\">hearth:</font> command not found: " + esc(cmd));
    }

    ListModel { id: out }
    ListView {
        id: lv
        x: 14; y: 8; width: parent.width - 28; height: parent.height - 44
        clip: true
        model: out
        boundsBehavior: Flickable.StopAtBounds
        delegate: Loader {
            required property string kind
            required property string html
            width: lv.width
            sourceComponent: kind === "fetch" ? fetchComp : textComp
            property string body: html
        }
    }
    Component {
        id: textComp
        Text { width: lv.width; text: parent ? parent.body : ""; textFormat: Text.StyledText; wrapMode: Text.WrapAnywhere; color: Theme.text; font.family: Theme.mono; font.pixelSize: 12; font.weight: Font.Light; lineHeight: 1.45 }
    }
    Component {
        id: fetchComp
        Row {
            spacing: 22; topPadding: 10; bottomPadding: 10; leftPadding: 4
            Logo { width: 62; height: 90; anchors.verticalCenter: parent.verticalCenter }
            Column {
                spacing: 1
                Repeater {
                    model: [
                        "<font color=\"#7FB98A\">carrot</font>@<font color=\"#7FB98A\">firelamp</font>",
                        "<font color=\"#5f5c59\">──────────────────</font>",
                        "<font color=\"#9aa6b2\">OS</font>        Firelamp OS 0.1 “Kindling” x86_64",
                        "<font color=\"#9aa6b2\">Base</font>      Arch Linux",
                        "<font color=\"#9aa6b2\">Shell</font>     Hearth (Qt Quick on Wayland)",
                        "<font color=\"#9aa6b2\">Assistant</font> " + app.esc(Os.name) + " · LLM brain + Jev reflexes",
                        "<font color=\"#9aa6b2\">UI tree</font>   AT-SPI2, live",
                        "<font color=\"#9aa6b2\">Cursors</font>   2 (yours + the fire one)"
                    ]
                    Text { required property string modelData; text: modelData.replace(/ /g, "&nbsp;"); textFormat: Text.StyledText; color: Theme.text; font.family: Theme.mono; font.pixelSize: 12; font.weight: Font.Light; lineHeight: 1.45 }
                }
                Row {
                    topPadding: 6; spacing: 0
                    Repeater { model: ["#121110", "#1F1D1B", "#312E2B", "#76706A", "#EFEAE4", "#F26A2E"]; Rectangle { required property string modelData; width: 20; height: 12; color: modelData } }
                }
            }
        }
    }

    // input line
    Row {
        x: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; width: parent.width - 28
        Text { id: pr; text: app.prompt; textFormat: Text.StyledText; font.family: Theme.mono; font.pixelSize: 12; font.weight: Font.Light; anchors.verticalCenter: parent.verticalCenter }
        Field {
            id: cmd
            width: parent.width - pr.width; height: 20
            label: "Command"
            pixelSize: 12
            input.font.family: Theme.mono
            input.font.weight: Font.Light
            onAccepted: { var t = text; text = ""; app.run(t); }
            Component.onCompleted: input.forceActiveFocus()
        }
    }
    MouseArea { anchors.fill: parent; z: -1; onPressed: cmd.input.forceActiveFocus() }
}
