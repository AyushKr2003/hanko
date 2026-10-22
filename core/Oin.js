.pragma library

// Ōin 押印, the boot screen (docs/kaze §4.1), for Settings › Boot: the
// layout scripts/hanko-boot draws and assets/boot/hanko.script places (the
// same numbers; tests/unit.mjs holds the three together), the hint under
// the hairline, the moments the page shows, one boot as a timeline to play,
// and whether the installed screen is out of date.

// 1080 px tall is 1.
var LAYOUT = {
  seal: 128,      // the seal, square
  sealAt: 0.42,   // its middle, as a share of the screen's height
  ruleGap: 64,    // from the seal's foot to the hairline
  rule: 360,      // the hairline's length
  hintGap: 20,    // from the hairline to the hint's top
  nick: 22,       // a nick every 22 px after the lead (core/Taiji.js)
  lead: 24,
  nickH: 7,
  hiltH: 15,
  corner: 64,     // the corner name's margin from the right and the foot
  // The brush mark, laid out as the shutdown ceremony is (plugins/hanko.osd)
  brush: 432,     // the kanji's box
  brushAt: 0.42,  // its middle
  brushGap: 60,   // from the kanji to the words
  brushRuleGap: 56,
  brushFrames: 20,
  stamp: 74,      // the seal pressed beside the last stroke
  wordsGap: 18
}

// The blade for `count` keys: its length and the nicks' x, as the script
// draws them (a long passphrase keeps the newest nicks at the tip).
function bladeWidth(count) {
  var n = Math.max(0, count | 0)
  return n === 0 ? 0 : Math.min(LAYOUT.rule, LAYOUT.lead + n * LAYOUT.nick + 16)
}
function nicks(count) {
  var n = Math.max(0, count | 0), w = bladeWidth(n), out = []
  if (n === 0) return out
  var room = Math.floor((w - LAYOUT.lead - 8) / LAYOUT.nick) + 1
  var shown = Math.min(n, room)
  for (var i = 0; i < shown; i++) out.push(Math.min(w - 8, LAYOUT.lead + i * LAYOUT.nick))
  return out
}

// The hint's picture (hint-*.png in the theme) for a moment, or "".
function hint(state, count, failed) {
  if (state === "checking") return "hint-check"
  if (state === "wrong") return "hint-wrong-" + Math.max(1, Math.min(9, failed || 1))
  if (state === "password") return count > 0 ? "hint-enter" : "hint-type"
  return ""
}

// The moments the page can hold still.
var MOMENTS = [
  { key: "asked", label: "Asked" },
  { key: "typing", label: "Typing" },
  { key: "wrong", label: "Wrong" },
  { key: "booting", label: "Booting" },
  { key: "shutdown", label: "Shutdown" }
]
// What the screen shows in each: { state, count, progress, press (0..1),
// failed }.
function moment(key) {
  switch (key) {
    case "typing": return { state: "password", count: 7, progress: 0, press: 1, failed: 0 }
    case "wrong": return { state: "wrong", count: 7, progress: 0, press: 1, failed: 1 }
    case "booting": return { state: "booting", count: 0, progress: 0.46, press: 1, failed: 0 }
    case "shutdown": return { state: "shutdown", count: 0, progress: 0, press: 1, failed: 0 }
    default: return { state: "password", count: 0, progress: 0, press: 1, failed: 0 }
  }
}

// One encrypted boot, ms from the start: the paper comes up, the seal is
// pressed (or the brush writes, 800 ms, then its seal and words), the
// prompt; a wrong passphrase, then the right one, then the boot's progress.
// The script's beats are frames at 50 a second.
var STORY_MS = 9400
function story(ms) {
  var t = Math.max(0, ms)
  var paper = Math.min(1, t / 300)
  var press = Math.max(0, Math.min(1, (t - 240) / 320))
  var write = Math.max(0, Math.min(1, (t - 240) / 800))
  var after = Math.max(0, Math.min(1, (t - 1040) / 220))
  var o = { state: "password", count: 0, progress: 0, press: press, write: write, after: after, paper: paper, failed: 0 }
  if (t < 1100) { o.state = "still"; return o }
  if (t < 1400) return o
  if (t < 2800) { o.count = Math.min(6, Math.floor((t - 1400) / 220) + 1); return o }
  if (t < 3400) { o.state = "checking"; o.count = 6; return o }
  if (t < 4400) { o.state = "wrong"; o.count = 6; o.failed = 1; o.fade = Math.min(1, (t - 3400) / 320); return o }
  if (t < 5800) { o.failed = 1; o.count = Math.min(5, Math.floor((t - 4400) / 220) + 1); return o }
  if (t < 6400) { o.state = "checking"; o.count = 5; o.failed = 1; return o }
  o.state = "booting"
  var r = Math.min(1, (t - 6400) / (STORY_MS - 6400))
  o.progress = 0.7 * (1 - (1 - r) * (1 - r))
  return o
}

// Why the installed screen no longer matches what it would be drawn as now
// ("" when it does): the theme, the seal, or a choice on the page.
// `drawn` is what `hanko boot on` kept (boot-drawn.json), `now` the same
// fields as they are; `pretty` turns a theme's folder name into its name.
function stale(drawn, now, pretty) {
  if (!drawn || !drawn.theme) return ""
  now = now || {}
  var p = pretty || function(s) { return s }
  if (now.theme && drawn.theme !== now.theme) return "Drawn for " + p(drawn.theme) + "; your theme is " + p(now.theme) + " now"
  if (now.glyph && drawn.glyph && drawn.glyph !== now.glyph) return "Drawn with " + drawn.glyph + "; your seal is " + now.glyph + " now"
  if (now.name && drawn.name && drawn.name !== now.name) return "The corner changed since it was drawn"
  if (now.press && drawn.press && drawn.press !== now.press) return "The press changed since it was drawn"
  if (now.mark && (drawn.mark || "seal") !== now.mark) return "Drawn with the " + (drawn.mark || "seal") + "; the mark is the " + now.mark + " now"
  return ""
}

// "22 October" from an ISO date, for "drawn for Hanko on 22 October".
var MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
function day(iso) {
  var d = new Date(iso)
  return isNaN(d.getTime()) ? "" : d.getDate() + " " + MONTHS[d.getMonth()]
}
