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
