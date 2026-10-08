// Records the shell running in headless Chromium and writes screenshots + GIFs to
// docs/media. There is no VM yet, so this is how the UI gets checked.
//
//   python3 -m http.server 8765          (from the repo root)
//   node tools/capture.mjs [scene ...]   (needs playwright and ffmpeg)
//
// Scenes: hero, email, tidy, vision, dock. No arguments records all of them.
import { chromium } from 'playwright';
import { execFileSync } from 'node:child_process';
import { mkdirSync, readdirSync, renameSync, rmSync } from 'node:fs';
import { join } from 'node:path';

const BASE = process.env.FIRELAMP_URL || 'http://localhost:8765/shell/';
const OUT = new URL('../docs/media/', import.meta.url).pathname;
const TMP = join(OUT, '.video');
const W = 1280, H = 800;
mkdirSync(TMP, { recursive: true });

// Captures freeze the lava wallpaper (?still) so GIFs stay small.
// Headless video has no system pointer, so draw the human's cursor ourselves.
const userCursor = () => {
  const c = document.createElement('div');
  c.innerHTML = '<svg width="20" height="26" viewBox="0 0 20 26"><path d="M2 2v19l5-5 3.5 8 3-1.3L10 14.8h7z" fill="#fff" stroke="#000" stroke-width="1.4" stroke-linejoin="round"/></svg>';
  Object.assign(c.style, { position: 'fixed', zIndex: 99999, pointerEvents: 'none', left: '-40px', top: '-40px', filter: 'drop-shadow(0 1px 2px rgba(0,0,0,.5))' });
  addEventListener('DOMContentLoaded', () => document.body.append(c));
  addEventListener('pointermove', e => { c.style.left = e.clientX - 2 + 'px'; c.style.top = e.clientY - 2 + 'px'; }, true);
};

async function scene(name, fn, { record = true, query = 'name=Pip&demo&still' } = {}) {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 1, ...(record ? { recordVideo: { dir: TMP, size: { width: W, height: H } } } : {}) });
  await ctx.addInitScript(userCursor);
  const page = await ctx.newPage();
  page.on('pageerror', e => console.error(`[${name}]`, e.message));
  await page.goto(BASE + '?' + query);
  await fn(page);
  await ctx.close(); await browser.close();
  if (!record) return;
  const webm = readdirSync(TMP).find(f => f.endsWith('.webm'));
  const src = join(TMP, webm), mp4 = join(OUT, name + '.webm');
  renameSync(src, mp4);
  // two-pass palette keeps the ember gradients clean
  const pal = join(TMP, 'pal.png');
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', mp4, '-vf', 'fps=12,scale=720:-1:flags=lanczos,palettegen=stats_mode=diff', pal]);
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', mp4, '-i', pal, '-lavfi', 'fps=12,scale=720:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle', join(OUT, name + '.gif')]);
  rmSync(mp4);
  console.log('wrote', name + '.gif');
}

const glide = async (page, x, y, steps = 25) => page.mouse.move(x, y, { steps });
const allowWhenAsked = async page => {
  const btn = await page.waitForSelector('.perm-allow', { timeout: 60000 });
  await page.waitForTimeout(1300);
  const b = await btn.boundingBox();
  await glide(page, b.x + b.width / 2, b.y + b.height / 2, 30);
  await page.waitForTimeout(250);
  await page.mouse.click(b.x + b.width / 2, b.y + b.height / 2);
};
const waitIdle = page => page.waitForFunction(() => window.firelamp?.agent.state() === 'idle', null, { timeout: 90000 });

const SCENES = {
  async hero(page) {
    await page.waitForTimeout(1500);
    await page.evaluate(() => { firelamp.wm.open('terminal', { x: 70, y: 40 }); });
    await page.waitForTimeout(900);
    await page.evaluate(() => { firelamp.wm.open('notes', { x: 160, y: 250 }); });
    await page.waitForTimeout(1200);
    await page.screenshot({ path: join(OUT, 'desktop.png') });
  },
  async email(page) {
    await page.waitForTimeout(800);
    await glide(page, 1000, 520);
    await page.getByText('Email Ana my meeting notes').click();
    await allowWhenAsked(page);
    await waitIdle(page);
    await page.waitForTimeout(400);
    await page.evaluate(() => firelamp.bus.emit('timeline:toggle', true));
    await page.waitForTimeout(1600);
    await page.screenshot({ path: join(OUT, 'timeline.png') });
  },
  async tidy(page) {
    await page.waitForTimeout(800);
    await page.getByText('Tidy up my Downloads').click();
    await glide(page, 640, 700);
    await page.waitForFunction(() => document.querySelector('#fire-cursor .verb')?.textContent.startsWith('moving'), null, { timeout: 30000 });
    await page.waitForTimeout(400);
    await page.screenshot({ path: join(OUT, 'drag.png') });
    await allowWhenAsked(page);
    await waitIdle(page);
    await page.waitForTimeout(800);
  },
  async vision(page) {
    await page.waitForTimeout(800);
    await page.getByText('Show me what you see').click();
    await page.waitForSelector('#vision.on');
    await page.waitForTimeout(2600);
    await page.screenshot({ path: join(OUT, 'vision.png') });
    await waitIdle(page);
  },
  async dock(page) {
    await page.waitForTimeout(1000);
    const r = await (await page.$('#dock')).boundingBox();
    await glide(page, r.x + 10, r.y + 30, 10);
    await glide(page, r.x + r.width - 10, r.y + 30, 70);
    await glide(page, r.x + r.width * .3, r.y + 30, 50);
    await page.mouse.click(r.x + r.width * .3, r.y + 30);
    await page.waitForTimeout(1500);
  },
};

const pick = process.argv.slice(2);
for (const [name, fn] of Object.entries(SCENES)) {
  if (pick.length && !pick.includes(name)) continue;
  await scene(name, fn, { record: name !== 'hero' });
}
rmSync(TMP, { recursive: true, force: true });
