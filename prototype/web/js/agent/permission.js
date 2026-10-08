// OS-level permission sheets. They are drawn by the shell, hidden from the AI's UI tree,
// and only a human can answer them, so the AI can never click "Allow" for itself.
import { h, assistantName } from '../store.js';
import { GLYPHS, logoSVG } from '../icons.js';

export function askPermission({ title, body, details = [], why, allow = 'Allow Once', deny = "Don't Allow" }) {
  const layer = document.getElementById('modal-layer');
  return new Promise(resolve => {
    const scrim = h('div', { class: 'scrim', 'data-ai-hidden': '' });
    const finish = ok => {
      sheet.classList.add('out'); scrim.style.transition = 'opacity .25s'; scrim.style.opacity = 0;
      setTimeout(() => { sheet.remove(); scrim.remove(); }, 260);
      removeEventListener('keydown', onKey, true);
      resolve(ok);
    };
    const onKey = e => { if (e.key === 'Escape') { e.stopPropagation(); finish(false); } };
    const sheet = h('div', { class: 'perm ink', role: 'alertdialog', 'aria-label': 'Permission request', 'data-ai-hidden': '' },
      h('div', { class: 'perm-top' },
        h('div', { class: 'perm-badge', html: logoSVG({ animated: true }) }),
        h('div', {}, h('h3', {}, title.replace('{name}', assistantName())), h('p', {}, body))),
      details.length ? h('dl', { class: 'perm-detail' }, details.map(([k, v]) => h('div', {}, h('dt', {}, k), h('dd', {}, v)))) : null,
      why ? h('div', { class: 'perm-why' }, h('span', { html: GLYPHS.sparkle }), h('span', {}, why)) : null,
      h('div', { class: 'perm-actions' },
        h('button', { class: 'btn', onclick: () => finish(false) }, deny),
        h('button', { class: 'btn primary perm-allow', onclick: () => finish(true) }, allow)),
      h('div', { class: 'perm-foot' }, `Only you can answer this. ${assistantName()} is waiting.`));
    addEventListener('keydown', onKey, true);
    layer.append(scrim, sheet);
  });
}
