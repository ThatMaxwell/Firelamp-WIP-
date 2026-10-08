// The fire cursor: the AI's own pointer, independent of yours. It glides on gentle arcs,
// leaves a trail of embers, and its flame outline boils like hand-drawn animation.
import { h, settings, assistantName, bus } from '../store.js';
import { logoSVG } from '../icons.js';

const SIZE_H = 35;
const SCALE = SIZE_H / 976;                       // logo viewBox height
const HOT = { x: (118 - 20) * SCALE, y: (202 - 20) * SCALE }; // arrow tip, in px

// ---------- embers ----------
const canvas = document.getElementById('embers');
const ctx = canvas.getContext('2d');
const parts = [];
let emberRaf = 0;
function resize() {
  const dpr = devicePixelRatio || 1;
  canvas.width = innerWidth * dpr; canvas.height = innerHeight * dpr;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}
resize(); addEventListener('resize', resize);

const EMBER_COLORS = ['255,208,138', '255,181,71', '255,138,61', '226,64,42'];
export function spark(x, y, n = 1, power = 1) {
  if (!settings.get('showTrail')) return;
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2, v = (Math.random() * .8 + .2) * power;
    parts.push({
      x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - .6 * power,
      life: 1, decay: .016 + Math.random() * .02, r: 1 + Math.random() * 1.8,
      c: EMBER_COLORS[(Math.random() * EMBER_COLORS.length) | 0],
    });
  }
  if (!emberRaf) emberRaf = requestAnimationFrame(drawEmbers);
}
function drawEmbers() {
  ctx.clearRect(0, 0, innerWidth, innerHeight);
  ctx.globalCompositeOperation = 'lighter';
  for (let i = parts.length - 1; i >= 0; i--) {
    const p = parts[i];
    p.x += p.vx; p.y += p.vy; p.vy -= .02; p.vx *= .97; p.vx += (Math.random() - .5) * .08;
    p.life -= p.decay;
    if (p.life <= 0) { parts.splice(i, 1); continue; }
    const r = p.r * (0.6 + p.life * .6);
    const g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, r * 3.2);
    g.addColorStop(0, `rgba(${p.c},${p.life})`);
    g.addColorStop(1, `rgba(${p.c},0)`);
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(p.x, p.y, r * 3.2, 0, Math.PI * 2); ctx.fill();
  }
  emberRaf = parts.length ? requestAnimationFrame(drawEmbers) : 0;
  if (!parts.length) ctx.clearRect(0, 0, innerWidth, innerHeight);
}

// ---------- cursor ----------
const easeInOut = t => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

export class FireCursor {
  constructor(root) {
    this.root = root;
    this.verb = h('span', { class: 'verb' });
    this.nameEl = h('span', { class: 'name' }, assistantName());
    this.body = h('div', { class: 'fc-body', html: logoSVG() });
    this.body.querySelector('.logo-flame').classList.add('boil-soft');
    root.append(this.body, h('div', { class: 'fc-tag' }, this.nameEl, this.verb));
    root.style.transformOrigin = `${HOT.x}px ${HOT.y}px`;
    this.x = innerWidth / 2; this.y = innerHeight - 140; this.tilt = 0;
    this.place();
    bus.on('settings', ({ key }) => { if (key === 'assistantName') this.nameEl.textContent = assistantName(); });
  }
  place() {
    this.root.style.transform = `translate(${this.x - HOT.x}px, ${this.y - HOT.y}px) rotate(${this.tilt}deg)`;
    if (this.carry) { this.carry.style.left = this.x + 'px'; this.carry.style.top = this.y + 'px'; }
  }
  show(from) {
    if (from) { this.x = from.x; this.y = from.y; this.place(); }
    this.root.classList.add('on');
    spark(this.x, this.y, 14, 1.4);
  }
  hide() { this.root.classList.remove('on'); }
  say(text) { this.verb.textContent = text || ''; }
  setPaused(p) { this.root.classList.toggle('paused', p); }

  /** Glide to (x, y) on a soft arc. Resolves when it arrives. */
  moveTo(x, y, { gate } = {}) {
    const sx = this.x, sy = this.y, dx = x - sx, dy = y - sy;
    const dist = Math.hypot(dx, dy);
    if (dist < 1) return Promise.resolve();
    const speed = settings.get('cursorSpeed') || 1;
    const dur = Math.min(1100, 260 + dist * .55) / speed;
    // control point bowed off the straight line, like a wrist movement
    const bow = (Math.random() < .5 ? -1 : 1) * Math.min(120, dist * .18);
    const cx = sx + dx / 2 - (dy / dist) * bow, cy = sy + dy / 2 + (dx / dist) * bow;
    return new Promise(resolve => {
      let t0 = null, lastSpark = 0, held = 0, pausedAt = 0;
      const frame = now => {
        if (gate?.paused) { if (!pausedAt) pausedAt = now; requestAnimationFrame(frame); return; }
        if (pausedAt) { held += now - pausedAt; pausedAt = 0; }
        t0 ??= now;
        const t = Math.min(1, (now - t0 - held) / dur), e = easeInOut(t), u = 1 - e;
        const nx = u * u * sx + 2 * u * e * cx + e * e * x;
        const ny = u * u * sy + 2 * u * e * cy + e * e * y;
        const vx = nx - this.x;
        this.tilt += (Math.max(-10, Math.min(10, vx * .9)) - this.tilt) * .2;
        this.x = nx; this.y = ny; this.place();
        if (now - lastSpark > 22 && t < .96) { spark(nx + 4, ny + 10, 1, .6); lastSpark = now; }
        if (t < 1) requestAnimationFrame(frame);
        else { this.tilt = 0; this.place(); resolve(); }
      };
      requestAnimationFrame(frame);
    });
  }

  async click() {
    this.root.classList.add('press');
    const ring = h('div', { class: 'click-ring', style: { left: this.x + 'px', top: this.y + 'px' } });
    document.body.append(ring);
    setTimeout(() => ring.remove(), 600);
    spark(this.x, this.y, 8, 1.5);
    await new Promise(r => setTimeout(r, 110));
    this.root.classList.remove('press');
  }
}
