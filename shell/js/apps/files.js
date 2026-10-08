import { h } from '../store.js';
import { GLYPHS, APP_ICONS } from '../icons.js';

const page = (band, label, lines = true) => `<svg viewBox="0 0 60 60"><path d="M14 4h22l12 12v38a3 3 0 0 1-3 3H14a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3z" fill="#fbf6f0"/><path d="M36 4v9a3 3 0 0 0 3 3h9z" fill="#e6dacd"/>${lines ? '<path d="M17 26h20M17 31h24M17 36h16" stroke="#d8cabd" stroke-width="2" stroke-linecap="round"/>' : ''}<rect x="11" y="42" width="37" height="11" fill="${band}"/><text x="29.5" y="50.5" text-anchor="middle" font-family="Inter Var,Inter,sans-serif" font-weight="700" font-size="7.5" fill="#fff">${label}</text></svg>`;
const photo = (a, b) => `<svg viewBox="0 0 60 60"><rect x="6" y="11" width="48" height="38" rx="3" fill="#fff"/><defs><linearGradient id="ph${a.slice(1)}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient></defs><rect x="9" y="14" width="42" height="32" rx="1.5" fill="url(#ph${a.slice(1)})"/><circle cx="40" cy="22" r="4" fill="#fff4d6" opacity=".9"/><path d="M9 46l12-12 9 8 7-6 14 10z" fill="rgba(40,14,8,.55)"/></svg>`;
const disc = `<svg viewBox="0 0 60 60"><defs><radialGradient id="dsc"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#ffd9b0"/><stop offset=".75" stop-color="#ffb3a0"/><stop offset="1" stop-color="#e9e2ff"/></radialGradient></defs><circle cx="30" cy="30" r="24" fill="url(#dsc)"/><circle cx="30" cy="30" r="6" fill="#1b1614" stroke="#ccc"/></svg>`;
const folder = APP_ICONS.downloads().replace(/<path d="M50 44v26[^>]*>/, '');

const ICON = {
  jpg: () => photo('#ffb547', '#e2402a'), png: () => photo('#ff9f6b', '#6a1f10'),
  pdf: () => page('#e2402a', 'PDF'), docx: () => page('#ff8a3d', 'DOC'), txt: () => page('#8a7a70', 'TXT'),
  iso: () => disc, gz: () => page('#6a5c54', 'TAR', false), mp3: () => page('#ff6a4a', 'MP3', false),
  folder: () => folder,
};
const ext = n => n.includes('.') ? n.split('.').pop() : 'folder';

const START = ['IMG_2041.jpg', 'invoice.pdf', 'sunset.png', 'Launch plan.docx', 'firelamp-0.1.iso', 'IMG_2042.jpg', 'invoice (1).pdf', 'ember-hours.mp3', 'notes.txt', 'jev-sdk.tar.gz'];

export const files = {
  id: 'files', title: 'Files', icon: 'files', w: 820, h: 520,
  render(body, win) {
    const items = START.map(name => ({ name, kind: ext(name), inside: [] }));
    const grid = h('div', { class: 'files-grid scroll', role: 'list', 'aria-label': 'Downloads' });
    const status = h('div', { class: 'files-status' });
    let sel = null;

    const tile = it => {
      const el = h('div', {
        class: 'file' + (sel === it ? ' sel' : ''), role: it.kind === 'folder' ? 'folder' : 'listitem', 'aria-label': it.name,
        onclick: () => { sel = it; draw(); },
      }, h('div', { class: 'fi', html: ICON[it.kind]?.() || ICON.txt() }),
        it.editing ? h('input', { class: 'fn', 'aria-label': 'Folder name', style: { width: '88px', background: 'var(--win-3)', border: 0, outline: '1px solid var(--orange)', textAlign: 'center' } }) : h('div', { class: 'fn' }, it.name),
        it.kind === 'folder' && it.inside.length ? h('div', { class: 'badge' }, `${it.inside.length} item${it.inside.length > 1 ? 's' : ''}`) : null);
      it.el = el;
      return el;
    };
    function draw() {
      grid.replaceChildren(...items.map(tile));
      status.textContent = `${items.length} items, 214.6 GB available`;
    }

    const api = {
      newFolder() {
        const it = { name: 'untitled folder', kind: 'folder', inside: [], editing: true };
        items.unshift(it); draw();
        it.el.classList.add('appear');
        const input = it.el.querySelector('input'); input.focus();
        input.addEventListener('keydown', e => { if (e.key === 'Enter') api.commit(it); });
        return it;
      },
      commit(it = items.find(i => i.editing)) {
        if (!it) return;
        const input = it.el.querySelector('input');
        it.name = input.value.trim() || 'untitled folder'; it.editing = false; draw();
      },
      move(name, folderName) {
        const it = items.find(i => i.name === name), f = items.find(i => i.name === folderName);
        if (!it || !f) return;
        it.el.classList.add('gone');
        return new Promise(r => setTimeout(() => { items.splice(items.indexOf(it), 1); f.inside.push(it); draw(); r(); }, 300));
      },
      remove(name) {
        const it = items.find(i => i.name === name);
        if (!it) return;
        it.el.classList.add('gone');
        return new Promise(r => setTimeout(() => { items.splice(items.indexOf(it), 1); draw(); r(); }, 320));
      },
    };
    win.ctx.files = api;

    body.append(
      h('div', { class: 'sidebar' },
        h('div', { class: 'side-h' }, 'Favorites'),
        [['Recents', GLYPHS.clock], ['Desktop', GLYPHS.grid], ['Documents', GLYPHS.doc], ['Downloads', GLYPHS.folder], ['Pictures', GLYPHS.image], ['Music', GLYPHS.music]]
          .map(([n, g]) => h('div', { class: 'side-i' + (n === 'Downloads' ? ' sel' : ''), role: 'button', 'aria-label': n }, h('span', { html: g }), n)),
        h('div', { class: 'side-h' }, 'Locations'),
        h('div', { class: 'side-i' }, h('span', { html: GLYPHS.globe }), 'Firelamp Cloud')),
      h('div', { class: 'main' },
        h('div', { class: 'toolbar' },
          h('button', { class: 'tb-btn', 'aria-label': 'Back', html: GLYPHS.chevronL }),
          h('button', { class: 'tb-btn', 'aria-label': 'Forward', html: GLYPHS.chevron }),
          h('h1', {}, 'Downloads'), h('div', { class: 'grow' }),
          h('button', { class: 'tb-btn', 'aria-label': 'New Folder', html: GLYPHS.plus, onclick: () => api.newFolder() }),
          h('button', { class: 'tb-btn', 'aria-label': 'Icon view', html: GLYPHS.grid }),
          h('button', { class: 'tb-btn', 'aria-label': 'List view', html: GLYPHS.list }),
          h('div', { class: 'tb-search' }, h('span', { html: GLYPHS.search }), 'Search')),
        grid, status));
    draw();
  },
};
