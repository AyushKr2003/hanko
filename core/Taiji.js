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

// The cut on unlock (plugins/hanko.desk): one timeline of CUT_MS, so the
// halves roll out from the cut in one motion rather than three. The
// hairline is on at once and fades; each half's three folds start a
// little after one another and overlap, so a strip is still turning while
// the next crease lifts.
var CUT_MS = 900
var CUT_FLASH = { hold: 50, fade: 150 }
// fold k (1..3): when it starts, how long it turns, on what curve. The
// first two land on the next strip, so they settle; the last is gone past
// the corner once edge-on, so it gathers speed and goes, as a sheath does.
var CUT_FOLDS = [
  { at: 60,  ms: 500, curve: [0.4, 0, 0.2, 1] },
  { at: 230, ms: 500, curve: [0.4, 0, 0.2, 1] },
  { at: 420, ms: 480, curve: [0.55, 0, 0.85, 0.45] }
]
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
function cutFold(k, ms) {
  var f = CUT_FOLDS[k - 1]
  return f ? cutEase(f.curve, (ms - f.at) / f.ms) : 0
}
