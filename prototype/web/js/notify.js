import { h } from './store.js';
import { APP_ICONS } from './icons.js';

export function toast({ icon = 'assistant', title, body, ms = 4200 }) {
  const t = h('div', { class: 'toast', role: 'status' },
    h('div', { class: 't-icon', html: APP_ICONS[icon]() }),
    h('div', {}, h('b', {}, title), h('span', {}, body)),
    h('time', {}, 'now'));
  document.getElementById('toasts').prepend(t);
  setTimeout(() => { t.classList.add('out'); setTimeout(() => t.remove(), 360); }, ms);
}
