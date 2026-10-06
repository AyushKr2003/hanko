// Hanko alpha1 mockup kit.
const THEMES = {
  hanko:        { name: 'Hanko', mode: 'dark', background: '#0a0a09', foreground: '#ddd5c7', red: '#d8452f' },
  'tokyo-night':{ name: 'Tokyo Night', mode: 'dark', background: '#1a1b26', foreground: '#c0caf5', red: '#f7768e' },
  kanagawa:     { name: 'Kanagawa', mode: 'dark', background: '#1f1f28', foreground: '#dcd7ba', red: '#c34043' },
  gruvbox:      { name: 'Gruvbox', mode: 'dark', background: '#282828', foreground: '#ebdbb2', red: '#fb4934' },
  'flexoki-light': { name: 'Flexoki Light', mode: 'light', background: '#FFFCF0', foreground: '#100F0F', red: '#D14D41' },
  'rose-pine':  { name: 'Rosé Pine Dawn', mode: 'light', background: '#faf4ed', foreground: '#575279', red: '#b4637a' },
};
function hex2rgb(h) { h = h.replace('#', ''); return [0, 2, 4].map(i => parseInt(h.substr(i, 2), 16)); }
function rgb2hex(c) { return '#' + c.map(v => Math.round(v).toString(16).padStart(2, '0')).join(''); }
function mix(a, b, t) { const A = hex2rgb(a), B = hex2rgb(b); return rgb2hex(A.map((v, i) => v * t + B[i] * (1 - t))); }
function rgba(h, a) { const c = hex2rgb(h); return `rgba(${c[0]},${c[1]},${c[2]},${a})`; }
function lum(h) { const c = hex2rgb(h).map(v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }); return .2126 * c[0] + .7152 * c[1] + .0722 * c[2]; }
function contrast(a, b) { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05); }
function tier(fg, bg, target) { let t = 1, c = fg; while (t > .2) { const n = mix(fg, bg, t - .01); if (contrast(n, bg) < target) break; t -= .01; c = n; } return c; }
function applyTheme(el, key) {
  const t = THEMES[key], bg = t.background, fg = t.foreground;
  const v = { paper: bg, ink: fg, inkDim: tier(fg, bg, 9), inkMuted: tier(fg, bg, 6.2), inkFaint: tier(fg, bg, 4.6),
    line: rgba(fg, .22), lineSoft: rgba(fg, .10), lineStrong: rgba(fg, .40), bone: fg, onBone: bg, seal: t.red, alert: t.red };
  for (const k in v) el.style.setProperty('--' + k, v[k]);
  return v;
}
document.write(`<svg width="0" height="0" style="position:absolute"><filter id="rough"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="4"/><feDisplacementMap in="SourceGraphic" scale="1.6"/></filter></svg>`);

const KNUM = ['〇', '壱', '弐', '参', '肆', '伍', '陸', '漆', '捌', '玖'];

// layout: list of [x,y,w,h] fractions; f = focused index
function glyph(ws) {
  if (!ws.win || !ws.win.length) return `<span class="lg empty"></span>`;
  const r = ws.win.map((w, i) => `<i class="${ws.on && i === ws.f ? 'f' : ''}" style="left:${w[0] * 100}%;top:${w[1] * 100}%;width:calc(${w[2] * 100}% - 2px);height:calc(${w[3] * 100}% - 2px);margin:1px"></i>`).join('');
  return `<span class="lg ${ws.on ? 'on' : ''} ${ws.big ? 'big' : ''}">${r}${ws.urg ? '<span class="u"></span>' : ''}</span>`;
}
const L = { one: [[0, 0, 1, 1]], two: [[0, 0, .5, 1], [.5, 0, .5, 1]], three: [[0, 0, .5, 1], [.5, 0, .5, .5], [.5, .5, .5, .5]], four: [[0, 0, .5, .5], [.5, 0, .5, .5], [0, .5, .5, .5], [.5, .5, .5, .5]], wide: [[0, 0, .62, 1], [.62, 0, .38, 1]] };

const DEF = {
  ws: [{ win: L.two }, { win: L.one }, { win: L.three, on: true, f: 0 }, { win: L.four, urg: true }, {}],
  active: 3, app: 'Alacritty', title: 'nvim · <b>~/code/hanko/</b>Bar.qml',
  time: '21:44', date: 'Tue 6 Oct',
  media: { song: 'Water Copy', artist: 'Hiroshi Yoshimura', p: .38 },
  st: [{ k: '音', v: '62' }, { k: '網', v: 'Kumo' }, { k: '電', v: '91' }],
  stamps: ['S', 'G', '火'], rodLabel: '',
};

function barHTML(s) {
  const media = s.media ? `<div class="np"><div class="s"><em>${s.media.song}</em> · ${s.media.artist}</div><div class="p"><b style="width:${s.media.p * 100}%"></b></div></div>` : '';
  const st = s.st.map(g => `<span class="g ${g.cls || ''}"><span class="k">${g.k}</span>${g.lbl ? `<span class="lbl">${g.lbl}</span>` : ''}${g.v}</span>`).join('');
  const stamps = s.stamps && s.stamps.length ? `<div class="stamps ${s.fan ? 'fan' : ''}">${s.stamps.map((x, i) => `<span class="st" style="transform:rotate(${[-6, 4, -2, 3][i % 4]}deg)">${x}</span>`).join('')}<span class="n">${String(s.stamps.length).padStart(2, '0')}</span></div>` : `<span class="g" style="font-family:var(--mono);font-size:9px;letter-spacing:1.8px;color:var(--inkFaint)">QUIET</span>`;
  return `<div class="bar ${s.glass ? 'glass' : ''}">
    <div class="l"><span class="seal">${KNUM[s.active]}</span><div class="spaces">${s.ws.map(glyph).join('')}</div>
      <div class="byline"><span class="app">${s.app}</span><span class="tt">${s.title}</span></div></div>
    <div class="c"><span class="clk">${s.time.replace(':', '<span class="sep">:</span>')}</span><span class="dt">${s.date}</span></div>
    <div class="r">${media}<div class="gs">${st}</div>${stamps}</div>
    <div class="rod ${s.rodLive ? 'live' : ''}"><span class="grip"></span>${s.rodLabel ? `<span class="pull">${s.rodLabel}</span>` : ''}</div>
  </div>`;
}
function mountBar(host, s) { host.innerHTML = barHTML(Object.assign({}, DEF, s)); return host.firstElementChild; }

// ---------- noise ----------
function h2(x, y) { let n = Math.sin(x * 127.1 + y * 311.7) * 43758.5453; return n - Math.floor(n); }
function vn(x, y) { const xi = Math.floor(x), yi = Math.floor(y), xf = x - xi, yf = y - yi; const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
  const a = h2(xi, yi), b = h2(xi + 1, yi), c = h2(xi, yi + 1), d = h2(xi + 1, yi + 1); return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v; }
function fbm(x, y, o = 5) { let s = 0, a = .5; for (let i = 0; i < o; i++) { s += a * vn(x, y); x *= 2.03; y *= 2.03; a *= .5; } return s; }
const BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]];

// ---------- wallpaper: a dithered marble orb eclipsing a small red sun ----------
function paintMarble(canvas, theme, o = {}) {
  const t = THEMES[theme]; const W = canvas.width, H = canvas.height, ctx = canvas.getContext('2d');
  const bg = hex2rgb(t.background), fg = hex2rgb(t.foreground), red = hex2rgb(t.red);
  const img = ctx.createImageData(W, H), d = img.data; const cell = o.cell || 2;
  const cx = W * (o.x ?? .66), cy = H * (o.y ?? .54), R = H * (o.r ?? .30);
  const sx = cx + R * (o.sunDX ?? .78), sy = cy - R * (o.sunDY ?? .74), sr = R * (o.sunR ?? .30);
  const lx = -.55, ly = -.62, lz = .56;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const th = (BAYER[Math.floor(y / cell) % 4][Math.floor(x / cell) % 4] + .5) / 16;
    let val = 0, col = fg;
    const dx = (x - cx) / R, dy = (y - cy) / R, rr = dx * dx + dy * dy;
    // the sun sits behind the orb
    if (Math.hypot(x - sx, y - sy) < sr && rr > 1) { val = 1; col = red; }
    else if (rr < 1) {
      const dz = Math.sqrt(1 - rr); let lam = Math.max(0, dx * lx + dy * ly + dz * lz);
      const rim = Math.pow(1 - dz, 3) * .25;
      // marble veins via domain warp on the sphere's surface coords
      const u = dx * 2.2, v = dy * 2.2 + dz * .8;
      const w = fbm(u * .9 + 3, v * .9, 4);
      const w2 = fbm(u * 2.1 + 9, v * 2.1 + 4, 3);
      const vein1 = Math.abs(Math.sin((u * 1.0 + v * .55) * 2.6 + w * 6.0));
      const vein2 = Math.abs(Math.sin((u * .4 - v * 1.0) * 4.1 + w2 * 5.0));
      let m = .12 + .84 * Math.pow(lam, 1.15) + rim;
      if (vein1 < .035) m *= .3; else if (vein1 < .09) m *= .72;
      if (vein2 < .02) m *= .55;
      m += (fbm(u * 7, v * 7, 3) - .5) * .08;
      val = m;
    } else {
      val = 0;
    }
    const on = val > th; const c = on ? col : bg;
    const p = (y * W + x) * 4; d[p] = c[0]; d[p + 1] = c[1]; d[p + 2] = c[2]; d[p + 3] = 255;
  }
  ctx.putImageData(img, 0, 0);
}

// interlude sliver between scroll sections: dithered ink wash
function paintSliver(canvas, theme, seed) {
  const t = THEMES[theme]; const W = canvas.width, H = canvas.height, ctx = canvas.getContext('2d');
  const bg = hex2rgb(t.background), fg = hex2rgb(t.foreground);
  const img = ctx.createImageData(W, H), d = img.data;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const th = (BAYER[y % 4][x % 4] + .5) / 16;
    const n = fbm(x / 26 + seed * 9, y / 60 + seed * 3, 5);
    const band = Math.sin(y / H * Math.PI);
    const edge = 1 - Math.abs(x / W - .5) * 2;
    const val = Math.max(0, (n - .38) * 1.6) * band * Math.pow(edge, .6) * .8;
    const c = val > th ? fg : bg; const p = (y * W + x) * 4; d[p] = c[0]; d[p + 1] = c[1]; d[p + 2] = c[2]; d[p + 3] = 255;
  }
  ctx.putImageData(img, 0, 0);
}

// ---------- emaki sections ----------
function fader(name, v, opt = {}) {
  let sc = ''; for (let i = 0; i <= 10; i++) sc += `<i class="${i % 5 === 0 ? 'm' : ''}"></i>`;
  return `<div class="fd ${opt.master ? 'master' : ''} ${opt.muted ? 'muted' : ''}"><div class="v">${opt.muted ? '—' : v}</div>
    <div class="rail"><div class="scale">${sc}</div><div class="slot"></div><div class="fill" style="height:${v}%"></div><div class="cap2" style="bottom:${v}%"></div></div>
    <div class="nm">${name}</div></div>`;
}
function dbars(n) { return `<span class="dbars">${[5, 8, 11, 14].map((h, i) => `<i class="${i < n ? '' : 'o'}" style="height:${h}px"></i>`).join('')}</span>`; }
const SECTIONS = {
  time: (w) => `<div class="sec" style="width:${w}px"><div class="wm">時</div>
    <div class="no"><span class="jp">時</span>01 // TIME</div><h3>Tuesday, <i style="font-style:italic;color:var(--inkMuted)">the sixth</i></h3>
    <div class="cap">Week 41 · day 279 of 365 · Tokyo 06:44 tomorrow</div>
    <div class="ribbon">${(() => { let h = ''; const dn = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; for (let d = 1; d <= 18; d++) { const k = (d + 2) % 7; h += `<div class="dd ${k >= 5 ? 'we' : ''} ${d < 6 ? 'past' : ''} ${d === 6 ? 't' : ''} ${k === 0 ? 'wk' : ''}"><small>${dn[k]}</small>${String(d).padStart(2, '0')}</div>`; } return h; })()}</div>
    <div class="cap" style="margin-top:12px">October ← drag the ribbon → November</div></div>`,
  sound: (w) => `<div class="sec" style="width:${w}px"><div class="wm">音</div>
    <div class="no"><span class="jp">音</span>02 // SOUND</div><h3>Sound</h3><div class="cap">Studio Monitors · 48 kHz · PipeWire</div>
    <div style="display:flex;gap:34px;align-items:flex-end">
      <div class="faders">${fader('Master', 62, { master: true })}${fader('Spotify', 80)}${fader('Firefox', 45)}${fader('Discord', 30, { muted: true })}${fader('Mic', 70)}</div>
      <div class="lst" style="width:250px;margin-bottom:26px">
        <div class="li on"><span class="ix">01</span>Studio Monitors<span class="m">Live</span></div>
        <div class="li"><span class="ix">02</span>WH-1000XM5<span class="m">BT · 70%</span></div>
        <div class="li"><span class="ix">03</span>Built-in<span class="m">Analog</span></div>
      </div></div></div>`,
  net: (w) => `<div class="sec" style="width:${w}px"><div class="wm">網</div>
    <div class="no"><span class="jp">網</span>03 // NETWORK</div><h3>Kumo-5G</h3><div class="cap">wlan0 · 5 GHz · 866 Mb/s · 192.168.1.24</div>
    <div class="lst">
      <div class="li on"><span class="ix">01</span>Kumo-5G<span class="m">Joined ${dbars(4)}</span></div>
      <div class="li"><span class="ix">02</span>Kumo<span class="m">Saved ${dbars(3)}</span></div>
      <div class="li"><span class="ix">03</span>Café Hiraeth<span class="m">Open ${dbars(2)}</span></div>
      <div class="li"><span class="ix">04</span>DIRECT-7F-Printer<span class="m">WPA2 ${dbars(1)}</span></div></div></div>`,
  power: (w) => `<div class="sec" style="width:${w}px"><div class="wm">電</div>
    <div class="no"><span class="jp">電</span>04 // POWER</div><h3>91<span style="font-size:24px;color:var(--inkMuted)"> %</span></h3><div class="cap">On battery · 6 h 10 m left</div>
    <div class="lst"><div class="li"><span class="ix">01</span>Saver</div><div class="li on"><span class="ix">02</span>Balanced<span class="m">Active</span></div><div class="li"><span class="ix">03</span>Performance</div></div></div>`,
  spaces: (w) => `<div class="sec" style="width:${w}px"><div class="wm">窓</div>
    <div class="no"><span class="jp">窓</span>05 // SPACES</div><h3>Five spaces</h3><div class="cap">Click a window to go there · drag to move it</div>
    <div style="display:flex;gap:14px;margin-top:22px">${[['壱', L.two, ['Firefox', 'Obsidian']], ['弐', L.one, ['Spotify']], ['参', L.three, ['nvim', 'zsh', 'btop'], 1], ['肆', L.four, ['Slack', 'Mail', 'Zoom', 'Files']], ['伍', [], []]].map(([k, ly, names, on]) => `<div style="flex:1"><div style="position:relative;height:96px;border:1px solid ${on ? 'var(--ink)' : 'var(--line)'};border-radius:3px">${ly.map((r, i) => `<div style="position:absolute;left:${r[0] * 100}%;top:${r[1] * 100}%;width:calc(${r[2] * 100}% - 6px);height:calc(${r[3] * 100}% - 6px);margin:3px;border:1px solid var(--line);border-radius:2px;background:${on && i === 0 ? 'var(--bone)' : 'var(--lineSoft)'};color:${on && i === 0 ? 'var(--onBone)' : 'var(--inkDim)'};font-size:10.5px;padding:5px 6px">${names[i]}</div>`).join('')}</div><div class="cap" style="margin-top:8px"><span style="font-family:var(--jps);font-size:13px;color:${on ? 'var(--seal)' : 'var(--inkMuted)'};letter-spacing:0;margin-right:6px">${k}</span>${ly.length ? ly.length + ' WIN' : 'EMPTY'}</div></div>`).join('')}</div></div>`,
  inbox: (w) => `<div class="sec" style="width:${w}px"><div class="wm">報</div>
    <div class="no"><span class="jp">報</span>06 // INBOX</div><h3>Three letters</h3><div class="cap">Stamped by the app that sent them</div>
    <div class="lst">${[['S', 'Slack', 'Mika: the build is green, ship it'], ['G', 'GitHub', 'omacom/omarchy · review requested'], ['火', 'Firefox', 'Download finished · hanko-alpha1.zip']].map(([s, a, m]) => `<div class="li" style="height:52px"><span class="st" style="margin:0;transform:rotate(-3deg)">${s}</span><div><div>${a}</div><div class="d">${m}</div></div><span class="m">2m</span></div>`).join('')}</div></div>`,
};
function emakiHTML(order, widths, active) {
  const idx = [['時', 'TIME'], ['音', 'SOUND'], ['網', 'NETWORK'], ['電', 'POWER'], ['窓', 'SPACES'], ['報', 'INBOX']];
  return `<div class="roller l"></div><div class="roller r"></div><div class="curl l"></div><div class="curl r"></div>
    <div class="idx">${idx.map(([k, n], i) => `<span class="${i === active ? 'on' : ''}"><span class="jp">${k}</span>${String(i + 1).padStart(2, '0')} ${n}</span>`).join('')}</div>
    <div class="view"><div class="track">${order.map((k, i) => SECTIONS[k](widths[i]) + (i < order.length - 1 ? `<div class="inter"><canvas width="70" height="300" data-seed="${i}"></canvas></div>` : '')).join('')}</div></div>
    <div class="foot"><span><span class="kbd">H</span> <span class="kbd">L</span> &nbsp;PAN</span><span class="pos"><b style="left:${active / 6 * 100}%;width:${100 / 6}%"></b></span><span><span class="kbd">ESC</span> &nbsp;ROLL UP</span></div>`;
}
