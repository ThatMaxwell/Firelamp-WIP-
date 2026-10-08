import { bus, h, settings, assistantName } from '../store.js';
import { GLYPHS, logoSVG, maxwellSVG } from '../icons.js';

const toggle = (key, label, hint) => {
  const t = h('button', { class: 'toggle', role: 'switch', 'aria-label': label, 'aria-checked': String(!!settings.get(key)) });
  t.addEventListener('click', () => {
    const v = !settings.get(key);
    if (key === 'visionOverlay') bus.emit('vision:toggle', v); else settings.set(key, v);
    t.setAttribute('aria-checked', String(v));
  });
  bus.on('settings', e => { if (e.key === key) t.setAttribute('aria-checked', String(!!e.value)); });
  return h('div', { class: 'row' }, h('div', { class: 'lbl' }, h('b', {}, label), hint ? h('span', {}, hint) : null), t);
};

export const settingsApp = {
  id: 'settings', title: 'System Settings', icon: 'settings', w: 720, h: 560,
  render(body) {
    const name = h('input', { 'aria-label': 'Assistant name', value: settings.get('assistantName'), maxlength: 24, placeholder: 'Name your assistant' });
    name.addEventListener('change', () => { if (name.value.trim()) settings.set('assistantName', name.value.trim()); });
    const speed = h('input', { type: 'range', class: 'slider', min: .5, max: 2, step: .1, value: settings.get('cursorSpeed'), 'aria-label': 'Cursor speed' });
    speed.addEventListener('input', () => settings.set('cursorSpeed', +speed.value));

    body.append(
      h('div', { class: 'sidebar' },
        h('div', { class: 'tb-search', style: { width: 'auto', margin: '0 2px 10px' } }, h('span', { html: GLYPHS.search }), 'Search'),
        [['Assistant', GLYPHS.sparkle, true], ['Permissions', GLYPHS.shield], ['Fire Cursor', GLYPHS.cursor], ['Activity', GLYPHS.clock], ['Appearance', GLYPHS.moon], ['Wi-Fi', GLYPHS.wifi], ['Sound', GLYPHS.volume], ['Bluetooth', GLYPHS.bluetooth]]
          .map(([n, g, s]) => h('div', { class: 'side-i' + (s ? ' sel' : ''), role: 'button', 'aria-label': n }, h('span', { html: g }), n))),
      h('div', { class: 'main' },
        h('div', { class: 'toolbar' }, h('h1', {}, 'Assistant')),
        h('div', { class: 'set-pane scroll' },
          h('div', { class: 'set-hero' }, h('div', { html: logoSVG({ animated: true }) }), h('div', { style: { flex: 1 } }, name, h('span', {}, 'The name your assistant answers to, and the name on its cursor.'))),
          h('div', {}, h('div', { class: 'group-h' }, 'Safety'), h('div', { class: 'group' },
            toggle('askBeforeRisky', 'Ask before risky actions', 'Deleting, sending, paying. The OS asks you, never the AI.'),
            h('div', { class: 'row' }, h('div', { class: 'lbl' }, h('b', {}, 'Pause or stop instantly'), h('span', {}, 'Works from anywhere, even mid-click')), h('span', { class: 'kbd' }, '⌃ Space'), h('span', { class: 'kbd' }, 'Esc')))),
          h('div', {}, h('div', { class: 'group-h' }, 'Fire cursor'), h('div', { class: 'group' },
            h('div', { class: 'row' }, h('div', { class: 'lbl' }, h('b', {}, 'Speed'), h('span', {}, 'How fast it moves between things')), speed),
            toggle('showTrail', 'Ember trail', 'Little sparks that follow it around'),
            toggle('visionOverlay', 'Show what the AI sees', 'Outline every element in the live UI tree'))))));
  },
};

export const about = {
  id: 'about', title: 'About Firelamp OS', icon: 'assistant', w: 340, h: 470,
  render(body) {
    const rows = [
      ['Version', '0.1 “Kindling”'], ['Base', 'Arch Linux'], ['Assistant', assistantName()],
      ['Brain', 'Large language model'], ['Reflexes', 'Jev by TypeSafe'], ['UI tree', 'AT-SPI2, live'],
    ];
    body.append(h('div', { class: 'about' },
      h('div', { html: logoSVG({ cls: 'a-logo', animated: true }) }),
      h('h1', {}, 'Firelamp OS'),
      h('div', { class: 'ver' }, 'The best OS for AI automation'),
      h('dl', {}, rows.map(([k, v]) => h('div', {}, h('dt', {}, k), h('dd', {}, v)))),
      h('div', { class: 'made' }, h('span', { html: maxwellSVG() }), 'Made with care by', h('a', { href: 'https://github.com/thatmaxwell', target: '_blank', rel: 'noopener' }, 'ThatMaxwell'))));
  },
};
