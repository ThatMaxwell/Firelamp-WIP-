// The activity timeline: a readable log of everything the AI did, and why.
import { bus, h, assistantName } from '../store.js';
import { GLYPHS, logoSVG } from '../icons.js';

const KIND_ICON = { open: GLYPHS.open, click: GLYPHS.click, type: GLYPHS.type, ask: GLYPHS.shield, denied: GLYPHS.x, done: GLYPHS.check, look: GLYPHS.eye, move: GLYPHS.folder, think: GLYPHS.sparkle };

export function mountTimeline(panel) {
  const list = h('div', { class: 'tl-list scroll' });
  const sub = h('div', { class: 'sub' });
  const empty = () => h('div', { class: 'tl-empty' }, h('div', { html: logoSVG() }), h('div', {}, `Nothing yet. When ${assistantName()} does something, it shows up here with the reason why.`));
  panel.append(
    h('div', { class: 'tl-head' },
      h('div', { html: logoSVG({ cls: 'tl-logo' }) }),
      h('div', {}, h('h3', {}, 'Activity'), sub),
      h('div', { class: 'grow' }),
      h('button', { class: 'tb-btn', 'aria-label': 'Close timeline', html: GLYPHS.x, onclick: () => toggle(false) })),
    list,
    h('div', { class: 'tl-foot' }, h('span', { html: GLYPHS.shield }), h('span', {}, 'Every action is logged. Risky ones always ask you first.')));
  list.append(empty());

  const setSub = () => { sub.textContent = `What ${assistantName()} did, and why`; };
  setSub();
  bus.on('settings', setSub);

  let entries = 0;
  bus.on('agent:log', e => {
    if (!entries++) { list.innerHTML = ''; list.append(h('div', { class: 'tl-day' }, 'Today')); }
    const t = new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', second: '2-digit' });
    const title = h('div', { class: 'tl-title' });
    // quote the element name: Clicked “Compose”
    const m = e.title.match(/^(.*?)“(.+)”(.*)$/);
    if (m) title.append(m[1], h('q', {}, m[2]), m[3]); else title.textContent = e.title;
    list.firstChild.after(h('div', { class: 'tl-entry ' + e.kind },
      h('div', { class: 'tl-spine' }, h('div', { class: 'tl-node', html: KIND_ICON[e.kind] || GLYPHS.sparkle })),
      h('div', { class: 'tl-card' }, title,
        e.why ? h('div', { class: 'tl-why' }, e.why) : null,
        h('div', { class: 'tl-meta' }, h('span', {}, t), e.app ? h('span', { class: 'tl-chip' }, e.app) : null))));
  });

  function toggle(on) {
    on = on ?? !panel.classList.contains('open');
    panel.classList.toggle('open', on);
  }
  bus.on('timeline:toggle', on => toggle(on));
  return { toggle };
}
