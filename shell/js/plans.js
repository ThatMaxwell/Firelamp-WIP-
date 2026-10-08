// The "brain". On the real system an LLM turns what you asked into a plan; in this build
// a few plans are written out by hand so the whole loop can be seen end to end.
// Each step names its target the way the UI tree labels it, plus the reason it's taken.
.pragma library

var SUGGESTIONS = [
    { text: "Email Ana my meeting notes", icon: "sent" },
    { text: "Tidy up my Downloads", icon: "folder" },
    { text: "Show me what you see", icon: "eye" }
];

var emailNotes = {
    label: "Emailing Ana the meeting notes",
    steps: function () {
        var notes = "";
        return [
            { op: "say", text: "On it. I'll grab today's launch notes and email them to Ana." },
            { op: "think", text: "Planning: Notes, then Mail", ms: 700 },
            { op: "open", app: "notes", why: "The meeting notes live in Notes." },
            { op: "click", target: { name: "Launch sync — Oct 7", app: "notes" }, why: "That's the note from today's meeting." },
            { op: "read", target: { name: "Note body", app: "notes", say: "the note" }, done: function (text) {
                notes = text.split("\n").filter(function (l) { return l.indexOf("•") === 0; }).join("\n");
            }, title: "Read “Launch sync — Oct 7”", why: "Copied the bullet points so I can paste them into the email." },
            { op: "open", app: "mail", why: "To write the email." },
            { op: "click", target: { name: "Compose", app: "mail" }, why: "Starting a new email." },
            { op: "type", target: { name: "To", app: "mail" }, text: "ana.souza@hearth.mail", why: "Ana is the one who asked for the notes." },
            { op: "type", target: { name: "Subject", app: "mail" }, text: "Notes from today’s launch sync", why: "A clear subject so she can find it later." },
            { op: "type", target: { name: "Message body", app: "mail", say: "the message" }, cps: 160, why: "Pasted the notes with a short hello.",
              text: function () { return "Hi Ana,\n\nHere are the notes from today’s sync:\n\n" + notes + "\n\nTalk soon!"; } },
            { op: "confirm", why: "You asked me to email Ana the notes.", logTitle: "Asked you before sending",
              request: { app: "mail", title: "Send “Notes from today’s launch sync” to Ana Souza?", body: "Sending can’t be undone, so Firelamp checks with you first.",
                         details: [["To", "ana.souza@hearth.mail"], ["Subject", "Notes from today’s launch sync"], ["App", "Mail"]], deny: "Don’t Send", allow: "Send" },
              denied: "No problem. I left the draft open so you can look it over." },
            { op: "click", target: { name: "Send", app: "mail", role: "button" }, why: "You said yes, so I sent it.", title: "Sent the email to Ana" },
            { op: "wait", ms: 400 },
            { op: "say", text: "Sent! Ana has the notes from today’s launch sync." }
        ];
    }
};

function folderSteps(name, files, kind) {
    var s = [
        { op: "click", target: { name: "New Folder", app: "files" }, why: "A folder for " + name.toLowerCase() + ".", title: "Made a new folder" },
        { op: "type", target: { name: "Folder name", app: "files" }, text: name, why: "Naming it so it’s easy to find.", title: "Named it “" + name + "”" },
        { op: "key", target: { name: "Folder name", app: "files" }, key: "Enter" }
    ];
    files.forEach(function (f) {
        s.push({ op: "drag", src: { name: f, app: "files" }, dst: { name: name, app: "files", role: "folder" }, why: "It’s " + kind + ".",
                 drop: function (a) { a.app("files").move(f, name); } });
    });
    return s;
}

var tidy = {
    label: "Tidying up Downloads",
    steps: function () {
        return [
            { op: "say", text: "Sure. I'll sort Downloads into folders and clear out the duplicate invoice." },
            { op: "think", text: "Looking at what’s in Downloads", ms: 600 },
            { op: "open", app: "files", why: "Downloads is in Files." }
        ].concat(folderSteps("Images", ["IMG_2041.jpg", "sunset.png", "IMG_2042.jpg"], "a picture"))
         .concat(folderSteps("Documents", ["invoice.pdf", "Launch plan.docx", "notes.txt"], "a document"))
         .concat([
            { op: "confirm", why: "Deleting is risky, so I always ask.", logTitle: "Asked you before deleting",
              request: { app: "files", title: "Move “invoice (1).pdf” to the Trash?", body: "It’s an exact copy of “invoice.pdf”. You can still restore it from the Trash.",
                         details: [["File", "invoice (1).pdf"], ["Size", "48 KB"], ["Where", "Downloads"]], deny: "Keep It", allow: "Move to Trash" },
              denied: "Okay, I kept the duplicate. Everything else is sorted." },
            { op: "drag", src: { name: "invoice (1).pdf", app: "files" }, dst: { name: "Trash", app: "dock" }, why: "You said it was fine to delete.",
              title: "Moved “invoice (1).pdf” to the Trash", drop: function (a) { a.app("files").remove("invoice (1).pdf"); a.trashFull(); } },
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
