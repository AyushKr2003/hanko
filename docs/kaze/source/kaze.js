// Kaze 風 mockup kit: the parts every sheet draws (bar, grass, windows),
// and the fit of a 1920×1080 screen into a frame.

// A small seeded random, so every render is the same picture.
function rng(seed) {
  let s = seed >>> 0
  return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296 }
}

// The living layer: brush blades along the foot of the screen.
//   wind   -1..1, the real wind (sign = direction, size = strength)
//   gust   { x, width, strength } a gust passing, or null
//   count  blades; height  the layer's height in px
function grass({ width = 1920, height = 150, count = 110, wind = 0.25, gust = null, seed = 7, color = 'var(--inkFaint)', opacity = 0.75 } = {}) {
  const r = rng(seed)
  let paths = ''
  for (let i = 0; i < count; i++) {
    const x = (i + r() * 0.9) * (width / count)
    const h = height * (0.32 + r() * 0.62)
    let lean = wind * (0.7 + r() * 0.5)
    if (gust) {
      const d = (x - gust.x) / gust.width
      lean += gust.strength * Math.exp(-d * d * 2)
    }
    const tipX = x + lean * h * 0.9
    const tipY = height - h * (1 - Math.min(0.5, Math.abs(lean) * 0.35))
    const cx = x + lean * h * 0.15
    const cy = height - h * 0.55
    const w = 1.2 + r() * 2.2
    // a blade: a thin closed curve, broad at the root, a point at the tip
    paths += `<path d="M${(x - w).toFixed(1)},${height} Q${(cx - w * 0.5).toFixed(1)},${cy.toFixed(1)} ${tipX.toFixed(1)},${tipY.toFixed(1)} Q${(cx + w * 0.4).toFixed(1)},${cy.toFixed(1)} ${(x + w).toFixed(1)},${height} Z" opacity="${(0.45 + r() * 0.55).toFixed(2)}"/>`
  }
  return `<svg class="grass" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" style="opacity:${opacity}"><g fill="${color}">${paths}</g></svg>`
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
