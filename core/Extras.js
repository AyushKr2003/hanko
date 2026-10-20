.pragma library

// Hanko's own small marks for what Omarchy shows as widgets (docs/ROADMAP.md,
// Phase 9): the indicators as kanji, the keyboard layout as a mono code, the
// microphone, and the tray. Plain data only; services/Extras.qml reads the
// machine, bar/Marks.qml draws.

// Indicator marks, in the order they sit: each a stamp with the same icon
// Omarchy's bar uses (Nerd Font, so it reads without knowing the kanji),
// the kanji kept for the settings and the stamp's name. Red means "you" or
// "now": only a recording and live dictation are red. The kanji are the
// plainest that say it, so a stamp stays clean at 1x: 写 recording, 言
// dictation, 予 reminder, 目 stay awake, 月 night light, 休 do not disturb.
var INDICATORS = [
  { key: "recording", glyph: "写", icon: "\u{f0ec2}", title: "Screen recording", red: true },
  { key: "dictation", glyph: "言", icon: "\u{f036c}", title: "Dictation", red: true },
  { key: "reminder",  glyph: "予", icon: "\u{f088c}", title: "Reminder", red: false },
  { key: "awake",     glyph: "目", icon: "\u{f0176}", title: "Stay awake", red: false },
  { key: "night",     glyph: "月", icon: "\u{f050e}", title: "Night light", red: false },
  { key: "dnd",       glyph: "休", icon: "\u{f009b}", title: "Do not disturb", red: false }
]
// Dictation at work on what it heard: an hourglass instead of the mic.
var TRANSCRIBING_ICON = "\u{f051f}"

// The marks for a state { recording, dictation: "recording" |
// "transcribing" | "idle", reminders: n, awake, night, dnd }: only what is
// on, or with `all` every one, those that are off marked on: false (the
// bar shows them as faint outlines, to switch on).
function indicators(state, all) {
  var s = state || {}
  var out = []
  for (var i = 0; i < INDICATORS.length; i++) {
    var d = INDICATORS[i]
    var on = d.key === "dictation" ? (s.dictation === "recording" || s.dictation === "transcribing")
      : d.key === "reminder" ? Number(s.reminders) > 0
      : !!s[d.key]
    if (!on && !all) continue
    var transcribing = d.key === "dictation" && s.dictation === "transcribing"
    out.push({ key: d.key, glyph: d.glyph, title: d.title, on: on,
               icon: transcribing ? TRANSCRIBING_ICON : d.icon,
               // Transcribing is work in progress, not "now": dim, not red.
               red: on && d.red && !transcribing,
               count: d.key === "reminder" && on ? Number(s.reminders) : 0 })
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

// Tray items registered by Ayatana's appindicator (Steam, most GTK apps)
// have no Activate method, only a menu, so a click opens the menu, as
// KDE's tray does. Quickshell doesn't give an item's DBus path, so they are
// read from the watcher's list (`busctl ... RegisteredStatusNotifierItems`:
// `as 2 ":1.127/org/ayatana/NotificationItem/steam" ...`), whose last part
// is the item's id with anything but letters, digits and _ made _.
function menuOnlyIds(text) {
  var out = []
  var re = /\/org\/ayatana\/NotificationItem\/([A-Za-z0-9_]+)/g
  var m
  while ((m = re.exec(String(text || ""))) !== null) if (out.indexOf(m[1]) < 0) out.push(m[1])
  return out
}
function pathId(id) {
  return String(id || "").replace(/[^A-Za-z0-9_]/g, "_")
}

// A tray menu entry's label as Hanko prints it: DBus menus mark the access
// key with an underscore ("_Quit"), and "__" stands for a real one.
function menuText(text) {
  return String(text || "").replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_")
}
