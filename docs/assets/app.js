/* Firelamp OS site: gate → loader → intro → scroll site */
(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const T = window.I18N;
  let lang = 'en';

  /* ---------- logos, drawn once in code ---------- */
  const LOGO = `<svg class="fl-logo" viewBox="0 0 877 1024" aria-hidden="true">
    <path class="fl-flame" fill="#E2402A" d="M80,44 C100,88 126,116 160,139 C180,100 205,70 226,37 C232,110 228,168 254,203 C290,176 326,156 364,147 C352,205 366,270 402,314 C432,296 470,288 510,292 C494,340 504,410 540,453 C590,450 626,466 657,490 C620,530 606,592 636,645 C648,690 626,730 588,730 L475,731 C500,800 550,862 550,918 C550,962 512,982 470,980 C405,980 362,966 346,933 C328,892 302,836 277,811 C220,860 152,918 100,920 C52,922 34,892 36,850 C38,760 34,640 36,560 C40,330 46,140 80,44 Z"/>
    <path class="fl-arrow" fill="#FF8A3D" stroke="#FF8A3D" stroke-width="12" stroke-linejoin="round" d="M126,208 L120,826 L268,700 L362,900 L455,856 L366,662 L548,662 Z"/>
    <path class="fl-core" fill="#FFD08A" stroke="#FFD08A" stroke-width="10" stroke-linejoin="round" d="M161,327 L159,693 L255,606 L313,738 L367,715 L309,587 L426,586 Z"/>
    <path class="fl-drop" fill="#FF8A3D" d="M746,169 C734,205 702,238 702,266 C702,288 718,302 738,302 C760,302 775,284 775,262 C775,232 754,208 746,169 Z"/>
    <circle class="fl-spark" fill="#FFB547" cx="826" cy="124" r="18"/></svg>`;
  const PETAL = 'M-20.7,-49.9 C-24.5,-60 -27,-72 -26,-84 C-25,-96 -14,-100.5 0,-100.5 C14,-100.5 25,-96 26,-84 C27,-72 24.5,-60 20.7,-49.9 Z';
  const FLOWER = `<svg viewBox="-110 -110 220 220" aria-hidden="true"><g fill="currentColor"><circle r="56"/>${[0, 45, 90, 135, 180, 225, 270, 315].map(a => `<path d="${PETAL}" transform="rotate(${a})"/>`).join('')}</g></svg>`;
  $$('[data-logo]').forEach(n => (n.innerHTML = LOGO));
  $$('[data-flower]').forEach(n => (n.innerHTML = FLOWER));

  /* ---------- embers ---------- */
  $$('[data-embers]').forEach(box => {
    const n = +box.dataset.embers;
    box.innerHTML = Array.from({ length: n }, () => {
      const s = 2 + Math.random() * 4;
      return `<i style="left:${Math.random() * 100}%;width:${s}px;height:${s}px;animation-duration:${6 + Math.random() * 8}s;animation-delay:${-Math.random() * 12}s;--x:${(Math.random() - 0.5) * 120}px"></i>`;
    }).join('');
  });

  /* ---------- line boil: 3 hand-drawn frames at ~8fps ---------- */
  if (!reduce) { let f = 0; setInterval(() => { f = (f + 1) % 3; document.documentElement.dataset.boil = f; }, 125); }
  document.documentElement.dataset.boil = 0;

  /* ---------- i18n ---------- */
  function setLang(l) {
    lang = l; document.documentElement.lang = l === 'pt' ? 'pt-BR' : 'en';
    const d = T[l];
    $$('[data-i18n]').forEach(n => { const v = d[n.dataset.i18n]; if (v != null) n.textContent = v; });
    $$('[data-i18n-html]').forEach(n => { const v = d[n.dataset.i18nHtml]; if (v != null) n.innerHTML = v; });
    $$('[data-i18n-ph]').forEach(n => (n.placeholder = d[n.dataset.i18nPh]));
    $$('#langToggle b').forEach(b => b.classList.toggle('on', b.dataset.l === l));
    try { localStorage.setItem('fl-lang', l); } catch (e) {}
    refreshDynamic();
  }

  /* ---------- flow ---------- */
  const gate = $('#gate'), loader = $('#loader'), site = $('#site');
  try { const saved = localStorage.getItem('fl-lang'); if (saved) $(`[data-pick="${saved}"]`)?.classList.add('last'); } catch (e) {}
  requestAnimationFrame(() => gate.classList.add('show'));

  $$('[data-pick]').forEach(b => b.addEventListener('click', () => {
    window.Music.init();                     // the click unlocks audio
    setLang(b.dataset.pick);
    gate.classList.add('out');
    loader.classList.add('show');
    setTimeout(() => { gate.classList.remove('show', 'out'); }, 700);
    setTimeout(() => {                       // 2s loader, then the launch film
      loader.classList.add('out');
      setTimeout(() => loader.classList.remove('show', 'out'), 600);
      playIntro();
    }, 2000);
  }));

  function playIntro() {
    document.body.classList.add('is-intro');
    window.Intro.play(lang, () => {
      document.body.classList.remove('is-gated', 'is-intro');
      if (!site.classList.contains('show')) { site.classList.add('show'); scrollTo(0, 0); }
      requestAnimationFrame(onScroll);
    });
  }
  $('#replay').addEventListener('click', () => { window.Music.init(); playIntro(); });
  $('#watch').addEventListener('click', () => { window.Music.init(); playIntro(); });
  $('#langToggle').addEventListener('click', () => setLang(lang === 'en' ? 'pt' : 'en'));

  /* ---------- scroll reveals ---------- */
  const io = new IntersectionObserver(es => es.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  }), { threshold: 0.18, rootMargin: '0px 0px -6% 0px' });
  $$('.rv').forEach((n, i) => { n.style.setProperty('--rd', (i % 4) * 90 + 'ms'); io.observe(n); });

  /* ---------- scroll-linked bits ---------- */
  const line = $('.scroll-line i'), nav = $('.nav'), hero = $('.hero'), treeSec = $('#tree');
  const treeItems = $$('#tree [data-t]');
  let ticking = false;
  function onScroll() {
    ticking = false;
    const y = scrollY, h = document.documentElement.scrollHeight - innerHeight;
    line.style.transform = `scaleX(${h > 0 ? y / h : 0})`;
    nav.classList.toggle('solid', y > 30);
    hero.style.setProperty('--p', Math.min(1, y / innerHeight).toFixed(3));
    // tree: progress through the sticky section lights up nodes one by one
    const r = treeSec.getBoundingClientRect(), span = r.height - innerHeight;
    const p = span > 0 ? Math.min(1, Math.max(0, -r.top / span)) : 0;
    const k = Math.floor(p * 7.2) - 1;
    treeItems.forEach(n => { const t = +n.dataset.t; n.classList.toggle('lit', t === k); n.classList.toggle('seen', t < k); });
    treeSec.style.setProperty('--tp', p.toFixed(3));
  }
  addEventListener('scroll', () => { if (!ticking) { ticking = true; requestAnimationFrame(onScroll); } }, { passive: true });
  addEventListener('resize', onScroll);

  /* ---------- two cursors: the fire cursor fills a form on a loop ---------- */
  const play = $('#play'), pc = $('.pa-cursor', play), status = $('.pa-status', play);
  let paused = false, visible = false, runId = 0;
  new IntersectionObserver(es => { visible = es[0].isIntersecting; if (visible) runPlay(); }, { threshold: 0.3 }).observe(play);
  const wait = ms => new Promise(r => setTimeout(r, ms));
  async function moveTo(node, fx = 0.3, fy = 0.6, dur = 520) {
    const a = play.getBoundingClientRect(), b = node.getBoundingClientRect();
    pc.style.transitionDuration = dur + 'ms';
    pc.style.transform = `translate(${b.left - a.left + b.width * fx}px, ${b.top - a.top + b.height * fy}px)`;
    await wait(dur + 40);
    pc.classList.remove('click'); void pc.offsetWidth; pc.classList.add('click');
  }
  async function typeInto(node, text, id) {
    const v = $('.val', node); v.classList.add('caret');
    for (let i = 1; i <= text.length; i++) { if (id !== runId) return; v.textContent = text.slice(0, i); await wait(45); }
    v.classList.remove('caret');
  }
  async function runPlay() {
    if (play.dataset.running) return;
    play.dataset.running = 1; const id = ++runId;
    while (visible && id === runId) {
      const d = T[lang], f = $$('[data-p]', play);
      f.forEach(n => { n.classList.remove('done', 'focus'); const v = $('.val', n); if (v) v.textContent = ''; });
      status.classList.remove('ok'); $('span', status).textContent = d['cur.status'];
      await wait(500);
      for (const [i, key] of [[0, 'cur.v1'], [1, 'cur.v2'], [2, 'cur.v3']]) {
        await moveTo(f[i]); f[i].classList.add('focus');
        await typeInto(f[i], T[lang][key], id); f[i].classList.remove('focus'); f[i].classList.add('done');
      }
      await moveTo(f[3], 0.08, 0.5); f[3].classList.add('done'); await wait(250);
      await moveTo(f[4], 0.5, 0.55, 600); f[4].classList.add('done');
      status.classList.add('ok'); $('span', status).textContent = T[lang]['cur.done'];
      await wait(2200);
    }
    delete play.dataset.running;
  }

  /* ---------- stop button ---------- */
  const stopBtn = $('#stopBtn'), stopper = $('#stopper');
  stopBtn.addEventListener('click', () => {
    paused = !paused;
    stopper.classList.toggle('paused', paused);
    $('span', stopBtn).textContent = T[lang][paused ? 'sf.resume' : 'sf.pause'];
  });

  /* ---------- name your assistant ---------- */
  const nameIn = $('#aiName'), nameOut = $('#nameOut');
  const showName = () => { const v = nameIn.value.trim(); nameOut.textContent = v; nameOut.classList.toggle('empty', !v); };
  nameIn.addEventListener('input', showName);

  function refreshDynamic() {
    $('span', stopBtn).textContent = T[lang][paused ? 'sf.resume' : 'sf.pause'];
    showName();
    runId++; delete play.dataset.running; if (visible) runPlay();
  }

  setLang('en');
})();
