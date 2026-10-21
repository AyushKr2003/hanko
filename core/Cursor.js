.pragma library

// Te 手, the panel cursor: every sheet, in every hand, driven from the
// keyboard with Omarchy's panel keys (its Ui/PanelKeyCatcher.qml): the
// arrows or h j k l move, Enter or Space act, Esc closes, Tab goes to the
// next sheet. The sheet's parts that do something (a row, a button, a
// ruler, a slip, a bead) say so with `keyStop`; bar/sheets/SheetView.qml
// gathers them where they are on the paper and hands their rectangles here.
// Moving is spatial, so one rule works for a ledger's rows, a tanzaku's
// slips hung side by side and a craft hand's board, without any of them
// listing its stops by hand.
//
// stop: { x, y, w, h, step (it has a level: Left/Right set it), chosen
//         (the one in use), pane (which column of a window it is in, the
//         settings rail or its page; Up/Down stay in it when they can) }

// Two stops share a line when their heights overlap by this much of the
// shorter one.
var SAME_LINE = 0.4
// Stops this close in their gap to the nearest line count as one line, so
// a ragged row of buttons is not skipped over.
var BAND_PX = 8

function cx(s) { return s.x + s.w / 2 }
function cy(s) { return s.y + s.h / 2 }

function overlap(a0, a1, b0, b1) { return Math.min(a1, b1) - Math.max(a0, b0) }

function sameLine(a, b) {
  return overlap(a.y, a.y + a.h, b.y, b.y + b.h) >= SAME_LINE * Math.min(a.h, b.h)
}

// Where the cursor lands when it first shows: on the first level you can
// set (Omarchy's audio panel starts on its output slider), else on the one
// in use, else on the first stop in reading order.
function start(stops) {
  if (!stops || !stops.length) return -1
  var order = reading(stops)
  for (var i = 0; i < order.length; i++) if (stops[order[i]].step) return order[i]
  for (var j = 0; j < order.length; j++) if (stops[order[j]].chosen) return order[j]
  return order[0]
}

// Indexes in reading order: line by line, left to right.
function reading(stops) {
  var idx = []
  for (var i = 0; i < stops.length; i++) idx.push(i)
  idx.sort(function(a, b) {
    var p = stops[a], q = stops[b]
    if (sameLine(p, q)) return p.x - q.x || p.y - q.y
    return cy(p) - cy(q)
  })
  return idx
}

// The stop a move goes to from `from`, or `from` when there is none that
// way (the cursor stops at the paper's edge, as Omarchy's does).
// dy: down (+1) or up (-1) to the nearest line that way, then the stop on
// it closest across. dx: the nearest stop on the same line that way; with
// `loose` (a window of columns: the settings rail beside its page), when
// there is none on the line, the nearest stop that way at all, rows
// overlapping first.
function move(stops, from, dx, dy, loose) {
  if (!stops || !stops.length) return -1
  if (from < 0 || from >= stops.length) return start(stops)
  var cur = stops[from]
  var best = -1, bestGap = Infinity, bestAcross = Infinity
  var i, s
  if (dy !== 0) {
    // The stops that way, each with its gap (edge to edge) from the cursor.
    var gaps = []
    // Up and Down stay in the cursor's pane while it has a stop that way.
    var inPane = false
    for (i = 0; i < stops.length; i++) {
      s = stops[i]
      if (i !== from && (s.pane || 0) === (cur.pane || 0) && !sameLine(cur, s) && (dy > 0 ? cy(s) > cy(cur) : cy(s) < cy(cur))) inPane = true
    }
    for (i = 0; i < stops.length; i++) {
      s = stops[i]
      var ahead = i !== from && !sameLine(cur, s) && (dy > 0 ? cy(s) > cy(cur) : cy(s) < cy(cur))
        && (!inPane || (s.pane || 0) === (cur.pane || 0))
      gaps.push(ahead ? Math.max(0, dy > 0 ? s.y - (cur.y + cur.h) : cur.y - (s.y + s.h)) : Infinity)
    }
    // Straight on first: the nearest stop the cursor's column runs through
    // (a slip hung shorter than its neighbour is still the one above).
    for (i = 0; i < stops.length; i++) {
      if (gaps[i] === Infinity || overlap(stops[i].x, stops[i].x + stops[i].w, cur.x, cur.x + cur.w) <= 0) continue
      if (gaps[i] < bestGap) { bestGap = gaps[i]; best = i }
    }
    if (best >= 0) return best
    // Else the nearest line that way, and on it the stop closest across.
    for (i = 0; i < stops.length; i++) if (gaps[i] < bestGap) bestGap = gaps[i]
    if (bestGap === Infinity) return from
    for (i = 0; i < stops.length; i++) {
      if (gaps[i] > bestGap + BAND_PX) continue
      var across = Math.abs(cx(stops[i]) - cx(cur))
      if (across < bestAcross) { bestAcross = across; best = i }
    }
    return best < 0 ? from : best
  }
  if (dx !== 0) {
    for (i = 0; i < stops.length; i++) {
      if (i === from) continue
      s = stops[i]
      if (!sameLine(cur, s)) continue
      var d = dx > 0 ? cx(s) - cx(cur) : cx(cur) - cx(s)
      if (d <= 0) continue
      if (d < bestGap) { bestGap = d; best = i }
    }
    if (best >= 0 || !loose) return best < 0 ? from : best
    var bestScore = Infinity
    for (i = 0; i < stops.length; i++) {
      if (i === from) continue
      s = stops[i]
      var gapX = dx > 0 ? s.x - (cur.x + cur.w) : cur.x - (s.x + s.w)
      if (gapX < 0) continue
      var off = Math.abs(cy(s) - cy(cur))
      var score = gapX + 2 * off
      if (score < bestScore) { bestScore = score; best = i }
    }
    return best < 0 ? from : best
  }
  return from
}

// The stop under a point (the pointer): the smallest that holds it, or -1.
function at(stops, point) {
  var best = -1, bestArea = Infinity
  for (var i = 0; stops && point && i < stops.length; i++) {
    var s = stops[i]
    if (point.x < s.x || point.x >= s.x + s.w || point.y < s.y || point.y >= s.y + s.h) continue
    if (s.w * s.h < bestArea) { bestArea = s.w * s.h; best = i }
  }
  return best
}

// After the sheet's data changes its parts are made anew: the stop now
// nearest to where the cursor was (its centre), or -1 when there are none.
function nearest(stops, point) {
  if (!stops || !stops.length || !point) return -1
  var best = -1, bestD = Infinity
  for (var i = 0; i < stops.length; i++) {
    var dx = cx(stops[i]) - point.x, dy = cy(stops[i]) - point.y
    var d = dx * dx + dy * dy
    if (d < bestD) { bestD = d; best = i }
  }
  return best
}

// What a key does on a sheet: { kind, dx, dy, dir } or null for a key the
// sheet itself may want (its letters: M, N, R, P, T, 1–9). Omarchy's
// PanelKeyCatcher, key for key.
function action(key, text, shift) {
  var K = KEYS
  if (key === K.Escape) return { kind: "close" }
  if (key === K.Tab || key === K.Backtab) return { kind: "tab", dir: shift || key === K.Backtab ? -1 : 1 }
  if (key === K.Down || text === "j") return { kind: "move", dx: 0, dy: 1 }
  if (key === K.Up || text === "k") return { kind: "move", dx: 0, dy: -1 }
  if (key === K.Right || text === "l") return { kind: "move", dx: 1, dy: 0 }
  if (key === K.Left || text === "h") return { kind: "move", dx: -1, dy: 0 }
  if (key === K.Return || key === K.Enter || key === K.Space) return { kind: "activate" }
  return null
}

// Qt's key codes, so this file stays plain JavaScript (and testable).
var KEYS = {
  Escape: 0x01000000, Tab: 0x01000001, Backtab: 0x01000002, Return: 0x01000004, Enter: 0x01000005,
  Left: 0x01000012, Up: 0x01000013, Right: 0x01000014, Down: 0x01000015, Space: 0x20
}
