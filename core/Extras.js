.pragma library

// Hanko's own small marks for what Omarchy shows as widgets (docs/ROADMAP.md,
// Phase 9): the indicators as kanji, the keyboard layout as a mono code, the
// microphone, and the tray. Plain data only; services/Extras.qml reads the
// machine, bar/Marks.qml draws.

// Indicator marks, in the order they sit. Red means "you" or "now": only a
// recording and live dictation are red.
var INDICATORS = [
  { key: "recording", glyph: "録", title: "Screen recording", red: true },
  { key: "dictation", glyph: "書", title: "Dictation", red: true },
  { key: "reminder",  glyph: "鈴", title: "Reminder", red: false },
  { key: "awake",     glyph: "醒", title: "Stay awake", red: false },
  { key: "night",     glyph: "夜", title: "Night light", red: false }
]

// The marks to show for a state { recording, dictation: "recording" |
// "transcribing" | "idle", reminders: n, awake, night }: only what is on.
function indicators(state) {
  var s = state || {}
  var out = []
  for (var i = 0; i < INDICATORS.length; i++) {
    var d = INDICATORS[i]
    var on = d.key === "dictation" ? (s.dictation === "recording" || s.dictation === "transcribing")
      : d.key === "reminder" ? Number(s.reminders) > 0
      : !!s[d.key]
    if (!on) continue
    out.push({ key: d.key, glyph: d.glyph, title: d.title,
               // Transcribing is work in progress, not "now": dim, not red.
               red: d.red && !(d.key === "dictation" && s.dictation === "transcribing"),
               count: d.key === "reminder" ? Number(s.reminders) : 0 })
  }
  return out
}

// Waybar-style module output (the last line is JSON) -> object, like
// Omarchy's Util.parseModuleJson.
function moduleJson(raw) {
  var text = String(raw || "").trim()
  if (!text) return {}
  var lines = text.split("\n")
  try { return JSON.parse(lines[lines.length - 1]) } catch (e) { return { text: text } }
}

// `hyprctl -j devices` -> { label: "US", count, keyboard } for the main
// keyboard (or the first real one): its layouts and which is active. A
// single layout has nothing to switch, so count tells the bar whether to
// show it at all.
function keyboard(json) {
  var d
  try { d = typeof json === "string" ? JSON.parse(json) : json } catch (e) { return null }
  var kbs = d && Array.isArray(d.keyboards) ? d.keyboards : []
  var k = null
  for (var i = 0; i < kbs.length; i++) if (kbs[i].main) { k = kbs[i]; break }
  if (!k) for (var j = 0; j < kbs.length; j++)
    if (!/power|button|video|virtual|consumer|system/i.test(kbs[j].name || "")) { k = kbs[j]; break }
  if (!k) return null
  var layouts = String(k.layout || "").split(",").map(function(s) { return s.trim() }).filter(function(s) { return s })
  var at = Number(k.active_layout_index)
  var code = layouts[at >= 0 && at < layouts.length ? at : 0] || ""
  if (!code) code = String(k.active_keymap || "").slice(0, 2)
  return { label: code.toUpperCase().slice(0, 3), count: layouts.length, keyboard: String(k.name || ""),
           keymap: String(k.active_keymap || "") }
}

// Tray items as plain rows: { id, title, icon, symbolic, letter }. letter is
// what Hanko prints when an item has no icon it can ink.
function tray(items) {
  var out = []
  for (var i = 0; i < (items || []).length; i++) {
    var t = items[i]
    if (!t) continue
    var title = String(t.tooltipTitle || t.title || t.id || "")
    var icon = String(t.icon || "")
    out.push({ id: String(t.id || i), title: title, icon: icon,
               symbolic: icon.split("?")[0].slice(-9) === "-symbolic",
               letter: (title.charAt(0) || "·").toUpperCase() })
  }
  return out
}
