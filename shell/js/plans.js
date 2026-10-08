// The "brain". On the real system an LLM turns what you asked into a plan; in this build
// a few plans are written out by hand so the whole loop can be seen end to end.
// Each step names its target the way the UI tree labels it, plus the reason it's taken.
.pragma library

// Suggestions come from what is actually on the machine: today's note, a messy Downloads.
var SUGGESTIONS = [
    { text: "Email Ana my meeting notes", icon: "sent", hint: "From today’s launch sync" },
    { text: "Tidy up my Downloads", icon: "folder", hint: "10 loose files" },
    { text: "Show me what you see", icon: "eye", hint: "The live UI tree" }
];

// Multi-step or risky plans are shown first as short numbered lines ("Go" / "Edit").
// Each line is a milestone: `plan` is how it reads before, `done` how it reads after.
// Steps carry { op: "milestone", i } markers so the timeline can group under them.
function M(i) { return { op: "milestone", i: i }; }

var emailNotes = {
    label: "Emailing Ana the meeting notes",
    intro: "Here’s my plan. I’ll check with you before anything is sent.",
    lines: function () {
        return [
            { plan: "Copy today’s launch notes from Notes", done: "Copied the launch notes" },
            { plan: "Write an email to Ana with the notes", done: "Wrote the email to Ana" },
            { plan: "Ask you before sending", done: "You said yes" },
            { plan: "Send it", done: "Sent the email to Ana" }
        ];
    },
    steps: function () {
        var notes = "";
        return [
            M(0),
            { op: "open", app: "notes", why: "The meeting notes live in Notes." },
            { op: "click", target: { name: "Launch sync — Oct 7", app: "notes" }, why: "That's the note from today's meeting." },
            { op: "read", target: { name: "Note body", app: "notes", say: "the note" }, done: function (text) {
                notes = text.split("\n").filter(function (l) { return l.indexOf("•") === 0; }).join("\n");
            }, title: "Read “Launch sync — Oct 7”", why: "Copied the bullet points so I can paste them into the email." },
            M(1),
            { op: "open", app: "mail", why: "To write the email." },
            { op: "click", target: { name: "Compose", app: "mail" }, why: "Starting a new email." },
            { op: "type", target: { name: "To", app: "mail" }, text: "ana.souza@hearth.mail", why: "Ana is the one who asked for the notes." },
            { op: "type", target: { name: "Subject", app: "mail" }, text: "Notes from today’s launch sync", why: "A clear subject so she can find it later." },
            { op: "type", target: { name: "Message body", app: "mail", say: "the message" }, cps: 160, why: "Pasted the notes with a short hello.",
              text: function () { return "Hi Ana,\n\nHere are the notes from today’s sync:\n\n" + notes + "\n\nTalk soon!"; } },
            M(2),
            { op: "confirm", why: "You asked me to email Ana the notes.", logTitle: "Asked you before sending",
              request: { app: "mail", title: "Send “Notes from today’s launch sync” to Ana Souza?", body: "Sending can’t be undone, so Firelamp checks with you first.",
                         details: [["To", "ana.souza@hearth.mail"], ["Subject", "Notes from today’s launch sync"], ["App", "Mail"]], deny: "Don’t Send", allow: "Send" },
              denied: "No problem. I left the draft open so you can look it over." },
            M(3),
            { op: "click", target: { name: "Send", app: "mail", role: "button", does: "sends this" }, why: "You said yes, so I sent it.", title: "Sent the email to Ana" },
            { op: "wait", ms: 400 },
            { op: "say", text: "Sent! Ana has the notes from today’s launch sync." }
        ];
    }
};

function folderSteps(name, files, kind) {
    var s = [
        { op: "click", target: { name: "New Folder", app: "files" }, why: "A folder for " + name.toLowerCase() + ".", title: "Made a new folder",
          undo: function (a) { a.app("files").remove(name); } },
        { op: "type", target: { name: "Folder name", app: "files" }, text: name, why: "Naming it so it’s easy to find.", title: "Named it “" + name + "”" },
        { op: "key", target: { name: "Folder name", app: "files" }, key: "Enter" }
    ];
    files.forEach(function (f) {
        s.push({ op: "drag", src: { name: f, app: "files" }, dst: { name: name, app: "files", role: "folder" }, why: "It’s " + kind + ".",
                 drop: function (a) { a.app("files").move(f, name); }, undo: function (a) { a.app("files").restore(f, name); } });
    });
    return s;
}

var tidy = {
    label: "Tidying up Downloads",
    intro: "Here’s my plan. Each part can be undone from Activity afterwards.",
    // the one obvious fork, asked up front instead of mid-task
    prefs: { q: "There’s an exact copy of “invoice.pdf”. What should I do with it?", options: ["Move it to the Trash", "Leave it"] },
    lines: function (pick) {
        var l = [
            { plan: "Open Downloads in Files", done: "Opened Downloads" },
            { plan: "Put the 3 pictures in a new Images folder", done: "Sorted 3 pictures into Images" },
            { plan: "Put the 3 documents in a new Documents folder", done: "Sorted 3 documents into Documents" }
        ];
        if (!pick) l.push({ plan: "Move the duplicate invoice to the Trash", done: "Moved the duplicate to the Trash" });
        return l;
    },
    steps: function (pick) {
        var s = [
            M(0),
            { op: "open", app: "files", why: "Downloads is in Files." },
            M(1)
        ].concat(folderSteps("Images", ["IMG_2041.jpg", "sunset.png", "IMG_2042.jpg"], "a picture"))
         .concat([M(2)])
         .concat(folderSteps("Documents", ["invoice.pdf", "Launch plan.docx", "notes.txt"], "a document"));
        if (pick) return s.concat([{ op: "say", text: "Done. Downloads now has an Images folder and a Documents folder. I left the duplicate invoice alone." }]);
        return s.concat([
            M(3),
            { op: "confirm", why: "Deleting is risky, so I always ask.", logTitle: "Asked you before deleting",
              request: { app: "files", title: "Move “invoice (1).pdf” to the Trash?", body: "It’s an exact copy of “invoice.pdf”. You can still restore it from the Trash.",
                         details: [["File", "invoice (1).pdf"], ["Size", "48 KB"], ["Where", "Downloads"]], deny: "Keep It", allow: "Move to Trash" },
              denied: "Okay, I kept the duplicate. Everything else is sorted." },
            { op: "drag", src: { name: "invoice (1).pdf", app: "files" }, dst: { name: "Trash", app: "dock" }, why: "You said it was fine to delete.",
              title: "Moved “invoice (1).pdf” to the Trash", drop: function (a) { a.app("files").remove("invoice (1).pdf"); a.trashFull(); },
              undo: function (a) { a.app("files").restore("invoice (1).pdf", ""); a.trashEmpty(); } },
            { op: "say", text: "Done. Downloads now has an Images folder and a Documents folder, and the duplicate is in the Trash." }
        ]);
    }
};

var vision = {
    label: "Showing you what I see",
    steps: function () {
        return [
            { op: "say", text: "Here's how I see the screen: no screenshots, just the live layout. Every element, its role, its label and exactly where it is, updated the moment anything changes." },
            { op: "think", text: "Reading the live UI tree", ms: 600 },
            { op: "vision", on: true },
            { op: "log", kind: "look", title: "Showed you the live UI tree", why: "This is everything I can see and touch.", app: "Firelamp" },
            { op: "open", app: "terminal", why: "The terminal can print the same tree as text." },
            { op: "type", target: { name: "Command", app: "terminal" }, text: "tree", why: "Asking for the tree in text form." },
            { op: "key", target: { name: "Command", app: "terminal" }, key: "Enter" },
            { op: "log", kind: "look", title: "Printed the UI tree", app: "Terminal" },
            { op: "wait", ms: 3200 },
            { op: "say", text: "Turn this view on any time from View → Show what the AI sees." },
            { op: "wait", ms: 1200 },
            { op: "vision", on: false }
        ];
    }
};

var INTENTS = [
    [/\b(e-?mail|mail|send|envi|mand)/i, emailNotes],
    [/\b(tidy|clean|organi[sz]|sort|download|arrum|limp)/i, tidy],
    [/\b(see|vision|look|tree|screen|vê|ver|enxerg)/i, vision]
];

function match(text) {
    for (var i = 0; i < INTENTS.length; i++) if (INTENTS[i][0].test(text)) return INTENTS[i][1];
    return null;
}
