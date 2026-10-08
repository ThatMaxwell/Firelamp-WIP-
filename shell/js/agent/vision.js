// "Show what the AI sees": draws the live UI tree over the screen. No screenshots,
// just the exact roles, labels and bounds the AI reads.
import { bus, h, settings } from '../store.js';
import { nodes } from '../uitree.js';

export function mountVision(root) {
  let on = false, raf = 0, last = 0, changes = 0, lastChange = '';
  const hud = h('div', { class: 'v-hud' });

  const draw = now => {
    raf = on ? requestAnimationFrame(draw) : 0;
    if (now - last < 90) return;
    last = now;
    const list = nodes();
    const frag = document.createDocumentFragment();
    for (const n of list) {
      if (n.app === 'menubar' && n.role !== 'button') continue;
      const { x, y, w, h: hh } = n.bounds;
      const cls = n.role === 'application' ? 'window' : n.role === 'textbox' ? 'input' : '';
      frag.append(h('div', { class: 'v-box ' + cls, style: { left: x + 'px', top: y + 'px', width: w + 'px', height: hh + 'px' } },
        (w > 26 || cls) ? h('span', { class: 'v-tag' }, `${n.role}${n.name ? ' · ' + n.name : ''}`) : null));
    }
    hud.innerHTML = `<span class="live">LIVE</span><span><b>${list.length}</b> elements</span><span><b>${changes}</b> changes</span><span>${lastChange}</span><span>0 screenshots</span>`;
    frag.append(hud);
    root.replaceChildren(frag);
  };

  bus.on('uitree:change', () => { changes++; lastChange = 'updated ' + new Date().toLocaleTimeString('en-US', { hour12: false }); });

  function set(v) {
    on = v;
    root.classList.toggle('on', on);
    if (on && !raf) raf = requestAnimationFrame(draw);
    if (!on) setTimeout(() => { if (!on) root.replaceChildren(); }, 300);
    if (settings.get('visionOverlay') !== on) settings.set('visionOverlay', on);
  }
  bus.on('vision:toggle', v => set(v ?? !on));
  if (settings.get('visionOverlay')) set(true);
  return { set, get on() { return on; } };
}
