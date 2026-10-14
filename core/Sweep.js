.pragma library

// Ha 刃, the focus sweep (docs/kaze, mockup 05): when focus moves, light runs
// once round the new window's edge, like light down a blade, and is gone.
// Hyprland draws the edge itself and inks it up from faint over the same
// time (style.lua's border speed), so the light passes and leaves full ink.
//
// Pure geometry, drawn by plugins/hanko.desk: a rectangle's perimeter walked
// clockwise from its top-left corner, and the lit stretch at a moment.

var MS = 600          // the whole pass
var HOLD = 30         // Iai's held beat before the draw
var LENGTH = 0.22     // the light's length, as a share of the perimeter
var PIECES = 24       // how many steps the light's tail fades in

// The frame Hyprland draws round a window: `border` px outside its geometry.
function frame(at, size, border) {
  var b = border === undefined ? 1 : border
  return { x: at[0] - b, y: at[1] - b, width: size[0] + 2 * b, height: size[1] + 2 * b }
}

function perimeter(r) {
  return 2 * (r.width + r.height)
}

// The point `d` px along the edge, clockwise from the top-left corner.
function pointAt(r, d) {
  var p = perimeter(r)
  if (p <= 0) return { x: r.x, y: r.y }
  d = ((d % p) + p) % p
  if (d < r.width) return { x: r.x + d, y: r.y }
  d -= r.width
  if (d < r.height) return { x: r.x + r.width, y: r.y + d }
  d -= r.height
  if (d < r.width) return { x: r.x + r.width - d, y: r.y + r.height }
  d -= r.width
  return { x: r.x, y: r.y + r.height - d }
}

// The lit stretch at progress t (0..1, already eased): PIECES short pieces
// from the tail to the head, each { a, b, alpha } with a and b points on the
// edge; brightest at the head. Nothing before it starts or once it is done.
// The head runs a full turn plus the light's length, so the tail ends where
// it began and the last frame is empty.
function lit(r, t) {
  if (!(t > 0) || t >= 1) return []
  var p = perimeter(r)
  if (p <= 0) return []
  var len = p * LENGTH
  var head = t * (p + len)
  var out = []
  for (var i = 0; i < PIECES; i++) {
    var d0 = head - len + i * len / PIECES
    var d1 = d0 + len / PIECES
    // Only the part of the run that is on the edge: not before the start,
    // not past one full turn.
    d0 = Math.max(0, d0); d1 = Math.min(p, d1)
    if (d1 <= d0) continue
    out = out.concat(split(r, d0, d1, Math.pow((i + 1) / PIECES, 1.6)))
  }
  return out
}

// A stretch of edge as straight pieces, cut at the corners it passes.
function split(r, d0, d1, alpha) {
  var corners = [0, r.width, r.width + r.height, 2 * r.width + r.height, perimeter(r)]
  var out = []
  var from = d0
  for (var k = 1; k < corners.length && from < d1; k++) {
    if (corners[k] <= from) continue
    var to = Math.min(d1, corners[k])
    out.push({ a: pointAt(r, from), b: pointAt(r, to === corners[k] && k < corners.length - 1 ? to - 1e-6 : to), alpha: alpha })
    from = to
  }
  return out
}

// A window rect in a screen's own coordinates, or null when it is on another.
function onScreen(win, screen) {
  if (!win || !screen) return null
  if (win.x + win.width <= screen.x || win.x >= screen.x + screen.width) return null
  if (win.y + win.height <= screen.y || win.y >= screen.y + screen.height) return null
  return { x: win.x - screen.x, y: win.y - screen.y, width: win.width, height: win.height }
}
