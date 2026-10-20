.pragma library

// Taiji 対峙, the standoff (docs/kaze, mockup 09): the lock screen. Nothing
// moves but the grass. Typing draws a blade under the time, a nick for each
// key (the password itself is never drawn); a wrong password is deflected.
// plugins/hanko.lock keeps Omarchy's lock service and both PAM flows as
// they are and draws its LockView from this file.

// The blade: its hilt, then 22 px a nick, at most `max` px long.
var NICK = 22
var LEAD = 24
function bladeWidth(count, max) {
  var n = Math.max(0, count | 0)
  if (n === 0) return 0
  return Math.min(max || 640, LEAD + n * NICK + 16)
}
// The nicks' x positions along a blade of `count` keys (they stop at the
// blade's end; a long password keeps the last nick at the tip).
function nicks(count, max) {
  var n = Math.max(0, count | 0)
  var w = bladeWidth(n, max)
  var out = []
  var room = Math.max(1, Math.floor((w - LEAD - 8) / NICK) + 1)
  for (var i = Math.max(0, n - room); i < n; i++) out.push(Math.min(w - 8, LEAD + (i - Math.max(0, n - room)) * NICK))
  return out
}

// The line under the blade.
function hint(st) {
  st = st || {}
  if (st.authenticating) return { text: "Checking…", red: false }
  if (st.failure) {
    var n = Number(st.attempts) || 0
    return { text: "Not that one" + (n > 0 ? " · " + n : ""), red: true }
  }
  if (st.count > 0) return { text: st.count + (st.count === 1 ? " character" : " characters") + " · Enter to cut", red: false }
  return { text: st.fingerprint ? "Type to unlock · or touch the reader" : "Type to unlock", red: false }
}

// "Wednesday · 14 October"
var DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
function dayLine(d) {
  return DAYS[d.getDay()] + " · " + d.getDate() + " " + MONTHS[d.getMonth()]
}

// "shadow" → "Shadow": the account's name, as the corner shows it.
function nameOf(user) {
  var u = String(user || "").trim()
  return u ? u.charAt(0).toUpperCase() + u.slice(1) : ""
}

// A microseason's English with its first letter up: "chrysanthemums bloom"
// → "Chrysanthemums bloom".
function sentence(s) {
  s = String(s || "")
  return s ? s.charAt(0).toUpperCase() + s.slice(1) : ""
}

// The cut on unlock (plugins/hanko.desk): one timeline of CUT_MS. The
// hairline is on at once and fades; each half peels off from the cut as a
// page is turned in a book: one end of the cut lifts first, the sheet rolls
// round a soft curl that grows as it goes, and the curl runs out past the
// far corner (assets/shaders/curl.vert draws it). The half above lifts a
// moment before the one below.
var CUT_MS = 1000
var CUT_FLASH = { hold: 50, fade: 150 }
// each half: when it starts and how long it rolls; the curve lifts slowly,
// then the sheet goes, as a page let go of does
var CUT_CURLS = [
  { at: 40,  ms: 860 },
  { at: 110, ms: 860 }
]
var CUT_CURVE = [0.5, 0, 0.3, 1]
// one end of the cut leads by this much (radians)
var CUT_TILT = 0.16
// the curl's radius, as a share of the half's depth: tight as it lifts,
// open as it goes
var CUT_RADIUS = { from: 0.05, to: 0.16 }
function cutFlash(ms) {
  if (ms < 0) return 0
  if (ms <= CUT_FLASH.hold) return 1
  return Math.max(0, 1 - (ms - CUT_FLASH.hold) / CUT_FLASH.fade)
}
// cubic-bezier(x1, y1, x2, y2) at x (as Iai.ease, kept here so this file
// stands alone).
function cutEase(c, x) {
  if (x <= 0) return 0
  if (x >= 1) return 1
  var cx = 3 * c[0], bx = 3 * (c[2] - c[0]) - cx, ax = 1 - cx - bx
  var cy = 3 * c[1], by = 3 * (c[3] - c[1]) - cy, ay = 1 - cy - by
  var lo = 0, hi = 1, t = x
  for (var i = 0; i < 30; i++) {
    t = (lo + hi) / 2
    if (((ax * t + bx) * t + cx) * t < x) lo = t
    else hi = t
  }
  return ((ay * t + by) * t + cy) * t
}
// How far half k (0 above the cut, 1 below) has rolled at `ms`: 0 flat,
// 1 gone.
function cutRoll(k, ms) {
  var c = CUT_CURLS[k]
  return c ? cutEase(CUT_CURVE, (ms - c.at) / c.ms) : 0
}
// Where on the screen the curl is, at roll t (0..1), for a w×h screen cut
// on the diagonal from the bottom left: `fold` is the roll's axis, measured
// from the centre along the half's outward direction (tilted by `tilt`),
// `radius` the curl's. At 0 the axis touches the leading end of the cut,
// so nothing is lifted; at 1 the whole roll is past the far corner.
function cutCurl(t, w, h) {
  var hyp = Math.sqrt(w * w + h * h)
  if (!(hyp > 0)) return { fold: 0, radius: 1, tilt: CUT_TILT, start: 0 }
  var reach = w * h / hyp
  var s = Math.sin(CUT_TILT), co = Math.cos(CUT_TILT)
  var corner = reach * co + (w * w - h * h) / (2 * hyp) * s
  var start = Math.min(-hyp / 2 * s, hyp / 2 * s, corner)
  var end = Math.max(-hyp / 2 * s, hyp / 2 * s, corner)
  var e = Math.max(0, Math.min(1, t))
  var grow = 1 - (1 - e) * (1 - e)
  var radius = reach * (CUT_RADIUS.from + (CUT_RADIUS.to - CUT_RADIUS.from) * grow)
  var last = reach * CUT_RADIUS.to
  return { fold: start + (end + last * 1.2 - start) * e, radius: radius, tilt: CUT_TILT, start: start, end: end }
}
