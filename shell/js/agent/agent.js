// The agent runtime. A plan (from the "brain") is a sequence of small actions; each one
// is resolved against the live UI tree (the "reflexes"), performed with the fire cursor,
// and written to the timeline with its reason. Pause and stop work at any moment.
import { bus, h, sleep, settings, assistantName } from '../store.js';
import { GLYPHS, logoSVG } from '../icons.js';
import { find } from '../uitree.js';
import { FireCursor, spark } from './cursor.js';
import { askPermission } from './permission.js';

class Stopped extends Error {}

export function createAgent({ wm, dock }) {
  const cursor = new FireCursor(document.getElementById('fire-cursor'));
  const gate = { paused: false, stopped: false, resume: null };
  let state = 'idle', capsule = null, mark = null, steps = 0;

  const setState = s => { state = s; bus.emit('agent:state', s); dock.setAiActive('assistant', s !== 'idle'); };

  // ---------- capsule ----------
  function showCapsule() {
    const slot = document.getElementById('capsule-slot');
    const what = h('span', { class: 'what' }, 'Getting ready…');
    const count = h('span', { class: 'count' }, '');
    const pauseBtn = h('button', { class: 'cap-btn', 'aria-label': 'Pause', 'data-ai-hidden': '', html: GLYPHS.pause, onclick: () => togglePause() });
    const stopBtn = h('button', { class: 'cap-btn stop', 'aria-label': 'Stop', 'data-ai-hidden': '', html: GLYPHS.stop, onclick: () => stop() });
    capsule = h('div', { class: 'capsule ink', 'data-ai-hidden': '' },
      h('span', { html: logoSVG({ cls: 'cap-logo', animated: true }) }),
      h('span', { class: 'who' }, assistantName()), what, count, pauseBtn, stopBtn);
    capsule.set = text => {
      what.classList.add('swap');
      setTimeout(() => { what.textContent = text; what.classList.remove('swap'); }, 120);
    };
    capsule.count = n => { count.textContent = `${n} step${n === 1 ? '' : 's'}`; };
    capsule.paused = p => { capsule.classList.toggle('paused', p); pauseBtn.innerHTML = p ? GLYPHS.play : GLYPHS.pause; pauseBtn.setAttribute('aria-label', p ? 'Resume' : 'Pause'); };
    slot.replaceChildren(capsule);
  }
  function hideCapsule() {
    const c = capsule; capsule = null;
    if (!c) return;
    c.classList.add('out'); setTimeout(() => c.remove(), 320);
  }

  // ---------- target mark ----------
  function markEl(el) {
    const r = el.getBoundingClientRect(), pad = 4;
    if (!mark) { mark = h('div', { class: 'target-mark' }); document.body.append(mark); }
    mark.classList.remove('out');
    Object.assign(mark.style, { left: r.left - pad + 'px', top: r.top - pad + 'px', width: r.width + pad * 2 + 'px', height: r.height + pad * 2 + 'px' });
  }
  function unmark() {
    const m = mark; mark = null;
    if (m) { m.classList.add('out'); setTimeout(() => m.remove(), 300); }
  }

  // ---------- control ----------
  async function checkpoint() {
    if (gate.stopped) throw new Stopped();
    if (gate.paused) await new Promise(r => (gate.resume = r));
    if (gate.stopped) throw new Stopped();
  }
  function togglePause() {
    if (state === 'idle') return;
    gate.paused = !gate.paused;
    cursor.setPaused(gate.paused);
    capsule?.paused(gate.paused);
    setState(gate.paused ? 'paused' : 'running');
    if (gate.paused) cursor.say('paused'); else { gate.resume?.(); gate.resume = null; }
  }
  function stop() {
    if (state === 'idle') return;
    gate.stopped = true; gate.paused = false;
    gate.resume?.(); gate.resume = null;
  }
  bus.on('agent:toggle-pause', togglePause);
  bus.on('agent:stop', stop);
  addEventListener('keydown', e => {
    if (state === 'idle') return;
    if (e.key === 'Escape' && !document.querySelector('.perm')) stop();
    if (e.key === ' ' && e.ctrlKey) { e.preventDefault(); togglePause(); }
  });

  const log = (kind, title, why, app) => { bus.emit('agent:log', { kind, title, why, app }); capsule?.count(++steps); };
  const appTitle = id => wm.get(id)?.app.title || id;

  // ---------- actions a plan can use ----------
  const act = {
    say: text => bus.emit('agent:say', text),

    async think(text, ms = 700) {
      await checkpoint();
      capsule?.set(text); cursor.say(text.toLowerCase().replace(/…$/, '') + '…');
      await sleep(ms);
    },

    async open(id, why) {
      await checkpoint();
      capsule?.set(`Opening ${wm.registryTitle(id)}`);
      cursor.say('opening ' + wm.registryTitle(id));
      const r = dock.rect(id);
      if (r) {
        await cursor.moveTo(r.left + r.width / 2, r.top + r.height / 2, { gate });
        await checkpoint();
        await cursor.click();
      }
      const w = wm.open(id);
      log('open', `Opened ${w.app.title}`, why, w.app.title);
      await sleep(520);
      return w;
    },

    async locate(target) {
      for (let i = 0; i < 20; i++) {             // the UI may still be animating in
        const n = find(target);
        if (n) return n;
        await sleep(80);
      }
      throw new Error(`Couldn't find “${target.name}” on screen`);
    },

    async point(target, verb) {
      await checkpoint();
      const n = await act.locate(target);
      const b = n.bounds;
      cursor.say(verb + ' ' + (target.say || n.name));
      markEl(n.el);
      const tx = b.x + Math.min(b.w / 2, 40 + Math.random() * 20), ty = b.y + b.h / 2;
      await cursor.moveTo(b.w > 120 ? tx : b.x + b.w / 2, ty, { gate });
      await checkpoint();
      return n;
    },

    async click(target, why, { title } = {}) {
      capsule?.set(title || `Clicking “${target.say || target.name}”`);
      const n = await act.point(target, 'clicking');
      await cursor.click();
      n.el.focus?.({ preventScroll: true });
      n.el.click();
      log('click', title || `Clicked “${target.say || n.name}”`, why, appTitle(n.app));
      await sleep(260);
      unmark();
      return n;
    },

    async type(target, text, why, { title, cps = 38 } = {}) {
      capsule?.set(title || `Typing in “${target.say || target.name}”`);
      const n = await act.point(target, 'typing in');
      await cursor.click();
      const el = n.el;
      el.focus({ preventScroll: true });
      cursor.say('typing…');
      const speed = settings.get('cursorSpeed') || 1;
      for (const ch of text) {
        await checkpoint();
        if (el.isContentEditable) el.textContent += ch;
        else { el.value += ch; el.scrollTop = el.scrollHeight; }
        el.dispatchEvent(new Event('input', { bubbles: true }));
        await sleep((ch === ' ' ? 1.6 : 1) * 1000 / cps / speed * (0.6 + Math.random() * 0.8));
      }
      log('type', title || `Typed into “${target.say || n.name}”`, why, appTitle(n.app));
      unmark();
      return n;
    },

    /** Press on one thing, carry it across, drop it on another. */
    async drag(src, dst, why, { onDrop, title } = {}) {
      capsule?.set(title || `Moving “${src.name}” to “${dst.name}”`);
      const s = await act.point(src, 'grabbing');
      cursor.root.classList.add('press');
      const ghost = h('div', { class: 'ghost' }, (s.el.querySelector('.fi') || s.el).cloneNode(true));
      document.body.append(ghost);
      cursor.carry = ghost; cursor.place();
      s.el.style.opacity = .35;
      unmark();
      const d = await act.locate(dst);
      cursor.say('moving to ' + d.name);
      markEl(d.el);
      d.el.classList.add('drop');
      await cursor.moveTo(d.bounds.x + d.bounds.w / 2, d.bounds.y + d.bounds.h / 2 - 10, { gate });
      await checkpoint();
      cursor.root.classList.remove('press');
      cursor.carry = null; ghost.remove();
      d.el.classList.remove('drop');
      spark(cursor.x, cursor.y, 10, 1.3);
      await onDrop?.(s, d);
      log('move', title || `Moved “${s.name}” into “${d.name}”`, why, appTitle(s.app));
      unmark();
    },

    /** Risky step: always asks the human first (unless they turned that off). */
    async confirm(request, why) {
      await checkpoint();
      if (!settings.get('askBeforeRisky')) return true;
      capsule?.set('Waiting for your OK');
      cursor.say('waiting for you');
      log('ask', request.logTitle || 'Asked for permission', why, 'Firelamp');
      bus.emit('agent:asking', true);
      const ok = await askPermission({ ...request, why });
      bus.emit('agent:asking', false);
      if (!ok) log('denied', 'You said no, so I stopped there', null, 'Firelamp');
      return ok;
    },

    log,
    wm, cursor, gate, checkpoint,
  };

  // ---------- run a plan ----------
  async function run(plan, { label }) {
    if (state !== 'idle') { act.say("I'm still working on the last thing. Pause or stop me first."); return; }
    gate.paused = gate.stopped = false; steps = 0;
    setState('running');
    showCapsule();
    capsule.set(label);
    const r = dock.rect('assistant');
    cursor.show(r ? { x: r.left + r.width / 2, y: r.top } : null);
    cursor.say('');
    try {
      await plan(act);
      log('done', 'Done', label, 'Firelamp');
    } catch (e) {
      if (e instanceof Stopped) { log('denied', 'Stopped by you', 'You pressed stop, so I stopped right away.', 'Firelamp'); act.say('Stopped. Nothing else was changed.'); }
      else { console.error(e); act.say(`I got stuck: ${e.message}.`); }
    } finally {
      unmark();
      cursor.say('');
      cursor.setPaused(false);
      // drift home and fade out
      if (r) await cursor.moveTo(r.left + r.width / 2, r.top + 4);
      cursor.hide();
      hideCapsule();
      setState('idle');
    }
  }

  return { run, act, state: () => state, togglePause, stop, cursor };
}
