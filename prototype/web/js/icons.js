// App icons (squircles, drawn in SVG so they stay crisp at every dock size) and the
// small line glyphs used across the shell.
import { LOGO_PATHS, LOGO_COLORS } from './logo.js';

// Continuous-corner squircle (superellipse, n = 5), the shape of a desktop app icon.
function squircle(cx = 50, cy = 50, r = 42, n = 5, steps = 72) {
  let d = '';
  for (let i = 0; i <= steps; i++) {
    const t = (i / steps) * Math.PI * 2;
    const c = Math.cos(t), s = Math.sin(t);
    const x = cx + r * Math.sign(c) * Math.abs(c) ** (2 / n);
    const y = cy + r * Math.sign(s) * Math.abs(s) ** (2 / n);
    d += (i ? 'L' : 'M') + x.toFixed(2) + ' ' + y.toFixed(2);
  }
  return d + 'Z';
}
export const SQUIRCLE = squircle();

let uid = 0;
const svg = (body, vb = '0 0 100 100') => `<svg viewBox="${vb}" xmlns="http://www.w3.org/2000/svg">${body}</svg>`;

// Wraps artwork in the squircle: background fill, artwork clipped to it, and the
// soft top sheen + hairline edge every icon shares.
function tile(bg, art, { sheen = .16 } = {}) {
  const id = 'i' + (++uid);
  return svg(`
    <defs>
      ${bg.defs || ''}
      <clipPath id="${id}c"><path d="${SQUIRCLE}"/></clipPath>
      <linearGradient id="${id}s" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#fff" stop-opacity="${sheen}"/>
        <stop offset=".5" stop-color="#fff" stop-opacity="0"/>
      </linearGradient>
    </defs>
    <g clip-path="url(#${id}c)">
      <path d="${SQUIRCLE}" fill="${bg.fill}"/>
      ${art}
      <path d="${SQUIRCLE}" fill="url(#${id}s)"/>
    </g>
    <path d="${SQUIRCLE}" fill="none" stroke="rgba(255,255,255,.14)" stroke-width=".8"/>`);
}

const lin = (id, a, b, x2 = 0, y2 = 1) =>
  `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient>`;

export function logoSVG({ cls = '', animated = false } = {}) {
  const p = LOGO_PATHS, c = LOGO_COLORS;
  return `<svg class="${cls}" viewBox="20 20 840 976" xmlns="http://www.w3.org/2000/svg">
    <g class="logo-flame${animated ? ' boil' : ''}"><path fill="${c.outer}" d="${p.outer}"/></g>
    <g class="logo-arrow"><path fill="${c.arrow}" d="${p.arrow}"/><path fill="${c.light}" d="${p.light}"/></g>
    <path class="logo-drop" fill="${c.drop}" d="${p.drop}"/>
    <path class="logo-dot" fill="${c.dot}" d="${p.dot}"/>
  </svg>`;
}

const PETAL = 'M-105 -252C-110 -285 -118 -325 -118 -365C-118 -450 -80 -498 0 -498C80 -498 118 -450 118 -365C118 -325 110 -285 105 -252Z';
export function maxwellSVG(fill = 'currentColor') {
  return svg(`<g fill="${fill}"><circle r="273"/>${[0,45,90,135,180,225,270,315].map(a => `<path d="${PETAL}" transform="rotate(${a})"/>`).join('')}</g>`, '-500 -500 1000 1000');
}

function calendarIcon() {
  const d = new Date();
  const mon = d.toLocaleString('en', { month: 'short' }).toUpperCase();
  return tile({ fill: '#fbf7f2' }, `
    <text x="50" y="33" text-anchor="middle" font-family="Inter Var, Inter, sans-serif" font-weight="650" font-size="13" letter-spacing="1" fill="#E2402A">${mon}</text>
    <text x="50" y="75" text-anchor="middle" font-family="Inter Var, Inter, sans-serif" font-weight="300" font-size="44" fill="#2a2320">${d.getDate()}</text>`, { sheen: 0 });
}

export const APP_ICONS = {
  assistant: () => tile({ fill: 'url(#aBg)', defs: `
      <radialGradient id="aBg" cx=".5" cy=".42" r=".75"><stop offset="0" stop-color="#3a2219"/><stop offset="1" stop-color="#120b08"/></radialGradient>
      <radialGradient id="aGlow" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#ff7a33" stop-opacity=".55"/><stop offset="1" stop-color="#ff7a33" stop-opacity="0"/></radialGradient>` },
    `<circle cx="50" cy="56" r="34" fill="url(#aGlow)"/>
     <g transform="translate(26 17) scale(.0585)">${logoSVG().replace(/^<svg[^>]*>|<\/svg>$/g, '')}</g>`),

  files: () => tile({ fill: 'url(#fBg)', defs: lin('fBg', '#ffcb6b', '#ff8a3d') + lin('fFr', '#ffffff', '#fff1df') }, `
    <path d="M22 34a5 5 0 0 1 5-5h14l6 6h26a5 5 0 0 1 5 5v4H22z" fill="#fff" opacity=".72"/>
    <rect x="22" y="40" width="56" height="34" rx="5" fill="url(#fFr)"/>
    <path d="M38 55q12 8 24 0" fill="none" stroke="#ff9a48" stroke-width="3" stroke-linecap="round"/>
    <circle cx="40" cy="49" r="2" fill="#ff9a48"/><circle cx="60" cy="49" r="2" fill="#ff9a48"/>`),

  web: () => tile({ fill: 'url(#wBg)', defs: lin('wBg', '#fefaf6', '#efe4da') + lin('wRing', '#ffb547', '#e2402a') }, `
    <circle cx="50" cy="50" r="31" fill="none" stroke="url(#wRing)" stroke-width="5"/>
    ${Array.from({ length: 24 }, (_, i) => { const a = i * 15 * Math.PI / 180, r1 = i % 6 ? 24 : 21; return `<line x1="${50 + Math.cos(a) * r1}" y1="${50 + Math.sin(a) * r1}" x2="${50 + Math.cos(a) * 26}" y2="${50 + Math.sin(a) * 26}" stroke="#c9b9ab" stroke-width="1.2"/>`; }).join('')}
    <path d="M50 50 L66 33 L54 54 Z" fill="#e2402a"/><path d="M50 50 L34 67 L46 46 Z" fill="#d9cdc3"/>
    <circle cx="50" cy="50" r="2.6" fill="#fff" stroke="#c9b9ab"/>`, { sheen: .3 }),

  terminal: () => tile({ fill: 'url(#tBg)', defs: lin('tBg', '#2a2421', '#0e0b0a') }, `
    <rect x="8" y="8" width="84" height="84" rx="16" fill="none" stroke="rgba(255,255,255,.08)"/>
    <path d="M27 36l11 9-11 9" fill="none" stroke="#ffb547" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
    <rect x="43" y="52" width="18" height="5" rx="2.5" fill="#ffd08a"/>`),

  notes: () => tile({ fill: '#fffaf1', defs: lin('nTop', '#ffc15a', '#ff9f3d') }, `
    <rect x="0" y="0" width="100" height="30" fill="url(#nTop)"/>
    <rect x="0" y="30" width="100" height="1.5" fill="rgba(0,0,0,.08)"/>
    ${[44, 56, 68, 80].map(y => `<line x1="20" y1="${y}" x2="80" y2="${y}" stroke="#e8dccd" stroke-width="1.6"/>`).join('')}
    <path d="M22 44h40M22 56h48M22 68h30" stroke="#b9a79a" stroke-width="2.4" stroke-linecap="round" opacity=".6"/>`, { sheen: .25 }),

  mail: () => tile({ fill: 'url(#mBg)', defs: lin('mBg', '#ffa45c', '#e8452c') + lin('mEnv', '#ffffff', '#fff0e3') }, `
    <rect x="20" y="31" width="60" height="40" rx="6" fill="url(#mEnv)"/>
    <path d="M22 34l28 21 28-21" fill="none" stroke="#f08a5a" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>`),

  music: () => tile({ fill: 'url(#muBg)', defs: lin('muBg', '#ff8a52', '#d8322a') }, `
    <path d="M41 30v32a8 8 0 1 1-4-7V36l28-6v26a8 8 0 1 1-4-7V30z" fill="#fff" transform="translate(-1 2)"/>
    <path d="M40 36l26-6" stroke="#fff" stroke-width="5" stroke-linecap="round"/>`),

  photos: () => tile({ fill: '#fdfaf6' }, `
    <g transform="translate(50 50) scale(.064)" style="mix-blend-mode:multiply">
      ${['#ffd08a', '#ffb547', '#ff8a3d', '#ff6a3a', '#e2402a', '#c8402f', '#ff8f6b', '#ffc27a'].map((c, i) => `<path d="${PETAL}" transform="rotate(${i * 45})" fill="${c}" opacity=".88"/>`).join('')}
    </g>`, { sheen: .2 }),

  calendar: calendarIcon,

  settings: () => tile({ fill: 'url(#sBg)', defs: lin('sBg', '#9a918b', '#5a524d') + lin('sG', '#4a4440', '#2c2826') }, `
    <g transform="translate(50 50)">
      ${Array.from({ length: 12 }, (_, i) => `<rect x="-4.5" y="-33" width="9" height="12" rx="2" fill="url(#sG)" transform="rotate(${i * 30})"/>`).join('')}
      <circle r="24" fill="url(#sG)"/><circle r="15" fill="#8d847e"/><circle r="9" fill="#3a3532"/>
    </g>`, { sheen: .3 }),

  timeline: () => tile({ fill: 'url(#tlBg)', defs: lin('tlBg', '#2f221d', '#140e0b') }, `
    <line x1="34" y1="26" x2="34" y2="74" stroke="#5a463c" stroke-width="3" stroke-linecap="round"/>
    <circle cx="34" cy="30" r="6" fill="#ffd08a"/><circle cx="34" cy="50" r="6" fill="#ff8a3d"/><circle cx="34" cy="70" r="6" fill="#e2402a"/>
    <rect x="46" y="27" width="30" height="6" rx="3" fill="#6e5649"/><rect x="46" y="47" width="22" height="6" rx="3" fill="#6e5649"/><rect x="46" y="67" width="26" height="6" rx="3" fill="#6e5649"/>`),

  downloads: () => svg(`
    <defs>${lin('dlB', '#ffd27a', '#ffa03d')}${lin('dlF', '#ffe3a8', '#ffb547')}</defs>
    <path d="M10 26a6 6 0 0 1 6-6h22l7 7h39a6 6 0 0 1 6 6v6H10z" fill="url(#dlB)"/>
    <rect x="10" y="32" width="80" height="54" rx="7" fill="url(#dlF)"/>
    <path d="M50 44v26m-10-10l10 10 10-10" fill="none" stroke="#e8822e" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>`),

  trash: (full = false) => svg(`
    <defs>${lin('trB', 'rgba(255,255,255,.62)', 'rgba(255,255,255,.28)')}</defs>
    <path d="M24 26h52l-5 60a6 6 0 0 1-6 5H35a6 6 0 0 1-6-5z" fill="url(#trB)" stroke="rgba(255,255,255,.5)" stroke-width="1"/>
    ${[36, 44, 52, 60, 68].map(x => `<path d="M${x} 32l${(x - 52) * .07} 54" stroke="rgba(255,255,255,.35)" stroke-width="1.6"/>`).join('')}
    ${full ? '<path d="M30 30q8-12 18-4q10-10 22 2" fill="#fff" opacity=".85"/>' : ''}
    <rect x="20" y="20" width="60" height="7" rx="3.5" fill="rgba(255,255,255,.75)"/>`),
};

// ---------- 16px line glyphs ----------
const g = (d, extra = '') => `<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" ${extra}>${d}</svg>`;

export const GLYPHS = {
  search: g('<circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5L14 14"/>'),
  wifi: g('<path d="M2 6.2a8.5 8.5 0 0 1 12 0M4.2 8.6a5.4 5.4 0 0 1 7.6 0M6.4 11a2.3 2.3 0 0 1 3.2 0"/><circle cx="8" cy="13.1" r=".6" fill="currentColor"/>'),
  battery: `<svg viewBox="0 0 26 13" fill="none"><rect x=".75" y=".75" width="21.5" height="11.5" rx="3.4" stroke="currentColor" stroke-opacity=".45" stroke-width="1.1"/><rect x="2.5" y="2.5" width="15.5" height="8" rx="1.8" fill="currentColor"/><path d="M24 4.5v4" stroke="currentColor" stroke-opacity=".45" stroke-width="1.4" stroke-linecap="round"/></svg>`,
  control: g('<rect x="1.8" y="3" width="12.4" height="4" rx="2"/><circle cx="11.6" cy="5" r="1" fill="currentColor"/><rect x="1.8" y="9" width="12.4" height="4" rx="2"/><circle cx="4.4" cy="11" r="1" fill="currentColor"/>'),
  pause: g('<path d="M5.5 3.5v9M10.5 3.5v9" stroke-width="2"/>'),
  play: `<svg viewBox="0 0 16 16"><path d="M5 3.2v9.6a.6.6 0 0 0 .9.5l7.6-4.8a.6.6 0 0 0 0-1L5.9 2.7a.6.6 0 0 0-.9.5z" fill="currentColor"/></svg>`,
  stop: `<svg viewBox="0 0 16 16"><rect x="3.5" y="3.5" width="9" height="9" rx="2" fill="currentColor"/></svg>`,
  mic: g('<rect x="5.5" y="1.8" width="5" height="8" rx="2.5"/><path d="M3.2 7.6a4.8 4.8 0 0 0 9.6 0M8 12.4v2"/>'),
  send: g('<path d="M8 13V3M3.8 7.2L8 3l4.2 4.2" stroke-width="1.8"/>'),
  click: g('<path d="M5.5 5.5l8 3-3.4 1.2L8.9 13z"/><path d="M3 1.8v1.6M1.8 3h1.6M5.6 2.2l-.8 1M2.2 5.6l1-.8"/>'),
  type: g('<rect x="1.5" y="4" width="13" height="8" rx="2"/><path d="M4 6.6h.01M6.6 6.6h.01M9.3 6.6h.01M12 6.6h.01M5 9.4h6"/>'),
  open: g('<rect x="2" y="2.5" width="12" height="11" rx="2.2"/><path d="M2 5.5h12"/>'),
  eye: g('<path d="M1.5 8s2.4-4.5 6.5-4.5S14.5 8 14.5 8s-2.4 4.5-6.5 4.5S1.5 8 1.5 8z"/><circle cx="8" cy="8" r="2"/>'),
  check: g('<path d="M3.2 8.4l3 3 6.6-6.8" stroke-width="1.8"/>'),
  x: g('<path d="M4 4l8 8M12 4l-8 8"/>'),
  shield: g('<path d="M8 1.8l5 1.9v4.1c0 3.2-2.2 5.4-5 6.4-2.8-1-5-3.2-5-6.4V3.7z"/><path d="M5.8 8l1.6 1.6 2.9-3"/>'),
  folder: g('<path d="M1.8 4.2c0-.7.5-1.2 1.2-1.2h3l1.5 1.5H13c.7 0 1.2.5 1.2 1.2v6.1c0 .7-.5 1.2-1.2 1.2H3c-.7 0-1.2-.5-1.2-1.2z"/>'),
  doc: g('<path d="M4 1.8h5l3.2 3.2v8.2c0 .6-.4 1-1 1H4c-.6 0-1-.4-1-1V2.8c0-.6.4-1 1-1z"/><path d="M9 1.8V5h3.2"/>'),
  image: g('<rect x="1.8" y="2.5" width="12.4" height="11" rx="2"/><circle cx="5.6" cy="6.2" r="1.2"/><path d="M2 12l3.8-3.6 2.8 2.4 2.2-1.8 3.4 3"/>'),
  music: g('<path d="M6 12V3.5l7-1.5v8.5"/><circle cx="4.3" cy="12" r="1.8"/><circle cx="11.3" cy="10.5" r="1.8"/>'),
  inbox: g('<path d="M1.8 9.2l2-6h8.4l2 6v3.2c0 .6-.4 1-1 1H2.8c-.6 0-1-.4-1-1z"/><path d="M1.8 9.2h3.6l1 1.6h3.2l1-1.6h3.6"/>'),
  sent: g('<path d="M14.2 1.8L7 9M14.2 1.8L9.6 14.2 7 9 1.8 6.4z"/>'),
  star: g('<path d="M8 1.8l1.9 3.9 4.3.6-3.1 3 .7 4.3L8 11.6l-3.8 2 .7-4.3-3.1-3 4.3-.6z"/>'),
  trash: g('<path d="M2.5 4.2h11M6 4.2V2.6h4v1.6M3.8 4.2l.7 9c0 .5.5.9 1 .9h5c.5 0 1-.4 1-.9l.7-9"/>'),
  compose: g('<path d="M8.5 2.5H3.2c-.6 0-1 .4-1 1v9.3c0 .6.4 1 1 1h9.3c.6 0 1-.4 1-1V7.5"/><path d="M12.2 1.6l2.2 2.2L8.6 9.6 6 10.2l.6-2.6z"/>'),
  clock: g('<circle cx="8" cy="8" r="6.2"/><path d="M8 4.6V8l2.3 1.5"/>'),
  sidebar: g('<rect x="1.8" y="2.5" width="12.4" height="11" rx="2"/><path d="M6 2.5v11"/>'),
  chevron: g('<path d="M6 3.5L10.5 8 6 12.5"/>'),
  chevronL: g('<path d="M10 3.5L5.5 8l4.5 4.5"/>'),
  plus: g('<path d="M8 3v10M3 8h10"/>'),
  grid: g('<rect x="2" y="2" width="5" height="5" rx="1.2"/><rect x="9" y="2" width="5" height="5" rx="1.2"/><rect x="2" y="9" width="5" height="5" rx="1.2"/><rect x="9" y="9" width="5" height="5" rx="1.2"/>'),
  list: g('<path d="M5.5 4h8.5M5.5 8h8.5M5.5 12h8.5M2 4h.01M2 8h.01M2 12h.01"/>'),
  sparkle: g('<path d="M8 1.5c.4 3.3 1.8 5 5.5 6.5-3.7 1.5-5.1 3.2-5.5 6.5-.4-3.3-1.8-5-5.5-6.5C6.2 6.5 7.6 4.8 8 1.5z"/>'),
  moon: g('<path d="M13.5 9.6A5.8 5.8 0 0 1 6.4 2.5a5.8 5.8 0 1 0 7.1 7.1z"/>'),
  sun: g('<circle cx="8" cy="8" r="2.8"/><path d="M8 1.5v1.2M8 13.3v1.2M1.5 8h1.2M13.3 8h1.2M3.4 3.4l.8.8M11.8 11.8l.8.8M3.4 12.6l.8-.8M11.8 4.2l.8-.8"/>'),
  volume: g('<path d="M2 6.2h2.4L8 3.2v9.6l-3.6-3H2z"/><path d="M10.6 5.6a3.4 3.4 0 0 1 0 4.8M12.4 3.8a6 6 0 0 1 0 8.4"/>'),
  bluetooth: g('<path d="M4.5 4.8l7 6.2L8 14V2l3.5 3L4.5 11.2"/>'),
  globe: g('<circle cx="8" cy="8" r="6.2"/><path d="M1.8 8h12.4M8 1.8c1.8 1.8 2.6 3.9 2.6 6.2S9.8 12.4 8 14.2C6.2 12.4 5.4 10.3 5.4 8S6.2 3.6 8 1.8z"/>'),
  reload: g('<path d="M13.5 8a5.5 5.5 0 1 1-1.6-3.9M13.5 2.5v3.3h-3.3"/>'),
  lock: g('<rect x="3" y="7" width="10" height="7" rx="1.8"/><path d="M5.2 7V5a2.8 2.8 0 0 1 5.6 0v2"/>'),
  cursor: g('<path d="M3.5 2.2l9 4.2-3.9 1.3-1.4 3.9z"/>'),
  tree: g('<rect x="1.8" y="2" width="5" height="3.4" rx="1"/><rect x="9.2" y="6.4" width="5" height="3.4" rx="1"/><rect x="9.2" y="11" width="5" height="3.4" rx="1"/><path d="M4.3 5.4v7.3h4.9M4.3 8.1h4.9"/>'),
};
