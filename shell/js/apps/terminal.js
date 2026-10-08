import { bus, h, assistantName } from '../store.js';
import { logoSVG } from '../icons.js';
import { snapshot } from '../uitree.js';

const esc = s => String(s).replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));

export const terminal = {
  id: 'terminal', title: 'Terminal', icon: 'terminal', w: 680, h: 420, titled: true,
  render(body) {
    const out = h('div');
    const input = h('input', { 'aria-label': 'Command', spellcheck: 'false', autocomplete: 'off' });
    const user = 'carrot@firelamp';
    const prompt = () => `<span class="p">${user}</span> <span class="a">~</span> <span class="d">%</span> `;
    const term = h('div', { class: 'term scroll', onclick: () => input.focus() }, out, h('div', { class: 'term-in', html: '<span>' + prompt() + '</span>' }));
    term.lastChild.append(input);
    body.append(term);

    const print = html => { out.append(h('div', { class: 'l', html })); term.scrollTop = term.scrollHeight; };

    const cmds = {
      help: () => print(`<span class="c">fetch</span>   system info        <span class="c">tree</span>   the live UI tree the AI reads\n<span class="c">ask</span> …   hand a task to ${esc(assistantName())}  <span class="c">whoami</span> <span class="c">date</span> <span class="c">clear</span>`),
      clear: () => out.replaceChildren(),
      whoami: () => print('carrot'),
      date: () => print(new Date().toString()),
      fetch: () => {
        const el = h('div', { class: 'fetch' }, h('div', { html: logoSVG({ animated: true }) }),
          h('div', { class: 'l', html: [
            `<span class="p">carrot</span>@<span class="p">firelamp</span>`,
            `<span class="d">──────────────────</span>`,
            `<span class="a">OS</span>        Firelamp OS 0.1 “Kindling” x86_64`,
            `<span class="a">Base</span>      Arch Linux`,
            `<span class="a">Kernel</span>    6.11-firelamp`,
            `<span class="a">Shell</span>     Hearth (Wayland)`,
            `<span class="a">Assistant</span> ${esc(assistantName())} · LLM brain + Jev reflexes`,
            `<span class="a">UI tree</span>   AT-SPI2, live`,
            `<span class="a">Cursors</span>   2 (yours + 🔥)`,
          ].join('\n') }, h('div', { class: 'swatches' }, ['#120d0b', '#E2402A', '#FF8A3D', '#FFB547', '#FFD08A', '#f7efe9'].map(c => h('i', { style: { background: c } })))));
        out.append(el); term.scrollTop = term.scrollHeight;
      },
      tree: () => {
        const t = snapshot();
        const lines = [];
        t.forEach((w, i) => {
          lines.push(`<span class="a">${esc(w.role)}</span> <span class="c">“${esc(w.name)}”</span>`);
          w.children.slice(0, 14).forEach((n, j) => {
            const last = j === Math.min(w.children.length, 14) - 1;
            lines.push(`<span class="d">${last ? '└─' : '├─'}</span> ${esc(n.role)} <span class="c">“${esc(n.name || '')}”</span> <span class="d">${n.bounds.x},${n.bounds.y} ${n.bounds.w}×${n.bounds.h}</span>`);
          });
          if (w.children.length > 14) lines.push(`<span class="d">   … ${w.children.length - 14} more</span>`);
        });
        print(lines.join('\n'));
      },
      ask: args => { if (!args) return print('usage: ask <something to do>'); bus.emit('ask:submit', { text: args }); print(`<span class="g">→</span> handed to ${esc(assistantName())}. Watch the fire cursor.`); },
    };

    input.addEventListener('keydown', e => {
      if (e.key !== 'Enter') return;
      const line = input.value; input.value = '';
      print(`${prompt()} ${esc(line)}`);
      const [cmd, ...rest] = line.trim().split(/\s+/);
      if (!cmd) return;
      (cmds[cmd] || (() => print(`<span class="r">hearth:</span> command not found: ${esc(cmd)}`)))(rest.join(' '));
    });

    print(`<span class="d">Last login: ${new Date().toDateString()} on ttys001</span>`);
    cmds.fetch();
    print('<span class="d">Type</span> <span class="c">help</span> <span class="d">to see commands.</span>');
    setTimeout(() => input.focus(), 300);
  },
};
