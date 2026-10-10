.pragma library

// The twenty-three typesetting settings, the presets, and how a style document
// resolves into the one flat object the bar reads. Pure JavaScript with no
// QML or Quickshell dependency, so tests/unit.mjs can run it under Node.
// docs/COMPONENTS.md is the spec for every option below.

var OPTIONS = {
  // Values after the Typeset ones come from Shōji (HANDOFF §10, "Shōji
  // into Hanko"), drawn with its parts (bar/parts) in Shōji's skin:
  //   seal carved     an ink outline, pressed red when letters wait (notif: seal)
  //   spaces brush    numerals (style `numerals`) with a brush mark under the
  //                   live one, a dot when busy, the 未 stamp when urgent
  //   title ink       the app, then what it shows, in Space Grotesk
  //   clock season    the time, the date and the solar term (style `season`)
  //   media ink       three level bars, the title and the artist
  //   status ink      an icon and a figure each, the name on reach, the
  //                   battery an ensō that closes as it fills
  //   notif seal      the letter count on the seal; the inbox cell goes
  //   surface washi   paper with long fibres (style `grain`)
  //   pointer brush   a faint brush mark under the cell you point at
  // The status values after `ink` are the four right-side studies
  // (docs/right-side), each a cure for a crowded right zone:
  //   ma       間 three groups held apart by space: links (network,
  //            Bluetooth), levels (a figure with a hairline fill under it),
  //            then the marks; the kanji is the label
  //   shizuka  静 quiet until something changes: network and battery stay,
  //            Bluetooth, volume and brightness wait as faint kanji and
  //            unfold for two seconds when they move (or while you point
  //            at the zone); anything that needs you stays open, in red
  //   suji     筋 a kanji and one short brush line each, its length the
  //            level; the figure comes out when you reach for it
  //   inro     印籠 one ruled case of compartments, kanji over value
  // None of the four draws meters; each carries its own level.
  seal:     ["stamp", "workspace", "carved", "none"],
  spaces:   ["folio", "layout", "kanji", "dots", "brush"],
  title:    ["cell", "byline", "ink", "none"],
  clock:    ["stacked", "inline", "mono", "season"],
  clockAt:  ["center", "right"],
  media:    ["cell", "underline", "ink", "none"],
  status:   ["cells", "glyphs", "numerals", "ink", "ma", "shizuka", "suji", "inro"],
  meters:   ["ticks", "off"],
  notif:    ["count", "stamps", "seal"],
  // A BT 双 cell for Bluetooth (only where there is an adapter):
  // device = the connected device's name and battery, marks = one kanji
  // mark per device with its charge under it, count = how many, as dots.
  bluetooth: ["device", "marks", "count", "off"],
  // Omarchy's indicators (recording, dictation, reminder, stay awake,
  // night light, do not disturb) as stamps in the right zone: all six, the
  // ones that are off faint, or only those that are on; and what is on a
  // stamp: Omarchy's icon or its kanji, alone or (iconname, kanjiname) with
  // its name in small caps beside it while it is on.
  indicators: ["all", "active"],
  indicatorStyle: ["icon", "kanji", "iconname", "kanjiname"],
  edge:     ["hairline", "dayrule", "rod", "rodrule"],
  rules:    ["on", "off"],
  pointer:  ["plain", "brush"],
  height:   [32, 36, 40, 44],
  surface:  ["solid", "glass", "inset", "washi"],
  position: ["top", "bottom"],
  panels:   ["sheets", "scroll"],
  // What sits between two sections of the scroll (docs/revision1 on the
  // docs branch): ma = space alone, hairline, folio = a ruler with the
  // section numbers, kotoba = the next section's name set vertically,
  // tsugime = a paper join, seal = the join with a seal pressed across it,
  // jiku = a slim inner roller, fuda = an index tab, su = the next number.
  interlude: ["ma", "hairline", "folio", "kotoba", "tsugime", "seal", "jiku", "fuda", "su"],
  // The leaf on the bare paper right of 08 // INBOX (core/Leaf.js; designs
  // in docs/revision2 on the docs branch): okugaki = a colophon of the
  // machine, koyomi = the almanac, kiki = the machine's load, shimai = the
  // session's end, iro = themes, dougu = tools, shuchu = a focus timer,
  // hikae = notes, batsu = an afterword.
  endleaf: ["okugaki", "koyomi", "kiki", "shimai", "iro", "dougu", "shuchu", "hikae", "batsu"],
  // The scroll's two side edges (docs/revision3 on the docs branch; they
  // replaced the rollers): bare = the paper simply fades out, curl = a soft
  // shaded fold, as if the paper rolls under.
  sides: ["bare", "curl"],
  // What helps you find your way on the scroll: both = the index plate of
  // tabs on top and the position bar along the foot, tabs = the plate only,
  // foot = the position bar only, none = bare paper.
  guides: ["both", "tabs", "foot", "none"]
}

var KEYS = Object.keys(OPTIONS)

var PRESETS = {
  Sheet:      { seal: "stamp", spaces: "folio", title: "cell", clock: "stacked", clockAt: "center", media: "cell", status: "cells", meters: "ticks", notif: "count", bluetooth: "device", indicators: "all", indicatorStyle: "kanji", edge: "dayrule", rules: "on", pointer: "plain", height: 36, surface: "solid", position: "top", panels: "sheets", interlude: "folio", endleaf: "shimai", sides: "bare", guides: "both" },
  Scroll:     { seal: "workspace", spaces: "layout", title: "byline", clock: "inline", clockAt: "center", media: "underline", status: "glyphs", meters: "off", notif: "stamps", bluetooth: "marks", indicators: "active", indicatorStyle: "kanji", edge: "rod", rules: "off", pointer: "plain", height: 40, surface: "solid", position: "top", panels: "scroll", interlude: "kotoba", endleaf: "okugaki", sides: "curl", guides: "both" },
  // Kamon 家紋, the family crest: the bar this plugin is known by, as the
  // user runs it (it was the Hanko preset; "hanko" still names it).
  Kamon:      { seal: "stamp", spaces: "kanji", title: "byline", clock: "stacked", clockAt: "center", media: "underline", status: "cells", meters: "ticks", notif: "stamps", bluetooth: "device", indicators: "active", indicatorStyle: "kanjiname", edge: "rodrule", rules: "on", pointer: "plain", height: 40, surface: "solid", position: "top", panels: "sheets", interlude: "seal", endleaf: "koyomi", sides: "curl", guides: "none" },
  Quiet:      { seal: "stamp", spaces: "dots", title: "none", clock: "inline", clockAt: "center", media: "none", status: "numerals", meters: "off", notif: "count", bluetooth: "off", indicators: "active", indicatorStyle: "icon", edge: "hairline", rules: "off", pointer: "plain", height: 32, surface: "glass", position: "top", panels: "sheets", interlude: "ma", endleaf: "batsu", sides: "bare", guides: "both" },
  Instrument: { seal: "stamp", spaces: "kanji", title: "cell", clock: "mono", clockAt: "right", media: "cell", status: "cells", meters: "ticks", notif: "count", bluetooth: "device", indicators: "all", indicatorStyle: "iconname", edge: "dayrule", rules: "on", pointer: "plain", height: 44, surface: "solid", position: "top", panels: "sheets", interlude: "folio", endleaf: "kiki", sides: "bare", guides: "both" },
  Islet:      { seal: "workspace", spaces: "kanji", title: "byline", clock: "inline", clockAt: "center", media: "underline", status: "glyphs", meters: "ticks", notif: "stamps", bluetooth: "marks", indicators: "active", indicatorStyle: "icon", edge: "rodrule", rules: "off", pointer: "plain", height: 36, surface: "inset", position: "top", panels: "scroll", interlude: "fuda", endleaf: "dougu", sides: "curl", guides: "both" },
  // Shōji 障子: the Shōji design, folded into Hanko (HANDOFF §10). Its
  // values are drawn with Shōji's parts; picking it also puts every sheet
  // in the Shōji hand and frames the overview (PRESET_BESIDE).
  "Shōji":    { seal: "carved", spaces: "brush", title: "ink", clock: "season", clockAt: "center", media: "ink", status: "ink", meters: "off", notif: "seal", bluetooth: "device", indicators: "active", indicatorStyle: "icon", edge: "hairline", rules: "off", pointer: "brush", height: 40, surface: "washi", position: "top", panels: "sheets", interlude: "ma", endleaf: "koyomi", sides: "bare", guides: "both" },
  // The four right-side studies (docs/right-side): the Kamon bar with the
  // right zone set each way. The marks are stamps alone (their names on
  // hover), so the zone they cure is not crowded again by the indicators.
  Ma:         { seal: "stamp", spaces: "kanji", title: "byline", clock: "stacked", clockAt: "center", media: "underline", status: "ma", meters: "off", notif: "stamps", bluetooth: "device", indicators: "active", indicatorStyle: "kanji", edge: "rodrule", rules: "off", pointer: "plain", height: 40, surface: "solid", position: "top", panels: "sheets", interlude: "ma", endleaf: "koyomi", sides: "curl", guides: "none" },
  Shizuka:    { seal: "stamp", spaces: "kanji", title: "byline", clock: "stacked", clockAt: "center", media: "underline", status: "shizuka", meters: "off", notif: "stamps", bluetooth: "device", indicators: "active", indicatorStyle: "kanji", edge: "rodrule", rules: "on", pointer: "plain", height: 40, surface: "solid", position: "top", panels: "sheets", interlude: "seal", endleaf: "koyomi", sides: "curl", guides: "none" },
  Suji:       { seal: "stamp", spaces: "kanji", title: "byline", clock: "stacked", clockAt: "center", media: "underline", status: "suji", meters: "off", notif: "stamps", bluetooth: "device", indicators: "active", indicatorStyle: "kanji", edge: "rodrule", rules: "on", pointer: "plain", height: 40, surface: "solid", position: "top", panels: "sheets", interlude: "seal", endleaf: "koyomi", sides: "curl", guides: "none" },
  "Inrō":     { seal: "stamp", spaces: "kanji", title: "byline", clock: "stacked", clockAt: "center", media: "underline", status: "inro", meters: "off", notif: "stamps", bluetooth: "device", indicators: "active", indicatorStyle: "kanji", edge: "rodrule", rules: "on", pointer: "plain", height: 40, surface: "solid", position: "top", panels: "sheets", interlude: "seal", endleaf: "koyomi", sides: "curl", guides: "none" }
}

var PRESET_NAMES = ["Sheet", "Scroll", "Kamon", "Quiet", "Instrument", "Islet", "Shōji", "Ma", "Shizuka", "Suji", "Inrō"]
// How the Presets 型 page groups them: the bars, then the right-side studies.
var PRESET_GROUPS = [
  { title: "Bars", jp: "版", names: ["Kamon", "Sheet", "Scroll", "Quiet", "Instrument", "Islet", "Shōji"] },
  { title: "Right-side studies", jp: "右", names: ["Ma", "Shizuka", "Suji", "Inrō"] }
]
// What picking a preset also sets beside the twenty-three (only Shōji does:
// its panels are a sheet hand and its overview is framed). Kept afterwards,
// like anything beside the settings.
var PRESET_BESIDE = {
  "Shōji": { sheetStyles: { time: "shoji", sound: "shoji", network: "shoji", bluetooth: "shoji", power: "shoji", display: "shoji", inbox: "shoji" },
             overview: "framed" }
}
// A preset name as typed: any case, with or without the macron (shoji).
function foldName(name) { return String(name || "").toLowerCase().replace(/ō/g, "o") }
var DEFAULT_PRESET = "Kamon"
var DEFAULT_SEAL_GLYPH = "鑑"

// Motion 動 sits outside the twenty-three settings (no preset sets it and it is
// not counted): paper moves like paper, still cuts every transition to its
// end frame. Omarchy's own reduced motion makes Hanko still as well.
var MOTIONS = ["paper", "still"]
var DEFAULT_MOTION = "paper"

function normalizeMotion(m) {
  return MOTIONS.indexOf(String(m)) >= 0 ? String(m) : DEFAULT_MOTION
}

// Type size sits beside motion: Hanko's own text on top of Omarchy's
// `[font] base-size`, for a 1x laptop panel or a HiDPI desk. Every size,
// the bar's height with it, is multiplied by TYPE_SCALE.
var TYPE_SIZES = ["small", "regular", "large"]
var TYPE_SCALE = { small: 0.9, regular: 1, large: 1.15 }
var DEFAULT_TYPE_SIZE = "regular"

function normalizeTypeSize(t) {
  return TYPE_SIZES.indexOf(String(t)) >= 0 ? String(t) : DEFAULT_TYPE_SIZE
}

// Shōji's three touches, beside the twenty-three like type size (global, not
// per monitor; presets, resets and shuffles keep them). They were Kata's
// `touches`; a saved `touches` is read into them.
//   season    the solar term by the clock (clock: season) and the kō in
//             the Shōji Time panel: off, in kanji, or in English
//   numerals  workspace numbers in spaces: brush and the Shōji panels
//   grain     the washi's fibres (surface: washi and the Shōji panels)
var SEASONS = ["off", "kanji", "english"]
var NUMERALS = ["arabic", "kanji"]
var GRAINS = ["smooth", "fine", "toothy"]
var TOUCH_DEFAULTS = { season: "kanji", numerals: "arabic", grain: "fine" }
var TOUCH_LISTS = { season: SEASONS, numerals: NUMERALS, grain: GRAINS }

function normalizeTouch(key, v, legacy) {
  var list = TOUCH_LISTS[key]
  if (v !== undefined && list.indexOf(String(v)) >= 0) return String(v)
  if (legacy && typeof legacy === "object" && list.indexOf(String(legacy[key])) >= 0) return String(legacy[key])
  return TOUCH_DEFAULTS[key]
}

// Panel opacity 透け, beside the twenty-three like motion: how much of the
// desk shows through every panel (sheets, the scroll, Kata's panels), in
// percent, 30 to 100. 0 (or no key) leaves it to the design: solid paper,
// Shōji's washi at 86%.
var OPACITY_MIN = 30
function normalizeOpacity(o) {
  if (o === undefined || o === null || o === "" || o === "auto") return 0
  var n = Math.round(Number(o))
  if (!isFinite(n) || n <= 0) return 0
  return Math.max(OPACITY_MIN, Math.min(100, n))
}

// Which workspace overview 一覧 opens, beside the twenty-three like motion:
// grid, Hanko's printed pages in a fixed 2 x 5 grid; dynamic, Ryoku's
// overview (only workspaces with windows, a + for a new one, desktops);
// framed, the same grid as Shōji prints it: each page washi in a lattice
// frame, its kanji numeral in the head (the `overview` part, bar/parts).
var OVERVIEWS = ["grid", "dynamic", "framed"]
var DEFAULT_OVERVIEW = "grid"

function normalizeOverview(o) {
  return OVERVIEWS.indexOf(String(o)) >= 0 ? String(o) : DEFAULT_OVERVIEW
}

// How each sheet is drawn (style.json `sheetStyles`, Settings › Sheets 紙),
// beside the twenty-three like the overview: no preset sets them and a reset
// keeps them. The hands for every cell's sheet:
//   ledger  帳  the editorial page: eyebrow, serif title, `//` groups, rows
//   tanzaku 短冊 the poem slips: each choice a paper strip hung from a rail,
//               right to left, as long as its level; the one in use inked
//   shogi   将棋 the board: a level is a rank of nine squares, its piece on
//               the square of its level; choices wait on the piece stand
//   soroban 算盤 the abacus: readings counted in beads pushed to the beam
//   odoshi  縅  armour lacing: each level a lame of scales laced to it
//   kasumi  霞  mist bands: each level a band of gold leaf drawn as far
//   shoji   障子 Shōji's panels: washi on a rail below the bar, a vertical
//               sign down the right edge, brush sliders and the ensō
// shogi..kasumi draw one model per sheet (core/Hands.js); shoji is the
// Shōji panels (bar/sheets/ShojiPanel.qml) in Shōji's skin.
// Stored only where a sheet is not a ledger; resolve() gives the full map.
var SHEET_STYLES = ["ledger", "tanzaku", "shogi", "soroban", "odoshi", "kasumi", "shoji"]
var SHEET_KEYS = ["time", "sound", "network", "bluetooth", "power", "display", "inbox"]

function normalizeSheetStyles(o) {
  var out = {}
  if (!o || typeof o !== "object") return out
  for (var i = 0; i < SHEET_KEYS.length; i++) {
    var k = SHEET_KEYS[i], v = String(o[k])
    // The Dial hand was replaced by Tanzaku; a saved dial carries over.
    if (v === "dial") v = "tanzaku"
    // Prose and Mon were taken out; a sheet saved in either is a ledger again.
    if (v === "prose" || v === "mon") v = "ledger"
    if (SHEET_STYLES.indexOf(v) > 0) out[k] = v
  }
  return out
}

function sheetStylesOf(d) {
  var out = {}, own = normalizeSheetStyles(d && d.sheetStyles)
  for (var i = 0; i < SHEET_KEYS.length; i++) out[SHEET_KEYS[i]] = own[SHEET_KEYS[i]] || "ledger"
  return out
}

// Parts of the bar you have hidden (style.json `hidden`, the Widgets 部品
// page), beside the twenty-three like the seal glyph: no preset sets them and a
// reset keeps them. A part is a name the bar knows: seal, spaces, title,
// clock, media, network, bluetooth, volume, brightness, battery, notif,
// edge, keyboard, mic, tray, weather and endleaf (the scroll's two leaves);
// or indicator:<key>, tray:<item id> and
// hosted:<widget id> for the marks, tray apps and hosted widgets.
// As a setting it is `show:<part>`, shown or hidden, so the settings page
// and `hanko style set show:mic hidden` go through withSetting().
var SHOW_OPTIONS = ["shown", "hidden"]
// Parts a setting can also leave out: showing one again puts it back.
var OFF = { seal: "none", title: "none", media: "none", bluetooth: "off" }
var PARTS = ["seal", "spaces", "title", "clock", "media", "network", "bluetooth", "volume",
             "brightness", "battery", "notif", "edge", "keyboard", "mic", "tray", "weather", "endleaf"]

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
// Values older Hankos wrote, and what they mean now.
var ALIASES = { bluetooth: { on: "device" }, indicatorStyle: { full: "iconname" } }

function coerce(key, value) {
  var options = OPTIONS[key]
  if (!options) return undefined
  var alias = ALIASES[key] && ALIASES[key][String(value)]
  if (alias !== undefined) value = alias
  for (var i = 0; i < options.length; i++)
    if (String(options[i]) === String(value)) return options[i]
  return undefined
}

function isValid(key, value) {
  return coerce(key, value) !== undefined
}

// Names a preset had before, folded: a style.json or a command that uses
// one gets the preset it became.
var PRESET_ALIASES = { hanko: "Kamon" }

function presetName(name) {
  for (var i = 0; i < PRESET_NAMES.length; i++)
    if (foldName(PRESET_NAMES[i]) === foldName(name)) return PRESET_NAMES[i]
  return PRESET_ALIASES[foldName(name)] || ""
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

// Kata's keys (core/Kata.js: design, borrow) are read, never kept: the
// Shōji design is the Shōji preset now (S4 of "Shōji into Hanko").
// Its `touches` became the season, numerals and grain settings: normalize
// reads them in and drops the key (a monitor's own touches are dropped).
var KATA_KEYS = ["design", "borrow"]


function withoutKata(obj) {
  var out = {}
  if (!obj || typeof obj !== "object") return out
  for (var k in obj) if (KATA_KEYS.indexOf(k) < 0) out[k] = obj[k]
  return out
}

// A style document as stored in style.json:
//   { preset, edits: {...}, sealGlyph, motion, typeSize, overview, sheetStyles, hidden: [...], monitors: { "<name>": {...} },
//     season, numerals, grain }
// Anything missing or invalid falls back, so resolve() always returns a full style.
//
// A file from before Shōji was folded into Hanko may name a design. Shōji
// (`design: "shoji"`) loads as the Shōji preset: its bar honoured only the
// height, position and Bluetooth of the Typeset edits, so only those are
// kept; every sheet not given a hand of its own takes the Shōji hand, and
// the overview is framed, as that design drew them. A monitor that named
// the other design than the file's gets that preset's values as overrides.
// `borrow` is dropped.
var SHOJI_KEPT_EDITS = ["height", "position", "bluetooth"]
function designOf(v) { var d = foldName(v); return d === "shoji" ? "Shōji" : d === "classic" || d === "hanko" ? "Kamon" : "" }

function normalize(doc, warnings) {
  doc = doc && typeof doc === "object" ? doc : {}
  var topDesign = designOf(doc.design) || "Kamon"
  if (topDesign === "Shōji") doc = fromShojiDesign(doc)
  var preset = presetName(doc.preset)
  if (!preset) {
    if (doc.preset !== undefined && warnings) warnings.push("unknown preset " + doc.preset + ", using " + DEFAULT_PRESET)
    preset = DEFAULT_PRESET
  }
  var monitors = {}
  if (doc.monitors && typeof doc.monitors === "object")
    for (var name in doc.monitors) {
      var raw = withoutKata(doc.monitors[name])
      delete raw.touches
      var own = cleanEdits(raw, warnings)
      // A monitor in the other design: that preset's values, under its own.
      var mine = designOf(doc.monitors[name] && doc.monitors[name].design)
      if (mine && mine !== topDesign) {
        var base = copyOf(PRESETS[mine])
        for (var ok in own) base[ok] = own[ok]
        own = base
      }
      monitors[name] = own
    }
  var out = {
    preset: preset,
    edits: cleanEdits(doc.edits, warnings),
    sealGlyph: normalizeGlyph(doc.sealGlyph),
    motion: normalizeMotion(doc.motion),
    typeSize: normalizeTypeSize(doc.typeSize),
    season: normalizeTouch("season", doc.season, doc.touches),
    numerals: normalizeTouch("numerals", doc.numerals, doc.touches),
    grain: normalizeTouch("grain", doc.grain, doc.touches),
    overview: normalizeOverview(doc.overview),
    hidden: normalizeHidden(doc.hidden, warnings),
    monitors: monitors
  }
  var op = normalizeOpacity(doc.panelOpacity)
  if (op) out.panelOpacity = op
  var ss = normalizeSheetStyles(doc.sheetStyles)
  if (Object.keys(ss).length) out.sheetStyles = ss
  return out
}

// A document whose design is Shōji, as the Shōji preset (see normalize).
function fromShojiDesign(doc) {
  var next = JSON.parse(JSON.stringify(doc))
  delete next.design
  delete next.borrow
  next.preset = "Shōji"
  var kept = {}
  var edits = next.edits && typeof next.edits === "object" ? next.edits : {}
  for (var i = 0; i < SHOJI_KEPT_EDITS.length; i++)
    if (edits[SHOJI_KEPT_EDITS[i]] !== undefined) kept[SHOJI_KEPT_EDITS[i]] = edits[SHOJI_KEPT_EDITS[i]]
  next.edits = kept
  var ss = next.sheetStyles && typeof next.sheetStyles === "object" ? next.sheetStyles : {}
  var all = PRESET_BESIDE["Shōji"].sheetStyles
  for (var k in all) if (!ss[k] || ss[k] === "ledger") ss[k] = all[k]
  next.sheetStyles = ss
  next.overview = "framed"
  return next
}

// Preset, then edits, then the named monitor's overrides.
function resolve(doc, monitor) {
  var d = normalize(doc)
  var style = copyOf(PRESETS[d.preset])
  for (var k in d.edits) style[k] = d.edits[k]
  var m = monitor && d.monitors[monitor]
  if (m) for (var j in m) if (KATA_KEYS.indexOf(j) < 0) style[j] = m[j]
  style.sealGlyph = d.sealGlyph
  style.motion = d.motion
  style.typeSize = d.typeSize
  style.season = d.season
  style.numerals = d.numerals
  style.grain = d.grain
  style.overview = d.overview
  style.panelOpacity = d.panelOpacity || 0
  style.sheetStyles = sheetStylesOf(d)
  style.hidden = d.hidden.slice()
  style.preset = d.preset
  style.edited = Object.keys(d.edits).length > 0
  return style
}

// Setting a value equal to the preset's drops the edit instead of storing it,
// so `edits` always lists exactly what differs. The seal glyph, motion and type size
// are kept beside the edits, the same for every preset.
function withSetting(doc, key, value) {
  var d = normalize(doc)
  if (key === "sealGlyph") { d.sealGlyph = normalizeGlyph(value); return d }
  if (key === "motion") {
    if (MOTIONS.indexOf(String(value)) < 0) return null
    d.motion = String(value)
    return d
  }
  if (key === "typeSize") {
    if (TYPE_SIZES.indexOf(String(value)) < 0) return null
    d.typeSize = String(value)
    return d
  }
  if (TOUCH_LISTS[key]) {
    if (TOUCH_LISTS[key].indexOf(String(value)) < 0) return null
    d[key] = String(value)
    return d
  }
  if (key === "panelOpacity") {
    if (value !== "auto" && !isFinite(Number(value))) return null
    var op = normalizeOpacity(value)
    if (op) d.panelOpacity = op
    else delete d.panelOpacity
    return d
  }
  // sheetStyle:<sheet> or sheetStyle:all, to one of SHEET_STYLES.
  if (String(key).indexOf("sheetStyle:") === 0) {
    var which = String(key).slice(11), how = String(value) === "dial" ? "tanzaku" : String(value)
    if (SHEET_STYLES.indexOf(how) < 0) return null
    if (which !== "all" && SHEET_KEYS.indexOf(which) < 0) return null
    var map = normalizeSheetStyles(d.sheetStyles)
    var keys = which === "all" ? SHEET_KEYS : [which]
    for (var si = 0; si < keys.length; si++) {
      if (how === "ledger") delete map[keys[si]]
      else map[keys[si]] = how
    }
    if (Object.keys(map).length) d.sheetStyles = map
    else delete d.sheetStyles
    return d
  }
  if (key === "overview") {
    if (OVERVIEWS.indexOf(String(value)) < 0) return null
    d.overview = String(value)
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
  var beside = PRESET_BESIDE[preset]
  if (beside) {
    if (beside.sheetStyles) d.sheetStyles = normalizeSheetStyles(beside.sheetStyles)
    if (beside.overview) d.overview = beside.overview
  }
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
