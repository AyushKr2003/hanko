// Hanko · Kata 型 — one engine for every design.
//
//   skeleton (shared, never changes)  +  parts (each a small choice)  =  a design
//
// A design is only a preset over PARTS. "Borrowing" a part from another
// design is one edit; partners marked `auto` follow what they depend on, so
// a mix stays coherent without the person having to understand why.
// resolve() is pure (no DOM) so it can be unit-tested and ported to
// core/Kata.js as is.

// ── the parts ───────────────────────────────────────────────────────────
// `by` says which design each variant comes from; `main: false` parts are
// partners that default to `auto`.
export const PARTS = {
  surface: { name: 'Surface', note: 'what panels are made of', main: true, v: { paper: ['Paper', 'margin'], card: ['Card', 'leaf'], washi: ['Washi', 'shoji'] } },
  arrive:  { name: 'Panels', note: 'how a panel appears', main: true, v: { fold: ['Fold out', 'margin'], slip: ['Slip from under', 'leaf'], slide: ['Slide on a rail', 'shoji'] } },
  pointer: { name: 'Pointer', note: 'what marks hover and focus', main: true, v: { thread: ['Thread', 'margin'], crop: ['Crop marks', 'leaf'], brush: ['Brush mark', 'shoji'] } },
  select:  { name: 'Selection', note: 'the chosen row and desk', main: true, v: { tint: ['Tint', 'margin'], plate: ['Ink plate', 'leaf'], wash: ['Ink wash', 'shoji'] } },
  slider:  { name: 'Slider', note: 'volume, brightness', main: true, v: { ruler: ['Ruler', 'margin'], block: ['Ruler + block', 'leaf'], brush: ['Brush stroke', 'shoji'] } },
  ring:    { name: 'Battery', note: 'and other progress', main: true, v: { glyph: ['Battery', 'margin'], enso: ['Ensō', 'shoji'] } },
  seal:    { name: 'Seal', note: 'at rest; red when for you', main: true, v: { outline: ['Outline', 'margin'], deboss: ['Deboss', 'leaf'], carved: ['Carved', 'shoji'] } },
  unread:  { name: 'Unread', note: 'and urgent desks', main: true, v: { edge: ['Red edge', 'margin'], dogear: ['Dog-ear', 'leaf'], stamp: ['未 stamp', 'shoji'] } },
  sign:    { name: 'Panel name', note: 'how a panel says what it is', main: true, v: { eyebrow: ['Heading', 'margin'], tabs: ['Index tabs', 'leaf'], tategaki: ['Vertical sign', 'shoji'] } },
  corner:  { name: 'Corners', main: false, follows: 'surface', v: { soft: ['Soft', 'margin'], cut: ['Cut', 'leaf'] } },
  divider: { name: 'Dividers', main: false, follows: 'surface', v: { hairline: ['Hairline', 'margin'], score: ['Score', 'leaf'], lattice: ['Lattice', 'shoji'] } },
  tempo:   { name: 'Tempo', main: false, follows: 'arrive', v: { spring: ['Spring', 'margin'], snap: ['Snap', 'leaf'], johakyu: ['Jo-ha-kyū', 'shoji'] } },
};
// what an `auto` partner becomes
export const AUTO = {
  corner:  { paper: 'soft', card: 'cut', washi: 'cut' },
  divider: { paper: 'hairline', card: 'score', washi: 'lattice' },
  tempo:   { fold: 'spring', slip: 'snap', slide: 'johakyu' },
};
// touches: independent of any design, each a plain switch
export const TOUCHES = {
  season:   { name: 'Season by the clock', v: ['off', 'kanji', 'english'] },
  numerals: { name: 'Desk numerals', v: ['arabic', 'kanji'] },
  grain:    { name: 'Paper grain', v: ['smooth', 'fine', 'toothy'] },
};
export const DESIGNS = {
  margin: { name: 'Margin', by: 'design', blurb: 'Calm paper, folds from the bar',
    parts: { surface: 'paper', arrive: 'fold', pointer: 'thread', select: 'tint', slider: 'ruler', ring: 'glyph', seal: 'outline', unread: 'edge', sign: 'eyebrow' },
    touches: { season: 'off', numerals: 'arabic', grain: 'smooth' } },
  leaf: { name: 'Leaf', by: 'design2', blurb: 'Sharp card, slips from under',
    parts: { surface: 'card', arrive: 'slip', pointer: 'crop', select: 'plate', slider: 'block', ring: 'glyph', seal: 'deboss', unread: 'dogear', sign: 'tabs' },
    touches: { season: 'off', numerals: 'arabic', grain: 'fine' } },
  shoji: { name: 'Shōji', by: 'design3', blurb: 'Washi on a rail, brush and seasons',
    parts: { surface: 'washi', arrive: 'slide', pointer: 'brush', select: 'wash', slider: 'brush', ring: 'enso', seal: 'carved', unread: 'stamp', sign: 'tategaki' },
    touches: { season: 'kanji', numerals: 'arabic', grain: 'fine' } },
};

// doc = { design, borrow: {part: variant | 'auto'}, touches: {...} }  →  flat style
export function resolve(doc = {}) {
  const warnings = [], d = DESIGNS[doc.design] ? doc.design : 'margin';
  if (doc.design && !DESIGNS[doc.design]) warnings.push(`unknown design "${doc.design}", using margin`);
  const out = { design: d, from: {} };
  for (const [k, p] of Object.entries(PARTS)) {
    let v = (doc.borrow || {})[k];
    if (v !== undefined && v !== 'auto' && !p.v[v]) { warnings.push(`${k}: unknown "${v}"`); v = undefined; }
    if (p.main) out[k] = v && v !== 'auto' ? v : DESIGNS[d].parts[k];
    else out[k] = v && v !== 'auto' ? v : null;      // partners resolved below
    out.from[k] = v && v !== 'auto' ? 'borrowed' : 'design';
  }
  for (const [k, map] of Object.entries(AUTO)) if (!out[k]) out[k] = map[out[PARTS[k].follows]];
  out.touches = { ...DESIGNS[d].touches };
  for (const [k, t] of Object.entries(TOUCHES)) { const v = (doc.touches || {})[k]; if (v !== undefined) t.v.includes(v) ? out.touches[k] = v : warnings.push(`${k}: unknown "${v}"`); }
  out.borrowed = Object.keys(doc.borrow || {}).filter(k => doc.borrow[k] !== 'auto' && PARTS[k] && PARTS[k].v[doc.borrow[k]] && (PARTS[k].main ? DESIGNS[d].parts[k] !== doc.borrow[k] : true));
  out.warnings = warnings;
  return out;
}
// a coherent surprise: a design plus two or three parts borrowed from the others
export function surprise(seed = Date.now()) {
  const r = rng(seed % 2147483646 + 1), names = Object.keys(DESIGNS), d = names[Math.floor(r() * 3)], borrow = {};
  const mains = Object.keys(PARTS).filter(k => PARTS[k].main).sort(() => r() - .5).slice(0, 2 + Math.floor(r() * 2));
  for (const k of mains) { const opts = Object.keys(PARTS[k].v).filter(v => v !== DESIGNS[d].parts[k]); borrow[k] = opts[Math.floor(r() * opts.length)]; }
  return { design: d, borrow };
}
export function describe(st) {
  const base = DESIGNS[st.design].name;
  if (!st.borrowed.length) return base;
  return base + ' with ' + st.borrowed.map(k => { const [nm, by] = PARTS[k].v[st[k]]; return `${DESIGNS[by] ? DESIGNS[by].name : by}’s ${PARTS[k].name.toLowerCase()}`; }).join(', ');
}

// ── colour: three theme values; every token mixed from them ─────────────
export const THEMES = {
  hanko: { paper: '#0e0d0b', ink: '#e9e1d2', red: '#d8452f', name: 'Hanko' },
  kanagawa: { paper: '#1f1f28', ink: '#dcd7ba', red: '#c34043', name: 'Kanagawa' },
  tokyo: { paper: '#1a1b26', ink: '#c0caf5', red: '#f7768e', name: 'Tokyo Night' },
  gruvbox: { paper: '#282828', ink: '#d4be98', red: '#ea6962', name: 'Gruvbox' },
  rosepine: { paper: '#faf4ed', ink: '#575279', red: '#b4637a', name: 'Rosé Pine Dawn' },
  flexoki: { paper: '#fffcf0', ink: '#100f0f', red: '#af3029', name: 'Flexoki Light' },
};
const hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const toHex = a => '#' + a.map(v => Math.round(Math.max(0, Math.min(255, v))).toString(16).padStart(2, '0')).join('');
export const mix = (a, b, t) => toHex(hex(a).map((v, i) => v + (hex(b)[i] - v) * t));
const rgba = (h, a) => `rgba(${hex(h).join(',')},${a})`;
const lum = h => { const c = hex(h).map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }); return .2126 * c[0] + .7152 * c[1] + .0722 * c[2]; };
export const contrast = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05); };
const tier = (ink, paper, target) => { let lo = 0, hi = 1; for (let i = 0; i < 24; i++) { const m = (lo + hi) / 2; contrast(mix(ink, paper, m), paper) > target ? lo = m : hi = m; } return mix(ink, paper, lo); };
export function tokens(key, grain = 'fine') {
  const t = THEMES[key] || THEMES.hanko, L = lum(t.paper) > .4, C = contrast(t.ink, t.paper), g = { smooth: 0, fine: 1, toothy: 2 }[grain] ?? 1;
  return {
    light: L, paper: t.paper, ink: t.ink, red: t.red,
    ink2: tier(t.ink, t.paper, Math.max(5.6, Math.min(7, C * .8))), ink3: tier(t.ink, t.paper, 4.6), ink4: tier(t.ink, t.paper, 2.05),
    line: mix(t.ink, t.paper, L ? .86 : .88), paper2: L ? mix(t.paper, t.ink, .055) : mix(t.paper, '#000000', .32), sunk: L ? mix(t.ink, t.paper, .975) : mix('#000000', t.paper, .55),
    cut: L ? 'rgba(255,255,255,.95)' : rgba(t.ink, .11), edge: L ? rgba(t.ink, .2) : 'rgba(0,0,0,.7)', edgeSide: L ? rgba(t.ink, .1) : rgba(t.ink, .06),
    shade: L ? rgba(mix(t.ink, '#000000', .4), .17) : 'rgba(0,0,0,.6)', shade2: L ? rgba(mix(t.ink, '#000000', .4), .07) : 'rgba(0,0,0,.3)', shadeIn: L ? rgba(t.ink, .2) : 'rgba(0,0,0,.65)',
    scoreDark: L ? rgba(t.ink, .15) : 'rgba(0,0,0,.6)', scoreLight: L ? 'rgba(255,255,255,.9)' : rgba(t.ink, .07),
    grain: g ? `url(${texture('grain', t, L, g)})` : 'none', washi: `url(${texture('washi', t, L, g || 1)})`,
  };
}
export function applyTokens(el, v) { for (const [k, c] of Object.entries(v)) if (typeof c === 'string') el.style.setProperty('--' + k, c); el.dataset.light = v.light ? '1' : '0'; }

// ── textures (generated once per theme) ─────────────────────────────────
export function rng(seed) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
export function noise1(seed) { const r = rng(seed), p = Array.from({ length: 256 }, r); return x => { const i = Math.floor(x), f = x - i, u = f * f * (3 - 2 * f); return p[i & 255] * (1 - u) + p[(i + 1) & 255] * u; }; }
const texCache = {};
function texture(kind, t, L, g) {
  const key = kind + t.paper + g; if (texCache[key]) return texCache[key];
  const c = document.createElement('canvas'), n = kind === 'grain' ? 160 : 320; c.width = c.height = n; const x = c.getContext('2d'), r = rng(kind === 'grain' ? 17 : 31);
  if (kind === 'grain') { for (let i = 0; i < 2600 * g; i++) { x.fillStyle = (r() < .5 ? '#000000' : '#ffffff') + (L ? '0b' : '09'); x.fillRect(r() * n, r() * n, 1, 1); } for (let i = 0; i < 30 * g; i++) { x.strokeStyle = t.ink + (L ? '0c' : '0a'); x.lineWidth = .5; const a = r() * 6.3, px = r() * n, py = r() * n; x.beginPath(); x.moveTo(px, py); x.lineTo(px + Math.cos(a) * 9, py + Math.sin(a) * 9); x.stroke(); } }
  else { for (let i = 0; i < 220; i++) { const px = r() * n, py = r() * n, a = r() * 6.3, l = 8 + r() * 46; x.strokeStyle = (r() < .5 ? t.ink : (L ? '#000000' : '#ffffff')) + (L ? '0d' : '0a'); x.lineWidth = .4 + r() * .7; x.beginPath(); x.moveTo(px, py); x.quadraticCurveTo(px + Math.cos(a + .6) * l * .5, py + Math.sin(a + .6) * l * .5, px + Math.cos(a) * l, py + Math.sin(a) * l); x.stroke(); } }
  return texCache[key] = c.toDataURL();
}

// one wallpaper for every design, so they are compared fairly (Omarchy owns the real one)
export function wallpaper(canvas, v, seed = 5) {
  const W = canvas.width = canvas.clientWidth * 2, H = canvas.height = canvas.clientHeight * 2, g = canvas.getContext('2d'), L = v.light, P = v.paper, I = v.ink;
  const sky = g.createLinearGradient(0, 0, 0, H); sky.addColorStop(0, L ? mix(P, I, .02) : mix(P, '#000000', .4)); sky.addColorStop(.6, L ? mix(P, v.red, .06) : mix(P, I, .07)); sky.addColorStop(1, L ? P : mix(P, '#000000', .2));
  g.fillStyle = sky; g.fillRect(0, 0, W, H);
  const mx = W * .87, my = H * .3, mr = H * .075, halo = g.createRadialGradient(mx, my, mr * .8, mx, my, mr * 5);
  halo.addColorStop(0, (L ? v.red : I) + (L ? '30' : '22')); halo.addColorStop(1, P + '00'); g.fillStyle = halo; g.fillRect(0, 0, W, H);
  g.fillStyle = L ? mix(P, v.red, .7) : mix(P, I, .8); g.beginPath(); g.arc(mx, my, mr, 0, 7); g.fill();
  for (let l = 0; l < 6; l++) {
    const n = noise1(seed * 17 + l * 53), t = l / 5, base = H * (.5 + l * .085), amp = H * (.2 - l * .022), fq = 1.6 + l * 1.1, ridge = [];
    for (let x = 0; x <= W; x += 4) { const u = x / W * fq; ridge.push([x, base - amp * (n(u) * .72 + n(u * 2.9 + 4) * .22 + n(u * 8 + 1) * .06)]); }
    const ink = L ? mix(P, I, .14 + t * .55) : (t < .5 ? mix(P, I, .3 - t * .4) : mix(P, '#000000', (t - .4) * 1.2)), top = Math.min(...ridge.map(p => p[1]));
    const gr = g.createLinearGradient(0, top, 0, top + H * (l === 5 ? .5 : .13 + t * .05)); gr.addColorStop(0, ink + 'ff'); gr.addColorStop(.5, ink + (L ? '88' : 'aa')); gr.addColorStop(1, ink + (l === 5 ? 'ff' : '00'));
    g.fillStyle = gr; g.beginPath(); g.moveTo(0, H); ridge.forEach(p => g.lineTo(p[0], p[1])); g.lineTo(W, H); g.fill();
  }
  const id = g.getImageData(0, 0, W, H), d = id.data, q = rng(seed + 9); for (let i = 0; i < d.length; i += 4) { const k = (q() - .5) * (L ? 8 : 10); d[i] += k; d[i + 1] += k; d[i + 2] += k; } g.putImageData(id, 0, 0);
}

// ── drawn parts ─────────────────────────────────────────────────────────
export function brushPath(w, h, seed = 3) {
  const n = noise1(seed), top = [], bot = [];
  for (let x = 0; x <= w; x += Math.max(1, w / 90)) { const u = x / w, head = Math.min(1, Math.sqrt(x / (h * .9))) * (1 + .18 * Math.exp(-x / h)), tail = 1 - Math.pow(u, 2.4) * .78, t = h / 2 * head * tail * (.88 + .24 * n(u * 7 + 2)), cy = h / 2 + (n(u * 2.5 + 9) - .5) * h * .18; top.push([x, cy - t]); bot.push([x, cy + t * .86]); }
  const f = p => p[0].toFixed(1) + ' ' + p[1].toFixed(1);
  return `M${f(bot[0])} Q${(-h * .35).toFixed(1)} ${(h / 2).toFixed(1)} ${f(top[0])} ` + top.map(p => 'L' + f(p)).join(' ') + ` L${(w + h * .45).toFixed(1)} ${(h / 2).toFixed(1)} ` + bot.slice().reverse().map(p => 'L' + f(p)).join(' ') + ' Z';
}
export const brush = (w, h, seed = 4, fill = 'var(--ink)') => {
  const r = rng(seed + 7); let k = ''; if (w > 40) for (let i = 0; i < 4; i++) { const y = h * (.3 + r() * .45), x0 = w * (.55 + r() * .25); k += `<path d="M${x0.toFixed(1)} ${y.toFixed(1)}L${(w + h * .4).toFixed(1)} ${y.toFixed(1)}" stroke="var(--paper)" stroke-width="${(.5 + r() * .7).toFixed(2)}" opacity=".7"/>`; }
  return `<svg width="${w + h}" height="${h}" viewBox="0 0 ${w + h} ${h}"><path d="${brushPath(w, h, seed)}" fill="${fill}"/>${k}</svg>`;
};
export function enso(v, size, { width = size * .1, seed = 8, ghost = true, fill = 'var(--ink)' } = {}) {
  const c = size / 2, R = size / 2 - width * .75, n = noise1(seed), a0 = -Math.PI * .62, sweep = Math.max(.02, v) * Math.PI * 1.9, out = [], inn = [];
  for (let i = 0; i <= 120; i++) { const u = i / 120, a = a0 + sweep * u, w = width * Math.min(1, u * 7) * (1 + .35 * Math.exp(-u * 10)) * (1 - Math.pow(u, 2.2) * .8) * (.7 + .55 * n(u * 5 + 1)), rr = R + (n(u * 4 + 7) - .5) * width * .35; out.push([c + Math.cos(a) * (rr + w / 2), c + Math.sin(a) * (rr + w / 2)]); inn.push([c + Math.cos(a) * (rr - w / 2), c + Math.sin(a) * (rr - w / 2)]); }
  const f = p => p[0].toFixed(1) + ' ' + p[1].toFixed(1), g = !ghost ? '' : size < 30 ? `<circle cx="${c}" cy="${c}" r="${R}" fill="none" stroke="currentColor" stroke-width="${(width * .45).toFixed(2)}" opacity=".28"/>` : `<circle cx="${c}" cy="${c}" r="${R}" fill="none" stroke="var(--ink4)" stroke-dasharray="2 4"/>`;
  return `<svg viewBox="0 0 ${size} ${size}" width="${size}" height="${size}">${g}<path d="M${out.map(f).join('L')}L${inn.reverse().map(f).join('L')}Z" fill="${fill}"/></svg>`;
}
const I = {
  wifi: '<path d="M2.5 8.8a14 14 0 0 1 19 0"/><path d="M5.6 12.1a9.5 9.5 0 0 1 12.8 0"/><path d="M8.8 15.3a5 5 0 0 1 6.4 0"/><circle cx="12" cy="18.6" r="1.1" fill="currentColor" stroke="none"/>',
  wifi2: '<path d="M2.5 8.8a14 14 0 0 1 19 0" opacity=".3"/><path d="M5.6 12.1a9.5 9.5 0 0 1 12.8 0"/><path d="M8.8 15.3a5 5 0 0 1 6.4 0"/><circle cx="12" cy="18.6" r="1.1" fill="currentColor" stroke="none"/>',
  vol: '<path d="M4 9.5h3.2L12 5.5v13l-4.8-4H4z"/><path d="M15.5 9a4 4 0 0 1 0 6"/><path d="M18.2 6.5a7.6 7.6 0 0 1 0 11"/>',
  speaker: '<rect x="6" y="3" width="12" height="18" rx="2"/><circle cx="12" cy="14.5" r="3.2"/><circle cx="12" cy="7.5" r="1"/>',
  head: '<path d="M4 15v-3a8 8 0 0 1 16 0v3"/><rect x="3.5" y="14" width="4" height="6.5" rx="1.6"/><rect x="16.5" y="14" width="4" height="6.5" rx="1.6"/>',
  laptop: '<rect x="4.5" y="5" width="15" height="10.5" rx="1.5"/><path d="M2.5 19h19"/>', mic: '<rect x="9" y="3.5" width="6" height="11" rx="3"/><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v2.5"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>', sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>',
  coffee: '<path d="M4.5 9h12v5a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5z"/><path d="M16.5 10.5h1.5a2.5 2.5 0 0 1 0 5h-2"/>', night: '<path d="M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9z"/>', moon: '<path d="M19.5 14.5A8 8 0 0 1 9.5 4.5a8 8 0 1 0 10 10z"/>',
  brush: '<path d="M14.5 4.5l5 5-8.5 8.5-5-5z"/><path d="M6 13l-1.5 6.5L11 18"/>', grid: '<rect x="4" y="4" width="7" height="7"/><rect x="13" y="4" width="7" height="7"/><rect x="4" y="13" width="7" height="7"/><rect x="13" y="13" width="7" height="7"/>',
  bar: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 8.5h18"/>', panel: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 8.5h18M12 8.5V20"/>', bell: '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 1.5h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>',
  key: '<circle cx="8" cy="15" r="4"/><path d="M11 12l8.5-8.5M16 7l2.5 2.5"/>', info: '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5M12 7.8v.01"/>', shuffle: '<path d="M3 7h4l10 10h4M3 17h4l3-3M14 10l3-3h4M18 4l3 3-3 3M18 14l3 3-3 3"/>', undo: '<path d="M9 7.5L4.5 12 9 16.5"/><path d="M4.5 12h10a5 5 0 0 1 0 10H12"/>',
  cloud: '<path d="M7 18.5a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5 3.8 3.8 0 0 1-.5 7.5z"/>', lock: '<rect x="5" y="10.5" width="14" height="10" rx="2"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>',
};
export const icon = (n, cls = 'ic') => `<svg class="${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${I[n] || ''}</svg>`;

// battery: a glyph (rounded or cut, by the corner part) or an ensō
export function ring(st, v, size, opts = {}) {
  if (st.ring === 'enso') return enso(v / 100, size, { width: size < 30 ? 2.6 : size * .095, seed: size < 30 ? 2 : 9, fill: opts.alert ? 'var(--red)' : size < 30 ? 'currentColor' : 'var(--ink)' });
  if (size < 30) { const r = st.corner === 'cut' ? 0 : 3.5; return `<svg width="22" height="12" viewBox="0 0 22 12"><rect x=".75" y=".75" width="18.5" height="10.5" rx="${r}" fill="none" stroke="currentColor" stroke-width="1.3"/><rect x="2.6" y="2.6" width="${Math.max(1, 14.8 * v / 100).toFixed(1)}" height="6.8" rx="${r ? 1.5 : 0}" fill="currentColor"/><rect x="20" y="4" width="1.6" height="4" fill="currentColor"/></svg>`; }
  return `<div style="width:${size}px;height:${size}px;display:grid;place-items:center"><svg width="${size * .78}" height="${size * .42}" viewBox="0 0 70 38"><rect x="1.5" y="1.5" width="61" height="35" rx="${st.corner === 'cut' ? 0 : 8}" fill="none" stroke="var(--ink)" stroke-width="2.5"/><rect x="7" y="7" width="${(50 * v / 100).toFixed(1)}" height="24" rx="${st.corner === 'cut' ? 0 : 4}" fill="var(--ink)"/><rect x="64" y="13" width="4.5" height="12" fill="var(--ink)"/></svg></div>`;
}
let sid = 0;
export function seal(st, glyph = '印', on = false, size = 24) {
  const id = 'sf' + (++sid), r = st.corner === 'cut' ? 0 : size * .22, rough = st.seal === 'carved';
  const f = rough ? `<defs><filter id="${id}"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="${sid}"/><feDisplacementMap in="SourceGraphic" scale="1.6"/></filter></defs>` : '';
  const flt = rough ? ` filter="url(#${id})"` : '';
  let body;
  if (on) body = `<rect x="1.5" y="1.5" width="21" height="21" rx="${(r * 24 / size).toFixed(1)}" fill="var(--red)"${flt}/>`;
  else if (st.seal === 'deboss') body = `<rect x="1" y="1" width="22" height="22" fill="var(--paper2)"/><path d="M1 23V1h22" stroke="var(--shadeIn)" fill="none" stroke-width="1.4"/><path d="M1 23h22V1" stroke="var(--cut)" fill="none" stroke-width="1.4"/>`;
  else body = `<rect x="2" y="2" width="20" height="20" rx="${(r * 24 / size).toFixed(1)}" fill="none" stroke="${rough ? 'var(--ink2)' : 'var(--ink3)'}" stroke-width="1.5"${flt}/>`;
  const col = on ? 'var(--paper)' : st.seal === 'deboss' ? 'var(--ink4)' : rough ? 'var(--ink2)' : 'var(--ink3)';
  return `<span class="seal" style="width:${size}px;height:${size}px"><svg viewBox="0 0 24 24">${f}${body}</svg><span style="color:${col};font-size:${size * .54}px">${glyph}</span></span>`;
}
// sliders: one API, three drawings
export function slider(st, v, w, { thin = false, muted = false, seed = 4 } = {}) {
  const h = thin ? 18 : 30, n = st.slider === 'brush' ? (thin ? 11 : 21) : thin ? 25 : 49, step = (w - 2) / (n - 1), at = Math.round(v / 100 * (n - 1));
  let s = '';
  if (st.slider === 'brush') {
    for (let i = 0; i < n; i++) s += `<i class="tk" style="left:${Math.round(i * step)}px;height:${i % 5 === 0 ? (thin ? 4 : 7) : (thin ? 2 : 4)}px;background:${i % 5 === 0 ? 'var(--ink3)' : 'var(--ink4)'}"></i>`;
    const len = Math.max(4, Math.round(v / 100 * w)), bh = thin ? 9 : 16;
    s += `<div class="stroke" style="top:${thin ? 1 : 3}px">${brush(len, bh, seed, muted ? 'var(--red)' : 'var(--ink)')}</div>`;
  } else {
    for (let i = 0; i < n; i++) { const maj = i % 4 === 0, isV = st.slider === 'ruler' && i === at; s += `<i class="tk${i < at ? ' f' : ''}${isV ? ' v' : ''}" style="left:${Math.round(i * step)}px;height:${isV ? h : maj ? (thin ? 9 : 16) : (thin ? 6 : 10)}px"></i>`; }
    if (st.slider === 'block') s += `<i class="hd" style="left:${Math.round(at * step)}px;height:${thin ? 13 : 22}px"></i>`;
  }
  return `<div class="sl ${st.slider}${muted ? ' muted' : ''}" style="width:${w}px;height:${h}px" data-v="${v}" data-w="${w}" data-thin="${thin ? 1 : ''}" data-seed="${seed}">${s}</div>`;
}

// ── data ────────────────────────────────────────────────────────────────
export const DATA = { time: '21:44', date: 'Thu 8 Oct', season: ['寒露', 'Cold dew'], spaces: [1, 2, 3, 4, 5], has: [1, 2, 3, 4], on: 3, urgent: 4, app: 'Neovim', doc: 'hanko / core / Kata.js', media: ['Water Copy', 'Hiroshi Yoshimura'], vol: 62, bat: 91, inbox: 3, glyph: '印' };
const KAN = ['〇', '一', '二', '三', '四', '五', '六'];

export function bar(st, d = DATA) {
  const t = st.touches, kan = t.numerals === 'kanji';
  return `<header class="bar surf">
    <div class="zone left">
      <div class="item seal-w" data-panel="inbox">${seal(st, d.glyph, !!d.inbox)}${d.inbox ? `<span class="count">${d.inbox}</span>` : ''}</div>
      <div class="desks"><div class="dmark"></div>${d.spaces.map(n => `<div class="ws${kan ? ' kan' : ''}${d.has.includes(n) ? ' has' : ''}${n === d.on ? ' on' : ''}${n === d.urgent ? ' urgent' : ''}">${kan ? KAN[n] : n}</div>`).join('')}</div>
      <div style="width:18px"></div>
      <div class="item title"><span class="app">${d.app}</span><span class="doc">${d.doc}</span></div>
    </div>
    <div class="zone"><div class="item clock" data-panel="time"><span class="time fig">${d.time}</span><span class="date">${d.date}</span>${t.season !== 'off' ? `<span class="season">${t.season === 'kanji' ? `<span class="jps">${d.season[0]}</span>` : d.season[1]}</span>` : ''}</div></div>
    <div class="zone right">
      <div class="item media"><span class="eq"><i></i><i></i><i></i></span><span class="t">${d.media[0]}</span><span class="a">${d.media[1]}</span></div><div class="vsep"></div>
      <div class="item" style="color:var(--ink3)">${icon('cloud')}</div>
      <div class="item" data-panel="net">${icon('wifi')}</div>
      <div class="item" data-panel="sound">${icon('vol')}<span class="v">${d.vol}</span></div>
      <div class="item" data-panel="power"><span style="display:flex">${ring(st, d.bat, 17)}</span><span class="v">${d.bat}</span></div>
    </div>
  </header>`;
}

// ── panels: content written once, in parts ──────────────────────────────
const row = (ic, t, s, end = '', cls = '') => `<div class="row ${cls}">${ic}<div class="main"><b>${t}</b>${s ? `<span>${s}</span>` : ''}</div><div class="end">${end}</div></div>`;
const list = (rows, sel = 0) => `<div class="list"><div class="ind" style="transform:translateY(${sel * 46}px)"></div>${rows.map((r, i) => i === sel ? r.replace('class="row ', 'class="row sel ') : r).join('')}</div>`;
const mon = s => `<span class="mon">${s}</span>`;
export const PANELS = {
  sound: { w: 400, kan: '音', en: 'Sound', icon: 'speaker', meta: 'Studio Monitors', anchor: '[data-panel="sound"]', body: (st, d) => `
    <div class="hero"><span class="n fig">${d.vol}</span><span class="u">%</span><span class="note">Scroll the figure<br>or drag below</span></div>
    ${slider(st, d.vol, 336)}<div class="scale" style="width:336px"><span>0</span><span>50</span><span>100</span></div>
    <div class="dv"></div><div class="h">Plays on</div>
    ${list([row(icon('speaker'), 'Studio Monitors', 'USB · 48 kHz', icon('check')), row(icon('head'), 'WH-1000XM5', 'Bluetooth · 70% battery'), row(icon('laptop'), 'Built-in speakers', 'Analog')], 0)}
    <div class="dv"></div><div class="h">Apps</div>
    ${row(mon('S'), 'Spotify', '', `${slider(st, 80, 120, { thin: true, seed: 11 })}<span class="fig" style="font-size:17px;width:24px;text-align:right;color:var(--ink)">80</span>`)}
    ${row(mon('F'), 'Firefox', '', `${slider(st, 45, 120, { thin: true, seed: 12 })}<span class="fig" style="font-size:17px;width:24px;text-align:right;color:var(--ink)">45</span>`)}
    <div class="dv"></div>${row(icon('mic'), 'Shure MV7', 'Microphone · 70%', '<div class="switch on"></div>')}` },
  power: { w: 400, kan: '電', en: 'Power', icon: 'sun', meta: 'on battery · 94% health', anchor: '[data-panel="power"]', body: (st, d) => `
    <div style="display:flex;gap:18px;align-items:center;margin-top:4px">${st.ring === 'enso' ? `<div style="position:relative;width:112px;height:112px;flex:none">${ring(st, d.bat, 112)}<span class="fig" style="position:absolute;inset:0;display:grid;place-items:center;font-size:38px;font-weight:340">${d.bat}</span></div>` : `<div class="hero" style="margin:0"><span class="n fig">${d.bat}</span><span class="u">%</span></div>`}
      <div><div style="font-family:Fraunces;font-size:21px;line-height:1.2;font-variation-settings:'opsz' 72,'SOFT' var(--soft);font-weight:380">About 6 h 10 min<br><span style="color:var(--ink2)">at this pace</span></div>${st.ring === 'glyph' ? `<div style="margin-top:8px">${ring(st, d.bat, 56)}</div>` : ''}</div></div>
    <div class="dv"></div><div class="h">${icon('sun')}Brightness<span class="sp"></span><span class="fig" style="font-size:16px;color:var(--ink)">72</span></div>${slider(st, 72, 360, { seed: 7 })}
    <div class="h" style="margin-top:16px">Power mode</div><div class="seg"><div class="knob" style="width:calc((100% - 6px)/3);transform:translateX(100%)"></div><span>Saver</span><span class="on">Balanced</span><span>Performance</span></div>
    <div class="dv"></div><div class="chips"><div class="chip">${icon('coffee')}<b>Keep awake</b></div><div class="chip on">${icon('night')}<b>Night light</b></div><div class="chip">${icon('moon')}<b>Quiet</b></div></div>` },
  inbox: { w: 400, kan: '便り', en: 'Letters', icon: 'bell', meta: '3 unread · 2 apps', anchor: '[data-panel="inbox"]', body: (st, d) => {
    const un = () => st.unread === 'edge' ? '<i class="un-edge"></i>' : st.unread === 'dogear' ? '<i class="un-ear"></i>' : '';
    const stamp = () => st.unread === 'stamp' ? seal({ ...st, seal: 'carved' }, '未', true, 18) : '';
    return `<div class="h" style="margin:0"><span>Quiet</span><span class="sp"></span><div class="switch"></div></div>
    <div class="nt">${un()}<div class="hd">${mon('S')}<b>Signal</b><span>· Mei · 2 min</span><span class="sp"></span>${stamp()}</div><h4>Are we still on for tomorrow?</h4><p>I found the place with the long table by the river — 7:30 works?</p><div style="display:flex;gap:6px;margin-top:10px"><span class="btn ink">Reply</span><span class="btn">Mark read</span></div></div>
    <div class="nt">${un()}<div class="hd">${mon('F')}<b>Firefox</b><span>· 14 min</span><span class="sp"></span>${stamp()}</div><h4>Download finished</h4><p>omarchy-4.1.iso · 2.4 GB</p></div>
    <div class="nt read"><div class="hd">${mon('O')}<b>Omarchy</b><span>· 1 h</span></div><h4>Update available</h4><p>4 packages · 38 MB</p></div>` } },
};
const ORDER = [['time', 'Time'], ['sound', 'Sound'], ['net', 'Network'], ['power', 'Power'], ['inbox', 'Letters']];
export function panelHTML(st, key, d = DATA) {
  const p = PANELS[key];
  const head = st.sign === 'eyebrow' ? `<div class="eyebrow">${icon(p.icon)}<b>${p.en}</b><span>· ${p.meta}</span><span class="sp"></span></div>` : st.sign === 'tabs' ? `<div class="eyebrow"><b>${p.meta}</b></div>` : `<div class="eyebrow"><b>${p.meta}</b></div>`;
  return `<i class="join l"></i><i class="join r"></i><div class="body">${head}${p.body(st, d)}</div>${st.sign === 'tategaki' ? `<div class="tate"><span class="kan">${p.kan}</span><span class="en">${p.en}</span></div>` : ''}${st.sign === 'tabs' ? `<div class="tabs">${ORDER.map(([k, n]) => `<span class="tab${k === key ? ' on' : ''}">${n}</span>`).join('')}</div>` : ''}`;
}

// ── mount a desk in a style ─────────────────────────────────────────────
export function setStyle(el, st) { for (const k of Object.keys(PARTS)) el.dataset[k] = st[k]; }
export function desk(el, st, o = {}) {
  const v = tokens(o.theme || 'hanko', st.touches.grain); applyTokens(el, v); setStyle(el, st);
  el.classList.add('k');
  el.innerHTML = `<canvas class="wall"></canvas>${o.windows === false ? '' : `
    <div class="win" style="left:14px;top:54px;width:${o.narrow ? 560 : 820}px;height:${(o.h || 900) - 68}px"><div class="chrome"><b>nvim</b> Kata.js<span style="margin-left:auto">~/code/hanko</span></div><div class="code">${['<span class="c">// one engine, every design</span>', '<span class="k1">export const</span> DESIGNS = {', '  margin: { surface: <span class="s">"paper"</span>, arrive: <span class="s">"fold"</span>, … },', '  leaf:   { surface: <span class="s">"card"</span>,  arrive: <span class="s">"slip"</span>, … },', '  shoji:  { surface: <span class="s">"washi"</span>, arrive: <span class="s">"slide"</span>, … },', '}', '', '<span class="k1">resolve</span>({ design: <span class="s">"shoji"</span>,', '          borrow: { slider: <span class="s">"ruler"</span> } })'].join('\n')}</div></div>`}
    ${bar(st, o.data || DATA)}`;
  wallpaper(el.querySelector('canvas'), v, o.seed || 5);
  placeMark(el, st);
  if (o.hover) pointAt(el, st, el.querySelector(o.hover));
  if (o.panel) openPanel(el, st, o.panel, o.data || DATA, true);
  return v;
}
export function placeMark(el, st) {
  const ws = el.querySelector('.ws.on'), m = el.querySelector('.dmark'); if (!ws || !m) return;
  m.style.transform = `translateX(${ws.offsetLeft + (st.select === 'wash' ? 4 : 0)}px)`;
  m.innerHTML = st.select === 'wash' ? brush(16, 4, 6) : '';
  m.style.width = st.select === 'wash' ? '22px' : '27px';
}
export function pointAt(el, st, target, tip = true) {
  el.querySelectorAll('.ptr').forEach(p => p.remove()); if (!target) return;
  const sr = el.getBoundingClientRect(), r = target.getBoundingClientRect(), p = document.createElement('div'), x = r.left - sr.left, w = r.width;
  p.className = 'ptr on ' + st.pointer;
  if (st.pointer === 'thread') Object.assign(p.style, { left: x + 6 + 'px', width: w - 12 + 'px', top: 'calc(var(--bar) - 2px)' });
  else if (st.pointer === 'crop') { Object.assign(p.style, { left: x + 2 + 'px', width: w - 4 + 'px', top: '5px', height: 'calc(var(--bar) - 10px)' }); p.innerHTML = `<i></i><i></i><i></i><i></i>${tip ? '' : '<!--'}<span class="tip">${target.dataset.panel ? { sound: 'Sound', power: 'Battery', net: 'Wi-Fi · Kumo', time: 'Calendar', inbox: 'Letters' }[target.dataset.panel] : ''}</span>${tip ? '' : '-->'}`; }
  else { const bw = Math.min(40, w - 10); Object.assign(p.style, { left: x + (w - bw) / 2 + 'px', width: bw + 'px', top: 'calc(var(--bar) - 11px)' }); p.innerHTML = brush(bw - 6, 4, 9, 'var(--ink3)'); }
  el.appendChild(p);
}
export function openPanel(el, st, key, d = DATA, instant = false) {
  const p = PANELS[key]; if (!p) return;
  const sr = el.getBoundingClientRect(), a = el.querySelector(p.anchor), r = a.getBoundingClientRect(), cx = r.left + r.width / 2 - sr.left;
  const total = p.w + (st.sign === 'tategaki' ? 52 : 0), left = Math.max(12, Math.min(sr.width - total - 12, cx - total / 2));
  let pn = el.querySelector('.panel');
  const travels = pn && st.arrive === 'slide';                  // one shōji, one rail: the same panel moves
  if (pn && !travels) pn.remove(), pn = null;
  if (!pn) { pn = document.createElement('div'); pn.className = 'panel surf'; el.appendChild(pn); pn.style.setProperty('--from', (cx > sr.width / 2 ? 48 : -48) + 'px'); }
  pn.style.left = left + 'px'; pn.style.width = total + 'px'; pn.innerHTML = panelHTML(st, key, d); pn.dataset.key = key;
  el.querySelectorAll('.item.open').forEach(x => x.classList.remove('open')); a.classList.add('open');
  if (instant || travels) pn.classList.add('open'); else requestAnimationFrame(() => requestAnimationFrame(() => pn.classList.add('open')));
  pointAt(el, st, a, false);
  return pn;
}
export function closePanel(el) { const pn = el.querySelector('.panel'); if (!pn) return; pn.classList.remove('open'); el.querySelectorAll('.item.open').forEach(x => x.classList.remove('open')); el.querySelectorAll('.ptr').forEach(p => p.remove()); setTimeout(() => pn.remove(), 260); }

// ── settings · Design: one choice, then borrow what you like ────────────
export function swatch(part, variant) {
  const st = resolve({ design: PARTS[part].v[variant][1] in DESIGNS ? PARTS[part].v[variant][1] : 'margin', borrow: { [part]: variant } });
  switch (part) {
    case 'surface': return `<i style="width:46px;height:28px;display:block;${variant === 'paper' ? 'border:1px solid var(--line);border-radius:7px;box-shadow:0 8px 14px -8px rgba(0,0,0,.6)' : variant === 'card' ? 'background:var(--paper) var(--grain);box-shadow:inset 0 1px 0 var(--cut),inset 0 -1px 0 var(--edge),0 2px 0 var(--shade),2px 4px 0 var(--shade2)' : 'border:1px solid var(--ink4);background:var(--washi),linear-gradient(180deg,color-mix(in srgb,var(--ink) 9%,transparent),transparent)'}"></i>`;
    case 'arrive': return `<svg width="64" height="30" viewBox="0 0 64 30">${variant === 'fold' ? '<path d="M2 3H62" stroke="var(--ink3)"/><path d="M18 3v18q0 6 6 6h16q6 0 6-6V3" fill="none" stroke="var(--ink)" stroke-width="1.3"/><path d="M28 14l4 4 4-4" stroke="var(--ink3)" fill="none"/>' : variant === 'slip' ? '<path d="M2 3H62" stroke="var(--ink)" stroke-width="2"/><rect x="18" y="5" width="28" height="20" fill="none" stroke="var(--ink)" stroke-width="1.3"/><path d="M22 25h6v3h-6z" fill="var(--ink3)"/><path d="M32 9v8M29 14l3 3 3-3" stroke="var(--ink3)" fill="none"/>' : '<path d="M2 3H62" stroke="var(--ink3)"/><rect x="26" y="7" width="26" height="20" fill="none" stroke="var(--ink)" stroke-width="1.3"/><rect x="10" y="7" width="26" height="20" fill="none" stroke="var(--ink4)" stroke-dasharray="2 2"/><path d="M14 17h8M19 14l3 3-3 3" stroke="var(--ink3)" fill="none"/>'}</svg>`;
    case 'pointer': return variant === 'thread' ? `<span style="position:relative;font-size:12px;color:var(--ink);padding-bottom:6px">62<i style="position:absolute;left:-4px;right:-4px;bottom:0;height:2px;background:var(--ink);border-radius:2px"></i></span>` : variant === 'crop' ? `<span class="ptr crop on" style="position:relative;opacity:1;padding:4px 7px;font-size:12px;color:var(--ink)"><i></i><i></i><i></i><i></i>62</span>` : `<span style="display:flex;flex-direction:column;align-items:center;font-size:12px;color:var(--ink);gap:2px">62${brush(20, 4, 9, 'var(--ink3)')}</span>`;
    case 'select': return `<span style="position:relative;width:76px;height:22px;display:flex;align-items:center;padding-left:8px;font-size:11px;${variant === 'tint' ? 'background:color-mix(in srgb,var(--ink) 9%,transparent);border-radius:6px;color:var(--ink)' : variant === 'plate' ? 'background:var(--ink);color:var(--paper)' : 'background:radial-gradient(120% 140% at 12% 50%,color-mix(in srgb,var(--ink) 14%,transparent),transparent 80%);color:var(--ink);box-shadow:inset 2px 0 0 var(--ink)'}">Monitors</span>`;
    case 'slider': return slider(st, 62, 70, { thin: true, seed: 4 });
    case 'ring': return `<span style="display:flex;gap:6px;align-items:center;font-size:12px;color:var(--ink)">${ring({ ...st, ring: variant }, 64, 17)}64</span>`;
    case 'seal': return `<span style="display:flex;gap:6px">${seal({ ...st, seal: variant }, '印', false, 22)}${seal({ ...st, seal: variant }, '印', true, 22)}</span>`;
    case 'unread': return `<span style="position:relative;width:62px;height:28px;border:1px solid var(--line);display:block;border-radius:${st.corner === 'cut' ? 0 : 6}px">${variant === 'edge' ? '<i style="position:absolute;left:-1px;top:7px;width:3px;height:12px;background:var(--red)"></i>' : variant === 'dogear' ? '<i style="position:absolute;right:0;top:0;border-top:10px solid var(--red);border-left:10px solid transparent"></i>' : `<span style="position:absolute;right:4px;top:4px">${seal({ ...st, seal: 'carved' }, '未', true, 15)}</span>`}</span>`;
    case 'sign': return variant === 'eyebrow' ? `<span style="font-size:11px;color:var(--ink2);display:flex;gap:5px;align-items:center">${icon('speaker')}Sound</span>` : variant === 'tabs' ? `<span style="display:flex;gap:2px;font-size:10px"><i style="font-style:normal;padding:3px 5px;border:1px solid var(--line);border-top:0;color:var(--ink3)">Time</i><i style="font-style:normal;padding:3px 5px;background:var(--ink);color:var(--paper)">Sound</i></span>` : `<span style="display:flex;gap:4px;align-items:center"><span class="jp" style="writing-mode:vertical-rl;font-size:15px;color:var(--ink)">音</span><span style="writing-mode:vertical-rl;font-size:9.5px;color:var(--ink3)">Sound</span></span>`;
    default: return '';
  }
}
export function settingsPage(el, st, doc) {
  const w = document.createElement('div'); w.className = 'setw surf';
  const nav = [['brush', 'Design', 1], ['bar', 'Bar'], ['panel', 'Panels'], ['bell', 'Letters'], ['key', 'Keys'], ['info', 'About']];
  const mains = Object.keys(PARTS).filter(k => PARTS[k].main);
  w.innerHTML = `<aside class="side"><div class="brand">${seal(st, '印', true, 26)}Hanko</div>${nav.map(n => `<div class="nav${n[2] ? ' on' : ''}">${icon(n[0])}${n[1]}</div>`).join('')}</aside>
  <main class="page"><h1>Design</h1><div class="lede">Pick a design. Then, if you like, borrow any part from another one.</div>
    <div class="designs">${Object.entries(DESIGNS).map(([k, D]) => `<div class="dc${st.design === k ? ' on' : ''}" data-d="${k}"><div class="pv"></div><div class="meta"><div><b>${D.name}</b><span>${D.blurb}</span></div></div></div>`).join('')}<div class="dc" data-d="classic"><div class="pv" style="display:grid;place-items:center;color:var(--ink3);font-size:12px">today’s Typeset bar</div><div class="meta"><div><b>Classic</b><span>Sheet, Scroll, Typeset presets</span></div></div></div></div>
    <div class="borrow"><div class="bt"><b>Borrow</b>each row shows one part as each design draws it · partners (corners, dividers, tempo) follow on their own</div>
      ${mains.map(k => `<div class="brow"><div class="nm">${PARTS[k].name}<span>${PARTS[k].note}</span></div>${['margin', 'leaf', 'shoji'].map(dn => { const variant = Object.keys(PARTS[k].v).find(x => PARTS[k].v[x][1] === dn); return variant ? `<div class="sw${st[k] === variant ? ' on' : ''}">${swatch(k, variant)}<span class="by">${DESIGNS[dn].name}</span></div>` : `<div class="sw" style="border-style:dashed;font-size:11px;color:var(--ink3)">same as Margin<span class="by">${DESIGNS[dn].name}</span></div>`; }).join('')}</div>`).join('')}
    </div>
    <div class="mixline">${icon('brush')}<span>Your bar: <b>${describe(st)}</b></span><span class="sp"></span>
      <span class="touch">Season <span class="switch${st.touches.season !== 'off' ? ' on' : ''}"></span></span><span class="touch">Kanji numerals <span class="switch${st.touches.numerals === 'kanji' ? ' on' : ''}"></span></span>
      <span class="btn">${icon('shuffle')}&nbsp;Surprise me</span><span class="btn">Reset to ${DESIGNS[st.design].name}</span></div>
  </main>`;
  el.appendChild(w);
  w.querySelectorAll('.dc[data-d]').forEach(c => { const dn = c.dataset.d; if (!DESIGNS[dn]) return; const pv = c.querySelector('.pv'); const mini = document.createElement('div'); mini.style.cssText = 'position:absolute;left:0;top:0;width:900px;height:270px;transform:scale(.3);transform-origin:0 0'; pv.appendChild(mini); desk(mini, resolve({ design: dn }), { windows: false, theme: el.dataset.theme || 'hanko', panel: 'sound' }); });
}
export function params() { const q = new URLSearchParams(location.search), o = {}; for (const [k, v] of q) o[k] = v; return o; }
export function docFromParams(o) {
  const doc = { design: o.design || 'margin', borrow: {}, touches: {} };
  for (const k of Object.keys(PARTS)) if (o[k]) doc.borrow[k] = o[k];
  for (const k of Object.keys(TOUCHES)) if (o[k]) doc.touches[k] = o[k];
  return doc;
}
export function ready(ms = 200) { document.fonts.ready.then(() => setTimeout(() => document.body.dataset.ready = 1, ms)); }
