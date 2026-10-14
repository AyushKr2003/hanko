// Kaze 風 mockup kit: the parts every sheet draws (bar, grass, windows),
// and the fit of a 1920×1080 screen into a frame.

// A small seeded random, so every render is the same picture.
function rng(seed) {
  let s = seed >>> 0
  return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296 }
}

// The living layer: clumps of brush blades along the foot of the screen,
// with gaps between them (ma) and a few pampas plumes, like susuki in a field.
//   wind   -1..1+, the real wind (sign = direction, size = strength)
//   gust   { x, width, strength } a gust passing, or null
//   count  roughly how many blades; height  the layer's height in px
function grass({ width = 1920, height = 150, count = 110, wind = 0.25, gust = null, seed = 7, color = 'var(--inkFaint)', opacity = 0.75, gaps = 0.18, spacing = 1 } = {}) {
  const r = rng(seed)
  let paths = ''
  const blade = (x, len, rest, w, op, plume) => {
    let lean = wind * (0.75 + r() * 0.5)
    if (gust) { const d = (x - gust.x) / gust.width; lean += gust.strength * Math.exp(-d * d * 2) }
    // the angle from upright: the blade's own rest angle plus the wind, longer blades bend more
    const ang = Math.max(-1.35, Math.min(1.35, rest + lean * (0.55 + len / height * 0.6)))
    const tipX = x + Math.sin(ang) * len, tipY = height - Math.cos(ang) * len
    // the bend: the lower half stays nearer upright
    const cx = x + Math.sin(ang * 0.35) * len * 0.55, cy = height - Math.cos(ang * 0.35) * len * 0.55
    paths += `<path d="M${(x - w).toFixed(1)},${height} Q${(cx - w * 0.45).toFixed(1)},${cy.toFixed(1)} ${tipX.toFixed(1)},${tipY.toFixed(1)} Q${(cx + w * 0.35).toFixed(1)},${cy.toFixed(1)} ${(x + w).toFixed(1)},${height} Z" opacity="${op.toFixed(2)}"/>`
    if (plume) {
      // a seed head: short strokes hanging off the tip, downwind
      for (let k = 0; k < 7; k++) {
        const t = k / 6, px = tipX - Math.sin(ang) * t * 26, py = tipY + Math.cos(ang) * t * 26
        const fl = 7 + r() * 6, fa = ang + 0.5 + r() * 0.4
        paths += `<path d="M${px.toFixed(1)},${py.toFixed(1)} L${(px + Math.sin(fa) * fl).toFixed(1)},${(py - Math.cos(fa) * fl * 0.4 + fl * 0.5).toFixed(1)}" stroke="currentColor" stroke-width="1" opacity="${(op * 0.7).toFixed(2)}" fill="none"/>`
      }
    }
  }
  let x = r() * 30, n = 0
  while (x < width && n < count) {
    const blades = 3 + Math.floor(r() * 6), tall = 0.45 + r() * 0.55
    for (let k = 0; k < blades; k++) {
      const len = height * tall * (0.45 + r() * 0.55)
      blade(x + (r() - 0.5) * 10, len, (k / (blades - 1 || 1) - 0.5) * 0.7 + (r() - 0.5) * 0.15, 0.9 + r() * 1.6, 0.4 + r() * 0.6, k === 1 && r() < 0.28)
      n++
    }
    x += (10 + r() * 34) * spacing + (r() < gaps ? 60 + r() * 120 : 0)   // now and then, a gap
  }
  return `<svg class="grass" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" style="opacity:${opacity};color:${color}"><g fill="${color}">${paths}</g></svg>`
}

// The Hanko bar, Kamon preset. opts: { ws, title, app, time, gust, urgent, hours }
function bar(o = {}) {
  const ws = o.ws ?? 2
  const kj = ['壱', '弐', '参', '肆', '伍']
  const spaces = kj.map((k, i) => `<span class="${i === ws ? 'on' : (i < 4 ? 'occ' : '')}${o.urgent === i ? ' u' : ''}">${k}</span>`).join('')
  const hour = o.hours ?? 21.7
  const p = (hour / 24 * 100).toFixed(2)
  const gust = o.gust ? `<div class="gust" style="left:${o.gust[0]}%;width:${o.gust[1]}%"></div>` : ''
  return `<div class="bar">
    <div class="l"><div class="seal">鑑</div><div class="div" style="margin-left:12px"></div>
      <div class="kws">${spaces}</div><div class="div"></div>
      <div class="byline">${o.app ?? 'Alacritty'}<small>${o.title ?? 'nvim · ~/code/hanko/Bar.qml'}</small></div></div>
    <div class="c"><span class="clk">${o.time ?? '21<em>:</em>44'}</span><span class="date">${o.date ?? 'Wed 14 Oct'}</span></div>
    <div class="r">
      <div class="cell"><div class="lab">NET<i>波</i></div><div class="val">Kumo</div></div>
      <div class="cell"><div class="lab">VOL<i>音</i></div><div class="val">62<small>%</small></div></div>
      <div class="cell${o.lowBattery ? ' red' : ''}"><div class="lab">BAT<i>力</i></div><div class="val">${o.battery ?? 91}<small>%</small></div></div>
      <div class="stamps">${o.stamps ?? '<b>静</b><b class="red">文</b>'}</div>
    </div>
    <div class="rodrule"><div class="spent" style="width:${p}%"></div><div class="now" style="left:${p}%"></div>${gust}</div>
  </div>`
}

// Scale every .screen[data-w] to fill its .fit box's width.
function fitScreens() {
  document.querySelectorAll('.fit').forEach(f => {
    const s = f.querySelector('.screen')
    const k = f.clientWidth / 1920
    s.style.transform = `scale(${k})`
    f.style.height = (1080 * k) + 'px'
  })
}

function ready() {
  fitScreens()
  document.fonts.ready.then(() => { fitScreens(); document.body.dataset.ready = '1' })
}
