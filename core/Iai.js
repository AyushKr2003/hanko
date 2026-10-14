.pragma library

// Iai 居合 (docs/kaze/README.md §3, mockup 02): the five beats every Kaze
// surface moves on, taken from iaidō. One source for the bar (Motion.qml),
// the surface plugins and Hyprland's windows (style.lua, checked against
// this file by tests/unit.mjs).
//
//   kamae    ready       hover, focus, a held key: no movement, the ink steps up a tier
//   nuki     draw        anything opens: a held beat, a fast travel, a hard stop
//   kiri     cut         a commit: the plate inverts at once, a hairline flashes and fades
//   chiburi  shake off   after a draw or a cut: the secondary things settle in
//   noto     sheath      anything closes: slow away, into the edge, then the click
//
// No beat overshoots: a swordsman doesn't wobble. Closing (noto) is slower
// than opening (nuki). `hold` is the still beat before a move starts; `delay`
// is how long after the move it answers it begins.
var BEATS = {
  kamae:   { ms: 90,  hold: 0,  delay: 0,  curve: [0.2, 0, 0, 1],      jp: "構", name: "Kamae",   line: "Ready: hover or focus inks a thing up one tier, nothing moves" },
  nuki:    { ms: 160, hold: 30, delay: 0,  curve: [0.05, 0.9, 0.1, 1], jp: "抜", name: "Nuki",    line: "Draw: a held beat, a fast travel along one axis, a hard stop" },
  kiri:    { ms: 70,  hold: 0,  delay: 0,  curve: [0, 1, 0, 1],        jp: "斬", name: "Kiri",    line: "Cut: a commit inverts at once; a hairline flashes and fades" },
  chiburi: { ms: 220, hold: 0,  delay: 60, curve: [0.25, 0.1, 0.25, 1], jp: "振", name: "Chiburi", line: "Shake off: values and labels settle in after their plate" },
  noto:    { ms: 240, hold: 0,  delay: 0,  curve: [0.7, 0, 0.84, 0],   jp: "納", name: "Nōtō",    line: "Sheath: slow away, into the edge it came from, then the click" }
}
var ORDER = ["kamae", "nuki", "kiri", "chiburi", "noto"]

// The last frame of a sheath snaps the final pixel shut.
var SNAP_PX = 1

// A QML easing.bezierCurve list: [x1, y1, x2, y2, 1, 1].
function qml(name) {
  var c = BEATS[name].curve
  return [c[0], c[1], c[2], c[3], 1, 1]
}

// Total time a beat takes from its cause: delay + hold + travel.
function total(name) {
  var b = BEATS[name]
  return b.delay + b.hold + b.ms
}

// cubic-bezier(x1, y1, x2, y2) evaluated at progress x (0..1): the eased value.
function ease(curve, x) {
  if (x <= 0) return 0
  if (x >= 1) return 1
  var cx = 3 * curve[0], bx = 3 * (curve[2] - curve[0]) - cx, ax = 1 - cx - bx
  var cy = 3 * curve[1], by = 3 * (curve[3] - curve[1]) - cy, ay = 1 - cy - by
  var lo = 0, hi = 1, t = x
  for (var i = 0; i < 40; i++) {
    t = (lo + hi) / 2
    var xt = ((ax * t + bx) * t + cx) * t
    if (xt < x) lo = t
    else hi = t
  }
  return ((ay * t + by) * t + cy) * t
}

// Where a beat is at `ms` after its cause (0..1), counting delay and hold.
function at(name, ms) {
  var b = BEATS[name]
  return ease(b.curve, (ms - b.delay - b.hold) / b.ms)
}

// Hyprland's animation speed is in tenths of a second (style.lua).
function hyprSpeed(name) {
  return Math.round(BEATS[name].ms / 10) / 10
}
