.pragma library

// Densho 伝書, the scroll's four touches (Style.js arrival, letters, faults,
// order; docs/densho on the design-densho branch). Pure JavaScript, no QML:
// how far the brush has written a section, which sections are at fault,
// whether a move is a jump, and the words of the house and the colophon
// that open and close the scroll under order: mokuroku.

function clamp01(v) { return Math.max(0, Math.min(1, v)) }
function trim(s) { return String(s === undefined || s === null ? "" : s).replace(/^\s+|\s+$/g, "") }
function two(n) { return (n < 10 ? "0" : "") + n }

// arrival: brush. How far the brush has written a section whose middle is
// `offset` px from the middle of a view `half` px wide each side: whole in
// the middle third, nothing by the edge, so a neighbour at rest shows only
// its head and a pan writes the next one on as it comes in.
var WRITE_FULL = 0.3
var WRITE_NONE = 0.62
function writeAt(offset, half) {
  if (!(half > 0)) return 1
  var d = Math.abs(offset) / half
  return clamp01((WRITE_NONE - d) / (WRITE_NONE - WRITE_FULL))
}

// faults: seam. A section is broken while it needs mending, not only your
// attention: offline (Net.js sheet `offline`), a battery low and draining
// (Power.js sheet `low`).
function faultOf(key, feed) {
  var f = feed || {}
  if (key === "network") return !!(f.network && f.network.offline)
  if (key === "power") return !!(f.power && f.power.low)
  return false
}

// order: mokuroku. A move further than the next section cuts to a stance
// (the section's sign held alone) instead of sliding past the ones between.
var STANCE_MS = 300
function isJump(from, to) { return Math.abs(to - from) > 1 }

var ORDINALS = ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth",
  "tenth", "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth",
  "eighteenth", "nineteenth", "twentieth", "twenty-first", "twenty-second", "twenty-third",
  "twenty-fourth", "twenty-fifth", "twenty-sixth", "twenty-seventh", "twenty-eighth", "twenty-ninth",
  "thirtieth", "thirty-first"]
var MONTHS = ["January", "February", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December"]

// Lines of `key<TAB>value` (services/Leaf.qml's colophon script) -> object.
function keyValues(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var t = lines[i].indexOf("\t")
    if (t > 0) out[trim(lines[i].slice(0, t))] = trim(lines[i].slice(t + 1))
  }
  return out
}

function whoOf(kv) { return trim(kv.name) || trim(kv.user) }

// 序 The house: who keeps this desk, and its line, as a licence scroll
// opens on the school and its masters. `raw` is the colophon reading, `x`
// { version, preset }, `now` a Date. The line's points, oldest first: the
// last upgrade, the boot, now (`now: true`).
function house(raw, x, now) {
  var kv = keyValues(raw), extra = x || {}
  var who = whoOf(kv), host = trim(kv.host)
  var t = now instanceof Date ? now : new Date(now)
  var up = parseFloat(kv.uptime)
  var points = []
  if (kv.upgraded) points.push({ at: 0, label: "Upgraded", value: kv.upgraded })
  if (up > 0) {
    var boot = new Date(t.getTime() - up * 1000)
    var sameDay = boot.toDateString() === t.toDateString()
    points.push({ at: points.length ? 0.72 : 0, label: "Booted",
                  value: (sameDay ? "" : boot.getDate() + " " + MONTHS[boot.getMonth()].slice(0, 3) + " · ") + two(boot.getHours()) + ":" + two(boot.getMinutes()) })
  }
  points.push({ at: 1, label: "Now", value: two(t.getHours()) + ":" + two(t.getMinutes()), now: true })
  var booted = points.filter(function(p) { return p.label === "Booted" })[0]
  return {
    title: who ? "<i>" + who + "</i>" : "This house",
    caption: ["Hanko " + (extra.version || ""), extra.preset || "", host].map(trim).filter(function(s) { return s && s !== "Hanko" }).join(" · "),
    points: points,
    spent: booted ? 1 - booted.at : 0,
    ready: !!(who || host)
  }
}

// 奥書 The colophon: the scroll signed to you, on the day, under your preset.
function colophon(raw, x, now) {
  var kv = keyValues(raw), extra = x || {}
  var who = whoOf(kv) || "you"
  var t = now instanceof Date ? now : new Date(now)
  return {
    title: "Sealed",
    caption: "Roll up to seal it · Esc",
    lines: ["Transmitted to " + who + ",",
            "on the " + ORDINALS[t.getDate()] + " of " + MONTHS[t.getMonth()] + ",",
            "under the house of " + (trim(extra.preset).replace(/ \+ edits$/, "") || "Hanko") + "."],
    who: who
  }
}

// The seam's line, `w` x `h` px: a mend that wanders a little up and down
// across the section, as an SVG path for a Shape (the same every time).
var SEAM_STEPS = [0.6, -0.8, 0.3, 0.9, -0.4, -0.9, 0.5, 0.2, -0.6, 0.8, -0.2, 0.4]
function seamPath(w, h, step) {
  var mid = h / 2, x = 0, k = 0, s = step > 0 ? step : 26
  var d = "M 0 " + mid.toFixed(1)
  while (x < w && k < 400) {
    var a = SEAM_STEPS[k % SEAM_STEPS.length]
    x = Math.min(w, x + s + Math.abs(a) * s * 1.4)
    d += " L " + x.toFixed(1) + " " + (mid + a * h * 0.32).toFixed(1)
    k++
  }
  return d
}
