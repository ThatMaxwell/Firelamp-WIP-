// The assistant: chat with it by text (or voice, on the real system), and it does the work.
import { bus, h, assistantName, sleep } from '../store.js';
import { GLYPHS, logoSVG } from '../icons.js';
import { SUGGESTIONS } from '../agent/plans.js';

export const assistant = {
  id: 'assistant', icon: 'assistant', w: 400, h: 600,
  get title() { return assistantName(); },
  render(body, win, opts) {
    const status = h('div', { class: 'st' }, h('i'), 'Ready');
    const chat = h('div', { class: 'chat scroll', role: 'log', 'aria-label': 'Conversation' });
    const input = h('input', { 'aria-label': 'Message', placeholder: `Ask ${assistantName()} to do something…` });
    const send = h('button', { class: 'c-btn send', 'aria-label': 'Send message', html: GLYPHS.send, disabled: true });
    const chips = h('div', { class: 'chips' }, SUGGESTIONS.map(s =>
      h('button', { class: 'chip', onclick: () => submit(s.text) }, h('span', { html: GLYPHS[s.icon] }), s.text)));

    const hello = h('div', { class: 'asst-hello' },
      h('div', { html: logoSVG({ animated: true }) }),
      h('h2', {}, `Hi, I'm ${assistantName()}.`),
      h('p', {}, 'I use this computer the way you do, just faster. Ask me for something and watch my cursor work. You can pause or stop me any time.'));
    chat.append(hello);

    body.append(h('div', { class: 'asst' },
      h('div', { class: 'asst-head' },
        h('div', { html: logoSVG({ cls: 'h-logo', animated: true }) }),
        h('div', {}, h('div', { class: 'who' }, assistantName()), status),
        h('div', { class: 'grow' }),
        h('button', { class: 'tb-btn', 'aria-label': 'Activity timeline', html: GLYPHS.clock, onclick: () => bus.emit('timeline:toggle') })),
      chat, chips,
      h('div', { class: 'composer' }, input,
        h('button', { class: 'c-btn', 'aria-label': 'Dictate', html: GLYPHS.mic }), send)));

    const scroll = () => chat.scrollTo({ top: chat.scrollHeight, behavior: 'smooth' });
    const add = (who, text) => {
      hello.remove();
      const m = h('div', { class: 'msg ' + who }, text);
      chat.append(m); scroll();
      return m;
    };
    let typing = null;
    const say = async text => {
      typing ??= add('ai typing', '');
      typing.replaceChildren(h('i'), h('i'), h('i'));
      await sleep(450 + Math.min(900, text.length * 12));
      typing.remove(); typing = null;
      add('ai', text);
    };

    async function submit(text) {
      text = text.trim();
      if (!text) return;
      input.value = ''; send.disabled = true;
      chips.style.display = 'none';
      add('me', text);
      bus.emit('ask:submit', { text, say });
    }
    input.addEventListener('input', () => { send.disabled = !input.value.trim(); });
    input.addEventListener('keydown', e => { if (e.key === 'Enter') submit(input.value); });
    send.addEventListener('click', () => submit(input.value));

    const offs = [
      bus.on('agent:say', text => say(text)),
      bus.on('agent:state', s => {
        status.classList.toggle('busy', s !== 'idle');
        status.lastChild.textContent = s === 'running' ? 'Working…' : s === 'paused' ? 'Paused' : 'Ready';
        if (s === 'idle') chips.style.display = '';
      }),
      bus.on('agent:log', e => { if (e.kind === 'done') add('sys', 'Task finished · see Activity for every step'); }),
      bus.on('assistant:submit', t => submit(t)),
    ];
    win.app.onClose = () => offs.forEach(off => off());
    if (opts.prompt) setTimeout(() => submit(opts.prompt), 500);
    setTimeout(() => input.focus(), 400);
  },
};
