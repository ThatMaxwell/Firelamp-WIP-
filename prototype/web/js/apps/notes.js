import { h } from '../store.js';
import { GLYPHS } from '../icons.js';

export const NOTES = [
  { title: 'Launch sync — Oct 7', date: '10:31 PM', body:
`Launch sync — Oct 7

• Site goes live with the intro video, EN + PT.
• Dock: final icons are in. Trash glass approved.
• Fire cursor gets the hand-drawn boil on the flame only.
• Jev early access: wire it up as the reflex layer.
• Next sync: Thursday, 4pm.` },
  { title: 'Groceries', date: 'Yesterday', body: 'Groceries\n\nCoffee beans, oat milk, lemons, bread, matches for the candle.' },
  { title: 'Ideas for the dock', date: 'Mon', body: 'Ideas for the dock\n\nA little ember under the assistant icon while it works. Done!' },
  { title: 'Books to read', date: 'Sep 28', body: 'Books to read\n\nThe Design of Everyday Things\nCalm Technology\nThe Timeless Way of Building' },
];

export const notes = {
  id: 'notes', title: 'Notes', icon: 'notes', w: 820, h: 540,
  render(body) {
    let sel = 1;
    const list = h('div', { class: 'notes-list scroll', role: 'list', 'aria-label': 'Notes' });
    const date = h('div', { class: 'note-date' });
    const ed = h('div', { class: 'note-body scroll', contenteditable: 'true', 'aria-label': 'Note body', spellcheck: 'false' });
    function draw() {
      list.replaceChildren(...NOTES.map((n, i) => h('div', {
        class: 'note-item' + (i === sel ? ' sel' : ''), role: 'listitem', 'aria-label': n.title,
        onclick: () => { save(); sel = i; draw(); },
      }, h('b', {}, n.title), h('span', {}, h('time', {}, n.date), n.body.split('\n').filter(Boolean)[1] || ''))));
      const n = NOTES[sel];
      date.textContent = `October 7, 2026 at ${n.date}`;
      const [first, ...rest] = n.body.split('\n');
      ed.replaceChildren(h('h3', {}, first), rest.join('\n').replace(/^\n/, ''));
      ed.classList.remove('selected');
    }
    const save = () => { const n = NOTES[sel]; if (n) n.body = ed.innerText; };
    ed.addEventListener('input', save);
    body.append(list, h('div', { class: 'note-ed' },
      h('div', { class: 'toolbar' }, h('div', { class: 'grow' }),
        h('button', { class: 'tb-btn', 'aria-label': 'New note', html: GLYPHS.compose }),
        h('button', { class: 'tb-btn', 'aria-label': 'Share note', html: GLYPHS.sent }),
        h('div', { class: 'tb-search' }, h('span', { html: GLYPHS.search }), 'Search')),
      date, ed));
    draw();
  },
};
