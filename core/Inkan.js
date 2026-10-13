.pragma library

// Inkan 印, the seal only (style `form: inkan`; docs/shell-concepts/inkan).
// The bar is taken away and one seal is left in a corner; its carving is
// the status, and a press prints No. 00, every sheet on one. This file is
// the seal's reading, where it and its sheet sit, and No. 00's rows, so the
// rules are tested without a running shell. bar/InkanSeal.qml and
// bar/SealWindow.qml draw them; the design kit draws the same specks.

// The seal's side and its distance from the screen's corner, at font size
// 12 (Type.px scales them), and the room between the seal and its sheet.
var SIZE = 46
var MARGIN = 18
var SHEET_GAP = 18
// No. 00's width, at font size 12.
var WIDTH = 440
var CORNERS = ["top-left", "top-right", "bottom-left", "bottom-right"]
var DEFAULT_CORNER = "bottom-right"

// The workspace numerals the bar's seal uses (bar/Seal.qml).
var NUMERALS = ["〇", "壱", "弐", "参", "肆", "伍", "陸", "漆", "捌", "玖"]

// No. 00's rows: each sheet's kanji, as core/Sheets.js names them.
var ROWS = [
  { key: "sound",     jp: "音", name: "Sound" },
  { key: "network",   jp: "網", name: "Network" },
  { key: "bluetooth", jp: "藍", name: "Bluetooth" },
  { key: "power",     jp: "電", name: "Power" },
  { key: "display",   jp: "明", name: "Display" },
  { key: "inbox",     jp: "報", name: "Inbox" }
]

function cornerOf(c) {
  return CORNERS.indexOf(String(c)) >= 0 ? String(c) : DEFAULT_CORNER
}
function atTop(c) { return cornerOf(c).indexOf("top") === 0 }
function atLeft(c) { return /left$/.test(cornerOf(c)) }

// ------------------------------------------------------------ the carving

// How much of the carving is left, 0..1, from the battery reading
// (core/Status.js battery()): whole at 60 % and up, while charging and with
// no battery at all; below 60 % it wears down to 0.3 at empty, which still
// leaves the glyph legible.
var WEAR_FROM = 60
function wear(battery) {
  if (!battery || battery.charging) return 1
  var pct = Number(battery.percent)
  if (!isFinite(pct) || pct >= WEAR_FROM) return 1
  return 0.3 + 0.7 * Math.max(0, pct) / WEAR_FROM
}

function rng(seed) {
  var s = Math.floor(Number(seed) || 1) % 2147483647
  if (s <= 0) s += 2147483646
  return function() { s = s * 16807 % 2147483647; return s / 2147483647 }
}

// Seeded blots inside the carving, in 0..1 of the seal's side: clusters,
// so the wear reads as worn strokes rather than noise. Each has a
// threshold `t`; it is drawn (in the plate's red, over the glyph) when `t`
// is under the erosion, 1 − wear, so the carving wears in the same places
// every time, a little more as the battery falls.
var SEED = 7
function specks(seed) {
  var r = rng(seed === undefined ? SEED : seed), out = []
  for (var c = 0; c < 14; c++) {
    var cx = 0.2 + r() * 0.6, cy = 0.2 + r() * 0.6, t0 = r()
    var n = 4 + Math.floor(r() * 6)
    for (var i = 0; i < n; i++)
      out.push({ x: cx + (r() - 0.5) * 0.16, y: cy + (r() - 0.5) * 0.16,
                 r: 0.018 + r() * 0.045, t: Math.min(1, t0 + r() * 0.25) })
  }
  return out
}

// The specks drawn at a wear.
function worn(list, w) {
  var e = 1 - Math.max(0, Math.min(1, Number(w)))
  return (list || []).filter(function(s) { return s.t < e })
}

// Chipped corners for letters waiting (Status.notifications): one for one
// or two, two for three or more; `deep` when one is urgent. None under do
// not disturb: the letters wait.
function chips(letters, dnd) {
  var list = Array.isArray(letters) ? letters : []
  if (dnd || !list.length) return { count: 0, deep: false }
  return { count: list.length >= 3 ? 2 : 1,
           deep: list.some(function(l) { return l && l.urgent }) }
}
// A chip's leg, as a share of the seal's side.
function chipSize(deep) { return deep ? 0.34 : 0.22 }

// Everything the seal draws, from the style and the live readings:
//   d = { battery, network, notifications, dnd, workspace (active id) }
// glyph: the seal glyph, or the workspace numeral under seal: workspace.
// outline: quiet (do not disturb), or seal: carved resting with no letters.
// broken: offline (the inner rule breaks along the foot).
function carving(style, d) {
  var s = style || {}, data = d || {}
  var ws = Number(data.workspace)
  var glyph = s.seal === "workspace"
    ? (ws >= 0 && ws < NUMERALS.length ? NUMERALS[ws] : String(ws))
    : (s.sealGlyph || "鑑")
  var ch = chips(data.notifications, data.dnd)
  return {
    glyph: glyph,
    wear: wear(data.battery),
    chips: ch.count,
    deep: ch.deep,
    outline: !!data.dnd || (s.seal === "carved" && ch.count === 0),
    broken: !!(data.network && data.network.off),
    low: !!(data.battery && data.battery.needsYou)
  }
}

// ------------------------------------------------------------ the reading

// The hover line beside the seal: the time, then the battery, the
// network, the inbox, a muted master; each part { text, jp, red }.
function reading(d, time) {
  var data = d || {}, out = [{ text: String(time || ""), time: true }]
  var b = data.battery
  if (b) out.push({ jp: "電", text: b.percent + "%" + (b.charging ? " · charging" : ""), red: !!b.needsYou })
  var n = data.network
  if (n) out.push({ text: n.off ? "offline" : n.name, red: !!n.off })
  var v = data.volume
  if (v && v.muted) out.push({ jp: "音", text: "muted", red: true })
  if (data.dnd) out.push({ jp: "静", text: "quiet" })
  else {
    var count = (data.notifications || []).length
    if (count) out.push({ jp: "報", text: String(count), red: (data.notifications || []).some(function(l) { return l.urgent }) })
  }
  return out
}

// ------------------------------------------------------------ No. 00

// One row per sheet there is something for, in the bar's order:
// { key, jp, name, value, red }. A desktop has no Power row, a machine
// without a backlight no Display row, one without an adapter no Bluetooth.
function rows(d) {
  var data = d || {}, out = []
  function push(key, value, red) {
    for (var i = 0; i < ROWS.length; i++)
      if (ROWS[i].key === key) out.push({ key: key, jp: ROWS[i].jp, name: ROWS[i].name, value: value, red: !!red })
  }
  var v = data.volume
  if (v) push("sound", v.muted ? "Muted" : v.percent + "%" + (data.output ? " · " + data.output : ""), v.muted)
  var n = data.network
  if (n) push("network", n.off ? "Offline" : n.kind === "wifi" ? n.name + " · " + Math.round(n.signal) + "%" : n.name, n.off)
  var bt = data.bluetooth
  if (bt) {
    var lvl = bt.level >= 0 ? " · " + Math.round(bt.level * 100) + "%" : ""
    push("bluetooth", !bt.enabled ? "Off" : bt.connected ? bt.name + lvl : "On", bt.needsYou)
  }
  var b = data.battery
  if (b) push("power", b.percent + "%" + (b.charging ? " · charging" : data.timeLeft ? " · " + data.timeLeft : ""), b.needsYou)
  var l = data.brightness
  if (l) push("display", l.percent + "%")
  var letters = data.notifications || []
  push("inbox", data.dnd ? "Quiet" : !letters.length ? "None" : letters.length + (letters.length === 1 ? " letter" : " letters"),
       !data.dnd && letters.some(function(x) { return x.urgent }))
  return out
}

// ------------------------------------------------------------ geometry

// The seal's square on a screen w × h: `size` from the corner's two edges,
// `margin` in.
function place(corner, w, h, size, margin) {
  var c = cornerOf(corner)
  return { x: atLeft(c) ? margin : w - margin - size, y: atTop(c) ? margin : h - margin - size,
           width: size, height: size }
}

// Where a sheet `sw` × `sh` prints for a seal at `seal`: its outer side on
// the seal's, set off the edge the seal shares (below a top seal, above a
// bottom one), kept inside the screen's margins. `origin` is the sheet's
// corner nearest the seal, where the print starts.
function sheetPlace(corner, w, h, seal, sw, sh, gap, margin) {
  var c = cornerOf(corner)
  var x = atLeft(c) ? seal.x : seal.x + seal.width - sw
  var y = atTop(c) ? seal.y + seal.height + gap : seal.y - gap - sh
  x = Math.round(Math.max(margin, Math.min(w - margin - sw, x)))
  y = Math.round(Math.max(margin, Math.min(h - margin - sh, y)))
  return { x: x, y: y, origin: c }
}

// The corner nearest a point (where a dragged seal lets go).
function nearest(x, y, w, h) {
  return (y < h / 2 ? "top" : "bottom") + "-" + (x < w / 2 ? "left" : "right")
}
