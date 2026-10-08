// App icons (squircles, drawn in SVG so they stay crisp at every dock size) and the
// small line glyphs used across the shell. Ported from prototype/web/js/icons.js;
// Qt's SVG renderer has no clip paths, so every layer is drawn inside the squircle.
.pragma library
.import "logo.js" as Logo

// Continuous-corner squircle (superellipse, n = 5), the shape of a desktop app icon.
function squircle(cx = 50, cy = 50, r = 42, n = 5, steps = 72) {
  let d = '';
  for (let i = 0; i <= steps; i++) {
    var t = (i / steps) * Math.PI * 2;
    var c = Math.cos(t), s = Math.sin(t);
    var x = cx + r * Math.sign(c) * Math.abs(c) ** (2 / n);
    var y = cy + r * Math.sign(s) * Math.abs(s) ** (2 / n);
    d += (i ? 'L' : 'M') + x.toFixed(2) + ' ' + y.toFixed(2);
  }
  return d + 'Z';
}
var SQUIRCLE = squircle();

var uid = 0;
var svg = (body, vb = '0 0 100 100') => `<svg viewBox="${vb}" xmlns="http://www.w3.org/2000/svg">${body}</svg>`;

// Wraps artwork in the squircle: background fill, artwork clipped to it, and the
// soft top sheen + hairline edge every icon shares.
function tile(bg, art, opts) {
  var sheen = opts && opts.sheen !== undefined ? opts.sheen : .16;
  var id = 'i' + (++uid);
  return svg(`
    <defs>
      ${bg.defs || ''}
      <linearGradient id="${id}s" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#fff" stop-opacity="${sheen}"/>
        <stop offset=".5" stop-color="#fff" stop-opacity="0"/>
      </linearGradient>
    </defs>
    <path d="${SQUIRCLE}" fill="${bg.fill}"/>
    ${art}
    <path d="${SQUIRCLE}" fill="url(#${id}s)"/>
    <path d="${SQUIRCLE}" fill="none" stroke="#ffffff" stroke-opacity=".08" stroke-width=".8"/>`);
}

var lin = (id, a, b, x2 = 0, y2 = 1) =>
  `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient>`;

function logoInner() {
  var p = Logo.PATHS, c = Logo.COLORS;
  return `<path fill="${c.outer}" d="${p.outer}"/><path fill="${c.arrow}" d="${p.arrow}"/><path fill="${c.light}" d="${p.light}"/>`;
}

var PETAL = 'M-105 -252C-110 -285 -118 -325 -118 -365C-118 -450 -80 -498 0 -498C80 -498 118 -450 118 -365C118 -325 110 -285 105 -252Z';
function maxwellSVG(fill = 'currentColor') {
  return svg(`<g fill="${fill}"><circle r="273"/>${[0,45,90,135,180,225,270,315].map(a => `<path d="${PETAL}" transform="rotate(${a})"/>`).join('')}</g>`, '-500 -500 1000 1000');
}

function calendarIcon() {
  var d = new Date();
  var mon = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][d.getMonth()];
  return tile({ fill: '#ECE7DF' }, `
    <text x="50" y="34" text-anchor="middle" font-family="Instrument Sans" font-weight="700" font-size="12" letter-spacing=".6" fill="#B04A2A">${mon}</text>
    <text x="50" y="76" text-anchor="middle" font-family="Instrument Sans" font-weight="600" font-size="42" fill="#2A2622">${d.getDate()}</text>`, { sheen: .07 });
}

// Our own icon family (design/DIRECTION.md §8): muted neutral tiles, one simple glyph each,
// filling about 55% of the tile. Graphite, paper, clay, sage, slate, ink-blue. Only the Assistant is ember.
function flat(bg, art) {
  return tile({ fill: bg }, `<g transform="translate(50 50) scale(.86) translate(-50 -50)">${art}</g>`, { sheen: .07 });
}

var APP_ICONS = {
  assistant: () => flat('#2A2622', `<g transform="translate(30.4 21.4) scale(.056)"><path fill="#F26A2E" d="${Logo.PATHS.outer}"/><path fill="#2A2622" d="${Logo.PATHS.arrow}"/></g>`),
  files: () => flat('#3A4A57', '<path d="M20 34h22l6 6h32v38H20z" fill="#C9D4DC"/>'),
  web: () => flat('#E9E4DC', '<circle cx="50" cy="50" r="26" fill="none" stroke="#3A3631" stroke-width="5"/><path d="M24 50h52M50 24c10 10 10 42 0 52M50 24c-10 10-10 42 0 52" fill="none" stroke="#3A3631" stroke-width="4"/>'),
  mail: () => flat('#2F3B4A', '<rect x="22" y="30" width="56" height="40" rx="5" fill="none" stroke="#DCE3EA" stroke-width="5"/><path d="M24 34l26 20 26-20" fill="none" stroke="#DCE3EA" stroke-width="5" stroke-linejoin="round"/>'),
  notes: () => flat('#D9CDB5', '<path d="M30 24h40v52H30z" fill="#F4EEE2"/><path d="M36 38h28M36 48h28M36 58h18" stroke="#8B7E68" stroke-width="4" stroke-linecap="round"/>'),
  terminal: () => flat('#1A1918', '<path d="M28 38l12 12-12 12" fill="none" stroke="#EFEAE4" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/><path d="M48 64h22" stroke="#76706A" stroke-width="5" stroke-linecap="round"/>'),
  calendar: calendarIcon,
  photos: () => flat('#5B6B57', '<circle cx="38" cy="40" r="7" fill="#E8E2D2"/><path d="M20 74l20-20 12 12 10-10 18 18z" fill="#E8E2D2"/>'),
  music: () => flat('#4A3B47', '<path d="M42 28v34a8 8 0 1 1-6-7.7V34l28-6v28a8 8 0 1 1-6-7.7V34" fill="none" stroke="#EADDE6" stroke-width="5" stroke-linejoin="round"/>'),
  settings: () => flat('#3A3836', '<circle cx="50" cy="50" r="10" fill="none" stroke="#D8D2CA" stroke-width="6"/><path d="M50 22v10M50 68v10M22 50h10M68 50h10M30 30l7 7M63 63l7 7M70 30l-7 7M37 63l-7 7" stroke="#D8D2CA" stroke-width="6" stroke-linecap="round"/>'),
  timeline: () => flat('#2C2B2A', '<path d="M30 30h.01M30 50h.01M30 70h.01" stroke="#D8D2CA" stroke-width="8" stroke-linecap="round"/><path d="M44 30h28M44 50h20M44 70h24" stroke="#8D867F" stroke-width="5" stroke-linecap="round"/>'),
  downloads: () => flat('#3A3E44', '<path d="M50 26v36M36 50l14 14 14-14M28 74h44" fill="none" stroke="#D4D9DE" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'),
  // live session only: a drive with the flame mark going onto it
  install: () => flat('#E9E4DC', `<rect x="24" y="56" width="52" height="18" rx="5" fill="#3A3631"/><circle cx="66" cy="65" r="2.6" fill="#E9E4DC"/><g transform="translate(41.5 22) scale(.026)"><path fill="#3A3631" d="${Logo.PATHS.outer}"/></g>`),
  trash: (full = false) => flat('#2C2B2A', `${full ? '<path d="M36 34q4-10 12-5 8-8 16 2z" fill="#E9E4DC"/>' : ''}<path d="M32 34h36l-4 42H36z" fill="none" stroke="#BDB6AE" stroke-width="4" stroke-linejoin="round"/><path d="M28 34h44M42 28h16" stroke="#BDB6AE" stroke-width="4" stroke-linecap="round"/>`),
};

// ---------- 16px line glyphs ----------
var g = (d, extra = '') => `<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" ${extra}>${d}</svg>`;

var GLYPHS = {
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

// ---------- QML helpers ----------
function uri(svgText) { return "data:image/svg+xml;utf8," + encodeURIComponent(svgText); }
function icon(name, arg) { return uri(APP_ICONS[name](arg)); }
function glyph(name, color) {
  var t = GLYPHS[name] || GLYPHS.sparkle;
  if (t.indexOf('xmlns') < 0) t = t.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ');
  return uri(t.split('currentColor').join(color || '#f7efe9'));
}
function maxwell(color) {
  var t = maxwellSVG(color || '#f7efe9');
  return uri(t);
}

// ---------- file icons (Files app) ----------
function page(band, label, lines) {
  return svg(`<path d="M14 4h22l12 12v38a3 3 0 0 1-3 3H14a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3z" fill="#fbf6f0"/><path d="M36 4v9a3 3 0 0 0 3 3h9z" fill="#e6dacd"/>${lines === false ? '' : '<path d="M17 26h20M17 31h24M17 36h16" stroke="#d8cabd" stroke-width="2" stroke-linecap="round"/>'}<rect x="11" y="42" width="37" height="11" fill="${band}"/><text x="29.5" y="50.5" text-anchor="middle" font-family="Instrument Sans" font-weight="700" font-size="7.5" fill="#fff">${label}</text>`, '0 0 60 60');
}
function photo(a, b) {
  return svg(`<defs>${lin('ph', a, b)}</defs><rect x="6" y="11" width="48" height="38" rx="3" fill="#fff"/><rect x="9" y="14" width="42" height="32" rx="1.5" fill="url(#ph)"/><circle cx="40" cy="22" r="4" fill="#fff4d6" fill-opacity=".9"/><path d="M9 46l12-12 9 8 7-6 14 10z" fill="#1B201D" fill-opacity=".5"/>`, '0 0 60 60');
}
var FILE_ICONS = {
  jpg: () => photo('#8DA2B4', '#3E4C59'), png: () => photo('#A7B2A0', '#4F5A4A'),
  pdf: () => page('#9A4B3A', 'PDF'), docx: () => page('#3E5568', 'DOC'), txt: () => page('#7A6C5D', 'TXT'),
  gz: () => page('#5B5550', 'TAR', false), mp3: () => page('#5E4A5A', 'MP3', false),
  iso: () => svg(`<defs><radialGradient id="dsc"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#ffd9b0"/><stop offset=".75" stop-color="#ffb3a0"/><stop offset="1" stop-color="#e9e2ff"/></radialGradient></defs><circle cx="30" cy="30" r="24" fill="url(#dsc)"/><circle cx="30" cy="30" r="6" fill="#1b1614" stroke="#ccc"/>`, '0 0 60 60'),
  folder: () => svg(`<path d="M10 26a6 6 0 0 1 6-6h22l7 7h39a6 6 0 0 1 6 6v6H10z" fill="#6F8496"/><rect x="10" y="32" width="80" height="54" rx="7" fill="#8FA3B3"/><path d="M10 39h80" stroke="#fff" stroke-opacity=".12"/>`),
};
function fileIcon(kind) { return uri((FILE_ICONS[kind] || FILE_ICONS.txt)()); }
function logo() { return Logo.uri(-1); }
