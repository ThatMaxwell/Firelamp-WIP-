// The menu bar: Firelamp menu, the focused app's menus, and status items on the right.
import { bus, h, assistantName } from './store.js';
import { GLYPHS, logoSVG } from './icons.js';

let openEl = null, openAnchor = null;

export function closeMenu() {
  openEl?.remove(); openEl = null;
  openAnchor?.classList.remove('open'); openAnchor = null;
}

export function openMenu(anchor, items, { align = 'left' } = {}) {
  closeMenu();
  const r = anchor.getBoundingClientRect();
  const menu = h('div', { class: 'menu', role: 'menu' },
    items.map(it => it === '-' ? h('div', { class: 'menu-sep' }) :
      h('div', {
        class: 'menu-item' + (it.disabled ? ' disabled' : ''), role: 'menuitem', 'aria-label': it.label,
        onclick: e => { e.stopPropagation(); if (it.disabled) return; closeMenu(); it.action?.(); },
      }, it.label, it.sc ? h('span', { class: 'sc' }, it.sc) : null)));
  document.body.append(menu);
  const left = align === 'right' ? r.right - menu.offsetWidth : r.left;
  Object.assign(menu.style, { left: Math.max(4, left) + 'px', top: r.bottom + 4 + 'px' });
  anchor.classList.add('open');
  openEl = menu; openAnchor = anchor;
}

addEventListener('pointerdown', e => {
  if (openEl && !openEl.contains(e.target) && !e.target.closest('.mb-item')) closeMenu();
});
addEventListener('keydown', e => { if (e.key === 'Escape') closeMenu(); });

const APP_MENUS = {
  File: [{ label: 'New Window', sc: '⌘N' }, { label: 'Open…', sc: '⌘O' }, '-', { label: 'Close Window', sc: '⌘W', action: () => bus.emit('wm:close-focused') }],
  Edit: [{ label: 'Undo', sc: '⌘Z' }, { label: 'Redo', sc: '⇧⌘Z' }, '-', { label: 'Cut', sc: '⌘X' }, { label: 'Copy', sc: '⌘C' }, { label: 'Paste', sc: '⌘V' }, { label: 'Select All', sc: '⌘A' }],
  View: [{ label: 'Show what the AI sees', sc: '⌥⌘V', action: () => bus.emit('vision:toggle') }, { label: 'Show Activity Timeline', sc: '⌥⌘T', action: () => bus.emit('timeline:toggle') }, '-', { label: 'Enter Full Screen', sc: '⌃⌘F' }],
  Window: [{ label: 'Minimize', sc: '⌘M', action: () => bus.emit('wm:minimize-focused') }, { label: 'Zoom', action: () => bus.emit('wm:zoom-focused') }, '-', { label: 'Bring All to Front' }],
  Help: [{ label: 'Firelamp Help' }, { label: 'Keyboard Shortcuts' }],
};

export function mountMenubar(root, { apps }) {
  const logoBtn = h('button', { class: 'mb-item logo', 'aria-label': 'Firelamp menu', html: logoSVG() });
  const appBtn = h('button', { class: 'mb-item app', 'aria-label': 'App menu' }, 'Desktop');
  const menuBtns = Object.keys(APP_MENUS).map(name => h('button', { class: 'mb-item', 'aria-label': name + ' menu' }, name));

  const ai = h('button', { class: 'mb-ai', 'aria-label': 'Assistant status' },
    h('span', { html: logoSVG({ cls: 'mini-logo' }) }), h('span', { class: 'ai-name' }, assistantName()), h('span', { class: 'dot' }));
  const search = h('button', { class: 'mb-item', 'aria-label': 'Ask', html: GLYPHS.search });
  const control = h('button', { class: 'mb-item', 'aria-label': 'Control Center', html: GLYPHS.control });
  const wifi = h('button', { class: 'mb-item', 'aria-label': 'Wi-Fi', html: GLYPHS.wifi });
  const batt = h('button', { class: 'mb-item battery', 'aria-label': 'Battery' }, '87%', h('span', { html: GLYPHS.battery }));
  const clock = h('button', { class: 'mb-item mb-clock', 'aria-label': 'Clock' });

  root.append(
    h('div', { class: 'mb-group' }, logoBtn, appBtn, ...menuBtns),
    h('div', { class: 'mb-spacer' }),
    h('div', { class: 'mb-group' }, ai, batt, wifi, search, control, clock));

  const menus = new Map([
    [logoBtn, () => [
      { label: 'About Firelamp OS', action: () => apps.open('about') },
      '-',
      { label: 'System Settings…', action: () => apps.open('settings') },
      { label: 'Activity Timeline', sc: '⌥⌘T', action: () => bus.emit('timeline:toggle') },
      '-',
      { label: 'Sleep' }, { label: 'Restart…' }, { label: 'Shut Down…' },
      '-',
      { label: 'Lock Screen', sc: '⌃⌘Q' },
    ]],
    [appBtn, () => [{ label: `About ${appBtn.textContent}` }, '-', { label: 'Settings…', sc: '⌘,', action: () => apps.open('settings') }, '-', { label: `Hide ${appBtn.textContent}`, sc: '⌘H' }, { label: `Quit ${appBtn.textContent}`, sc: '⌘Q', action: () => bus.emit('wm:close-focused') }]],
    ...menuBtns.map(b => [b, () => APP_MENUS[b.textContent]]),
    [control, () => [{ label: 'Focus', sc: 'Off' }, { label: 'Screen Mirroring' }, '-', { label: `Pause ${assistantName()}`, sc: '⌃Space', action: () => bus.emit('agent:toggle-pause') }, { label: `Stop ${assistantName()}`, sc: 'Esc', action: () => bus.emit('agent:stop') }]],
    [wifi, () => [{ label: 'Wi-Fi', sc: 'On' }, '-', { label: 'Hearth', sc: '●' }, { label: 'Kitchen 5G' }, '-', { label: 'Network Settings…' }]],
    [batt, () => [{ label: 'Battery 87%', disabled: true }, { label: 'Power Source: Battery', disabled: true }, '-', { label: 'Battery Settings…' }]],
  ]);

  for (const [btn, items] of menus) {
    const right = btn.closest('.mb-group') !== logoBtn.parentElement;
    btn.addEventListener('pointerdown', e => {
      e.stopPropagation();
      if (openAnchor === btn) return closeMenu();
      openMenu(btn, items(), { align: right ? 'right' : 'left' });
    });
    btn.addEventListener('pointerenter', () => { if (openEl && openAnchor !== btn) openMenu(btn, items(), { align: right ? 'right' : 'left' }); });
  }
  ai.addEventListener('click', () => bus.emit('timeline:toggle'));
  search.addEventListener('click', () => bus.emit('ask:open'));

  const tick = () => {
    const d = new Date();
    const day = d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    const time = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    clock.textContent = `${day}  ${time}`;
  };
  tick(); setInterval(tick, 5000);

  bus.on('wm:focus', w => { appBtn.textContent = w ? w.app.title : 'Desktop'; });
  bus.on('settings', ({ key }) => { if (key === 'assistantName') ai.querySelector('.ai-name').textContent = assistantName(); });
  bus.on('agent:state', s => {
    ai.classList.toggle('working', s === 'running');
    ai.classList.toggle('paused', s === 'paused');
  });
}
