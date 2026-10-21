.pragma library

// The right zone's plain data (docs/COMPONENTS.md, "Right: how things are").
// services/Status.qml gathers the raw readings; this file turns them into the
// shape the bar draws, so the rules can be tested without a running shell.

// A battery at or under this, and draining, needs you.
var LOW_BATTERY = 15

function clamp01(v) {
  v = Number(v)
  if (!isFinite(v)) return 0
  return Math.max(0, Math.min(1, v))
}

// How many of `count` ticks a 0..1 level lights. Anything above zero lights
// at least one, so a quiet 3 % still shows.
function ticks(level, count) {
  var l = clamp01(level)
  if (l <= 0) return 0
  return Math.max(1, Math.min(count, Math.round(l * count)))
}

// Wi-Fi signal (0..100) as 0..4 bars.
function bars(signal) {
  var s = Number(signal)
  if (!isFinite(s) || s <= 0) return 0
  if (s >= 75) return 4
  if (s >= 50) return 3
  if (s >= 25) return 2
  return 1
}

// One line of `omarchy-network-status`: kind \t name \t signal \t freq.
function network(line) {
  var f = String(line || "").replace(/\n+$/, "").split("\t")
  var kind = f[0] || ""
  if (kind === "wifi") {
    var signal = Number(f[2])
    return { kind: "wifi", name: f[1] || "Wi-Fi", signal: isFinite(signal) ? signal : 0,
             freq: Number(f[3]) || 0, bars: bars(signal), off: false, needsYou: false }
  }
  if (kind === "ethernet")
    return { kind: "ethernet", name: "Wired", signal: 100, bars: 4, off: false, needsYou: false }
  return { kind: "disconnected", name: "Offline", signal: 0, bars: 0, off: true, needsYou: true }
}

// Pipewire sink volume (0..1+, may exceed 1) and mute.
function volume(level, muted, present) {
  if (present === false) return null
  var pct = Math.round(Math.max(0, Number(level) || 0) * 100)
  return { percent: pct, level: clamp01(pct / 100), muted: !!muted, needsYou: !!muted }
}

// UPower display device: percent 0..100, charging, present.
function battery(percent, charging, present) {
  if (!present) return null
  var pct = Math.round(Math.max(0, Math.min(100, Number(percent) || 0)))
  return { percent: pct, level: pct / 100, charging: !!charging,
           needsYou: !charging && pct <= LOW_BATTERY }
}

// One line of `brightnessctl -m`: device,class,current,percent%,max.
function brightness(line) {
  var f = String(line || "").trim().split(",")
  if (f.length < 4) return null
  var pct = parseInt(f[3], 10)
  if (!isFinite(pct)) return null
  return { percent: pct, level: clamp01(pct / 100), needsYou: false }
}

// Notification stamps get the app's initial; a few apps get a kanji instead,
// the way a seal carves a name.
var STAMP_KANJI = { firefox: "火", "zen": "禅", "librewolf": "狼", "signal": "信", "spotify": "音" }

function stampGlyph(app) {
  var a = String(app || "").trim()
  if (a === "") return "・"
  var k = STAMP_KANJI[a.toLowerCase()]
  if (k) return k
  var ch = a.charAt(0)
  return /[a-z]/i.test(ch) ? ch.toUpperCase() : ch
}

// A small, steady tilt per stamp: the same notification never jumps.
function tilt(key) {
  var s = String(key || ""), h = 0
  for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0
  return ((Math.abs(h) % 9) - 4) * 1.5   // -6 .. 6 degrees in 1.5° steps
}

// The persisted popup and history files Omarchy's notification service
// writes (~/.local/state/omarchy/notifications{,/history}/*.json), one JSON
// object per line. Newest first.
function notifications(raw) {
  var out = []
  var seen = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line === "") continue
    var e
    try { e = JSON.parse(line) } catch (err) { continue }
    if (!e || typeof e !== "object") continue
    var app = String(e.app || e.appName || "")
    var stamp = Number(e.timestamp || 0)
    // A live toast and its history copy are one notification (Omarchy keys
    // them by timestamp and original id).
    var key = stamp + "-" + (e.originalId || e.id || "") + "-" + (e.summary || "")
    if (seen[key]) continue
    seen[key] = true
    // stem: the name Omarchy files it under (timestamp-originalId), live
    // or in the history, which is how one letter is put away.
    out.push({ app: app, summary: String(e.summary || ""), body: String(e.body || ""), timestamp: stamp,
               stem: stamp + "-" + (e.originalId || e.id || 0), urgent: Number(e.urgency) === 2,
               glyph: stampGlyph(app), tilt: tilt(app + stamp + (e.summary || "")) })
  }
  out.sort(function(a, b) { return b.timestamp - a.timestamp })
  return out
}

// The letters left once the ones put away (a map of stems) are taken out.
function without(letters, gone) {
  return (letters || []).filter(function(l) { return !(gone && gone[l.stem]) })
}

// "now", "12m", "3h", "2d": how long ago a notification came in.
function age(timestamp, now) {
  var mins = Math.floor((Number(now) - Number(timestamp)) / 60000)
  if (!(mins >= 1)) return "now"
  if (mins < 60) return mins + "m"
  if (mins < 24 * 60) return Math.floor(mins / 60) + "h"
  return Math.floor(mins / 1440) + "d"
}

// "03": counts are always two digits, like a folio.
function count2(n) {
  n = Math.max(0, Math.round(Number(n) || 0))
  return n > 99 ? "99" : (n < 10 ? "0" : "") + n
}

// A name cut to what a glance needs, for the narrow right-side styles (ma,
// shizuka, suji, inro): a short all-caps brand in front is dropped (OPPO
// Enco Buds2 → Enco Buds2), then the first word is kept, with the next
// one when the first is too short to tell apart (Enco → Enco Buds2).
// Infinix NOTE 50S 5G → Infinix. The full name stays in the sheet.
function short(name) {
  var words = String(name === undefined || name === null ? "" : name).trim().split(/\s+/).filter(function(w) { return w !== "" })
  if (!words.length) return ""
  if (words.length > 1 && /^[A-Z]{2,5}$/.test(words[0])) words = words.slice(1)
  var out = words[0]
  if (out.length < 5 && words.length > 1) out += " " + words[1]
  return out.length > 14 ? out.slice(0, 13) + "…" : out
}

// How full a reading is, 0..1, for the styles that draw every reading as a
// level (suji's line): network by its bars (wired is full, offline empty),
// Bluetooth by the device's charge (full when it has none to tell, empty
// when off or nothing is connected), volume empty when muted.
function fill(key, src) {
  var s = src || {}
  if (key === "network") return s.off ? 0 : s.kind === "wifi" ? clamp01((s.bars || 0) / 4) : 1
  if (key === "bluetooth") return !s.enabled || !(s.connected > 0) ? 0 : s.level >= 0 ? clamp01(s.level) : 1
  if (key === "volume") return s.muted ? 0 : clamp01(s.level)
  return clamp01(s.level)
}
