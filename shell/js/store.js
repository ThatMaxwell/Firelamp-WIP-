// Tiny event bus + persisted settings shared by every part of the shell.

const listeners = new Map();

export const bus = {
  on(type, fn) {
    if (!listeners.has(type)) listeners.set(type, new Set());
    listeners.get(type).add(fn);
    return () => listeners.get(type).delete(fn);
  },
  emit(type, detail) {
    listeners.get(type)?.forEach(fn => fn(detail));
    listeners.get('*')?.forEach(fn => fn(type, detail));
  },
};

const KEY = 'firelamp.settings';
const defaults = {
  assistantName: '',           // the user names their assistant; there is no default
  askBeforeRisky: true,
  cursorSpeed: 1,              // 0.5 – 2
  showTrail: true,
  visionOverlay: false,
};

function load() {
  try { return { ...defaults, ...JSON.parse(localStorage.getItem(KEY) || '{}') }; }
  catch { return { ...defaults }; }
}

const state = load();
const params = new URLSearchParams(location.search);
if (params.has('reset')) Object.assign(state, defaults);
if (params.get('name')) state.assistantName = params.get('name').slice(0, 24);

export const settings = {
  get: k => state[k],
  set(k, v) {
    state[k] = v;
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch {}
    bus.emit('settings', { key: k, value: v });
  },
};

export const flags = {
  demo: params.has('demo'),
  nosplash: params.has('nosplash') || params.has('demo'),
};

export const sleep = ms => new Promise(r => setTimeout(r, ms));

export function h(tag, attrs = {}, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'html') el.innerHTML = v;
    else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else if (k === 'style' && typeof v === 'object') Object.assign(el.style, v);
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const kid of kids.flat()) if (kid != null && kid !== false) el.append(kid.nodeType ? kid : document.createTextNode(kid));
  return el;
}

export const assistantName = () => settings.get('assistantName') || 'Assistant';
