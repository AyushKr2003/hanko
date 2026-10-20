// Densho 伝書 mockup kit: the handscroll drawn as a transmission scroll.
// Needs ../../kaze/source/kaze.js (rng, bar) loaded first.

// The scroll in a licence scroll's order: the house, the techniques, the seal.
const SECTIONS = [
  { jp: '序', no: '00', label: 'Opening', poem: 'The house' },
  { jp: '時', no: '01', label: 'Time', poem: 'Keeping the hour' },
  { jp: '音', no: '02', label: 'Sound', poem: 'Listening' },
  { jp: '網', no: '03', label: 'Network', poem: 'Casting the net' },
  { jp: '藍', no: '04', label: 'Bluetooth', poem: 'The indigo thread' },
  { jp: '電', no: '05', label: 'Power', poem: 'Held breath' },
  { jp: '明', no: '06', label: 'Display', poem: 'The lantern' },
  { jp: '窓', no: '07', label: 'Spaces', poem: 'Five rooms' },
  { jp: '報', no: '08', label: 'Inbox', poem: 'Letters' },
  { jp: '奥', no: '09', label: 'Colophon', poem: 'Signed and sealed' },
]
const SPINE_W = [0, 98, 70, 50]
let uid = 0

const clamp01 = v => Math.max(0, Math.min(1, v))

// A title written by the brush: `write` 0..1 is how far the stroke has
// travelled (a dry-brush edge leads it), `dry` 0..1 thins the ink at speed.
function title(text, o = {}) {
  const id = ++uid, write = o.write ?? 1, dry = o.dry ?? 0
  const size = o.size ?? 66, w = o.width ?? 1000, tw = o.tw ?? text.replace(/<[^>]+>/g, '').length * size * 0.5
  const wght = Math.round(400 - 240 * dry)
  const col = o.color ?? 'var(--ink)'
  const style = `font-family:Fraunces;font-size:${size}px;font-variation-settings:'wght' ${wght},'opsz' 72;letter-spacing:${(-0.8 + dry * 2.2).toFixed(1)}px;fill:${col};opacity:${(1 - 0.38 * dry).toFixed(2)}`
  const body = text.replace(/<i>(.*?)<\/i>/g, '<tspan font-style="italic">$1</tspan>')
  if (write >= 0.7) return `<svg width="${w}" height="80"><text x="0" y="62" style="${style}">${body}</text></svg>`
  const r = rng(id * 7 + 3), edge = clamp01(write / 0.7) * (tw + 30)
  let streaks = ''
  // the dry hairs at the head of the stroke: a few thin trails, not a block
  for (let k = 0; k < 7; k++) {
    const y = size * 0.2 + r() * size * 0.7, len = 10 + r() * size * 0.5, x = edge - len * 0.6
    streaks += `<path d="M${x.toFixed(1)},${y.toFixed(1)} q${(len / 2).toFixed(1)},${((r() - .5) * 3).toFixed(1)} ${len.toFixed(1)},${((r() - .5) * 4).toFixed(1)}" stroke="${col}" stroke-width="${(0.6 + r() * 0.9).toFixed(1)}" fill="none" stroke-linecap="round" opacity="${(0.2 + r() * 0.4).toFixed(2)}"/>`
  }
  return `<svg width="${w}" height="80"><defs>
    <filter id="kz${id}" x="-10%" y="-5%" width="125%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="0.03 0.22" numOctaves="3" seed="${id}"/><feDisplacementMap in="SourceGraphic" scale="${Math.round(size * 0.5)}" xChannelSelector="R" yChannelSelector="R"/></filter>
    <mask id="mk${id}"><rect x="-200" y="-400" width="${edge + 170}" height="1000" fill="#fff" filter="url(#kz${id})"/></mask></defs>
    <text x="0" y="62" mask="url(#mk${id})" style="${style}">${body}</text>${streaks}</svg>`
}

// A red seal, pressed. `rough` gives it a worn impression.
function seal(glyph, size = 120, o = {}) {
  const rot = o.rot ?? -3
  return `<div style="width:${size}px;height:${size}px;background:var(--seal);border-radius:${size * 0.06}px;display:grid;place-items:center;transform:rotate(${rot}deg);filter:url(#worn);position:relative;${o.style ?? ''}">
    <div style="position:absolute;inset:${size * 0.06}px;border:${Math.max(1, size * 0.018)}px solid color-mix(in srgb, var(--paper) 55%, transparent);border-radius:${size * 0.04}px"></div>
    <span style="font-family:var(--jps);font-weight:700;font-size:${size * 0.56}px;color:var(--paper);line-height:1">${glyph}</span></div>`
}

function sig(n) { return `<span class="sig">${[4, 6, 9, 12].map((h, i) => `<i class="${i < n ? 'f' : ''}" style="height:${h}px"></i>`).join('')}</span>` }

// How each row appears as the brush passes: the head first, rows after.
function arrive(o, i) { const w = o.write ?? 1; return w >= 1 ? 1 : clamp01((w - 0.62 - i * 0.07) / 0.12) }
function inkOf(o, i) { return (arrive(o, i) * (1 - 0.45 * (o.dry ?? 0))).toFixed(2) }

// ----------------------------------------------------------------- sections
const BODIES = {
  0: o => ({
    title: 'The house of <i>shadow</i>', caption: 'Hanko · Kamon preset · this desk since 3 March',
    body: `<div style="display:flex;gap:70px;align-items:flex-end;margin-top:34px">
      <div style="flex:1;opacity:${inkOf(o, 0)}">${lineage()}</div>
      <div style="opacity:${inkOf(o, 1)}">${seal('鑑', 128, { rot: -2 })}</div></div>`,
  }),
  1: o => ({
    title: 'Wednesday, <i>the fourteenth</i>', caption: 'Week 42 · day 288 of 366 · Tokyo 06:44 tomorrow',
    body: `<div style="margin-top:34px;opacity:${inkOf(o, 0)}">${hours()}</div>`,
  }),
  2: o => ({
    title: 'Sound', caption: 'Studio monitors · USB · Focusrite 2i2 · 48 kHz',
    body: `<div style="display:flex;gap:80px;margin-top:30px">
      <div class="faders" style="opacity:${inkOf(o, 0)}">${[['62', 'Master', .62], ['80', 'Spotify', .8], ['45', 'Firefox', .45], ['—', 'Discord', 0], ['0', 'Mic', 0, 1]].map(([v, n, l, m]) =>
        `<div class="fd${m ? ' mute' : ''}"><div class="v">${v}</div><div class="tr"><b style="height:${l * 150}px"></b><u style="bottom:${l * 150 - 3}px"></u></div><div class="n">${n}</div></div>`).join('')}</div>
      <div style="width:430px">
        <div class="colh" style="opacity:${inkOf(o, 1)}">Output</div>
        <div class="rows">
          <div class="row on" style="opacity:${inkOf(o, 1)}"><span class="ix">01</span><span>Studio monitors</span><span class="nt">USB</span></div>
          <div class="row" style="opacity:${inkOf(o, 2)}"><span class="ix">02</span><span>WH-1000XM5</span><span class="nt">BT</span></div>
          <div class="row" style="opacity:${inkOf(o, 3)}"><span class="ix">03</span><span>Built-in</span><span class="nt">Analog</span></div>
        </div></div></div>`,
  }),
  3: o => o.offline ? {
    title: 'Offline', color: 'var(--seal)', caption: 'No network · last joined Kumo at 21:31 · looking…',
    body: `<div style="display:flex;gap:80px;margin-top:34px">
      <div class="rows" style="width:560px">${[['Kumo', 'Saved', 0], ['Kumo 2.4', 'Saved', 0], ['Neighbour', 'WPA', 0], ['Library', 'Open', 0]].map(([n, t], i) =>
        `<div class="row" style="opacity:${(.42 * arrive(o, i)).toFixed(2)}"><span class="ix">0${i + 1}</span><span>${n}</span><span class="nt">${t}${sig(0)}</span></div>`).join('')}</div>
      <div style="width:330px;opacity:${inkOf(o, 2)}"><div class="colh">Try</div>
        <div class="rows"><div class="row on"><span class="ix">R</span><span>Rescan</span><span class="nt">now</span></div>
        <div class="row"><span class="ix">W</span><span>Wi-Fi off and on</span><span class="nt"></span></div></div></div></div>`,
  } : {
    title: 'Kumo', caption: 'Wi-Fi · WPA2 · 5 GHz · 82% · 866 Mb/s',
    body: `<div style="display:flex;gap:80px;margin-top:34px">
      <div class="rows" style="width:560px">${[['Kumo', 'Joined', 4, 1], ['Kumo 2.4', 'Saved', 3], ['Neighbour', 'WPA', 2], ['Library', 'Open', 1]].map(([n, t, s, on], i) =>
        `<div class="row${on ? ' on' : ''}" style="opacity:${inkOf(o, i)}"><span class="ix">0${i + 1}</span><span>${n}</span><span class="nt">${t}${sig(s)}</span></div>`).join('')}</div>
      <div style="width:330px;opacity:${inkOf(o, 2)}"><div class="colh">This network</div>${kv([['Address', '192.168.1.24'], ['Gateway', '192.168.1.1'], ['DNS', '1.1.1.1']])}</div></div>`,
  },
  4: o => ({
    title: 'WH-1000XM5', caption: 'Headphones · connected · battery 80%',
    body: `<div style="display:flex;gap:80px;margin-top:34px">
      <div class="rows" style="width:560px">${[['WH-1000XM5', 'Connected', 1], ['MX Keys', 'Paired'], ['MX Master 3S', 'Paired'], ['Pixel 9', 'Phone']].map(([n, t, on], i) =>
        `<div class="row${on ? ' on' : ''}" style="opacity:${inkOf(o, i)}"><span class="ix">0${i + 1}</span><span>${n}</span><span class="nt">${t}</span></div>`).join('')}</div>
      <div style="width:330px;opacity:${inkOf(o, 2)}"><div class="colh">Nearby</div>${kv([['Looking', '…'], ['Power', 'On']])}</div></div>`,
  }),
  6: o => ({
    title: '70 %', caption: 'Built-in · 2880×1800 · 120 Hz · night light at 21:00',
    body: `<div style="display:flex;gap:80px;margin-top:30px">
      <div class="faders" style="opacity:${inkOf(o, 0)}">${[['70', 'Light', .7], ['off', 'Night', 0]].map(([v, n, l]) =>
        `<div class="fd"><div class="v">${v}</div><div class="tr"><b style="height:${l * 150}px"></b><u style="bottom:${l * 150 - 3}px"></u></div><div class="n">${n}</div></div>`).join('')}</div>
      <div class="rows" style="width:500px">${[['Built-in', '2880×1800', 1], ['DP-2', '2560×1440'], ['HDMI-A-1', 'Off']].map(([n, t, on], i) =>
        `<div class="row${on ? ' on' : ''}" style="opacity:${inkOf(o, i + 1)}"><span class="ix">0${i + 1}</span><span>${n}</span><span class="nt">${t}</span></div>`).join('')}</div></div>`,
  }),
  7: o => ({
    title: 'Five rooms', caption: 'Click a window to go there',
    body: `<div style="display:flex;gap:18px;margin-top:34px">${[['壱', ['Firefox', 'Obsidian']], ['弐', ['Alacritty']], ['参', ['Spotify', 'Discord'], 1], ['肆', ['Zoom']], ['伍', []]].map(([k, ws, on], i) =>
      `<div style="width:170px;height:150px;border:1px solid ${on ? 'var(--ink)' : 'var(--line)'};border-radius:3px;padding:12px;opacity:${inkOf(o, i)}"><div style="font:18px var(--jps);color:${on ? 'var(--ink)' : 'var(--inkMuted)'}">${k}</div>${ws.map(w => `<div style="font-size:14px;color:var(--inkDim);margin-top:8px">${w}</div>`).join('') || '<div class="t0" style="margin-top:10px">Empty</div>'}</div>`).join('')}</div>`,
  }),
  5: o => ({
    title: '91 %', caption: '2 h 40 min left · discharging · 9.8 W',
    body: `<div class="rows" style="width:560px;margin-top:34px">${[['Performance', ''], ['Balanced', 'In use', 1], ['Power saver', '']].map(([n, t, on], i) =>
      `<div class="row${on ? ' on' : ''}" style="opacity:${inkOf(o, i)}"><span class="ix">0${i + 1}</span><span>${n}</span><span class="nt">${t}</span></div>`).join('')}</div>`,
  }),
  8: o => ({
    title: 'Four letters', caption: 'Stamped by the app that sent them · warm one to read it',
    body: `<div style="margin-top:28px;width:${(o.fw ?? 1100) - 80}px">${LETTERS.map((l, i) => letter(l, i, o)).join('')}</div>`,
  }),
  9: o => ({
    title: 'Signed and sealed', caption: 'Roll up to close the scroll',
    body: `<div style="display:flex;gap:90px;align-items:center;margin-top:30px">
      <div style="font:italic 26px/1.55 var(--display);color:var(--inkDim);opacity:${inkOf(o, 0)}">Transmitted to <span style="color:var(--ink)">shadow</span>,<br>on the fourteenth of October,<br>under the house of Kamon.</div>
      <div style="display:flex;flex-direction:column;align-items:center;gap:14px;opacity:${inkOf(o, 1)}">${seal('鑑', 118, { rot: -4 })}<span class="t0">Issuer's seal</span></div>
      <div style="display:flex;flex-direction:column;align-items:center;gap:14px;opacity:${inkOf(o, 2)}"><div style="width:118px;height:118px;border:1px dashed var(--lineStrong);border-radius:6px;display:grid;place-items:center;font:12px var(--mono);letter-spacing:2px;color:var(--inkFaint)">ESC</div><span class="t0">Yours, on roll-up</span></div></div>`,
  }),
}

const LETTERS = [
  { st: '信', app: 'Signal', bd: 'Mika: see you at eight, by the north exit of the station', tm: '21:40' },
  { st: '郵', app: 'Mail', bd: 'Your invoice for October is ready, 2 attachments', tm: '20:12' },
  { st: '火', app: 'Firefox', bd: 'Download complete · hanko-densho.zip · 4.2 MB', tm: '19:58' },
  { st: '系', app: 'System', bd: 'Updates are ready: omarchy 3.2, 14 packages', tm: '18:03' },
]

// A letter. Bodies are written in secret ink (aburidashi) unless warmed:
// o.warm = { row, x, amount } holds the pointer's warmth over one of them.
function letter(l, i, o) {
  const w = o.warm, hidden = o.secret
  let bd = `<span class="bd${hidden ? ' hid' : ''}">${l.bd}</span>`
  if (hidden && w && w.row === i) {
    const a = w.amount
    bd = `<span class="bd" style="-webkit-mask-image:radial-gradient(${120 + a * 260}px 46px at ${w.x}px 50%, #000 ${Math.round(a * 55)}%, rgba(0,0,0,.075) 100%)">${l.bd}</span>`
  }
  const glow = hidden && w && w.row === i ? `<div style="position:absolute;left:184px;top:0;bottom:0;width:${(w.x + 260)}px;background:radial-gradient(${140 + w.amount * 200}px 40px at ${w.x}px 50%, color-mix(in srgb, var(--ink) ${Math.round(4 + w.amount * 5)}%, transparent), transparent);pointer-events:none"></div>` : ''
  const ptr = hidden && w && w.row === i ? `<svg style="position:absolute;left:${184 + w.x}px;top:26px;z-index:3" width="18" height="24" viewBox="0 0 18 24"><path d="M1 1 L1 19 L6 14.5 L9.5 22 L12.5 20.6 L9 13.3 L15.5 13.3 Z" fill="var(--paper)" stroke="var(--ink)" stroke-width="1.2"/></svg>` : ''
  return `<div class="lt" style="opacity:${inkOf(o, i)}">${glow}<span class="st">${l.st}</span><span class="ap">${l.app}</span>${bd}<span class="tm">${l.tm}</span>${ptr}</div>`
}

function kv(rows) {
  return rows.map(([k, v]) => `<div style="display:flex;justify-content:space-between;height:36px;align-items:center;border-bottom:1px solid var(--lineSoft)"><span style="font:11px var(--mono);letter-spacing:2px;color:var(--inkFaint);text-transform:uppercase">${k}</span><span style="font:14px var(--mono);color:var(--inkDim)">${v}</span></div>`).join('')
}

// The house's line: boot, login, update, now, along one hairline.
function lineage() {
  const pts = [[0, 'Installed', '3 Mar'], [0.58, 'Updated', 'omarchy 3.2'], [0.78, 'Booted', '08:12'], [0.8, '', ''], [1, 'Now', '21:44']]
  return `<div class="t0" style="margin-bottom:46px">The line of the house</div><div style="position:relative;height:60px">
    <div style="position:absolute;left:0;right:0;top:20px;height:1px;background:var(--lineStrong)"></div>
    <div style="position:absolute;left:78%;width:22%;top:19px;height:3px;background:var(--inkMuted)"></div>
    ${pts.filter(p => p[1]).map(([x, a, b]) => `<div style="position:absolute;left:${x * 100}%;top:0;transform:translateX(${x === 1 ? '-100%' : x ? '-50%' : '0'});text-align:${x === 1 ? 'right' : x ? 'center' : 'left'}">
      <div style="position:absolute;${x === 1 ? 'right:0' : x ? 'left:50%' : 'left:0'};top:14px;width:${a === 'Now' ? 2 : 1}px;height:${a === 'Now' ? 14 : 11}px;background:${a === 'Now' ? 'var(--seal)' : 'var(--inkMuted)'}"></div>
      <div style="margin-top:36px;font:11px var(--mono);letter-spacing:2px;color:var(--inkFaint);text-transform:uppercase;white-space:nowrap">${a}</div>
      <div style="font-size:15px;color:var(--inkDim);margin-top:3px;white-space:nowrap">${b}</div></div>`).join('')}</div>`
}

function hours() {
  let t = ''
  for (let h = 0; h <= 24; h++) t += `<i style="position:absolute;left:${h / 24 * 100}%;bottom:0;width:1px;height:${h % 6 ? 6 : 12}px;background:var(--lineStrong)"></i>${h % 6 ? '' : `<b style="position:absolute;left:${h / 24 * 100}%;bottom:18px;transform:translateX(-50%);font:400 11px var(--mono);color:var(--inkFaint)">${String(h).padStart(2, '0')}</b>`}`
  return `<div style="position:relative;height:40px;border-bottom:1px solid var(--lineStrong);width:900px">${t}
    <div style="position:absolute;left:0;bottom:-2px;height:3px;width:${21.73 / 24 * 100}%;background:var(--inkMuted)"></div>
    <div style="position:absolute;left:${21.73 / 24 * 100}%;bottom:-4px;width:2px;height:16px;background:var(--seal)"></div></div>
    <div style="display:flex;gap:60px;margin-top:30px">${[['Here', '21:44', 'Wed'], ['Tokyo', '06:44', 'Thu'], ['London', '14:44', 'Wed']].map(([c, t, d]) =>
      `<div><div class="t0">${c}</div><div style="font:400 34px var(--display);margin-top:6px">${t} <small style="font:12px var(--mono);letter-spacing:2px;color:var(--inkFaint)">${d.toUpperCase()}</small></div></div>`).join('')}</div>`
}

// Kasumi 霞: long mist bands with rounded ends, as emaki divide scenes.
function mist(bands, w, h) {
  const id = ++uid
  return `<svg style="position:absolute;left:0;top:0;pointer-events:none;z-index:6" width="${w}" height="${h}"><defs>
    <filter id="ms${id}" x="-10%" y="-80%" width="120%" height="260%"><feTurbulence type="fractalNoise" baseFrequency="0.012 0.08" numOctaves="3" seed="${id}"/><feDisplacementMap in="SourceGraphic" scale="14" xChannelSelector="R" yChannelSelector="G"/><feGaussianBlur stdDeviation="2.4"/></filter></defs>
    <g filter="url(#ms${id})">${bands.map(b => `<rect x="${b.x}" y="${b.y}" width="${b.w}" height="${b.h}" rx="${b.h / 2}" fill="var(--ink)" opacity="${b.op ?? 0.042}"/>`).join('')}</g></svg>`
}

// The wind: ink fibres drifting from `x0` toward the spine that needs you.
function gust(x0, tx, ty, w, h, o = {}) {
  const r = rng(o.seed ?? 5), n = o.count ?? 150, dir = Math.sign(tx - x0)
  let p = ''
  for (let k = 0; k < n; k++) {
    const t = Math.pow(r(), 0.8), x = x0 + t * (tx - x0)
    const spread = 90 * (1 - t) + 10, y = ty + (r() - 0.5) * 2 * spread + Math.sin(x / 70) * 14 * (1 - t)
    const len = (12 + r() * 34) * (0.6 + t * 0.8), bow = (r() - 0.5) * 16
    const op = (0.08 + 0.55 * t * (0.4 + r() * 0.6)) * (o.strength ?? 1)
    p += `<path d="M${x.toFixed(1)},${y.toFixed(1)} q${(dir * len / 2).toFixed(1)},${bow.toFixed(1)} ${(dir * len).toFixed(1)},${(bow * 0.15 + (r() - .5) * 8).toFixed(1)}" stroke="var(--inkMuted)" stroke-width="${(0.8 + r() * 0.6).toFixed(1)}" fill="none" stroke-linecap="round" opacity="${op.toFixed(2)}"/>`
  }
  return `<svg style="position:absolute;left:0;top:0;pointer-events:none;z-index:7" width="${w}" height="${h}">${p}</svg>`
}

// A repair line across a section at fault: one red seam, like kintsugi in seal red.
function seam(x, y, w, seed = 3) {
  const r = rng(seed)
  let d = `M${x},${y}`, cx = x, cy = y
  while (cx < x + w) { cx += 18 + r() * 46; cy += (r() - 0.5) * 16; cy = Math.max(y - 12, Math.min(y + 12, cy)); d += ` L${cx.toFixed(1)},${cy.toFixed(1)}` }
  return `<svg style="position:absolute;left:0;top:0;pointer-events:none;z-index:7;overflow:visible" width="10" height="10"><path d="${d}" stroke="var(--seal)" stroke-width="2.2" fill="none" stroke-linejoin="round" opacity=".9"/><path d="${d}" stroke="var(--seal)" stroke-width="7" fill="none" stroke-linejoin="round" opacity=".12"/></svg>`
}

// ------------------------------------------------------------------ the scroll
// o: at (section open), W, H, write, dry, press, mist (true/false or a shift
// in px for parallax), gust ({ to, from, strength }), flags ([index]),
// offline, secret, warm, curl (0..1 the paper rolling up), stance.
function scroll(o = {}) {
  const W = o.W ?? 1660, H = o.H ?? 460, at = o.at ?? 2, n = SECTIONS.length
  const flags = o.flags ?? []
  let xl = 58, xr = W - 58, spines = '', centres = {}
  for (let d = 3; d >= 1; d--) {
    const i = at - d
    if (i >= 0) { spines += spine(i, d, xl, 'lft', flags); centres[i] = xl + SPINE_W[d] / 2; xl += SPINE_W[d] }
  }
  for (let d = 3; d >= 1; d--) {
    const i = at + d
    if (i < n) { xr -= SPINE_W[d]; spines += spine(i, d, xr, 'rgt', flags); centres[i] = xr + SPINE_W[d] / 2 }
  }
  // what is wound past the spines sits on the rollers
  for (let i = 0; i < at - 3; i++) centres[i] = 30
  for (let i = at + 4; i < n; i++) centres[i] = W - 30
  const fx = xl + 46, fw = xr - xl - 92
  const s = SECTIONS[at], b = (BODIES[at] ?? BODIES[2])({ ...o, fw })
  const write = o.write ?? 1, dry = o.dry ?? 0
  const head = `<div class="fh" style="opacity:${write >= 1 ? (1 - .3 * dry) : clamp01(write * 4)}"><span class="fj${o.press ? ' press' : ''}">${s.jp}</span><span class="fe">${s.no} // ${s.label}</span><span class="fp">${s.poem}</span></div>`
  const focus = o.stance ? stance(s, fx, fw, H) : `<div class="focus" style="left:${fx + (o.shift ?? 0)}px;width:${fw}px;padding-top:58px">
    <div class="wm" style="opacity:${(0.045 * (o.write ?? 1)).toFixed(3)}">${s.jp}</div>
    ${head}<div class="ft">${title(b.title, { write, dry, width: fw, color: b.color })}</div>
    <div class="fc" style="opacity:${write >= 1 ? (1 - .4 * dry) : clamp01((write - .45) * 4)}">${b.caption}</div>${b.body}</div>`
  const rolls = roller('l', at, 14, at, flags.filter(i => i < at - 3)) + roller('r', n - 1 - at, W - 48, n - 1 - at, flags.filter(i => i > at + 3).map(i => n - 1 - i))
  const sh = typeof o.mist === 'number' ? o.mist : 0
  const bands = o.mist === false ? '' : mist([
    { x: fx + fw - 470 + sh * 1.4, y: H - 92, w: 640, h: 20 }, { x: fx + fw - 260 + sh * 1.9, y: H - 66, w: 360, h: 12, op: .03 },
    { x: fx + fw - 300 + sh * 1.4, y: 26, w: 560, h: 18 }, { x: fx + fw - 120 + sh * 1.8, y: 48, w: 280, h: 11, op: .03 },
    { x: 20 + sh * 1.6, y: H - 58, w: fx + 10, h: 14, op: .035 },
  ], W, H)
  const g = o.gust ? gust(o.gust.from ?? fx + fw * 0.3, centres[o.gust.to], o.gust.y ?? H * 0.55, W, H, o.gust) : ''
  const sm = o.offline ? seam(fx - 30, 232, fw + 50) : ''
  return `<div class="scr" style="width:${W}px;height:${H}px">${rolls}${spines}${focus}${bands}${g}${sm}${o.extra ?? ''}</div>`
}

function spine(i, d, x, side, flags) {
  const s = SECTIONS[i], w = SPINE_W[d]
  return `<div class="spine ${side} d${d}" style="left:${x}px;width:${w}px">${flags.includes(i) ? '<span class="flag"></span>' : ''}<span class="sj">${s.jp}</span><span class="sl"><b>${s.no}</b> ${s.label}</span>${d === 1 ? `<span class="sp">${s.poem}</span>` : ''}</div>`
}

// k counts from the outer end: section 0 is the outermost line on the left,
// the last section the outermost on the right. Flagged ones are red.
function roller(side, count, x, dark, red) {
  let lines = ''
  for (let k = 0; k < count; k++) {
    const off = side === 'l' ? 4 + k * 3 : 30 - k * 3
    const flag = side === 'l' ? red.includes(k) : red.includes(k)
    lines += `<i class="${k >= count - Math.min(3, dark) ? 'k' : ''}" style="left:${off}px${flag ? ';background:var(--seal);width:2px' : ''}"></i>`
  }
  return `<div class="roll ${side}" style="left:${x}px">${lines}</div>`
}

// A jump (1–8) cuts to a stance: the section's sign, held, before it writes in.
function stance(s, fx, fw, H) {
  return `<div class="focus" style="left:${fx}px;width:${fw}px">
    <div style="position:absolute;left:0;right:0;top:${H * 0.5}px;height:1px;background:linear-gradient(90deg, transparent, var(--bone) 20%, var(--bone) 80%, transparent);opacity:.7"></div>
    <div style="position:absolute;left:50%;top:50px;transform:translateX(-50%);display:flex;gap:26px;align-items:flex-start">
      <span style="font-family:var(--brush);font-size:300px;line-height:1;color:var(--ink)">${s.jp}</span>
      <span style="writing-mode:vertical-rl;font:13px var(--mono);letter-spacing:5px;color:var(--inkMuted);text-transform:uppercase;margin-top:30px">${s.no} · ${s.label}</span>
      <span style="writing-mode:vertical-rl;font:italic 22px var(--display);color:var(--inkFaint);margin-top:30px">${s.poem}</span></div></div>`
}

// A whole screen: the print, the bar, and the scroll hanging from it.
function screen(o = {}) {
  return `<div class="screen">
    <div class="wp" style="background-image:url(../../kaze/source/img/${o.print ?? '7-haboku-dark.webp'});opacity:${o.printOp ?? .4}"></div>
    ${bar(o.bar ?? {})}
    <div style="position:absolute;left:132px;top:46px">${o.scroll ?? scroll(o)}</div>${o.over ?? ''}</div>`
}

function fitPanes() {
  document.querySelectorAll('.pane').forEach(p => {
    const at = p.querySelector('.at'), w = +p.dataset.w, h = +p.dataset.h
    const k = p.clientWidth / w
    at.style.width = w + 'px'; at.style.height = h + 'px'
    at.style.transform = `scale(${k})`; p.style.height = (h * k) + 'px'
  })
}

function pane(html, w, h, extra = '') { return `<div class="pane" data-w="${w}" data-h="${h}" ${extra}><div class="at">${html}</div></div>` }

function densho() {
  document.body.insertAdjacentHTML('afterbegin', `<svg width="0" height="0" style="position:absolute"><filter id="worn" x="-5%" y="-5%" width="110%" height="110%">
    <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="4" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -2.2 1.45" result="m"/>
    <feComposite in="SourceGraphic" in2="m" operator="in" result="s"/>
    <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="9" result="w"/>
    <feDisplacementMap in="s" in2="w" scale="3"/></filter></svg>`)
  fitPanes()
  document.fonts.ready.then(() => { fitPanes(); document.body.dataset.ready = '1' })
}
