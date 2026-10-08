// The "brain". On the real system an LLM turns what you asked into a plan; in this demo
// shell a few plans are written out by hand so the whole loop can be seen end to end.
// Each step names its target the way the UI tree labels it, plus the reason it's taken.
import { bus, sleep } from '../store.js';

export const SUGGESTIONS = [
  { text: 'Email Ana my meeting notes', icon: 'sent' },
  { text: 'Tidy up my Downloads', icon: 'folder' },
  { text: 'Show me what you see', icon: 'eye' },
];

const press = async (a, target, key) => {
  const n = await a.locate(target);
  n.el.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }));
  await sleep(200);
};

const emailNotes = {
  label: 'Emailing Ana the meeting notes',
  async run(a) {
    a.say("On it. I'll grab today's launch notes and email them to Ana.");
    await a.think('Planning: Notes, then Mail', 700);
    await a.open('notes', 'The meeting notes live in Notes.');
    await a.click({ name: 'Launch sync — Oct 7', app: 'notes' }, "That's the note from today's meeting.");
    const body = await a.point({ name: 'Note body', app: 'notes', say: 'the note' }, 'reading');
    body.el.classList.add('selected');
    await sleep(500);
    const lines = body.el.innerText.split('\n').filter(l => l.startsWith('•'));
    a.log('look', 'Read “Launch sync — Oct 7”', 'Copied the bullet points so I can paste them into the email.', 'Notes');
    await a.open('mail', 'To write the email.');
    await a.click({ name: 'Compose', app: 'mail' }, 'Starting a new email.');
    await a.type({ name: 'To', app: 'mail' }, 'ana.souza@hearth.mail', 'Ana is the one who asked for the notes.');
    await a.type({ name: 'Subject', app: 'mail' }, 'Notes from today’s launch sync', 'A clear subject so she can find it later.');
    await a.type({ name: 'Message body', app: 'mail', say: 'the message' },
      `Hi Ana,\n\nHere are the notes from today’s sync:\n\n${lines.join('\n')}\n\nTalk soon!`,
      'Pasted the notes with a short hello.', { cps: 160 });
    const ok = await a.confirm({
      title: 'Allow {name} to send this email?',
      body: 'Sending can’t be undone, so Firelamp checks with you first.',
      details: [['To', 'ana.souza@hearth.mail'], ['Subject', 'Notes from today’s launch sync'], ['App', 'Mail']],
      logTitle: 'Asked you before sending',
      allow: 'Send It',
    }, 'You asked me to email Ana the notes.');
    if (!ok) { a.say('No problem. I left the draft open so you can look it over.'); return; }
    await a.click({ name: 'Send', app: 'mail', role: 'button' }, 'You said yes, so I sent it.', { title: 'Sent the email to Ana' });
    await sleep(400);
    a.say('Sent! Ana has the notes from today’s launch sync.');
  },
};

const tidy = {
  label: 'Tidying up Downloads',
  async run(a) {
    a.say("Sure. I'll sort Downloads into folders and clear out the duplicate invoice.");
    await a.think('Looking at what’s in Downloads', 600);
    const w = await a.open('files', 'Downloads is in Files.');
    const files = w.ctx.files;
    const folder = async (name, items) => {
      await a.click({ name: 'New Folder', app: 'files' }, `A folder for ${name.toLowerCase()}.`, { title: `Made a new folder` });
      await a.type({ name: 'Folder name', app: 'files' }, name, 'Naming it so it’s easy to find.', { title: `Named it “${name}”` });
      await press(a, { name: 'Folder name', app: 'files' }, 'Enter');
      for (const f of items) {
        await a.drag({ name: f, app: 'files' }, { name, app: 'files', role: 'folder' },
          `It’s ${name === 'Images' ? 'a picture' : 'a document'}.`, { onDrop: () => files.move(f, name) });
      }
    };
    await folder('Images', ['IMG_2041.jpg', 'sunset.png', 'IMG_2042.jpg']);
    await folder('Documents', ['invoice.pdf', 'Launch plan.docx', 'notes.txt']);
    const ok = await a.confirm({
      title: 'Allow {name} to delete a file?',
      body: '“invoice (1).pdf” is an exact copy of “invoice.pdf”. It will go to the Trash.',
      details: [['File', 'invoice (1).pdf'], ['Size', '48 KB'], ['Where', 'Downloads']],
      logTitle: 'Asked you before deleting',
      allow: 'Move to Trash',
    }, 'Deleting is risky, so I always ask.');
    if (!ok) { a.say('Okay, I kept the duplicate. Everything else is sorted.'); return; }
    await a.drag({ name: 'invoice (1).pdf', app: 'files' }, { name: 'Trash', app: 'dock' }, 'You said it was fine to delete.', {
      title: 'Moved “invoice (1).pdf” to the Trash',
      onDrop: () => { files.remove('invoice (1).pdf'); bus.emit('trash:full'); },
    });
    a.say('Done. Downloads now has an Images folder and a Documents folder, and the duplicate is in the Trash.');
  },
};

const vision = {
  label: 'Showing you what I see',
  async run(a) {
    a.say("Here's how I see the screen: no screenshots, just the live layout. Every element, its role, its label and exactly where it is, updated the moment anything changes.");
    await a.think('Reading the live UI tree', 600);
    bus.emit('vision:toggle', true);
    a.log('look', 'Showed you the live UI tree', 'This is everything I can see and touch.', 'Firelamp');
    await a.open('terminal', 'The terminal can print the same tree as text.');
    await a.type({ name: 'Command', app: 'terminal' }, 'tree', 'Asking for the tree in text form.', { cps: 12 });
    await press(a, { name: 'Command', app: 'terminal' }, 'Enter');
    a.log('look', 'Printed the UI tree', null, 'Terminal');
    await sleep(3200);
    a.say('Turn this view on any time from View → Show what the AI sees.');
    await sleep(1200);
    bus.emit('vision:toggle', false);
  },
};

const INTENTS = [
  [/\b(e-?mail|mail|send|envi|mand)/i, emailNotes],
  [/\b(tidy|clean|organi[sz]|sort|download|arrum|limp)/i, tidy],
  [/\b(see|vision|look|tree|screen|vê|ver|enxerg)/i, vision],
];

export function plan(text) {
  for (const [re, p] of INTENTS) if (re.test(text)) return p;
  return null;
}
