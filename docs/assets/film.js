/* Firelamp launch film: ~30s, drawn live in the DOM and locked to music.js */
window.Film = (() => {
  const LEN = 30.6;
  const el = document.getElementById('film');
  const bar = el.querySelector('.film-bar i');
  const video = el.querySelector('.d-video');
  const $ = s => el.querySelector(s);
  const $$ = s => [...el.querySelectorAll(s)];
  const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));

  // the shutter words land on the same 16ths as music.js's shutter clicks
  const WORDS = [4.5, 5, 5.5, 6, 6.5, 6.75, 7, 7.125, 7.25, 7.375];
  const CAPS = [12.4, 14.9, 17.4, 19.9];

  let raf, wall0, done, fired, onEnd, lang = 'en';

  const cues = [
    [0, () => scene('a')],
    [2.7, () => { $('.sc-a').classList.add('go'); }],
    [2.75, () => { $('.sys-cursor').style.transform = 'translate(-14vw, -9vh)'; }],
    [4, () => scene('b')],
    ...WORDS.map((t, i) => [t, () => { word(i); shot(i); }]),
    [7.55, () => scene(null)],
    [8, () => { scene('c'); hit(); }],
    [12, () => { scene('d'); try { video.currentTime = 0; video.play(); } catch (e) {} }],
    ...CAPS.map((t, i) => [t, () => cap(i)]),
    [22, () => { scene('e'); punch(0); hit(); }], [23, () => punch(1)], [24, () => punch(2)], [25, () => punch(3)],
    [26, () => { scene('f'); hit(); video.pause(); }]
  ];

  function scene(k) { $$('.sc').forEach(s => s.classList.toggle('on', !!k && s.classList.contains('sc-' + k))); }
  function hit() { el.classList.remove('hit'); void el.offsetWidth; el.classList.add('hit'); }
  function word(i) { $$('.b-word span').forEach((s, j) => s.classList.toggle('on', j === i % 6)); }
  function shot() { const s = $('.b-shots i'); s.classList.remove('on'); void s.offsetWidth; s.classList.add('on'); }
  function cap(i) { $$('.d-caps li').forEach((li, j) => { li.classList.toggle('on', j === i); li.classList.toggle('past', j < i); }); }
  function punch(i) { $$('.punch').forEach((p, j) => p.classList.toggle('on', j === i)); }

  function reset() {
    fired = new Set();
    el.className = 'layer film';
    $$('.on,.past,.go').forEach(n => n.classList.remove('on', 'past', 'go'));
    $('.sys-cursor').style.transform = '';
    $('.typed').textContent = '';
  }

  const now = () => { const m = window.Music.time(); return m != null ? m : (performance.now() - wall0) / 1000; };

  function frame() {
    const t = now();
    if (t >= 0) {
      cues.forEach((c, i) => { if (!fired.has(i) && t >= c[0]) { fired.add(i); c[1](); } });
      if (t < 4) {   // typewriter
        const full = window.I18N[lang]['f.a'], n = Math.round(clamp((t - 0.35) / 2.1) * full.length);
        const ty = $('.typed'); if (ty.textContent.length !== n) ty.textContent = full.slice(0, n);
      }
      if (t >= 12 && t < 26 && !video.paused && Math.abs(video.currentTime - (t - 12)) > 0.3) video.currentTime = t - 12;
      bar.style.transform = `scaleX(${clamp(t / LEN)})`;
    }
    if (t >= LEN) return finish();
    raf = requestAnimationFrame(frame);
  }

  function play(l, cb) {
    lang = l; onEnd = cb; done = false;
    reset();
    el.classList.add('show');
    wall0 = performance.now();
    window.Music.start();
    cancelAnimationFrame(raf);
    raf = requestAnimationFrame(frame);
  }
  function finish() {
    if (done) return; done = true;
    cancelAnimationFrame(raf);
    video.pause();
    window.Music.stop(false);
    el.classList.add('out');
    setTimeout(() => el.classList.remove('show', 'out'), 850);
    onEnd && onEnd();
  }

  document.getElementById('filmSkip').addEventListener('click', finish);
  document.getElementById('filmMute').addEventListener('click', e => {
    window.Music.setMuted(!window.Music.muted);
    e.currentTarget.classList.toggle('muted', window.Music.muted);
  });
  addEventListener('keydown', e => { if (e.key === 'Escape' && el.classList.contains('show')) finish(); });

  return { play };
})();
