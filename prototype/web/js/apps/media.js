import { h } from '../store.js';
import { GLYPHS, logoSVG } from '../icons.js';

const T = {
  prev: '<svg viewBox="0 0 24 24"><path d="M11 12l8-6v12zM3 12l8-6v12z" fill="currentColor"/></svg>',
  next: '<svg viewBox="0 0 24 24"><path d="M13 12L5 6v12zM21 12l-8-6v12z" fill="currentColor"/></svg>',
  play: '<svg viewBox="0 0 24 24"><path d="M7 4.5v15l12-7.5z" fill="currentColor"/></svg>',
  pause: '<svg viewBox="0 0 24 24"><rect x="6" y="4.5" width="4" height="15" rx="1" fill="currentColor"/><rect x="14" y="4.5" width="4" height="15" rx="1" fill="currentColor"/></svg>',
};

export const music = {
  id: 'music', title: 'Music', icon: 'music', w: 340, h: 560,
  render(body) {
    let playing = true;
    const root = h('div', { class: 'music' });
    const btn = h('button', { class: 'big', 'aria-label': 'Pause', html: T.pause });
    btn.onclick = () => { playing = !playing; btn.innerHTML = playing ? T.pause : T.play; btn.setAttribute('aria-label', playing ? 'Pause' : 'Play'); root.classList.toggle('stopped', !playing); };
    root.append(
      h('div', { class: 'art', html: logoSVG({ animated: true }) }),
      h('div', { class: 'track' }, h('b', {}, 'Ember Hours'), h('span', {}, 'Lo-Fi Hearth · Warm Static')),
      h('div', { class: 'prog' }, h('div', { class: 'bar' }, h('i')), h('div', { class: 't' }, h('span', {}, '1:12'), h('span', {}, '-2:21'))),
      h('div', { class: 'transport' }, h('button', { 'aria-label': 'Previous', html: T.prev }), btn, h('button', { 'aria-label': 'Next', html: T.next })),
      h('div', { class: 'eq' }, h('i'), h('i'), h('i'), h('i')));
    body.append(root);
  },
};

const PHOTO = [
  ['#ffb547', '#e2402a', 160], ['#3a1a10', '#ff8a3d', 200], ['#ffd08a', '#ff6a3a', 120], ['#2a1f1b', '#c8402f', 180],
  ['#ff9f6b', '#6a1f10', 140], ['#ffe3b8', '#ffb547', 220], ['#e2402a', '#2a0f08', 100], ['#ffc27a', '#8a3a1a', 170],
  ['#5a2a1a', '#ffd08a', 210], ['#ff7a33', '#ffd08a', 130], ['#1c0f0a', '#e2402a', 190], ['#ffb547', '#fff1d6', 150],
];
export const photos = {
  id: 'photos', title: 'Photos', icon: 'photos', w: 760, h: 520,
  render(body) {
    body.append(h('div', { class: 'main' },
      h('div', { class: 'toolbar with-lights' }, h('h1', {}, 'Library'), h('span', { class: 'sub' }, 'Oct 2026'), h('div', { class: 'grow' }), h('div', { class: 'tb-search' }, h('span', { html: GLYPHS.search }), 'Search')),
      h('div', { class: 'photos scroll' }, PHOTO.map(([a, b, deg], i) => h('div', {
        class: 'photo', role: 'img', 'aria-label': `Photo ${i + 1}`,
        style: { background: `radial-gradient(60% 50% at ${30 + (i * 17) % 50}% ${60 - (i * 11) % 40}%, rgba(255,240,220,.35), transparent 70%), linear-gradient(${deg}deg, ${a}, ${b})` },
      })))));
  },
};

export const calendar = {
  id: 'calendar', title: 'Calendar', icon: 'calendar', w: 760, h: 540,
  render(body) {
    const now = new Date(), y = now.getFullYear(), m = now.getMonth();
    const first = new Date(y, m, 1).getDay(), days = new Date(y, m + 1, 0).getDate(), prev = new Date(y, m, 0).getDate();
    const events = { 7: [['Launch sync', ''], ['Dock review', 'b']], 9: [['Jev onboarding', '']], 14: [['Site goes live', '']], 21: [['Firelamp 0.1', 'b']] };
    const cells = [];
    for (let i = 0; i < 42; i++) {
      const d = i - first + 1, inMonth = d >= 1 && d <= days;
      const n = inMonth ? d : d < 1 ? prev + d : d - days;
      cells.push(h('div', { class: 'cal-day' + (inMonth ? '' : ' dim') + (inMonth && d === now.getDate() ? ' today' : '') },
        h('span', { class: 'num' }, n), ...(inMonth ? (events[d] || []).map(([t, c]) => h('div', { class: 'ev ' + c }, t)) : [])));
    }
    body.append(h('div', { class: 'main' },
      h('div', { class: 'toolbar with-lights' }, h('h1', {}, now.toLocaleString('en', { month: 'long' })), h('span', { class: 'sub', style: { fontSize: '15px', fontWeight: 400 } }, y),
        h('div', { class: 'grow' }), h('button', { class: 'tb-btn', 'aria-label': 'Previous month', html: GLYPHS.chevronL }), h('button', { class: 'btn' }, 'Today'), h('button', { class: 'tb-btn', 'aria-label': 'Next month', html: GLYPHS.chevron })),
      h('div', { class: 'cal' }, h('div', { class: 'cal-grid' }, ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(d => h('div', { class: 'dow' }, d)), cells))));
  },
};

export const web = {
  id: 'web', title: 'Web', icon: 'web', w: 940, h: 600,
  render(body) {
    const favs = [['GitHub', '#2a2320'], ['Jev', '#e2402a'], ['Hearth', '#ff8a3d'], ['Arch Wiki', '#3a7bd5'], ['Maps', '#5aa85a'], ['News', '#8a7a70'], ['Music', '#ff6a4a'], ['Docs', '#ffb547']];
    body.append(h('div', { class: 'web' },
      h('div', { class: 'web-bar' },
        h('button', { class: 'tb-btn', 'aria-label': 'Back', html: GLYPHS.chevronL }), h('button', { class: 'tb-btn', 'aria-label': 'Forward', html: GLYPHS.chevron }),
        h('div', { class: 'url', role: 'textbox', 'aria-label': 'Address bar' }, h('span', { html: GLYPHS.lock }), 'start.firelamp.os'),
        h('button', { class: 'tb-btn', 'aria-label': 'Reload', html: GLYPHS.reload }), h('button', { class: 'tb-btn', 'aria-label': 'New tab', html: GLYPHS.plus })),
      h('div', { class: 'web-page scroll' },
        h('div', { html: logoSVG({ cls: 'w-logo', animated: true }) }),
        h('h2', {}, 'Good evening, Carrot'),
        h('div', { class: 'web-search', role: 'textbox', 'aria-label': 'Search the web' }, h('span', { html: GLYPHS.search }), 'Search or ask anything'),
        h('div', { class: 'favs' }, favs.map(([n, c]) => h('div', { class: 'fav', role: 'link', 'aria-label': n }, h('i', { style: { background: c } }, n[0]), n))))));
  },
};
