.pragma library

// The sixteen typesetting settings, the presets, and how a style document
// resolves into the one flat object the bar reads. Pure JavaScript with no
// QML or Quickshell dependency, so tests/unit.mjs can run it under Node.
// docs/COMPONENTS.md is the spec for every option below.

var OPTIONS = {
  seal:     ["stamp", "workspace", "none"],
  spaces:   ["folio", "layout", "kanji", "dots"],
  title:    ["cell", "byline", "none"],
  clock:    ["stacked", "inline", "mono"],
  clockAt:  ["center", "right"],
  media:    ["cell", "underline", "none"],
  status:   ["cells", "glyphs", "numerals"],
  meters:   ["ticks", "off"],
  notif:    ["count", "stamps"],
  // A BT 藍 cell for Bluetooth (only where there is an adapter).
  bluetooth: ["on", "off"],
  edge:     ["hairline", "dayrule", "rod", "rodrule"],
  rules:    ["on", "off"],
  height:   [32, 36, 40, 44],
  surface:  ["solid", "glass", "inset"],
  position: ["top", "bottom"],
  panels:   ["sheets", "scroll"]
}

var KEYS = Object.keys(OPTIONS)

var PRESETS = {
  Sheet:      { seal: "stamp", spaces: "folio", title: "cell", clock: "stacked", clockAt: "center", media: "cell", status: "cells", meters: "ticks", notif: "count", bluetooth: "on", edge: "dayrule", rules: "on", height: 36, surface: "solid", position: "top", panels: "sheets" },
  Scroll:     { seal: "workspace", spaces: "layout", title: "byline", clock: "inline", clockAt: "center", media: "underline", status: "glyphs", meters: "off", notif: "stamps", bluetooth: "on", edge: "rod", rules: "off", height: 40, surface: "solid", position: "top", panels: "scroll" },
  Hanko:      { seal: "workspace", spaces: "layout", title: "byline", clock: "stacked", clockAt: "center", media: "underline", status: "cells", meters: "ticks", notif: "stamps", bluetooth: "on", edge: "rodrule", rules: "on", height: 40, surface: "solid", position: "top", panels: "scroll" },
  Quiet:      { seal: "stamp", spaces: "dots", title: "none", clock: "inline", clockAt: "center", media: "none", status: "numerals", meters: "off", notif: "count", bluetooth: "off", edge: "hairline", rules: "off", height: 32, surface: "glass", position: "top", panels: "sheets" },
  Instrument: { seal: "stamp", spaces: "kanji", title: "cell", clock: "mono", clockAt: "right", media: "cell", status: "cells", meters: "ticks", notif: "count", bluetooth: "on", edge: "dayrule", rules: "on", height: 44, surface: "solid", position: "top", panels: "sheets" },
  Islet:      { seal: "workspace", spaces: "kanji", title: "byline", clock: "inline", clockAt: "center", media: "underline", status: "glyphs", meters: "ticks", notif: "stamps", bluetooth: "on", edge: "rodrule", rules: "off", height: 36, surface: "inset", position: "top", panels: "scroll" }
}

var PRESET_NAMES = ["Sheet", "Scroll", "Hanko", "Quiet", "Instrument", "Islet"]
var DEFAULT_PRESET = "Hanko"
var DEFAULT_SEAL_GLYPH = "印"

// Motion 動 sits outside the sixteen settings (no preset sets it and it is
// not counted): paper moves like paper, still cuts every transition to its
// end frame. Omarchy's own reduced motion makes Hanko still as well.
var MOTIONS = ["paper", "still"]
var DEFAULT_MOTION = "paper"

function normalizeMotion(m) {
  return MOTIONS.indexOf(String(m)) >= 0 ? String(m) : DEFAULT_MOTION
}

// Parts of the bar you have hidden (style.json `hidden`, the Widgets 部品
// page), beside the sixteen like the seal glyph: no preset sets them and a
// reset keeps them. A part is a name the bar knows: seal, spaces, title,
// clock, media, network, bluetooth, volume, brightness, battery, notif,
// edge, keyboard, mic, tray; or indicator:<key>, tray:<item id> and
// hosted:<widget id> for the marks, tray apps and hosted widgets.
// As a setting it is `show:<part>`, shown or hidden, so the settings page
// and `hanko style set show:mic hidden` go through withSetting().
var SHOW_OPTIONS = ["shown", "hidden"]
// Parts a setting can also leave out: showing one again puts it back.
var OFF = { seal: "none", title: "none", media: "none", bluetooth: "off" }
var PARTS = ["seal", "spaces", "title", "clock", "media", "network", "bluetooth", "volume",
             "brightness", "battery", "notif", "edge", "keyboard", "mic", "tray"]

// A part name the bar knows; tray app and widget ids can be anything.
function isPart(part) {
  var p = String(part || "")
  return PARTS.indexOf(p) >= 0 || /^(indicator|tray|hosted):\S+$/.test(p)
}

function normalizeHidden(list, warnings) {
  var out = []
  if (!Array.isArray(list)) return out
  for (var i = 0; i < list.length; i++) {
    var p = String(list[i] === undefined || list[i] === null ? "" : list[i]).trim()
    if (!p) continue
    if (!isPart(p)) { if (warnings) warnings.push("ignored unknown part " + p + " in hidden"); continue }
    if (out.indexOf(p) < 0) out.push(p)
  }
  return out.sort()
}

// Whether a resolved style shows a part: not hidden, and not left out by
// its own setting (seal: none and the like).
function shows(style, part) {
  var hidden = style && Array.isArray(style.hidden) ? style.hidden : []
  if (hidden.indexOf(part) >= 0) return false
  return !(OFF[part] !== undefined && style && style[part] === OFF[part])
}

// "40" from a hand-edited file or the CLI is the same as 40.
function coerce(key, value) {
  var options = OPTIONS[key]
  if (!options) return undefined
  for (var i = 0; i < options.length; i++)
    if (String(options[i]) === String(value)) return options[i]
  return undefined
}

function isValid(key, value) {
  return coerce(key, value) !== undefined
}

function presetName(name) {
  for (var i = 0; i < PRESET_NAMES.length; i++)
    if (PRESET_NAMES[i].toLowerCase() === String(name || "").toLowerCase()) return PRESET_NAMES[i]
  return ""
}

function copyOf(obj) {
  var out = {}
  for (var k in obj) out[k] = obj[k]
  return out
}

// Keeps only known keys with valid values. Everything dropped is reported, so
// a style written by a newer Hanko degrades with a warning instead of failing.
function cleanEdits(edits, warnings) {
  var out = {}
  if (!edits || typeof edits !== "object") return out
  for (var k in edits) {
    var v = coerce(k, edits[k])
    if (v === undefined) {
      if (warnings) warnings.push(OPTIONS[k] ? "ignored " + k + "=" + edits[k] : "ignored unknown setting " + k)
      continue
    }
    out[k] = v
  }
  return out
}

function normalizeGlyph(glyph) {
  var s = String(glyph === undefined || glyph === null ? "" : glyph).trim()
  if (s === "") return DEFAULT_SEAL_GLYPH
  // One user-perceived character; Array.from keeps surrogate pairs together.
  return Array.from(s)[0]
}

// A style document as stored in style.json:
//   { preset, edits: {...}, sealGlyph, motion, hidden: [...], monitors: { "<name>": {...} } }
// Anything missing or invalid falls back, so resolve() always returns a full style.
function normalize(doc, warnings) {
  doc = doc && typeof doc === "object" ? doc : {}
  var preset = presetName(doc.preset)
  if (!preset) {
    if (doc.preset !== undefined && warnings) warnings.push("unknown preset " + doc.preset + ", using " + DEFAULT_PRESET)
    preset = DEFAULT_PRESET
  }
  var monitors = {}
  if (doc.monitors && typeof doc.monitors === "object")
    for (var name in doc.monitors) monitors[name] = cleanEdits(doc.monitors[name], warnings)
  return {
    preset: preset,
    edits: cleanEdits(doc.edits, warnings),
    sealGlyph: normalizeGlyph(doc.sealGlyph),
    motion: normalizeMotion(doc.motion),
    hidden: normalizeHidden(doc.hidden, warnings),
    monitors: monitors
  }
}

// Preset, then edits, then the named monitor's overrides.
function resolve(doc, monitor) {
  var d = normalize(doc)
  var style = copyOf(PRESETS[d.preset])
  for (var k in d.edits) style[k] = d.edits[k]
  var m = monitor && d.monitors[monitor]
  if (m) for (var j in m) style[j] = m[j]
  style.sealGlyph = d.sealGlyph
  style.motion = d.motion
  style.hidden = d.hidden.slice()
  style.preset = d.preset
  style.edited = Object.keys(d.edits).length > 0
  return style
}

// Setting a value equal to the preset's drops the edit instead of storing it,
// so `edits` always lists exactly what differs. The seal glyph and motion
// are kept beside the edits, the same for every preset.
function withSetting(doc, key, value) {
  var d = normalize(doc)
  if (key === "sealGlyph") { d.sealGlyph = normalizeGlyph(value); return d }
  if (key === "motion") {
    if (MOTIONS.indexOf(String(value)) < 0) return null
    d.motion = String(value)
    return d
  }
  if (String(key).indexOf("show:") === 0) return withShown(d, String(key).slice(5), value)
  var v = coerce(key, value)
  if (v === undefined) return null
  if (PRESETS[d.preset][key] === v) delete d.edits[key]
  else d.edits[key] = v
  // Picking a way to draw a hidden part (a seal stamp) shows it again.
  if (OFF[key] !== undefined && v !== OFF[key]) d.hidden = d.hidden.filter(function(h) { return h !== key })
  return d
}

// Show or hide one part (`shown` / `hidden`). Showing a part its own
// setting leaves out (seal: none) also sets it back: to the preset's way
// when the preset draws it, else the first way that draws it.
function withShown(doc, part, value) {
  var d = normalize(doc)
  var p = String(part || "").trim()
  if (!isPart(p) || SHOW_OPTIONS.indexOf(String(value)) < 0) return null
  var hidden = d.hidden.filter(function(h) { return h !== p })
  if (value === "hidden") hidden.push(p)
  d.hidden = normalizeHidden(hidden)
  if (value === "shown" && OFF[p] !== undefined && resolve(d)[p] === OFF[p]) {
    var preset = PRESETS[d.preset][p]
    var on = preset !== OFF[p] ? preset : OPTIONS[p].filter(function(o) { return o !== OFF[p] })[0]
    return withSetting(d, p, on)
  }
  return d
}

// One setting for one monitor only (style.json `monitors`); a value equal
// to what the monitor would get anyway drops the override. An empty
// override list drops the monitor.
function withMonitorSetting(doc, monitor, key, value) {
  var d = normalize(doc)
  var name = String(monitor || "").trim()
  var v = coerce(key, value)
  if (!name || v === undefined) return null
  var own = d.monitors[name] || {}
  delete own[key]
  if (resolve({ preset: d.preset, edits: d.edits, sealGlyph: d.sealGlyph, monitors: {} })[key] !== v) own[key] = v
  if (Object.keys(own).length) d.monitors[name] = own
  else delete d.monitors[name]
  return d
}

function withPreset(doc, name) {
  var preset = presetName(name)
  if (!preset) return null
  var d = normalize(doc)
  d.preset = preset
  d.edits = {}
  return d
}

// rng() returns [0, 1). Position and panels are left alone: they change where
// things are, not how the bar reads, and a shuffle should never move the bar.
function shuffled(doc, rng) {
  var d = normalize(doc)
  var base = PRESETS[d.preset]
  var edits = {}
  for (var i = 0; i < KEYS.length; i++) {
    var k = KEYS[i]
    if (k === "position" || k === "panels") {
      if (d.edits[k] !== undefined) edits[k] = d.edits[k]
      continue
    }
    var v = OPTIONS[k][Math.floor(rng() * OPTIONS[k].length)]
    if (base[k] !== v) edits[k] = v
  }
  d.edits = edits
  return d
}

function combinations() {
  var n = 1
  for (var i = 0; i < KEYS.length; i++) n *= OPTIONS[KEYS[i]].length
  return n
}
