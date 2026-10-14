.pragma library

// Kaze 風, the living layer (docs/kaze, mockup 04): grass along the foot of
// the print that leans with the real wind, and a gust that runs through it
// toward something that needs you. Pure geometry; plugins/hanko.background
// draws it.

// Wind speed (km/h) at which the grass leans its full way.
var FULL = 40
// The most the grass leans (a storm), and the least a felt wind leans it.
var MAX_LEAN = 1.4
var MIN_FELT = 0.35
// A gust: how long it takes to cross to its target, and how hard it pushes.
var GUST_MS = 600
var GUST_WIDTH = 0.08     // of the layer's width
var GUST_STRENGTH = 1.2

// The lean for a wind of `speed` km/h blowing from `fromDeg` (meteorological:
// 270 is a wind from the west, blowing east, so the grass leans right).
// A wind from the north or south still leans the grass, by the sign of its
// small east-west part, but never less than MIN_FELT of its strength.
function lean(speed, fromDeg) {
  var v = Number(speed), d = Number(fromDeg)
  if (!(v > 0)) return 0
  var east = -Math.sin(d * Math.PI / 180)
  if (!isFinite(east)) east = 0
  var size = Math.min(MAX_LEAN, v / FULL) * (MIN_FELT + (1 - MIN_FELT) * Math.abs(east))
  return Math.round((east < 0 ? -size : size) * 1000) / 1000
}

// A small seeded random, so the field is the same on every start.
function rng(seed) {
  var s = (seed >>> 0) || 1
  return function() {
    s = (Math.imul ? Math.imul(s, 1664525) : (s * 1664525) | 0) + 1013904223 >>> 0
    return s / 4294967296
  }
}

// The field: clumps of 3–8 blades fanning from one root, with now and then
// a gap (ma), and a few pampas plumes. Each blade:
//   { x, len, rest, w, alpha, plume }  (len in px; rest = its own angle, rad)
function field(width, height, seed) {
  var r = rng(seed || 7)
  var out = []
  var x = r() * 30
  while (x < width) {
    var n = 3 + Math.floor(r() * 6), tall = 0.45 + r() * 0.55
    for (var k = 0; k < n; k++) {
      out.push({
        x: x + (r() - 0.5) * 10,
        len: height * tall * (0.45 + r() * 0.55),
        rest: (k / (n - 1 || 1) - 0.5) * 0.7 + (r() - 0.5) * 0.15,
        w: 0.9 + r() * 1.6,
        alpha: 0.4 + r() * 0.6,
        plume: k === 1 && r() < 0.28,
        jitter: 0.75 + r() * 0.5
      })
    }
    x += 10 + r() * 34 + (r() < 0.18 ? 60 + r() * 120 : 0)
  }
  return out
}

// How far a gust at progress t (0..1) has come, as a share of the width,
// running from the far side toward `target` (0..1). `scale` softens it (the
// wind's own puffs are gentler than a gust toward something that needs you).
function gustAt(t, target, scale) {
  if (!(t > 0) || t >= 1) return null
  var from = target > 0.5 ? 0 : 1
  var k = scale === undefined ? 1 : scale
  return { x: from + (target - from) * t, width: GUST_WIDTH, strength: k * GUST_STRENGTH * Math.sin(Math.PI * Math.min(1, t * 1.15)) }
}

// The ripple: in a felt wind the grass doesn't hold one lean, it waves, and
// the wave runs downwind across the field. `t` in seconds, `x` the blade's
// share of the width. Stronger and quicker as the wind rises; none in calm.
function ripple(windLean, t, x) {
  var a = Math.abs(windLean)
  if (a < 0.15) return 0
  var s = windLean < 0 ? -1 : 1
  var f = 0.3 + 0.4 * Math.min(1, a)            // Hz
  var amp = 0.05 + 0.11 * Math.min(1, a)        // rad, at the blade's root
  var p = 2 * Math.PI * (f * t - s * x * 2.6)
  return s * amp * (0.65 * Math.sin(p) + 0.35 * Math.sin(1.7 * p + 1.3))
}

// The same wave for the grass shader (assets/shaders/grass.frag): the tips'
// furthest shift as a share of the width, its frequency and its side.
// The shift is the ripple's angle carried up a tall blade (1.2 × height).
function rippleUniforms(windLean, height, width) {
  var a = Math.abs(windLean)
  if (a < 0.15 || !(width > 0)) return { amp: 0, freq: 0, dir: 1 }
  return {
    amp: (0.05 + 0.11 * Math.min(1, a)) * height * 1.2 / width,
    freq: 0.3 + 0.4 * Math.min(1, a),
    dir: windLean < 0 ? -1 : 1
  }
}

// How long until the wind's next puff (ms), for a random r in 0..1; 0 when
// the wind is too light to puff. Every 3–12 s, more often as it rises.
function puffAfter(windLean, r) {
  var a = Math.abs(windLean)
  if (a < 0.5) return 0
  return Math.round(3000 + r * (9000 - 6000 * Math.min(1, (a - 0.5) / 0.9)))
}

// One blade's shape for a lean, a sway (a small extra lean, or the ripple) and a gust
// ({ x, width, strength } in shares of `width`, or null):
//   { root: [x, y], ctrl: [x, y], tip: [x, y], w, alpha, plume: [[x0,y0,x1,y1], …] }
function blade(b, height, width, windLean, sway, gust) {
  // `sway` is a number, or { t } for the ripple at time t (per blade).
  var sw = sway && typeof sway === "object" ? ripple(windLean, sway.t, b.x / width) : (sway || 0)
  var l = windLean * b.jitter + sw
  if (gust) {
    var d = (b.x / width - gust.x) / gust.width
    l += gust.strength * Math.exp(-d * d * 2)
  }
  var ang = Math.max(-1.35, Math.min(1.35, b.rest + l * (0.55 + b.len / height * 0.6)))
  var tip = [b.x + Math.sin(ang) * b.len, height - Math.cos(ang) * b.len]
  var ctrl = [b.x + Math.sin(ang * 0.35) * b.len * 0.55, height - Math.cos(ang * 0.35) * b.len * 0.55]
  var plume = []
  if (b.plume) {
    for (var k = 0; k < 7; k++) {
      var t = k / 6
      var px = tip[0] - Math.sin(ang) * t * 26, py = tip[1] + Math.cos(ang) * t * 26
      var fl = 7 + (k * 37 % 6), fa = ang + 0.5 + (k % 3) * 0.13
      plume.push([px, py, px + Math.sin(fa) * fl, py - Math.cos(fa) * fl * 0.4 + fl * 0.5])
    }
  }
  return { root: [b.x, height], ctrl: ctrl, tip: tip, w: b.w, alpha: b.alpha, plume: plume }
}

// Whether the grass may move now: never under a fullscreen window, never
// with motion still, not on battery below 30%.
function mayMove(still, fullscreen, onBattery, percent) {
  if (still || fullscreen) return false
  if (onBattery && Number(percent) < 0.3) return false
  return true
}

// The sway on a windy day: a slow nudge, ±4% of the lean's size, at `tick`.
function swayAt(windLean, tick) {
  if (Math.abs(windLean) < 0.15) return 0
  return Math.sin(tick * 0.9) * 0.04 * Math.max(1, Math.abs(windLean) * 2)
}

// A virtual wind (`wind: "virtual"`): your own speed, 0 to VIRTUAL_MAX km/h,
// blowing from the west (leaning right) or the east (leaning left).
var VIRTUAL_MAX = 60
var VIRTUAL_SPEED = 15

// The few settings Kaze keeps for the wind, from ~/.config/hanko/kaze.json.
function settings(doc) {
  doc = doc || {}
  var speed = Number(doc.windSpeed)
  return {
    grass: ["grass", "edge", "off"].indexOf(doc.grass) >= 0 ? doc.grass : "grass",
    gusts: doc.gusts !== false,
    wind: doc.wind === "calm" || doc.wind === "virtual" ? doc.wind : "weather",
    speed: isFinite(speed) && doc.windSpeed !== null && doc.windSpeed !== "" ? Math.max(0, Math.min(VIRTUAL_MAX, Math.round(speed))) : VIRTUAL_SPEED,
    from: doc.windFrom === "east" ? "east" : "west"
  }
}

// The lean of the virtual wind, as a real wind of that speed and side.
function virtualLean(s) {
  return lean(s.speed, s.from === "east" ? 90 : 270)
}
