/* Firelamp launch score: a ~31s track synthesized live with Web Audio.
   120 BPM, A minor (Am F C G). Intro build 0-8s, drop at 8s, outro hit at 26s. */
window.Music = (() => {
  const BPM = 120, BEAT = 60 / BPM, S16 = BEAT / 4, BAR = BEAT * 4;
  const END = 31;
  let ctx, out, comp, verb, verbIn, delayIn, padDuck, noise, t0 = 0, timer, nextStep = 0, playing = false, muted = false;

  const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
  // chord per bar: Am7, Fmaj7, C(add9), G6
  const CH = [[57, 60, 64, 67], [53, 57, 60, 64], [55, 60, 62, 64], [55, 59, 62, 64]];
  const ROOT = [33, 29, 36, 31];
  // hook: [step-in-bar(16ths), midi, length in 16ths] per chord
  const HOOK = [
    [[0, 76, 2], [3, 72, 1], [4, 76, 2], [6, 81, 4], [12, 79, 2], [14, 76, 2]],
    [[0, 77, 2], [3, 76, 1], [4, 72, 2], [6, 69, 4], [12, 72, 4]],
    [[0, 79, 2], [3, 76, 1], [4, 79, 2], [6, 84, 4], [12, 83, 2], [14, 79, 2]],
    [[0, 86, 3], [4, 83, 2], [6, 79, 4], [12, 74, 2], [14, 79, 2]]
  ];

  let irBuf;
  function init() {
    if (ctx) { ctx.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    ctx = new AC();
    ctx.resume();
    comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -14; comp.ratio.value = 4; comp.attack.value = 0.004; comp.release.value = 0.2;
    comp.connect(ctx.destination);
    const len = ctx.sampleRate * 2.6;
    irBuf = ctx.createBuffer(2, len, ctx.sampleRate);
    for (let c = 0; c < 2; c++) { const d = irBuf.getChannelData(c); for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 2.6); }
    noise = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate);
    const nd = noise.getChannelData(0); for (let i = 0; i < nd.length; i++) nd[i] = Math.random() * 2 - 1;
  }

  // a fresh mix bus per playback, so stopping silences every note already scheduled
  function buildBus() {
    out = ctx.createGain(); out.gain.value = muted ? 0 : 0.85; out.connect(comp);
    verb = ctx.createConvolver(); verb.buffer = irBuf;
    verbIn = ctx.createGain(); verbIn.gain.value = 0.5; verbIn.connect(verb); verb.connect(out);
    const dl = ctx.createDelay(1), fb = ctx.createGain(), lp = ctx.createBiquadFilter();
    dl.delayTime.value = S16 * 3; fb.gain.value = 0.38; lp.type = 'lowpass'; lp.frequency.value = 2800;
    delayIn = ctx.createGain(); delayIn.gain.value = 0.32;
    delayIn.connect(dl); dl.connect(lp); lp.connect(fb); fb.connect(dl); lp.connect(out); lp.connect(verbIn);
    padDuck = ctx.createGain(); padDuck.connect(out); padDuck.connect(verbIn);
  }

  /* ---------- instruments ---------- */
  function env(g, t, a, peak, d, sus = 0.0001) {
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + a);
    g.gain.exponentialRampToValueAtTime(Math.max(sus, 0.0001), t + a + d);
  }
  function noiseSrc(t, dur) { const s = ctx.createBufferSource(); s.buffer = noise; s.start(t, Math.random()); s.stop(t + dur); return s; }

  function kick(t, v = 1) {
    const o = ctx.createOscillator(), g = ctx.createGain();
    o.frequency.setValueAtTime(165, t); o.frequency.exponentialRampToValueAtTime(42, t + 0.13);
    env(g, t, 0.002, v, 0.42);
    o.connect(g); g.connect(out); o.start(t); o.stop(t + 0.5);
    padDuck.gain.cancelScheduledValues(t);
    padDuck.gain.setValueAtTime(0.25, t); padDuck.gain.linearRampToValueAtTime(1, t + 0.32);
  }
  function clap(t, v = 0.5) {
    const s = noiseSrc(t, 0.3), f = ctx.createBiquadFilter(), g = ctx.createGain();
    f.type = 'bandpass'; f.frequency.value = 1600; f.Q.value = 0.9;
    g.gain.setValueAtTime(0.0001, t);
    [0, 0.012, 0.024].forEach(o => { g.gain.setValueAtTime(v, t + o); g.gain.exponentialRampToValueAtTime(v * 0.3, t + o + 0.01); });
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.24);
    s.connect(f); f.connect(g); g.connect(out); g.connect(verbIn);
  }
  function hat(t, open = false, v = 0.12) {
    const s = noiseSrc(t, open ? 0.3 : 0.06), f = ctx.createBiquadFilter(), g = ctx.createGain();
    f.type = 'highpass'; f.frequency.value = open ? 7000 : 9000;
    env(g, t, 0.001, v, open ? 0.22 : 0.04);
    s.connect(f); f.connect(g); g.connect(out);
  }
  function bass(t, m, dur, v = 0.32) {
    const o = ctx.createOscillator(), sub = ctx.createOscillator(), f = ctx.createBiquadFilter(), g = ctx.createGain();
    o.type = 'sawtooth'; o.frequency.value = mtof(m); sub.type = 'sine'; sub.frequency.value = mtof(m);
    f.type = 'lowpass'; f.Q.value = 6; f.frequency.setValueAtTime(900, t); f.frequency.exponentialRampToValueAtTime(160, t + dur);
    env(g, t, 0.006, v, dur);
    o.connect(f); sub.connect(g); f.connect(g); g.connect(out);
    o.start(t); sub.start(t); o.stop(t + dur + 0.05); sub.stop(t + dur + 0.05);
  }
  function pluck(t, m, v = 0.09, bright = 3200) {
    const o = ctx.createOscillator(), o2 = ctx.createOscillator(), f = ctx.createBiquadFilter(), g = ctx.createGain();
    o.type = 'triangle'; o2.type = 'square'; o.frequency.value = mtof(m); o2.frequency.value = mtof(m) * 1.003;
    const g2 = ctx.createGain(); g2.gain.value = 0.25;
    f.type = 'lowpass'; f.frequency.setValueAtTime(bright, t); f.frequency.exponentialRampToValueAtTime(500, t + 0.3);
    env(g, t, 0.003, v, 0.32);
    o.connect(f); o2.connect(g2); g2.connect(f); f.connect(g); g.connect(out); g.connect(delayIn); g.connect(verbIn);
    o.start(t); o2.start(t); o.stop(t + 0.4); o2.stop(t + 0.4);
  }
  function pad(t, notes, dur, v = 0.05, cutoff = 1400) {
    notes.forEach(m => {
      [-8, 8].forEach(det => {
        const o = ctx.createOscillator(), f = ctx.createBiquadFilter(), g = ctx.createGain();
        o.type = 'sawtooth'; o.frequency.value = mtof(m); o.detune.value = det;
        f.type = 'lowpass'; f.frequency.value = cutoff;
        g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(v, t + 0.35);
        g.gain.setValueAtTime(v, t + dur - 0.1); g.gain.linearRampToValueAtTime(0.0001, t + dur + 0.5);
        o.connect(f); f.connect(g); g.connect(padDuck); o.start(t); o.stop(t + dur + 0.6);
      });
    });
  }
  function lead(t, m, dur, v = 0.07) {
    const o = ctx.createOscillator(), o2 = ctx.createOscillator(), f = ctx.createBiquadFilter(), g = ctx.createGain();
    const lfo = ctx.createOscillator(), lg = ctx.createGain();
    o.type = 'sawtooth'; o2.type = 'square'; o.frequency.value = mtof(m); o2.frequency.value = mtof(m - 12);
    lfo.frequency.value = 5.5; lg.gain.value = 6; lfo.connect(lg); lg.connect(o.detune);
    f.type = 'lowpass'; f.frequency.value = 2600; f.Q.value = 2;
    const g2 = ctx.createGain(); g2.gain.value = 0.35;
    g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(v, t + 0.015);
    g.gain.setValueAtTime(v, t + dur * 0.8); g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.12);
    o.connect(f); o2.connect(g2); g2.connect(f); f.connect(g); g.connect(out); g.connect(delayIn); g.connect(verbIn);
    [o, o2, lfo].forEach(x => { x.start(t); x.stop(t + dur + 0.2); });
  }
  function riser(t, dur) {
    const s = noiseSrc(t, dur), f = ctx.createBiquadFilter(), g = ctx.createGain();
    f.type = 'bandpass'; f.Q.value = 3; f.frequency.setValueAtTime(300, t); f.frequency.exponentialRampToValueAtTime(7000, t + dur);
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(0.22, t + dur);
    s.connect(f); f.connect(g); g.connect(out); g.connect(verbIn);
    const o = ctx.createOscillator(), og = ctx.createGain();
    o.type = 'sawtooth'; o.frequency.setValueAtTime(110, t); o.frequency.exponentialRampToValueAtTime(880, t + dur);
    og.gain.setValueAtTime(0.0001, t); og.gain.exponentialRampToValueAtTime(0.03, t + dur);
    const of = ctx.createBiquadFilter(); of.type = 'lowpass'; of.frequency.value = 2000;
    o.connect(of); of.connect(og); og.connect(out); o.start(t); o.stop(t + dur);
  }
  function impact(t, v = 1) {
    kick(t, v);
    const sub = ctx.createOscillator(), sg = ctx.createGain();
    sub.frequency.setValueAtTime(70, t); sub.frequency.exponentialRampToValueAtTime(32, t + 1.4);
    env(sg, t, 0.005, 0.6 * v, 1.6); sub.connect(sg); sg.connect(out); sub.start(t); sub.stop(t + 1.8);
    const s = noiseSrc(t, 1.6), f = ctx.createBiquadFilter(), g = ctx.createGain();
    f.type = 'lowpass'; f.frequency.setValueAtTime(5000, t); f.frequency.exponentialRampToValueAtTime(200, t + 1.4);
    env(g, t, 0.003, 0.35 * v, 1.5); s.connect(f); f.connect(g); g.connect(out); g.connect(verbIn);
  }
  // camera-shutter tick for the screenshot words
  function shutter(t) {
    const s = noiseSrc(t, 0.08), f = ctx.createBiquadFilter(), g = ctx.createGain();
    f.type = 'bandpass'; f.frequency.value = 3800; f.Q.value = 1.4;
    env(g, t, 0.001, 0.5, 0.05); s.connect(f); f.connect(g); g.connect(out);
    const s2 = noiseSrc(t + 0.045, 0.06), g2 = ctx.createGain(), f2 = ctx.createBiquadFilter();
    f2.type = 'highpass'; f2.frequency.value = 2500;
    env(g2, t + 0.045, 0.001, 0.3, 0.04); s2.connect(f2); f2.connect(g2); g2.connect(out); g2.connect(verbIn);
  }
  const SHUTTER = new Set([36, 40, 44, 48, 52, 54, 56, 57, 58, 59]);
  function sparkle(t, m) { pluck(t, m, 0.05, 6000); }

  /* ---------- arrangement, one 16th step at a time ---------- */
  function step(i, t) {
    const time = i * S16, bar = Math.floor(i / 16), s = i % 16, ci = bar % 4, ch = CH[ci];
    if (time >= END) return;

    if (SHUTTER.has(i)) shutter(t);
    if (bar < 4) {                       // 0-8s intro build
      if (s === 0) pad(t, ch, BAR, bar < 2 ? 0.055 : 0.065, 800 + bar * 400);
      const arpOn = bar < 2 ? s % 4 === 0 : s % 2 === 0;
      if (arpOn && !(bar === 3 && s >= 12)) pluck(t, ch[(s / 2) % 4 | 0] + 12, bar < 2 ? 0.09 : 0.11);
      if (bar === 2 && s === 0) riser(t, BAR * 2 - BEAT);
      if (bar === 3 && s < 12) { hat(t, false, 0.04 + s * 0.006); if (s >= 8) clap(t, 0.08 + (s - 8) * 0.05); }
      return;
    }
    if (bar < 13) {                      // 8-26s drop
      if (i === 64) impact(t, 1);
      if (s === 0) pad(t, ch, BAR, 0.05, 2400);
      if (s % 4 === 0 && i !== 64) kick(t, 0.95);
      if (s === 4 || s === 12) clap(t, 0.45);
      if (s % 4 === 2) hat(t, true, 0.08); else if (s % 2 === 0) hat(t, false, 0.07);
      if (s % 2 === 1 || s % 4 === 2) bass(t, ROOT[ci] + (s === 14 ? 12 : 0), S16 * 1.6);
      if (bar < 8 || bar >= 11) { if (s % 2 === 0) pluck(t, ch[(s / 2 + bar) % 4] + 12 + (s >= 8 ? 12 : 0), 0.06); }
      if (bar >= 8 && bar < 11) HOOK[ci].forEach(([st, m, l]) => { if (st === s) lead(t, m, l * S16); });
      if (bar >= 11 && s % 8 === 0) sparkle(t, ch[s / 8 | 0] + 24);
      if (bar === 12 && s >= 8) { clap(t, 0.15 + (s - 8) * 0.05); hat(t, false, 0.1); }
      return;
    }
    if (i === 208) {                     // 26s: final hit + long chord
      impact(t, 1.15);
      pad(t, [57, 64, 67, 71, 76], 4.2, 0.05, 1800);
      bass(t, 33, 3, 0.3);
      [81, 84, 88, 91, 93].forEach((m, k) => sparkle(t + 0.25 + k * 0.32, m));
    }
  }

  function schedule() {
    const ahead = ctx.currentTime + 0.15;
    while (t0 + nextStep * S16 < ahead) { step(nextStep, t0 + nextStep * S16); nextStep++; }
    if (nextStep * S16 < END) timer = setTimeout(schedule, 30);
  }

  function start() {
    if (!ctx) return;
    stop(true);
    buildBus();
    t0 = ctx.currentTime + 0.08; nextStep = 0; playing = true;
    schedule();
  }
  function stop(hard) {
    clearTimeout(timer); playing = false;
    if (!ctx || !out) return;
    const n = ctx.currentTime, old = out, fade = hard ? 0.04 : 0.8;
    old.gain.cancelScheduledValues(n);
    old.gain.setValueAtTime(old.gain.value, n);
    old.gain.linearRampToValueAtTime(0, n + fade);
    setTimeout(() => old.disconnect(), fade * 1000 + 100);
    out = null;
  }
  function setMuted(m) {
    muted = m;
    if (ctx && out) { out.gain.cancelScheduledValues(ctx.currentTime); out.gain.setTargetAtTime(m ? 0 : 0.85, ctx.currentTime, 0.05); }
  }
  const time = () => (ctx && playing ? ctx.currentTime - t0 : null);
  const running = () => !!ctx && ctx.state === 'running';

  // offline render of the whole score to a WAV (used to export a preview video)
  async function renderWav() {
    const live = ctx, sr = 44100, oc = new OfflineAudioContext(2, sr * (END + 1), sr);
    ctx = oc;
    comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -14; comp.ratio.value = 4; comp.attack.value = 0.004; comp.release.value = 0.2;
    comp.connect(ctx.destination);
    const len = sr * 2.6; irBuf = ctx.createBuffer(2, len, sr);
    for (let c = 0; c < 2; c++) { const d = irBuf.getChannelData(c); for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 2.6); }
    noise = ctx.createBuffer(1, sr * 2, sr);
    const nd = noise.getChannelData(0); for (let i = 0; i < nd.length; i++) nd[i] = Math.random() * 2 - 1;
    buildBus();
    for (let i = 0; i * S16 < END; i++) step(i, i * S16);
    const buf = await oc.startRendering();
    ctx = live;
    const n = buf.length, ab = new ArrayBuffer(44 + n * 4), v = new DataView(ab), w = (o, s) => [...s].forEach((c, i) => v.setUint8(o + i, c.charCodeAt(0)));
    w(0, 'RIFF'); v.setUint32(4, 36 + n * 4, true); w(8, 'WAVEfmt '); v.setUint32(16, 16, true); v.setUint16(20, 1, true); v.setUint16(22, 2, true);
    v.setUint32(24, sr, true); v.setUint32(28, sr * 4, true); v.setUint16(32, 4, true); v.setUint16(34, 16, true); w(36, 'data'); v.setUint32(40, n * 4, true);
    const L = buf.getChannelData(0), R = buf.getChannelData(1);
    for (let i = 0; i < n; i++) { v.setInt16(44 + i * 4, Math.max(-1, Math.min(1, L[i])) * 32767, true); v.setInt16(46 + i * 4, Math.max(-1, Math.min(1, R[i])) * 32767, true); }
    return ab;
  }

  return { renderWav, init, start, stop, time, running, setMuted, get muted() { return muted; }, END };
})();
