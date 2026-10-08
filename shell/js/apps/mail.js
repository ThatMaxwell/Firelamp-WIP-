import { bus, h } from '../store.js';
import { GLYPHS } from '../icons.js';
import { toast } from '../notify.js';

const GRAD = ['#ff8a3d,#e2402a', '#ffb547,#ff7a33', '#c8402f,#7a1f12', '#ffd08a,#ff9f3d', '#8a7a70,#4e4440'];
const avatar = (name, i) => h('div', { class: 'avatar', style: { background: `linear-gradient(160deg,${GRAD[i % GRAD.length]})` } }, name.split(' ').map(s => s[0]).join('').slice(0, 2));

const INBOX = [
  { from: 'Ana Souza', sub: 'Launch sync tomorrow?', pre: 'Hey! Could you send me the notes from today’s meeting when you get a sec? I want to prep the deck.', time: '11:02 PM', unread: true,
    body: 'Hey!\n\nCould you send me the notes from today’s meeting when you get a sec? I want to prep the launch deck tonight.\n\nThanks,\nAna' },
  { from: 'TypeSafe', sub: 'Your Jev early access is live', pre: 'Welcome aboard. Jev is ready to make fast, typed decisions for your agents.', time: '6:40 PM', unread: true,
    body: 'Welcome aboard.\n\nJev is ready to make fast, typed decisions for your agents. Your keys are in the dashboard.\n\n— The TypeSafe team' },
  { from: 'Leo Martins', sub: 'Dock icons v3', pre: 'Pushed the new squircles. The trash glass looks so good now.', time: '4:15 PM',
    body: 'Pushed the new squircles. The trash glass looks so good now. Let me know about the calendar one.' },
  { from: 'Hearth Weekly', sub: 'Cozy computing, issue 42', pre: 'This week: warm color systems, lava lamps, and why friendly AI matters.', time: 'Yesterday',
    body: 'This week: warm color systems, lava lamps, and why friendly AI matters.' },
  { from: 'GitHub', sub: '[Firelamp-WIP-] New star', pre: 'Someone starred ThatMaxwell/Firelamp-WIP-.', time: 'Yesterday',
    body: 'Someone starred ThatMaxwell/Firelamp-WIP-.' },
];

export const mail = {
  id: 'mail', title: 'Mail', icon: 'mail', w: 980, h: 600,
  render(body, win) {
    const folders = { Inbox: INBOX.slice(), Sent: [] };
    let folder = 'Inbox', sel = 0;
    const items = h('div', { class: 'mail-items scroll', role: 'list', 'aria-label': 'Messages' });
    const read = h('div', { class: 'mail-doc scroll' });
    const head = h('h1', {}, 'Inbox');
    const sub = h('div', { class: 'sub' });
    const side = name => h('div', { class: 'side-i' + (name === folder ? ' sel' : ''), role: 'button', 'aria-label': name + ' mailbox', 'data-f': name, onclick: () => { folder = name; sel = 0; draw(); } },
      h('span', { html: { Inbox: GLYPHS.inbox, Sent: GLYPHS.sent, Starred: GLYPHS.star, Drafts: GLYPHS.doc, Trash: GLYPHS.trash }[name] }), name, h('span', { class: 'n' }));
    const sideEls = ['Inbox', 'Starred', 'Sent', 'Drafts', 'Trash'].map(side);

    function draw() {
      const list = folders[folder] || [];
      sideEls.forEach(e => {
        e.classList.toggle('sel', e.dataset.f === folder);
        const n = (folders[e.dataset.f] || []).filter(m => m.unread).length;
        e.querySelector('.n').textContent = n || '';
      });
      head.textContent = folder;
      sub.textContent = `${list.length} message${list.length === 1 ? '' : 's'}`;
      items.replaceChildren(...list.map((m, i) => h('div', {
        class: 'mail-item' + (i === sel ? ' sel' : '') + (m.unread ? ' unread' : '') + (m.fresh ? ' new' : ''), role: 'listitem', 'aria-label': `${m.from}: ${m.sub}`,
        onclick: () => { sel = i; m.unread = false; draw(); },
      }, avatar(m.to || m.from, i), h('div', {}, h('div', { class: 'mi-top' }, h('b', {}, m.to ? 'To: ' + m.to : m.from), h('time', {}, m.time)), h('div', { class: 'mi-sub' }, m.sub), h('div', { class: 'mi-pre' }, m.pre)))));
      const m = list[sel];
      read.replaceChildren(...(m ? [
        h('h2', {}, m.sub),
        h('div', { class: 'mail-from' }, avatar(m.to || m.from, sel), h('div', {}, h('b', {}, m.to ? 'To: ' + m.to : m.from), h('span', {}, m.time))),
        h('div', { class: 'mail-body' }, m.body),
      ] : [h('div', { class: 'tl-empty' }, 'No message selected')]));
    }

    function compose() {
      if (readPane.querySelector('.compose')) return;
      const to = h('input', { 'aria-label': 'To' });
      const subject = h('input', { 'aria-label': 'Subject' });
      const text = h('textarea', { 'aria-label': 'Message body', placeholder: 'Write something warm…' });
      const box = h('div', { class: 'compose', role: 'form', 'aria-label': 'New message' },
        h('div', { class: 'compose-head' }, 'New Message', h('div', { class: 'grow' }),
          h('button', { class: 'tb-btn', 'aria-label': 'Discard draft', html: GLYPHS.trash, onclick: () => box.remove() }),
          h('button', { class: 'btn primary send-btn', 'aria-label': 'Send', 'data-risky': 'send', onclick: () => sendMail() }, h('span', { html: GLYPHS.sent }), 'Send')),
        h('div', { class: 'c-field' }, h('label', {}, 'To:'), to),
        h('div', { class: 'c-field' }, h('label', {}, 'Subject:'), subject),
        text);
      readPane.append(box);
      setTimeout(() => to.focus(), 50);
      box.sendMail = sendMail;
      function sendMail() {
        box.classList.add('out');
        setTimeout(() => box.remove(), 450);
        folders.Sent.unshift({ to: to.value || 'someone', sub: subject.value || '(no subject)', pre: text.value.slice(0, 120), body: text.value, time: 'Now', fresh: true });
        const ana = folders.Inbox.find(m => m.from === 'Ana Souza'); if (ana) ana.unread = false;
        draw();
        toast({ icon: 'mail', title: 'Message sent', body: `To ${to.value} · “${subject.value}”` });
        bus.emit('mail:sent');
      }
    }

    const readPane = h('div', { class: 'mail-read' },
      h('div', { class: 'toolbar' }, h('div', { class: 'grow' }),
        h('button', { class: 'tb-btn', 'aria-label': 'Archive', html: GLYPHS.inbox }),
        h('button', { class: 'tb-btn', 'aria-label': 'Delete message', html: GLYPHS.trash }),
        h('button', { class: 'tb-btn', 'aria-label': 'Compose', html: GLYPHS.compose, onclick: compose }),
        h('div', { class: 'tb-search' }, h('span', { html: GLYPHS.search }), 'Search')),
      read);

    body.append(
      h('div', { class: 'sidebar' }, h('div', { class: 'side-h' }, 'Hearth Mail'), sideEls),
      h('div', { class: 'mail-list' }, h('div', { class: 'toolbar' }, h('div', {}, head, sub)), items),
      readPane);
    draw();
  },
};
