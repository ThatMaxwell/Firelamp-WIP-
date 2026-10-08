// The dock. Mac-style magnification: icons swell with a cosine falloff around the
// pointer and push their neighbours apart, eased every frame so it feels liquid.
import { bus, h } from './store.js';
import { APP_ICONS } from './icons.js';

const MAX = 1.62;           // peak magnification
const REACH = 2.9;          // falloff radius, in base icon widths

export function mountDock(root, { items, onLaunch }) {
  const base = parseFloat(getComputedStyle(root).getPropertyValue('--base')) || 54;
  const els = new Map();
  const nodes = [];

  for (const it of items) {
    if (it === '-') { root.append(h('div', { class: 'dock-sep' })); continue; }
    const icon = h('div', { class: 'dock-icon', html: APP_ICONS[it.icon]() });
    const el = h('div', {
      class: 'dock-item', role: 'button', 'aria-label': it.title, 'data-app': it.id,
      onclick: () => onLaunch(it.id),
    }, icon, h('div', { class: 'dock-tip' }, it.title), h('div', { class: 'dock-dot' }));
    root.append(el);
    els.set(it.id, el);
    nodes.push({ el, size: base, target: base });
  }

  let mouseX = null, raf = 0;
  const step = () => {
    raf = 0;
    // centres of every item in the un-magnified layout, so the falloff never feeds back on itself
    const dockRect = root.getBoundingClientRect();
    const totalNow = nodes.reduce((s, n) => s + n.size + 4, 0);
    const extra = dockRect.width - totalNow;           // padding + separators
    const baseWidth = nodes.length * (base + 4) + extra;
    const baseLeft = innerWidth / 2 - baseWidth / 2;
    let x = baseLeft + 6, moving = false;
    for (const n of nodes) {
      // walk the real DOM order so separators are accounted for
      const prev = n.el.previousElementSibling;
      if (prev?.classList.contains('dock-sep')) x += 15;
      const cx = x + 2 + base / 2;
      x += base + 4;
      let t = 1;
      if (mouseX != null) {
        const d = Math.abs(mouseX - cx) / (base * REACH);
        t = d >= 1 ? 1 : 1 + (MAX - 1) * (Math.cos(d * Math.PI) + 1) / 2;
      }
      n.target = base * t;
      n.size += (n.target - n.size) * .32;
      if (Math.abs(n.target - n.size) > .2) moving = true; else n.size = n.target;
      n.el.style.setProperty('--s', n.size.toFixed(2) + 'px');
    }
    if (moving) raf = requestAnimationFrame(step);
  };
  const kick = () => { if (!raf) raf = requestAnimationFrame(step); };
  root.addEventListener('pointermove', e => { mouseX = e.clientX; kick(); });
  root.addEventListener('pointerleave', () => { mouseX = null; kick(); });

  const api = {
    el: id => els.get(id),
    rect: id => els.get(id)?.querySelector('.dock-icon').getBoundingClientRect(),
    setRunning: (id, on) => els.get(id)?.classList.toggle('running', on),
    setAiActive: (id, on) => els.get(id)?.classList.toggle('ai-active', on),
    bounce(id) {
      const el = els.get(id); if (!el) return;
      el.classList.remove('bounce'); void el.offsetWidth; el.classList.add('bounce');
      setTimeout(() => el.classList.remove('bounce'), 1300);
    },
    refreshIcon(id, iconKey, ...args) {
      const el = els.get(id); if (el) el.querySelector('.dock-icon').innerHTML = APP_ICONS[iconKey](...args);
    },
  };
  bus.on('dock:hide', on => root.classList.toggle('hidden-dock', on));
  return api;
}
