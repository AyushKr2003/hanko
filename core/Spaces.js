.pragma library

// Workspace data for the left zone, as plain objects:
//   { id, name, active, urgent, windows: [ { x, y, w, h, focused } ] }
// x/y/w/h are fractions of the monitor's usable area, so `layout` can draw
// each workspace's real tiling at any size. Pure; tested in tests/unit.mjs.

var NUMERALS = ["〇", "壱", "弐", "参", "肆", "伍", "陸", "漆", "捌", "玖", "拾"]

function numeral(id) {
  return id >= 0 && id < NUMERALS.length ? NUMERALS[id] : String(id)
}

function folio(id) {
  return id < 10 ? "0" + id : String(id)
}

function clamp01(v) {
  return Math.max(0, Math.min(1, v))
}

// windows: [{ at: [x, y], size: [w, h], floating, focused }] in layout px.
// area: { x, y, width, height } the monitor's usable area in the same px.
// Floating windows are left out: the glyph shows the tiling.
function layoutOf(windows, area) {
  var out = []
  if (!area || !(area.width > 0) || !(area.height > 0)) return out
  for (var i = 0; i < (windows || []).length; i++) {
    var w = windows[i]
    if (!w || !w.at || !w.size || w.floating) continue
    var x = clamp01((w.at[0] - area.x) / area.width)
    var y = clamp01((w.at[1] - area.y) / area.height)
    var r = clamp01((w.at[0] + w.size[0] - area.x) / area.width)
    var b = clamp01((w.at[1] + w.size[1] - area.y) / area.height)
    if (r - x < 0.01 || b - y < 0.01) continue
    out.push({ x: x, y: y, w: r - x, h: b - y, focused: !!w.focused })
  }
  // Fullscreen or a single window still reads as one pane.
  return out
}

// A monitor's usable area: its logical size minus Hyprland's reserved edges
// (the bar itself, gaps). reserved is [left, top, right, bottom].
function usableArea(monitor) {
  if (!monitor) return null
  var scale = monitor.scale > 0 ? monitor.scale : 1
  var transform = monitor.transform || 0
  var pw = monitor.width / scale, ph = monitor.height / scale
  // Transforms 1, 3, 5 and 7 rotate by 90 degrees.
  if (transform % 2 === 1) { var t = pw; pw = ph; ph = t }
  var r = monitor.reserved || [0, 0, 0, 0]
  return {
    x: monitor.x + r[0],
    y: monitor.y + r[1],
    width: Math.max(1, pw - r[0] - r[2]),
    height: Math.max(1, ph - r[1] - r[3])
  }
}

// workspaces: [{ id, name, urgent, windows }]; ids 1..min are always shown,
// like Omarchy's own bar, plus any other occupied numbered workspace up to 10.
// Special (negative id) workspaces never appear here.
function list(workspaces, activeId, min) {
  min = min || 5
  var byId = {}
  for (var i = 0; i < (workspaces || []).length; i++) {
    var w = workspaces[i]
    if (w && w.id > 0 && w.id <= 10) byId[w.id] = w
  }
  var ids = []
  for (var n = 1; n <= min; n++) ids.push(n)
  for (var k in byId) {
    var id = Number(k)
    if (ids.indexOf(id) === -1 && (byId[id].windows || []).length > 0) ids.push(id)
  }
  if (activeId > 0 && activeId <= 10 && ids.indexOf(activeId) === -1) ids.push(activeId)
  ids.sort(function(a, b) { return a - b })
  return ids.map(function(id) {
    var w = byId[id] || {}
    return {
      id: id,
      name: w.name || String(id),
      active: id === activeId,
      urgent: !!w.urgent,
      windows: w.windows || []
    }
  })
}
