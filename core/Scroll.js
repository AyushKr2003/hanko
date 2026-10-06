.pragma library

// The handscroll 巻 (docs/COMPONENTS.md, "Panels"; panels: scroll): six
// sections side by side on one long paper, with dithered interludes
// between them, panned sideways under a window held by two rollers. This
// is the geometry: where each section sits on the track, where the track
// must be for a section to sit in the middle, which section a pan lands
// on, and the dither the interludes are painted with.

// Index order, which is also the order on the paper.
var SECTIONS = [
  { key: "time",    no: "01", jp: "時", label: "TIME",    width: 600 },
  { key: "sound",   no: "02", jp: "音", label: "SOUND",   width: 660 },
  { key: "network", no: "03", jp: "網", label: "NETWORK", width: 540 },
  { key: "bluetooth", no: "04", jp: "藍", label: "BLUETOOTH", width: 500 },
  { key: "power",   no: "05", jp: "電", label: "POWER",   width: 420 },
  { key: "display", no: "06", jp: "明", label: "DISPLAY", width: 520 },
  { key: "spaces",  no: "07", jp: "窓", label: "SPACES",  width: 700 },
  { key: "inbox",   no: "08", jp: "報", label: "INBOX",   width: 560 }
]
// A dithered ink-wash sliver between two sections.
var INTERLUDE = 70

function indexOf(key) {
  for (var i = 0; i < SECTIONS.length; i++) if (SECTIONS[i].key === key) return i
  return -1
}

// The section a bar cell unrolls to, or "".
function forCell(cell) {
  var map = { clock: "time", volume: "sound", network: "network", bluetooth: "bluetooth", battery: "power",
              brightness: "display", workspaces: "spaces", seal: "spaces", notif: "inbox" }
  return map[cell] || ""
}

// Left edge of every section on the track, in px before scaling, and the
// track's whole width. `scale` multiplies every width (Type.scale).
function layout(scale) {
  var s = scale || 1
  var xs = []
  var x = 0
  for (var i = 0; i < SECTIONS.length; i++) {
    xs.push(Math.round(x))
    x += SECTIONS[i].width * s
    if (i < SECTIONS.length - 1) x += INTERLUDE * s
  }
  return { xs: xs, width: Math.round(x), widths: SECTIONS.map(function(k) { return Math.round(k.width * s) }) }
}

// The track's x that puts section `index` in the middle of a view `viewW`
// wide.
function centred(index, viewW, scale) {
  var l = layout(scale)
  var i = Math.max(0, Math.min(SECTIONS.length - 1, index))
  return Math.round(viewW / 2 - (l.xs[i] + l.widths[i] / 2))
}

// The section whose middle is nearest the view's middle with the track at
// `trackX`.
function nearest(trackX, viewW, scale) {
  var l = layout(scale)
  var mid = viewW / 2 - trackX
  var best = 0
  for (var i = 1; i < SECTIONS.length; i++)
    if (Math.abs(l.xs[i] + l.widths[i] / 2 - mid) < Math.abs(l.xs[best] + l.widths[best] / 2 - mid)) best = i
  return best
}

// The track can't be panned past the first or last section's middle.
function clampTrack(trackX, viewW, scale) {
  var lo = centred(SECTIONS.length - 1, viewW, scale)
  var hi = centred(0, viewW, scale)
  return Math.max(lo, Math.min(hi, trackX))
}

// Where a pan comes to rest: carried on a little by its speed (px per
// second at release), then landed on the nearest section. Returns its index.
function landing(trackX, velocity, viewW, scale) {
  var carried = trackX + (Number(velocity) || 0) * 0.18
  return nearest(clampTrack(carried, viewW, scale), viewW, scale)
}

// The position bar at the foot: one section's share of its width, at the
// section.
function position(index) {
  var n = SECTIONS.length
  return { x: Math.max(0, Math.min(n - 1, index)) / n, width: 1 / n }
}

// ------------------------------------------------------------ dither

var BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

function hash(x, y) {
  var n = Math.sin(x * 127.1 + y * 311.7) * 43758.5453
  return n - Math.floor(n)
}

function valueNoise(x, y) {
  var xi = Math.floor(x), yi = Math.floor(y), xf = x - xi, yf = y - yi
  var u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf)
  var a = hash(xi, yi), b = hash(xi + 1, yi), c = hash(xi, yi + 1), d = hash(xi + 1, yi + 1)
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v
}

function fbm(x, y) {
  var s = 0, a = 0.5
  for (var i = 0; i < 5; i++) { s += a * valueNoise(x, y); x *= 2.03; y *= 2.03; a *= 0.5 }
  return s
}

// Which pixels of a `w` x `h` interlude are inked: an ink-wash that fades
// out at the top, the bottom and both sides, ordered-dithered so it stays
// two colours. `seed` makes each interlude different. Returns a flat array
// of 0/1, row by row.
function sliver(w, h, seed) {
  var out = []
  for (var y = 0; y < h; y++) {
    var band = Math.sin(y / h * Math.PI)
    for (var x = 0; x < w; x++) {
      var threshold = (BAYER[y % 4][x % 4] + 0.5) / 16
      var edge = 1 - Math.abs(x / w - 0.5) * 2
      var n = fbm(x / 26 + seed * 9, y / 60 + seed * 3)
      var v = Math.max(0, (n - 0.38) * 1.6) * band * Math.pow(edge, 0.6) * 0.8
      out.push(v > threshold ? 1 : 0)
    }
  }
  return out
}
