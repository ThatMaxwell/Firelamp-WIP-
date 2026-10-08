// Firelamp OS shell: boots the desktop and wires every piece together.
import { bus, h, settings, flags, sleep, assistantName } from './store.js';
import { installBoil } from './boil.js';
import { startWallpaper } from './wallpaper.js';
import { logoSVG } from './icons.js';
import { mountMenubar } from './menubar.js';
import { mountDock } from './dock.js';
import { createWM } from './wm.js';
import { watch } from './uitree.js';
import { createAgent } from './agent/agent.js';
import { mountTimeline } from './agent/timeline.js';
import { mountVision } from './agent/vision.js';
import { plan } from './agent/plans.js';
import { openAsk } from './ask.js';
import { toast } from './notify.js';
import { assistant } from './apps/assistant.js';
import { mail } from './apps/mail.js';
import { notes } from './apps/notes.js';
import { files } from './apps/files.js';
import { terminal } from './apps/terminal.js';
import { settingsApp, about } from './apps/system.js';
import { music, photos, calendar, web } from './apps/media.js';

installBoil();
startWallpaper(document.getElementById('wallpaper'));

const registry = Object.fromEntries([assistant, mail, notes, files, terminal, settingsApp, about, music, photos, calendar, web].map(a => [a.id, a]));

const DOCK = [
  { id: 'assistant', icon: 'assistant', get title() { return assistantName(); } },
  { id: 'files', icon: 'files', title: 'Files' },
  { id: 'web', icon: 'web', title: 'Web' },
  { id: 'mail', icon: 'mail', title: 'Mail' },
  { id: 'notes', icon: 'notes', title: 'Notes' },
  { id: 'terminal', icon: 'terminal', title: 'Terminal' },
  { id: 'music', icon: 'music', title: 'Music' },
  { id: 'photos', icon: 'photos', title: 'Photos' },
  { id: 'calendar', icon: 'calendar', title: 'Calendar' },
  { id: 'timeline', icon: 'timeline', title: 'Activity' },
  { id: 'settings', icon: 'settings', title: 'System Settings' },
  '-',
  { id: 'downloads', icon: 'downloads', title: 'Downloads' },
  { id: 'trash', icon: 'trash', title: 'Trash' },
];

let wm;
const dock = mountDock(document.getElementById('dock'), {
  items: DOCK,
  onLaunch(id) {
    if (id === 'timeline') return bus.emit('timeline:toggle');
    if (id === 'downloads') return wm.open('files');
    if (id === 'trash') return;
    wm.open(id, id === 'assistant' ? assistantSpot() : {});
  },
});
wm = createWM(document.getElementById('desktop'), { registry, dock });
mountMenubar(document.getElementById('menubar'), { apps: wm });
mountTimeline(document.getElementById('timeline-panel'));
mountVision(document.getElementById('vision'));
watch();
const agent = createAgent({ wm, dock });

const assistantSpot = () => ({ x: innerWidth - 400 - 36, y: 26 });

// keep the dock tooltip in sync with the name
bus.on('settings', ({ key }) => {
  if (key !== 'assistantName') return;
  const tip = dock.el('assistant')?.querySelector('.dock-tip');
  if (tip) tip.textContent = assistantName();
});
bus.on('trash:full', () => dock.refreshIcon('trash', 'trash', true));

// ---------- asking for things ----------
bus.on('ask:submit', ({ text }) => {
  const p = plan(text);
  if (!p) {
    bus.emit('agent:say', `I'm running in demo mode, so I only know a few tasks so far. Try “Email Ana my meeting notes”, “Tidy up my Downloads” or “Show me what you see”.`);
    return;
  }
  if (!wm.get('assistant')) wm.open('assistant', assistantSpot());
  agent.run(p.run, { label: p.label });
});

function askFromAnywhere(text) {
  const existing = wm.get('assistant');
  wm.open('assistant', assistantSpot());
  setTimeout(() => bus.emit('assistant:submit', text), existing ? 50 : 650);
}
bus.on('ask:open', () => openAsk(askFromAnywhere));

addEventListener('keydown', e => {
  if ((e.altKey && e.code === 'Space') || (e.ctrlKey && e.key.toLowerCase() === 'k')) { e.preventDefault(); openAsk(askFromAnywhere); }
  if (e.altKey && e.metaKey && e.key.toLowerCase() === 'v') bus.emit('vision:toggle');
  if (e.altKey && e.metaKey && e.key.toLowerCase() === 't') bus.emit('timeline:toggle');
});

// ---------- boot ----------
async function splash() {
  const el = h('div', { id: 'splash' }, h('div', { class: 'splash-inner' },
    h('div', { html: logoSVG({ animated: true }) }), h('div', { class: 'splash-bar' }, h('i'))));
  document.body.append(el);
  await sleep(1900);
  el.classList.add('gone');
  setTimeout(() => el.remove(), 800);
  await sleep(300);
}

function nameYourAssistant() {
  return new Promise(resolve => {
    const layer = document.getElementById('modal-layer');
    const input = h('input', { placeholder: 'Type a name', maxlength: 24, 'aria-label': 'Assistant name', spellcheck: 'false' });
    const go = h('button', { class: 'btn primary', disabled: true }, 'Continue');
    const underline = h('div', { class: 'underline boil-soft', html: '<svg viewBox="0 0 250 10" preserveAspectRatio="none" width="100%" height="10"><path d="M3 6 C 60 2, 120 9, 180 5 S 240 4, 247 6"/></svg>' });
    const card = h('div', { class: 'card namecard' },
      h('div', { html: logoSVG({ cls: 'big-logo', animated: true }) }),
      h('h2', {}, 'Name your assistant'),
      h('p', {}, 'It will answer to this name, and you’ll see it on its fire cursor whenever it’s working.'),
      h('div', { class: 'name-field' }, input, underline), go);
    const scrim = h('div', { class: 'scrim' });
    layer.append(scrim, card);
    setTimeout(() => input.focus(), 300);
    input.addEventListener('input', () => { go.disabled = !input.value.trim(); });
    const done = () => {
      if (!input.value.trim()) return;
      settings.set('assistantName', input.value.trim());
      card.style.transition = scrim.style.transition = 'opacity .3s';
      card.style.opacity = scrim.style.opacity = 0;
      setTimeout(() => { card.remove(); scrim.remove(); resolve(); }, 300);
    };
    input.addEventListener('keydown', e => { if (e.key === 'Enter') done(); });
    go.addEventListener('click', done);
  });
}

(async () => {
  if (!flags.nosplash) await splash();
  if (!settings.get('assistantName')) await nameYourAssistant();
  wm.open('assistant', assistantSpot());
  if (!flags.demo) setTimeout(() => toast({ icon: 'assistant', title: `${assistantName()} is ready`, body: 'Ask for anything with ⌥ Space. Press Esc to stop it, any time.' }), 900);
})();

window.firelamp = { bus, wm, agent, dock, settings };
