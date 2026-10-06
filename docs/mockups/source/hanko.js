// Hanko mockup kit: derives the paper-and-ink ramp from an Omarchy colors.toml
// and draws the bar, its day rule and a procedural print wallpaper.

const THEMES = {
  hanko:        { name: 'Hanko (signature)', mode: 'dark', background: '#0a0a09', foreground: '#ddd5c7', red: '#d8452f', accent: '#d8452f' },
  'tokyo-night':{ name: 'Tokyo Night', mode: 'dark', background: '#1a1b26', foreground: '#c0caf5', red: '#f7768e', accent: '#7aa2f7' },
  kanagawa:     { name: 'Kanagawa', mode: 'dark', background: '#1f1f28', foreground: '#dcd7ba', red: '#c34043', accent: '#dcd7ba' },
  'flexoki-light': { name: 'Flexoki Light', mode: 'light', background: '#FFFCF0', foreground: '#100F0F', red: '#D14D41', accent: '#205EA6' },
  gruvbox:      { name: 'Gruvbox', mode: 'dark', background: '#282828', foreground: '#ebdbb2', red: '#fb4934', accent: '#d79921' },
  'rose-pine':  { name: 'Rosé Pine Dawn', mode: 'light', background: '#faf4ed', foreground: '#575279', red: '#b4637a', accent: '#56949f' },
};

function hex2rgb(h) { h = h.replace('#', ''); return [0, 2, 4].map(i => parseInt(h.substr(i, 2), 16)); }
function rgb2hex(c) { return '#' + c.map(v => Math.round(v).toString(16).padStart(2, '0')).join(''); }
function mix(a, b, t) { const A = hex2rgb(a), B = hex2rgb(b); return rgb2hex(A.map((v, i) => v * t + B[i] * (1 - t))); }
function rgba(h, a) { const c = hex2rgb(h); return `rgba(${c[0]},${c[1]},${c[2]},${a})`; }
function lum(h) { const c = hex2rgb(h).map(v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }); return .2126 * c[0] + .7152 * c[1] + .0722 * c[2]; }
function contrast(a, b) { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05); }
// Walk the ink toward the paper until it lands just above a target contrast.
function tier(fg, bg, target) { let t = 1; let c = fg; while (t > 0.2) { const n = mix(fg, bg, t - 0.01); if (contrast(n, bg) < target) break; t -= 0.01; c = n; } return c; }

function applyTheme(el, key) {
  const t = THEMES[key]; const bg = t.background, fg = t.foreground;
  const lift = t.mode === 'dark' ? mix(fg, bg, .05) : mix(fg, bg, .04);
  const v = {
    paper: bg, paperLift: lift, ink: fg,
    inkDim: tier(fg, bg, 9), inkMuted: tier(fg, bg, 6.2), inkFaint: tier(fg, bg, 4.6),
    line: rgba(fg, .24), lineSoft: rgba(fg, .12), lineStrong: rgba(fg, .42),
    bone: fg, onBone: bg, seal: t.red, alert: t.red,
  };
  for (const k in v) el.style.setProperty('--' + k, v[k]);
  el.dataset.theme = key;
  return v;
}

const ICON = {
  bt: '<svg viewBox="0 0 16 16"><path d="M4.5 5l7 6-3.5 3V2l3.5 3-7 6"/></svg>',
  shot: '<svg viewBox="0 0 16 16"><rect x="2" y="4" width="12" height="9" rx="1"/><circle cx="8" cy="8.5" r="2.3"/><path d="M6 4l1-1.5h2L10 4"/></svg>',
  cloud: '<svg viewBox="0 0 16 16"><path d="M4.5 12.5h7a2.8 2.8 0 0 0 .4-5.6A4 4 0 0 0 4.2 7.6 2.5 2.5 0 0 0 4.5 12.5z"/></svg>',
};

function ticks(n, on, low) {
  let s = `<span class="ticks${low ? ' low' : ''}">`;
  for (let i = 0; i < n; i++) s += `<i class="${i < on ? '' : 'off'}${i % 5 === 4 ? '' : ''}"></i>`;
  return s + '</span>';
}
function sig(n) { let s = '<span class="sig">'; [4, 6, 8, 10].forEach((h, i) => s += `<i class="${i < n ? '' : 'off'}" style="height:${h}px"></i>`); return s + '</span>'; }

// state: { ws:[{n,state:'on'|'occ'|'',win,urg}], app, title, time:'21:44', day, date, media, net, vol, bat, open, hover, battery low ... }
function barHTML(s) {
  const ws = s.ws.map(w => {
    const dots = w.win ? `<span class="dots">${'<i></i>'.repeat(w.win)}</span>` : '';
    const lead = w.state === 'on' ? '<span class="lead">//</span>' : '';
    return `<span class="ws ${w.state}">${lead}${String(w.n).padStart(2, '0')}${dots}${w.urg ? '<span class="urg"></span>' : ''}</span>`;
  }).join('');
  const cls = id => (s.open === id ? ' open' : '') + (s.hover === id ? ' hover' : '');
  const media = s.media ? `
    <div class="cell${cls('media')}" data-id="media"><div class="lab">Now <span class="jp">再生</span></div>
      <div class="val">${s.media}</div></div><div class="rule"></div>` : '';
  const rec = s.rec ? `<div class="cell" data-id="rec"><div class="lab" style="color:var(--alert)">● Rec <span class="jp">録画</span></div><div class="val">${s.rec}<span class="unit">MIN</span></div></div><div class="rule"></div>` : '';
  return `
  <div class="bar ${s.transparent ? 'transparent' : ''}">
    <div class="sec left">
      <div class="seal" data-id="seal"><div class="stamp">${s.sealGlyph || '印'}</div></div>
      <div class="rule full"></div>
      <div class="folio" data-id="ws">${ws}</div>
      <div class="rule"></div>
      <div class="cell title" data-id="title"><div class="lab">${s.app} <span class="jp">窓</span></div><div class="val">${s.title}</div></div>
    </div>
    <div class="sec center">
      <div class="clock${cls('clock')}" data-id="clock"><span class="t">${s.time.replace(':', '<span class="c">:</span>')}</span>
        <span class="d"><b>${s.day}</b><span>${s.date}</span></span></div>
    </div>
    <div class="sec right">
      ${rec}${media}
      <div class="cell${cls('net')}" data-id="net"><div class="lab">Net <span class="jp">接続</span></div><div class="val">${s.net}${sig(s.sigN ?? 3)}</div></div>
      <div class="rule"></div>
      <div class="cell${cls('vol')}" data-id="vol"><div class="lab">Vol <span class="jp">音</span></div><div class="val">${s.vol}<span class="unit">%</span>${ticks(10, Math.round(s.vol / 10))}</div></div>
      <div class="rule"></div>
      <div class="cell${cls('bat')}" data-id="bat"><div class="lab">${s.charging ? 'Bat · AC' : 'Bat'} <span class="jp">電</span></div><div class="val">${s.bat}<span class="unit">%</span>${ticks(10, Math.round(s.bat / 10), s.bat <= 15)}</div></div>
      <div class="rule"></div>
      <div class="tray" data-id="tray">${ICON.bt}${ICON.shot}${ICON.cloud}</div>
      <div class="rule full"></div>
      <div class="cell${cls('notif')}" data-id="notif" style="padding:0 14px 2px;align-items:center">
        <div class="lab">Inbox</div><div class="val" style="font-family:var(--mono);font-size:12px">${String(s.notif ?? 0).padStart(2, '0')}${s.notif ? '<span style="width:5px;height:5px;border-radius:50%;background:var(--alert);display:inline-block;margin-left:-3px;position:relative;top:-5px"></span>' : ''}</div></div>
    </div>
    <div class="dayrule" data-id="rule"></div>
  </div>`;
}

function drawDayRule(bar, frac, labels) {
  const r = bar.querySelector('.dayrule');
  let h = `<div class="base"></div><div class="elapsed" style="width:${frac * 100}%"></div>`;
  for (let i = 1; i < 24; i++) h += `<div class="tk${i % 6 === 0 ? ' maj' : ''}" style="left:${i / 24 * 100}%"></div>`;
  if (labels) for (let i = 0; i <= 24; i += 3) h += `<div class="lbl" style="left:${Math.min(Math.max(i / 24 * 100, 0.8), 99.2)}%">${String(i).padStart(2, '0')}</div>`;
  h += `<div class="now" style="left:${frac * 100}%"></div>`;
  r.innerHTML = h;
}

function mountBar(host, state, opts = {}) {
  host.innerHTML = barHTML(state);
  const bar = host.querySelector('.bar');
  const [hh, mm] = state.time.split(':').map(Number);
  drawDayRule(bar, (hh * 60 + mm) / 1440, opts.labels);
  return bar;
}

const DEFAULT_STATE = {
  ws: [{ n: 1, state: 'occ', win: 2 }, { n: 2, state: 'occ', win: 1 }, { n: 3, state: 'on' }, { n: 4, state: 'occ', win: 3, urg: true }, { n: 5, state: '' }],
  app: 'Alacritty', title: 'nvim <span class="dim">~/code/hanko/</span>Bar.qml',
  time: '21:44', day: 'TUE', date: '06 OCT',
  media: 'Hiroshi Yoshimura <span class="dim">— Water Copy</span>',
  net: 'Kumo-5G', vol: 62, bat: 91, notif: 3,
};

// ---------- procedural print wallpaper: dithered sun over ink ridges ----------
function paintWallpaper(canvas, theme, opt = {}) {
  const t = THEMES[theme];
  const W = canvas.width, H = canvas.height, ctx = canvas.getContext('2d');
  const bg = hex2rgb(t.background), fg = hex2rgb(t.foreground), red = hex2rgb(opt.sun || t.red);
  const img = ctx.createImageData(W, H); const d = img.data;
  const B = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]];
  const cell = opt.cell || 3;
  // value noise
  function hash(x) { x = Math.sin(x * 127.1) * 43758.5453; return x - Math.floor(x); }
  function noise(x) { const i = Math.floor(x), f = x - i, u = f * f * (3 - 2 * f); return hash(i) * (1 - u) + hash(i + 1) * u; }
  function fbm(x, s) { let v = 0, a = .5, fr = 1; for (let o = 0; o < 4; o++) { v += a * noise(x * fr + s * 17.3); a *= .42; fr *= 2.3; } return v; }
  const sx = W * (opt.sunX ?? .68), sy = H * (opt.sunY ?? .40), sr = H * (opt.sunR ?? .25);
  const ridges = [
    { base: .66, amp: .14, f: 1.6 / W, s: 1, ink: .06 },
    { base: .76, amp: .11, f: 2.4 / W, s: 2, ink: .12 },
    { base: .86, amp: .08, f: 3.4 / W, s: 3, ink: .035 },
    { base: .95, amp: .05, f: 4.6 / W, s: 4, ink: .18 },
  ];
  const heights = ridges.map(r => { const a = new Float32Array(W); for (let x = 0; x < W; x++) a[x] = H * (r.base - r.amp * fbm(x * r.f * 3, r.s)); return a; });
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const th = (B[Math.floor(y / cell) % 4][Math.floor(x / cell) % 4] + .5) / 16;
    let col = bg;
    // sun: radial density with a soft dithered falloff
    const dist = Math.hypot(x - sx, y - sy) / sr;
    let sun = dist < 1 ? 1 : Math.max(0, 1 - (dist - 1) * 3.2) * .55;
    if (dist < 1) sun = .92 - .25 * Math.pow(dist, 3) + .06 * Math.sin(y / sr * 18); // banded plate
    if (sun > th) col = red;
    // haze lines across the sun (cut by paper)
    for (let i = 0; i < ridges.length; i++) {
      if (y >= heights[i][x]) {
        const depth = (y - heights[i][x]) / (H * .25);
        const dens = ridges[i].ink * Math.max(0, 1 - depth * 1.4) + 0.012;
        col = dens > th ? fg : bg;
        // contour hairline at the crest
        if (y - heights[i][x] < 1.6) col = fg;
      }
    }
    const p = (y * W + x) * 4; d[p] = col[0]; d[p + 1] = col[1]; d[p + 2] = col[2]; d[p + 3] = 255;
  }
  ctx.putImageData(img, 0, 0);
}
