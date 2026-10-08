.pragma library

// Shōji's ink: a brush stroke (pressed head, thinning body, dry tail) and an
// ensō (one brush circle that closes as it fills), as SVG path strings for
// QtQuick.Shapes' PathSvg. Deterministic: the same seed draws the same
// stroke, so a value change re-paths and nothing else moves.

function rng(seed) {
  var s = seed % 2147483647
  if (s <= 0) s += 2147483646
  return function() { s = (s * 16807) % 2147483647; return s / 2147483647 }
}

// Smooth 1D value noise in [0, 1).
function noise(seed) {
  var r = rng(seed)
  var p = []
  for (var i = 0; i < 256; i++) p.push(r())
  return function(x) {
    var i0 = Math.floor(x), f = x - i0, u = f * f * (3 - 2 * f)
    return p[i0 & 255] * (1 - u) + p[(i0 + 1) & 255] * u
  }
}

function f1(v) { return Math.round(v * 10) / 10 }

// A stroke w long and h thick, starting at x = 0; the tail reaches w + h * 0.45.
function stroke(w, h, seed) {
  w = Math.max(1, w)
  var n = noise(seed === undefined ? 3 : seed)
  var top = [], bot = []
  var step = Math.max(1, w / 90)
  for (var x = 0; x <= w + 0.001; x += step) {
    var u = x / w
    var head = Math.min(1, Math.sqrt(x / (h * 0.9))) * (1 + 0.18 * Math.exp(-x / h))
    var tail = 1 - Math.pow(u, 2.4) * 0.78
    var t = h / 2 * head * tail * (0.88 + 0.24 * n(u * 7 + 2))
    var cy = h / 2 + (n(u * 2.5 + 9) - 0.5) * h * 0.18
    top.push([x, cy - t]); bot.push([x, cy + t * 0.86])
  }
  var p = function(q) { return f1(q[0]) + " " + f1(q[1]) }
  var d = "M " + p(bot[0]) + " Q " + f1(-h * 0.35) + " " + f1(h / 2) + " " + p(top[0])
  for (var i = 0; i < top.length; i++) d += " L " + p(top[i])
  d += " L " + f1(w + h * 0.45) + " " + f1(h / 2)
  for (var j = bot.length - 1; j >= 0; j--) d += " L " + p(bot[j])
  return d + " Z"
}

// Dry-brush streaks across the tail, to draw in the paper's colour:
// [{ x0, x1, y, width }].
function kasure(w, h, seed) {
  var out = []
  if (w <= 40) return out
  var r = rng((seed === undefined ? 3 : seed) + 7)
  for (var i = 0; i < 4; i++)
    out.push({ x0: f1(w * (0.55 + r() * 0.25)), x1: f1(w + h * 0.4), y: f1(h * (0.3 + r() * 0.45)), width: f1(0.5 + r() * 0.7) })
  return out
}

// An ensō in a size × size box, open by what is left of v (0..1): the
// brush lands heavy, swells, and lifts away dry.
function enso(v, size, width, seed) {
  var c = size / 2
  width = width === undefined ? size * 0.1 : width
  var R = size / 2 - width * 0.75
  var n = noise(seed === undefined ? 8 : seed)
  var a0 = -Math.PI * 0.62
  var sweep = Math.max(0.02, Math.min(1, v)) * Math.PI * 1.9
  var out = [], inn = []
  for (var i = 0; i <= 120; i++) {
    var u = i / 120, a = a0 + sweep * u
    var w = width * Math.min(1, u * 7) * (1 + 0.35 * Math.exp(-u * 10)) * (1 - Math.pow(u, 2.2) * 0.8) * (0.7 + 0.55 * n(u * 5 + 1))
    var rr = R + (n(u * 4 + 7) - 0.5) * width * 0.35
    out.push([c + Math.cos(a) * (rr + w / 2), c + Math.sin(a) * (rr + w / 2)])
    inn.push([c + Math.cos(a) * (rr - w / 2), c + Math.sin(a) * (rr - w / 2)])
  }
  var p = function(q) { return f1(q[0]) + " " + f1(q[1]) }
  var d = "M " + p(out[0])
  for (var j = 1; j < out.length; j++) d += " L " + p(out[j])
  for (var k = inn.length - 1; k >= 0; k--) d += " L " + p(inn[k])
  return d + " Z"
}
