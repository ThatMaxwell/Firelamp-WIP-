// The Ask bar: summon the assistant from anywhere (⌥ Space or Ctrl K), like a launcher.
import { h, assistantName } from './store.js';
import { GLYPHS, logoSVG } from './icons.js';
import { SUGGESTIONS } from './agent/plans.js';

let el = null;

export function closeAsk() { el?.remove(); el = null; }

export function openAsk(onSubmit) {
  if (el) return closeAsk();
  let sel = -1;
  const input = h('input', { placeholder: `Ask ${assistantName()} to do anything…`, 'aria-label': 'Ask', spellcheck: 'false' });
  const sugs = SUGGESTIONS.map((s, i) => h('div', { class: 'ask-sug', onclick: () => go(s.text), onpointerenter: () => pick(i) },
    h('span', { html: GLYPHS[s.icon] }), s.text, h('span', { class: 'kbd' }, '↵')));
  const pick = i => { sel = i; sugs.forEach((s, j) => s.classList.toggle('sel', j === i)); };
  const go = text => { if (!text.trim()) return; closeAsk(); onSubmit(text.trim()); };
  el = h('div', { id: 'ask', role: 'dialog', 'aria-label': 'Ask bar' },
    h('div', { class: 'ask-row' }, h('span', { html: logoSVG({ cls: 'ask-logo', animated: true }) }), input, h('span', { class: 'kbd' }, 'esc')),
    h('div', { class: 'ask-sugs' }, sugs));
  document.body.append(el);
  input.focus();
  input.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeAsk();
    else if (e.key === 'ArrowDown') { e.preventDefault(); pick((sel + 1) % sugs.length); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); pick((sel - 1 + sugs.length) % sugs.length); }
    else if (e.key === 'Enter') go(sel >= 0 && !input.value ? SUGGESTIONS[sel].text : input.value);
  });
  setTimeout(() => addEventListener('pointerdown', function off(e) {
    if (el && !el.contains(e.target)) { closeAsk(); removeEventListener('pointerdown', off); }
  }), 0);
}
