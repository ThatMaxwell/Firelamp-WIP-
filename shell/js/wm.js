// Window manager: open, focus, drag, resize, minimize to the dock, zoom, close.
import { bus, h } from './store.js';

const LIGHT_GLYPHS = {
  close: '<svg viewBox="0 0 8 8"><path d="M1.6 1.6l4.8 4.8M6.4 1.6L1.6 6.4" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/></svg>',
  min: '<svg viewBox="0 0 8 8"><path d="M1.4 4h5.2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/></svg>',
  zoom: '<svg viewBox="0 0 8 8"><path d="M1.6 5.6V1.6h4zM6.4 2.4v4h-4z" fill="currentColor"/></svg>',
};

export function createWM(desktop, { registry, dock }) {
  const wins = [];
  let z = 10, focused = null, cascade = 0;

  const workArea = () => ({ x: 0, y: 0, w: desktop.clientWidth, h: desktop.clientHeight - 88 });

  function focus(w) {
    if (focused === w) return;
    focused?.el.classList.remove('focused');
    focused = w;
    if (w) { w.el.style.zIndex = ++z; w.el.classList.add('focused'); }
    bus.emit('wm:focus', w);
  }

  function originFromDock(w) {
    const r = dock.rect(w.app.id), wr = w.el.getBoundingClientRect();
    if (!r) return;
    w.el.style.setProperty('--fx', (r.left + r.width / 2 - (wr.left + wr.width / 2)) + 'px');
    w.el.style.setProperty('--fy', (r.top + r.height / 2 - (wr.top + wr.height)) + 'px');
  }

  function open(id, opts = {}) {
    const app = registry[id];
    if (!app) return null;
    const existing = wins.find(w => w.app.id === id);
    if (existing && !app.multi) {
      if (existing.minimized) restore(existing); else focus(existing);
      return existing;
    }
    const wa = workArea();
    const width = Math.min(opts.w ?? app.w ?? 760, wa.w - 40);
    const height = Math.min(opts.h ?? app.h ?? 500, wa.h - 30);
    // leave room on the right for the assistant, which lives there
    const room = wins.some(w => w.app.id === 'assistant' && !w.minimized) && id !== 'assistant' ? 440 : 0;
    const x = opts.x ?? Math.max(16, Math.round((wa.w - room - width) / 2 + (cascade % 4) * 24 - 36));
    const y = opts.y ?? Math.round(Math.max(18, (wa.h - height) / 2 - 10) + (cascade % 5) * 22 - 30);
    cascade++;

    const body = h('div', { class: 'win-body' });
    const lights = h('div', { class: 'lights' },
      ['close', 'min', 'zoom'].map(k => h('button', { class: 'light ' + k, 'aria-label': { close: 'Close', min: 'Minimize', zoom: 'Zoom' }[k], 'data-ai': 'window control', html: LIGHT_GLYPHS[k] })));
    const bar = h('div', { class: 'win-titlebar' }, lights, app.titled ? h('div', { class: 'win-title' }, app.title) : null);
    const el = h('section', {
      class: 'win opening' + (app.titled ? ' titled' : ''), role: 'application', 'aria-label': app.title, 'data-app': id,
      style: { left: x + 'px', top: Math.max(0, y) + 'px', width: width + 'px', height: height + 'px', zIndex: ++z },
    }, bar, body, ['n', 's', 'e', 'w', 'ne', 'nw', 'se', 'sw'].map(d => h('div', { class: 'rz ' + d, 'data-dir': d })));
    desktop.append(el);

    const w = { app, el, body, minimized: false, zoomed: null, ctx: {} };
    wins.push(w);
    originFromDock(w);
    el.addEventListener('animationend', () => el.classList.remove('opening', 'restoring'), { once: false });

    lights.children[0].addEventListener('click', e => { e.stopPropagation(); close(w); });
    lights.children[1].addEventListener('click', e => { e.stopPropagation(); minimize(w); });
    lights.children[2].addEventListener('click', e => { e.stopPropagation(); zoom(w); });
    el.addEventListener('pointerdown', () => focus(w), true);
    bar.addEventListener('dblclick', e => { if (!e.target.closest('button')) zoom(w); });
    makeDraggable(w, bar);
    makeResizable(w);

    app.render(body, w, opts);
    dock.setRunning(id, true);
    dock.bounce(id);
    focus(w);
    bus.emit('wm:open', w);
    return w;
  }

  function close(w) {
    w.el.classList.add('closing');
    setTimeout(() => {
      w.el.remove();
      wins.splice(wins.indexOf(w), 1);
      w.app.onClose?.(w);
      if (!wins.some(o => o.app.id === w.app.id)) dock.setRunning(w.app.id, false);
      if (focused === w) { focused = null; focus(topmost()); }
      bus.emit('wm:close', w);
    }, 190);
  }

  function minimize(w) {
    originFromDock(w);
    w.el.classList.add('minimizing');
    setTimeout(() => {
      w.el.classList.remove('minimizing');
      w.el.style.display = 'none';
      w.minimized = true;
      if (focused === w) { focused = null; focus(topmost()); }
    }, 480);
  }

  function restore(w) {
    w.el.style.display = '';
    w.minimized = false;
    originFromDock(w);
    w.el.classList.add('restoring');
    focus(w);
  }

  function zoom(w) {
    const s = w.el.style;
    w.el.classList.add('animate-frame');
    if (w.zoomed) {
      Object.assign(s, w.zoomed); w.zoomed = null; w.el.classList.remove('zoomed');
    } else {
      w.zoomed = { left: s.left, top: s.top, width: s.width, height: s.height };
      const wa = workArea();
      Object.assign(s, { left: '6px', top: '6px', width: wa.w - 12 + 'px', height: wa.h - 4 + 'px' });
    }
    setTimeout(() => w.el.classList.remove('animate-frame'), 380);
  }

  const topmost = () => wins.filter(w => !w.minimized).sort((a, b) => b.el.style.zIndex - a.el.style.zIndex)[0] || null;

  function makeDraggable(w, handle) {
    handle.addEventListener('pointerdown', e => {
      if (e.button !== 0 || e.target.closest('button, input, textarea, [data-nodrag]')) return;
      const sx = e.clientX, sy = e.clientY, ox = w.el.offsetLeft, oy = w.el.offsetTop;
      handle.setPointerCapture(e.pointerId);
      const move = ev => {
        w.el.style.left = ox + ev.clientX - sx + 'px';
        w.el.style.top = Math.max(0, oy + ev.clientY - sy) + 'px';
      };
      const up = () => { handle.removeEventListener('pointermove', move); handle.removeEventListener('pointerup', up); };
      handle.addEventListener('pointermove', move);
      handle.addEventListener('pointerup', up);
    });
  }

  function makeResizable(w) {
    w.el.querySelectorAll('.rz').forEach(rz => rz.addEventListener('pointerdown', e => {
      e.stopPropagation();
      const d = rz.dataset.dir, sx = e.clientX, sy = e.clientY;
      const o = { x: w.el.offsetLeft, y: w.el.offsetTop, w: w.el.offsetWidth, h: w.el.offsetHeight };
      rz.setPointerCapture(e.pointerId);
      const move = ev => {
        const dx = ev.clientX - sx, dy = ev.clientY - sy, s = w.el.style;
        if (d.includes('e')) s.width = Math.max(320, o.w + dx) + 'px';
        if (d.includes('s')) s.height = Math.max(200, o.h + dy) + 'px';
        if (d.includes('w')) { const nw = Math.max(320, o.w - dx); s.width = nw + 'px'; s.left = o.x + o.w - nw + 'px'; }
        if (d.includes('n')) { const nh = Math.max(200, o.h - dy); s.height = nh + 'px'; s.top = Math.max(0, o.y + o.h - nh) + 'px'; }
      };
      const up = () => { rz.removeEventListener('pointermove', move); rz.removeEventListener('pointerup', up); };
      rz.addEventListener('pointermove', move);
      rz.addEventListener('pointerup', up);
    }));
  }

  bus.on('wm:close-focused', () => focused && close(focused));
  bus.on('wm:minimize-focused', () => focused && minimize(focused));
  bus.on('wm:zoom-focused', () => focused && zoom(focused));
  desktop.addEventListener('pointerdown', e => { if (e.target === desktop) focus(null); });

  return { registryTitle: id => registry[id]?.title || id, open, close, focus, minimize, restore, zoom, get: id => wins.find(w => w.app.id === id), all: () => wins, focused: () => focused };
}
