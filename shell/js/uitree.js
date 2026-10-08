// The live UI tree. Instead of screenshots, the AI reads this: every window, button and
// field with its role, label and exact bounds, and it hears about every change.
//
// On the real OS this tree comes from AT-SPI2 over D-Bus for native apps; the shell's own
// surfaces publish theirs the same way. Here it is built from the shell's DOM.
import { bus } from './store.js';

const ids = new WeakMap();
let nextId = 1;
const idOf = el => ids.get(el) ?? (ids.set(el, nextId++), ids.get(el));

const INTERACTIVE = 'button, input, textarea, select, a[href], [contenteditable="true"], [role], [aria-label], [data-ai]';

function roleOf(el) {
  const r = el.getAttribute('role');
  if (r) return r;
  switch (el.tagName) {
    case 'BUTTON': return 'button';
    case 'INPUT': return el.type === 'checkbox' ? 'checkbox' : el.type === 'range' ? 'slider' : 'textbox';
    case 'TEXTAREA': return 'textbox';
    case 'SELECT': return 'combobox';
    case 'A': return 'link';
  }
  if (el.isContentEditable) return 'textbox';
  return el.dataset.ai || 'item';
}

function nameOf(el) {
  return (el.getAttribute('aria-label') || el.getAttribute('placeholder') || el.getAttribute('title') ||
    el.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 64);
}

function visible(el) {
  if (el.closest('[data-ai-hidden]')) return false;
  const r = el.getBoundingClientRect();
  if (r.width < 2 || r.height < 2) return false;
  if (r.bottom < 0 || r.right < 0 || r.top > innerHeight || r.left > innerWidth) return false;
  const cs = getComputedStyle(el);
  return cs.visibility !== 'hidden' && cs.display !== 'none' && +cs.opacity > 0.05;
}

const ROOTS = ['#menubar', '#desktop', '#dock', '#modal-layer'];

/** Flat list of every element the AI can perceive right now. */
export function nodes() {
  const out = [];
  for (const sel of ROOTS) {
    const root = document.querySelector(sel);
    if (!root) continue;
    for (const el of root.querySelectorAll(INTERACTIVE)) {
      if (!visible(el)) continue;
      const r = el.getBoundingClientRect();
      const win = el.closest('.win');
      out.push({
        id: idOf(el), el, role: roleOf(el), name: nameOf(el),
        value: 'value' in el ? el.value : undefined,
        app: win?.dataset.app ?? (el.closest('#dock') ? 'dock' : el.closest('#menubar') ? 'menubar' : 'system'),
        z: win ? +win.style.zIndex : 99999,
        bounds: { x: Math.round(r.left), y: Math.round(r.top), w: Math.round(r.width), h: Math.round(r.height) },
      });
    }
  }
  return out;
}

/** Nested tree, for the terminal's `tree` command and for debugging. */
export function snapshot() {
  const list = nodes();
  const byApp = {};
  for (const n of list) (byApp[n.app] ??= []).push(n);
  return Object.entries(byApp).map(([app, children]) => ({ role: app === 'menubar' || app === 'dock' ? app : 'window', name: app, children }));
}

const norm = s => (s || '').toLowerCase().replace(/[^\p{L}\p{N} ]/gu, ' ').replace(/\s+/g, ' ').trim();

/**
 * Pick the element that best matches a target description. This is the "reflex" a fast
 * decision model (Jev) makes on the real system; here it is a small scorer over the tree.
 */
export function find({ name, role, app, exact = false }) {
  const want = norm(name);
  let best = null, bestScore = 0;
  for (const n of nodes()) {
    if (app && n.app !== app) continue;
    if (role && n.role !== role) continue;
    const have = norm(n.name);
    let s = 0;
    if (have === want) s = 100;
    else if (!exact && have.startsWith(want)) s = 70;
    else if (!exact && have.includes(want)) s = 50;
    else if (!exact) {
      const words = want.split(' ');
      const hits = words.filter(w => have.includes(w)).length;
      s = hits ? 30 * hits / words.length : 0;
    }
    if (!s) continue;
    s += n.z / 1e5; // prefer what is on top
    if (s > bestScore) { bestScore = s; best = n; }
  }
  return best;
}

/** Notify listeners the moment anything on screen changes. */
export function watch() {
  let queued = false;
  const mo = new MutationObserver(() => {
    if (queued) return;
    queued = true;
    queueMicrotask(() => { queued = false; bus.emit('uitree:change'); });
  });
  for (const sel of ROOTS) {
    const root = document.querySelector(sel);
    if (root) mo.observe(root, { subtree: true, childList: true, attributes: true, characterData: true, attributeFilter: ['class', 'style', 'aria-label', 'value'] });
  }
}
