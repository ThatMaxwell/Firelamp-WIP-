/* Firelamp OS site: language → loader → film → the page */
(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const T = window.I18N;
  let lang = 'en';

  /* ---------- marks, drawn in code ---------- */
  const LOGO = `<svg class="fl" viewBox="24 26 644 966" aria-hidden="true">
    <path fill="#E2402A" d="M80,44 C100,88 126,116 160,139 C180,100 205,70 226,37 C232,110 228,168 254,203 C290,176 326,156 364,147 C352,205 366,270 402,314 C432,296 470,288 510,292 C494,340 504,410 540,453 C590,450 626,466 657,490 C620,530 606,592 636,645 C648,690 626,730 588,730 L475,731 C500,800 550,862 550,918 C550,962 512,982 470,980 C405,980 362,966 346,933 C328,892 302,836 277,811 C220,860 152,918 100,920 C52,922 34,892 36,850 C38,760 34,640 36,560 C40,330 46,140 80,44 Z"/>
    <path fill="#FF8A3D" stroke="#FF8A3D" stroke-width="12" stroke-linejoin="round" d="M126,208 L120,826 L268,700 L362,900 L455,856 L366,662 L548,662 Z"/>
    <path fill="#FFD08A" stroke="#FFD08A" stroke-width="10" stroke-linejoin="round" d="M161,327 L159,693 L255,606 L313,738 L367,715 L309,587 L426,586 Z"/></svg>`;
  const PETAL = 'M-20.7,-49.9 C-24.5,-60 -27,-72 -26,-84 C-25,-96 -14,-100.5 0,-100.5 C14,-100.5 25,-96 26,-84 C27,-72 24.5,-60 20.7,-49.9 Z';
  const FLOWER = `<svg viewBox="-110 -110 220 220" aria-hidden="true"><g fill="currentColor"><circle r="56"/>${[0, 45, 90, 135, 180, 225, 270, 315].map(a => `<path d="${PETAL}" transform="rotate(${a})"/>`).join('')}</g></svg>`;
  $$('[data-logo]').forEach(n => (n.innerHTML = LOGO));
  $$('[data-flower]').forEach(n => (n.innerHTML = FLOWER));

  /* ---------- line boil: 3 frames at 8fps ---------- */
  document.documentElement.dataset.boil = 0;
  if (!reduce) { let f = 0; setInterval(() => { f = (f + 1) % 3; document.documentElement.dataset.boil = f; }, 125); }

  /* ---------- copy ---------- */
  function setLang(l) {
    lang = l; document.documentElement.lang = l === 'pt' ? 'pt-BR' : 'en';
    const d = T[l];
    $$('[data-i18n]').forEach(n => { const v = d[n.dataset.i18n]; if (typeof v === 'string') n.textContent = v; });
    $$('[data-i18n-ph]').forEach(n => (n.placeholder = d[n.dataset.i18nPh]));
    $$('#langToggle b').forEach(b => b.classList.toggle('on', b.dataset.l === l));
    try { localStorage.setItem('fl-lang', l); } catch (e) {}
    splitWords(); onScroll(); pipeReset(); ctlText();
  }

  /* ---------- flow ---------- */
  const gate = $('#gate'), loader = $('#loader'), site = $('#site');
  gate.classList.add('show');
  requestAnimationFrame(() => requestAnimationFrame(() => gate.classList.add('in')));
  // the browser's language goes first, already focused: Enter is enough
  const guess = (navigator.language || '').toLowerCase().startsWith('pt') ? 'pt' : 'en';
  const first = $(`[data-pick="${guess}"]`);
  first.classList.add('guess'); first.parentNode.prepend(first);
  setTimeout(() => first.focus({ preventScroll: true }), 300);
  $$('[data-pick]').forEach(b => b.addEventListener('click', () => {
    window.Music.init();               // this click is what unlocks audio
    setLang(b.dataset.pick);
    gate.classList.add('out');
    setTimeout(() => gate.classList.remove('show', 'out', 'in'), 520);
    loader.classList.add('show');
    setTimeout(() => {
      loader.classList.add('out');
      setTimeout(() => loader.classList.remove('show', 'out'), 420);
      playFilm();
    }, 2000);
  }));

  function playFilm() {
    document.body.classList.add('locked');
    window.Film.play(lang, () => {
      document.body.classList.remove('locked');
      if (!site.classList.contains('show')) { scrollTo(0, 0); site.classList.add('show'); startHero(); }
      onScroll();
    });
  }
  $('#replay').addEventListener('click', () => { window.Music.init(); playFilm(); });
  $('#watch').addEventListener('click', () => { window.Music.init(); playFilm(); });
  $('#langToggle').addEventListener('click', () => setLang(lang === 'en' ? 'pt' : 'en'));

  function startHero() {
    $$('.hero .rise').forEach((n, i) => n.style.setProperty('--d', i * 90));
    setTimeout(selectWord, 1500);
  }

  // the fire cursor flies in and selects "cursor." the way you'd select text
  const sel = $('#selWord');
  async function selectWord() {
    if (reduce) { sel.style.setProperty('--sel', 1); return; }
    cursor.wake();
    const r = () => sel.getBoundingClientRect();
    cursor.hold(r().left - 4, r().top + r().height * 0.55);
    for (let i = 0; i < 80 && !cursor.near(); i++) await wait(25);
    cursor.click(); await wait(120);
    const t0 = performance.now(), dur = 520;
    await new Promise(done => (function drag(t) {
      const k = Math.min(1, (t - t0) / dur), e = k * k * (3 - 2 * k), b = r();
      sel.style.setProperty('--sel', e.toFixed(3));
      cursor.hold(b.left - 4 + (b.width + 4) * e, b.top + b.height * 0.55);
      k < 1 ? requestAnimationFrame(drag) : done();
    })(t0));
    await wait(1100);
    cursor.release();
  }

  /* ---------- statement: words light up as you read down ---------- */
  const words = $('.reveal-words');
  function splitWords() {
    words.innerHTML = words.textContent.trim().split(/\s+/).map(w => `<span class="w">${w}</span>`).join(' ');
  }

  /* ---------- scroll-linked ---------- */
  const nav = $('.nav'), screen = $('#heroScreen'), tilt = $('.screen-tilt');
  let ticking = false;
  function onScroll() {
    ticking = false;
    nav.classList.toggle('solid', scrollY > 20);
    // hero screen eases back a touch as you scroll past it
    const vh = innerHeight;
    tilt.style.setProperty('--tilt', Math.min(1, scrollY / vh).toFixed(3));
    // statement words
    const wr = words.getBoundingClientRect(), ws = $$('.w', words);
    const q = Math.min(1, Math.max(0, (vh * 0.78 - wr.top) / (wr.height + vh * 0.25)));
    const lit = Math.round(q * ws.length);
    ws.forEach((w, i) => w.classList.toggle('lit', i < lit));
  }
  addEventListener('scroll', () => { if (!ticking) { ticking = true; requestAnimationFrame(onScroll); } }, { passive: true });
  addEventListener('resize', onScroll);

  /* ---------- the story: reveal once, play footage only while it's on screen ---------- */
  const revealIO = new IntersectionObserver(es => es.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('in'); revealIO.unobserve(e.target); }
  }), { rootMargin: '0px 0px -12% 0px' });
  $$('.reveal').forEach(n => revealIO.observe(n));
  const clipIO = new IntersectionObserver(es => es.forEach(e => {
    const v = e.target;
    if (e.isIntersecting) { v.preload = 'auto'; v.play().catch(() => {}); } else v.pause();
  }), { threshold: 0.35 });
  $$('.clip').forEach(v => clipIO.observe(v));

  /* ---------- brain → reflexes pipeline ---------- */
  const pipe = $('#pipe'), plan = $('.plan', pipe), acts = $('.acts', pipe);
  let pipeRun = 0, pipeVisible = false;
  const wait = ms => new Promise(r => setTimeout(r, ms));
  function pipeReset() { pipeRun++; plan.innerHTML = ''; acts.innerHTML = ''; if (pipeVisible) runPipe(); }
  async function runPipe() {
    const id = ++pipeRun;
    while (pipeVisible && id === pipeRun) {
      plan.innerHTML = ''; acts.innerHTML = '';
      await wait(700);
      for (const s of T[lang]['pipe.plan']) { if (id !== pipeRun) return; plan.insertAdjacentHTML('beforeend', `<span>${s}</span>`); await wait(260); }
      await wait(300);
      for (const a of T[lang]['pipe.acts']) {
        if (id !== pipeRun) return;
        $$('span', acts).forEach(x => x.classList.remove('cur'));
        acts.insertAdjacentHTML('beforeend', `<span class="cur">${a}</span>`);
        await wait(a.includes('…') || a.includes('wait') || a.includes('esperar') ? 900 : 380);
      }
      $$('span', acts).forEach(x => x.classList.remove('cur'));
      await wait(2600);
    }
  }
  new IntersectionObserver(es => { pipeVisible = es[0].isIntersecting; if (pipeVisible) runPipe(); else pipeRun++; }, { threshold: 0.4 }).observe(pipe);

  /* ---------- the page's own fire cursor ---------- */
  const cursor = (() => {
    const el = $('#pageCursor'), tag = $('.pc-tag', el);
    let x = innerWidth * 0.8, y = innerHeight * 0.4, tx = x, ty = y, vx = 0, vy = 0;
    let paused = false, awake = false, asleep = false, nextAt = 0, raf;
    const targets = () => $$('.hero-h, .hero-sub, .btn, .reveal-words .w.lit, .feat h3, .feat-text p, .stack-p, .pipe-v span, .lede, .keycap, #aiName, .end-h, .num, .h2')
      .filter(n => { const r = n.getBoundingClientRect(); return r.width && r.bottom > 80 && r.top < innerHeight - 40; });
    function pick(t) {
      const ts = targets();
      if (!ts.length) { tx = innerWidth * (0.6 + Math.random() * 0.3); ty = innerHeight * (0.3 + Math.random() * 0.4); return; }
      const n = ts[Math.floor(Math.random() * ts.length)], r = n.getBoundingClientRect();
      tx = Math.min(innerWidth - 40, r.left + r.width * (0.1 + Math.random() * 0.8));
      ty = Math.min(innerHeight - 40, Math.max(80, r.top + r.height * (0.3 + Math.random() * 0.5)));
      nextAt = t + 1400 + Math.random() * 2200;
      if (n.matches('.btn, .keycap, .pipe-v span') && Math.random() < 0.6) setTimeout(click, 700);
    }
    function click() { if (paused) return; el.classList.remove('click'); void el.offsetWidth; el.classList.add('click'); }
    let lastY = scrollY;
    function loop(t) {
      if (!paused) {
        const dy = scrollY - lastY; lastY = scrollY; ty -= dy * 0.6;   // drift with the page a little
        if (t > nextAt) pick(t);
        // critically damped spring: quick, then settles
        const k = 0.012, d = 0.22;
        vx = (vx + (tx - x) * k) * (1 - d); vy = (vy + (ty - y) * k) * (1 - d);
        x += vx; y += vy;
        el.style.transform = `translate(${x.toFixed(1)}px, ${y.toFixed(1)}px) rotate(${Math.max(-12, Math.min(12, vx * 0.6)).toFixed(1)}deg)`;
      } else lastY = scrollY;
      raf = requestAnimationFrame(loop);
    }
    function wake() { if (awake || reduce) return; awake = true; el.classList.add('on'); raf = requestAnimationFrame(loop); }
    function sleep() { asleep = true; el.classList.remove('on'); cancelAnimationFrame(raf); awake = false; }
    function setPaused(p) { paused = p; document.body.classList.toggle('paused', p); }
    function setName(n) { tag.textContent = n; tag.classList.toggle('on', !!n); }
    // hand the cursor a fixed spot; it stays there until released
    function hold(px, py) { tx = px; ty = py; nextAt = Infinity; }
    function release() { nextAt = 0; }
    const near = () => Math.hypot(tx - x, ty - y) < 14;
    return { wake, sleep, setPaused, setName, hold, release, click, near, get paused() { return paused; } };
  })();

  /* ---------- pause: Esc or the key ---------- */
  const key = $('#escKey');
  function ctlText() { $('#ctlState').textContent = T[lang][cursor.paused ? 'ctl.paused' : 'ctl.run']; }
  function togglePause() { cursor.setPaused(!cursor.paused); ctlText(); }
  key.addEventListener('click', togglePause);
  addEventListener('keydown', e => {
    if (e.key !== 'Escape' || !site.classList.contains('show') || $('#film').classList.contains('show')) return;
    key.classList.add('down'); togglePause();
  });
  addEventListener('keyup', e => { if (e.key === 'Escape') key.classList.remove('down'); });

  /* ---------- name ---------- */
  const nameIn = $('#aiName'), ask = $('#nameAsk');
  nameIn.addEventListener('input', e => cursor.setName(e.target.value.trim()));
  // the signature moment: the fire cursor fills in its own name
  ask.addEventListener('click', async () => {
    if (ask.disabled) return;
    ask.disabled = true;
    cursor.wake(); cursor.setPaused(false); ctlText();
    const r = nameIn.getBoundingClientRect();
    cursor.hold(r.left + 18, r.top + r.height * 0.55);
    for (let i = 0; i < 90 && !cursor.near(); i++) await wait(30);
    cursor.click(); await wait(260);
    nameIn.value = ''; cursor.setName('');
    for (const ch of T[lang]['nm.sample']) {
      if (cursor.paused) break;
      nameIn.value += ch; cursor.setName(nameIn.value);
      cursor.hold(nameIn.getBoundingClientRect().left + 18 + nameIn.value.length * 14, r.top + r.height * 0.55);
      await wait(45 + Math.random() * 70);
    }
    await wait(900); cursor.release(); ask.disabled = false;
  });

  /* ---------- download: the button reveals the terminal command ---------- */
  const REL = 'https://github.com/ThatMaxwell/Firelamp-WIP-/releases/download/v0.1.0';
  const ISO = 'firelamp-2026.10.08-x86_64.iso';
  const CMD = {
    win: { path: '$HOME\\Firelamp', text: [
      '$d = "$HOME\\Firelamp"; mkdir $d -Force | Out-Null; cd $d',
      `$u = "${REL}"`,
      `$n = "${ISO}"`,
      'foreach ($f in "$n.part00", "$n.part01", "$n.sha256") { curl.exe -L -C - -o $f "$u/$f" }',
      'cmd /c "copy /b $n.part00+$n.part01 $n"',
      'if ((Get-FileHash $n -Algorithm SHA256).Hash -eq (Get-Content "$n.sha256").Split(" ")[0]) { "OK: checksum matches, ISO is ready"; del "$n.part*" } else { "Checksum mismatch, run the command again" }'
    ] },
    nix: { path: '~/Firelamp', text: [
      'mkdir -p ~/Firelamp && cd ~/Firelamp',
      `u=${REL}`,
      `n=${ISO}`,
      'for f in $n.part00 $n.part01 $n.sha256; do curl -L -C - -o $f $u/$f; done',
      'cat $n.part00 $n.part01 > $n',
      'if sha256sum -c $n.sha256 2>/dev/null || shasum -a 256 -c $n.sha256; then rm $n.part0*; echo "OK: checksum matches, ISO is ready"; else echo "Checksum mismatch, run the command again"; fi'
    ] }
  };
  const dlBtn = $('#dlBtn'), dlPanel = $('#dlPanel'), dlCode = $('#dlCode'), dlCopy = $('#dlCopy');
  let dlOs = /Windows/i.test(navigator.userAgent) ? 'win' : 'nix';
  const esc = t => t.replace(/&/g, '&amp;').replace(/</g, '&lt;');
  function dlShow(os) {
    dlOs = os;
    $$('.dl-tabs button').forEach(b => b.setAttribute('aria-selected', b.dataset.os === os));
    // commands bright, arguments quieter, so the six steps read at a glance
    dlCode.innerHTML = CMD[os].text.map(l => esc(l).replace(/^(\S+)/, '<b>$1</b>')).join('\n');
    $('#dlPath').textContent = CMD[os].path;
    $('#dlShell').textContent = os === 'win' ? 'PowerShell' : 'Terminal';
    dlCopy.textContent = T[lang]['dl.copy'];
  }
  $$('.dl-tabs button').forEach(b => b.addEventListener('click', () => dlShow(b.dataset.os)));
  dlBtn.addEventListener('click', () => {
    const open = dlBtn.getAttribute('aria-expanded') !== 'true';
    dlBtn.setAttribute('aria-expanded', open);
    if (open) {
      dlShow(dlOs); dlPanel.hidden = false;
      requestAnimationFrame(() => requestAnimationFrame(() => dlPanel.classList.add('open')));
      setTimeout(() => dlPanel.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'nearest' }), 250);
    } else {
      dlPanel.classList.remove('open'); setTimeout(() => { if (!dlPanel.classList.contains('open')) dlPanel.hidden = true; }, 600);
    }
  });
  dlCopy.addEventListener('click', async () => {
    const text = CMD[dlOs].text.join('\n');
    try { await navigator.clipboard.writeText(text); }
    catch (e) { const r = document.createRange(); r.selectNodeContents(dlCode); const sel = getSelection(); sel.removeAllRanges(); sel.addRange(r); document.execCommand('copy'); }
    dlCopy.textContent = T[lang]['dl.copied'];
    clearTimeout(dlCopy._t); dlCopy._t = setTimeout(() => (dlCopy.textContent = T[lang]['dl.copy']), 1800);
  });

  setLang('en');
})();
