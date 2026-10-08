/* Firelamp launch intro: a ~30s "video" rendered live in the DOM, synced to music.js */
window.Intro = (() => {
  const LEN = 30.6;
  const el = document.getElementById('intro');
  const desk = document.getElementById('desk');
  const fcur = document.getElementById('fcur');
  const ucur = document.getElementById('ucur');
  const bar = el.querySelector('.iv-progress i');
  const scenes = { A: [0, 4], B: [4, 7.55], C: [8, 12], D: [12, 22], E: [22, 26], F: [26, 99] };
  const D = 12; // live demo start

  let raf, wall0, done, fired, scale = 1, onEnd, typed = {};

  const ease = x => x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
  const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
  const $ = s => desk.querySelector(s);

  /* ---- layout: the desktop is designed at a fixed size and scaled to fit ---- */
  function layout() {
    const vw = innerWidth, vh = innerHeight, portrait = vw / vh < 0.85;
    desk.classList.toggle('portrait', portrait);
    const W = portrait ? 560 : 960, H = portrait ? 860 : 600;
    desk.style.width = W + 'px'; desk.style.height = H + 'px';
    scale = Math.min((vw * (portrait ? 0.92 : 0.86)) / W, (vh * (portrait ? 0.74 : 0.74)) / H);
    desk.style.setProperty('--k', scale);
  }
  function pt(sel, fx = 0.5, fy = 0.5) {
    const n = typeof sel === 'string' ? $(sel) : sel, d = desk.getBoundingClientRect(), r = n.getBoundingClientRect();
    return [(r.left - d.left + r.width * fx) / scale, (r.top - d.top + r.height * fy) / scale];
  }

  /* ---- fire cursor path: waypoints [time, target, fx, fy, click?] ---- */
  const FPATH = [
    [D + 0.9, '.as-av', 0.5, 0.5], [D + 1.65, '[data-node=dockmail]', 0.5, 0.45, 1],
    [D + 2.35, '[data-node=dockmail]', 0.5, 0.45], [D + 2.75, '[data-node=to]', 0.3, 0.55, 1],
    [D + 3.5, '[data-node=to]', 0.3, 0.55], [D + 3.8, '[data-node=subj]', 0.35, 0.55, 1],
    [D + 4.4, '[data-node=subj]', 0.35, 0.55], [D + 4.7, '[data-node=body]', 0.25, 0.3, 1],
    [D + 6.0, '[data-node=body]', 0.6, 0.6], [D + 6.3, '[data-node=attach]', 0.5, 0.5, 1],
    [D + 6.7, '[data-node=attach]', 0.5, 0.5], [D + 7.0, '[data-node=send]', 0.5, 0.5, 1],
    [D + 8.3, '[data-node=send]', 0.5, 0.5], [D + 9.0, '.as-av', 0.6, 0.6]
  ];
  const UPATH = [[D + 7.0, 'corner'], [D + 7.95, '[data-node=allow]', 0.45, 0.6, 1], [D + 9.5, 'corner2']];

  function resolve(w) {
    if (w[1] === 'corner') return [desk.offsetWidth + 40, desk.offsetHeight * 0.9];
    if (w[1] === 'corner2') return [desk.offsetWidth * 0.8, desk.offsetHeight + 40];
    return pt(w[1], w[2], w[3]);
  }
  function along(path, t) {
    if (t <= path[0][0]) return { p: resolve(path[0]), moving: false };
    for (let i = 1; i < path.length; i++) {
      const a = path[i - 1], b = path[i];
      if (t <= b[0]) {
        const k = ease(clamp((t - a[0]) / (b[0] - a[0]))), A = resolve(a), B = resolve(b);
        const dx = B[0] - A[0], dy = B[1] - A[1], arc = Math.sin(k * Math.PI) * 0.12;
        return { p: [A[0] + dx * k - dy * arc, A[1] + dy * k + dx * arc], moving: k > 0 && k < 1 };
      }
    }
    return { p: resolve(path[path.length - 1]), moving: false };
  }
  function place(node, p) { node.style.transform = `translate(${p[0]}px, ${p[1]}px)`; }

  /* ---- one-shot cues ---- */
  const T = window.I18N;
  let L = 'en';
  const cues = [
    [0, () => scene('A')], [4, () => scene('B')], [7.55, () => scene(null)],
    [8, () => { scene('C'); el.classList.add('shake'); }], [8.6, () => el.classList.remove('shake')],
    [D, () => scene('D')], [D + 0.2, () => $('.bubble.me').classList.add('on')], [D + 0.75, () => $('.bubble.ai').classList.add('on')],
    [D + 0.9, () => fcur.classList.add('on')],
    [D + 1.65, () => click(fcur)], [D + 1.8, () => { $('#mailwin').classList.add('on'); log(0); }],
    [D + 2.25, () => { buildTags(); $('#mailwin').classList.add('tags'); }], [D + 3.6, () => $('#mailwin').classList.add('tags-dim')],
    [D + 2.75, () => { click(fcur); focus('to'); }], [D + 3.8, () => { click(fcur); focus('subj'); log(1); }],
    [D + 4.7, () => { click(fcur); focus('body'); }], [D + 6.0, () => log(2)],
    [D + 6.3, () => { click(fcur); focus(null); $('.attach-row').classList.add('on'); }], [D + 6.6, () => log(3)],
    [D + 7.0, () => { click(fcur); }], [D + 7.15, () => { $('#sheet').classList.add('on'); log(4); ucur.classList.add('on'); }],
    [D + 7.95, () => click(ucur)], [D + 8.1, () => { $('#sheet').classList.remove('on'); $('#mailwin').classList.add('sent'); $('#toast').classList.add('on'); log(5); }],
    [D + 8.4, () => el.querySelector('.d-caption').classList.add('on')],
    [22, () => scene('E')], [22, () => punch(0)], [23, () => punch(1)], [24, () => punch(2)], [25, () => punch(3)],
    [26, () => { scene('F'); el.classList.add('shake'); }], [26.6, () => el.classList.remove('shake')]
  ];
  // typed fields: [key, start, end]
  const TYPES = [['to', D + 2.85, D + 3.4], ['subj', D + 3.9, D + 4.35], ['body', D + 4.8, D + 5.95]];

  function scene(k) {
    el.querySelectorAll('.scene').forEach(s => s.classList.toggle('on', !!k && s.classList.contains('s' + k)));
  }
  function click(c) { c.classList.remove('click'); void c.offsetWidth; c.classList.add('click'); }
  function focus(n) { desk.querySelectorAll('[data-node]').forEach(x => x.classList.toggle('focus', x.dataset.node === n)); }
  function log(i) { desk.querySelectorAll('.log li')[i].classList.add('on'); }
  function punch(i) {
    el.querySelectorAll('.punch').forEach((p, j) => p.classList.toggle('on', j === i));
    el.classList.remove('hit'); void el.offsetWidth; el.classList.add('hit');
  }

  /* UI-tree tags drawn over the mail window (the "labeled for the AI" overlay) */
  function buildTags() {
    const win = $('#mailwin'), layer = win.querySelector('.tag-layer'), wr = win.getBoundingClientRect();
    layer.innerHTML = '';
    const roles = { to: 'textfield', subj: 'textfield', body: 'textarea', attach: 'button', send: 'button' };
    win.querySelectorAll('[data-node]').forEach((n, i) => {
      const r = n.getBoundingClientRect(), b = document.createElement('i');
      b.className = 'tagbox t-' + n.dataset.node;
      b.style.cssText = `left:${(r.left - wr.left) / scale - 3}px;top:${(r.top - wr.top) / scale - 3}px;width:${r.width / scale + 6}px;height:${r.height / scale + 6}px;--d:${i * 70}ms`;
      b.innerHTML = `<b>${roles[n.dataset.node]} · ${n.querySelector('label')?.textContent || n.textContent.trim().slice(0, 14) || 'body'}</b>`;
      layer.appendChild(b);
    });
  }

  function split(node) {
    const words = node.textContent.trim().split(/\s+/);
    node.innerHTML = words.map((w, i) => `<span class="w" style="--i:${i}"><span>${w}</span></span>`).join(' ');
  }

  function reset() {
    fired = new Set(); typed = {};
    el.className = 'screen intro';
    el.querySelectorAll('.on,.tags,.tags-dim,.sent,.focus').forEach(n => n.classList.remove('on', 'tags', 'tags-dim', 'sent', 'focus'));
    desk.querySelectorAll('[data-type]').forEach(n => (n.textContent = ''));
    el.querySelectorAll('.kinetic').forEach(split);
    layout();
  }

  function now() {
    const m = window.Music.time();
    return m != null ? m : (performance.now() - wall0) / 1000;
  }

  function frame() {
    const t = now();
    if (t >= 0) {
      cues.forEach((c, i) => { if (!fired.has(i) && t >= c[0]) { fired.add(i); c[1](); } });
      if (t >= D - 0.2 && t < 22) {
        const f = along(FPATH, t), u = along(UPATH, t);
        place(fcur, f.p); place(ucur, u.p);
        fcur.classList.toggle('moving', f.moving);
        TYPES.forEach(([k, a, b]) => {
          const full = T[L]['type.' + k], n = Math.round(clamp((t - a) / (b - a)) * full.length);
          if (typed[k] !== n) { typed[k] = n; const v = desk.querySelector(`[data-type=${k}]`); v.textContent = [...full].slice(0, n).join(''); v.classList.toggle('caret', n > 0 && n < [...full].length); }
        });
      }
      bar.style.transform = `scaleX(${clamp(t / LEN)})`;
    }
    if (t >= LEN) return finish();
    raf = requestAnimationFrame(frame);
  }

  function play(lang, cb) {
    L = lang; onEnd = cb; done = false;
    reset();
    el.classList.add('show');
    wall0 = performance.now();
    window.Music.start();
    cancelAnimationFrame(raf);
    raf = requestAnimationFrame(frame);
  }
  function finish(skipped) {
    if (done) return; done = true;
    cancelAnimationFrame(raf);
    window.Music.stop(false);
    el.classList.add('out');
    setTimeout(() => { el.classList.remove('show', 'out'); }, 900);
    onEnd && onEnd();
  }

  addEventListener('resize', () => { if (el.classList.contains('show')) { layout(); if ($('#mailwin').classList.contains('tags')) buildTags(); } });
  document.getElementById('ivSkip').addEventListener('click', () => finish(true));
  document.getElementById('ivMute').addEventListener('click', e => {
    window.Music.setMuted(!window.Music.muted);
    e.currentTarget.classList.toggle('muted', window.Music.muted);
  });

  return { play, layout };
})();
