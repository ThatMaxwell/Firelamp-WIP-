// The wallpaper: a slow lava lamp. Metaballs are evaluated on a tiny canvas and the
// browser blurs and upscales it, so it costs almost nothing per frame.

const W = 128, H = 80;

const blobs = Array.from({ length: 7 }, (_, i) => ({
  x: Math.random() * W, y: H * (0.2 + Math.random() * 0.8),
  r: 7 + Math.random() * 8,
  vx: (Math.random() - .5) * .05, vy: (i % 2 ? -1 : 1) * (.03 + Math.random() * .05),
  heat: Math.random(),
}));

// field value -> color. Dark warm base, deep ember edges, orange cores, a hint of amber.
const stops = [
  [0.00, [14, 10, 8]],
  [0.60, [20, 13, 10]],
  [0.95, [52, 18, 11]],
  [1.25, [104, 31, 17]],
  [1.80, [116, 38, 19]],
  [2.60, [156, 60, 28]],
];
const lut = new Uint8ClampedArray(256 * 3);
for (let i = 0; i < 256; i++) {
  const v = i / 255 * 2.6;
  let j = 0; while (j < stops.length - 2 && v > stops[j + 1][0]) j++;
  const [a, ca] = stops[j], [b, cb] = stops[j + 1];
  const t = Math.min(1, Math.max(0, (v - a) / (b - a)));
  const s = t * t * (3 - 2 * t);
  for (let k = 0; k < 3; k++) lut[i * 3 + k] = ca[k] + (cb[k] - ca[k]) * s;
}

export function startWallpaper(canvas) {
  canvas.width = W; canvas.height = H;
  const ctx = canvas.getContext('2d');
  const img = ctx.createImageData(W, H);
  const still = matchMedia('(prefers-reduced-motion: reduce)').matches || new URLSearchParams(location.search).has('still');
  let last = 0;

  function frame(t) {
    if (t - last > 50) { // ~20fps is plenty for something this slow
      last = t;
      for (const b of blobs) {
        // lava physics, roughly: hot blobs rise, cool ones sink, they reheat at the bottom
        b.heat += (b.y > H * .8 ? .004 : -.0015);
        b.heat = Math.max(0, Math.min(1, b.heat));
        b.vy += (0.5 - b.heat) * .0009;
        b.vy *= .995; b.vx *= .998;
        b.vx += (Math.random() - .5) * .002;
        b.x += b.vx; b.y += b.vy;
        if (b.x < -5 || b.x > W + 5) b.vx *= -1;
        if (b.y < -8) { b.y = -8; b.vy = Math.abs(b.vy) * .5; }
        if (b.y > H + 8) { b.y = H + 8; b.vy = -Math.abs(b.vy) * .5; }
      }
      const d = img.data;
      for (let y = 0; y < H; y++) {
        for (let x = 0; x < W; x++) {
          let f = 0;
          for (const b of blobs) {
            const dx = x - b.x, dy = (y - b.y) * 1.15;
            f += (b.r * b.r) / (dx * dx + dy * dy + 1);
          }
          f *= 0.5 + 0.5 * (y / H); // a little darker at the top, under the menu bar
          const i = Math.min(255, (f / 2.6 * 255) | 0) * 3, o = (y * W + x) * 4;
          d[o] = lut[i]; d[o + 1] = lut[i + 1]; d[o + 2] = lut[i + 2]; d[o + 3] = 255;
        }
      }
      ctx.putImageData(img, 0, 0);
    }
    if (!still) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}
