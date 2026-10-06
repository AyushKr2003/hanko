.pragma library

// The settings window (docs/COMPONENTS.md §6): what its rail lists, how the
// Typesetting 組版 page groups the sixteen settings into six cards, and the
// small sums its header and action bar print. bar/settings/ draws these.

var RAIL = [
  { group: "01 BAR",    pages: [{ key: "typesetting", label: "Typesetting", jp: "組版" },
                                { key: "colour", label: "Colour", jp: "色" },
                                { key: "widgets", label: "Widgets", jp: "部品" }] },
  { group: "02 PANELS", pages: [{ key: "sheets", label: "Sheets", jp: "紙" },
                                { key: "scroll", label: "Scroll", jp: "巻" }] },
  { group: "03 FEEL",   pages: [{ key: "motion", label: "Motion", jp: "動" },
                                { key: "keys", label: "Keys", jp: "鍵" }] },
  { group: "04 SHARE",  pages: [{ key: "presets", label: "Presets", jp: "型" }] }
]

var PRESET_BLURBS = {
  Sheet: "beta1, as drawn", Scroll: "alpha1, as drawn", Hanko: "the merge",
  Quiet: "least on screen", Instrument: "most on screen", Islet: "floating, inset"
}

// Seal glyphs offered as one-tap choices; anything else is typed under
// Advanced (or with the "…" button).
var GLYPHS = ["印", "力", "侍", "A"]

var CARDS = [
  { title: "Left · where you are", rows: [
    { key: "seal", name: "Seal", detail: "Fixed glyph or your workspace" },
    { key: "spaces", name: "Workspaces", detail: "How spaces are drawn" },
    { key: "title", name: "Window title", detail: "Cell, byline or hidden" }] },
  { title: "Centre · when", rows: [
    { key: "clock", name: "Clock", detail: "Typeface of the time" },
    { key: "clockAt", name: "Clock position", detail: "" },
    { key: "media", name: "Now playing", detail: "" }] },
  { title: "Right · how things are", rows: [
    { key: "status", name: "Status", detail: "Cells, kanji glyphs or numerals" },
    { key: "meters", name: "Meters", detail: "Ticks beside quantities" },
    { key: "notif", name: "Notifications", detail: "" },
    { key: "bluetooth", name: "Bluetooth", detail: "A BT 藍 cell for your devices" }] },
  { title: "Edge", rows: [
    { key: "edge", name: "Bottom edge", detail: "Hairline, day rule, rod, both" },
    { key: "rules", name: "Dividers", detail: "Hairlines between groups" }] },
  { title: "Frame", rows: [
    { key: "height", name: "Height", detail: "px at font size 12" },
    { key: "surface", name: "Surface", detail: "" },
    { key: "position", name: "Position", detail: "" }] },
  { title: "Panels", rows: [
    { key: "panels", name: "Panels open as", detail: "Flush sheets or one scroll" },
    { key: "sealGlyph", name: "Seal glyph", detail: "Used when seal is fixed" }] }
]

// The Motion 動 page: one switch outside the sixteen (style.json `motion`),
// and the timings it governs (core/Motion.qml holds the numbers).
var MOTION_CARD = { title: "Motion · paper moves like paper", rows: [
  { key: "motion", name: "Motion", detail: "Paper eases every move; still cuts each one to its end frame" }] }
var MOTION_OPTIONS = ["paper", "still"]

// [name, what moves, Motion.qml property for its time]
var MOTION_ROWS = [
  ["Unroll", "The rod drops and the scroll's paper follows it", "unroll"],
  ["Ink", "Section ink arrives after the paper has moved", "ink"],
  ["Pan", "A pan carries on and lands centred on a section", "pan"],
  ["Print", "A sheet prints top-down from the cell you clicked", "sheetPrint"],
  ["Plates", "The live page's plate slides to the next one", "slide"],
  ["Values", "A changed reading fades through to the new one", "fade"],
  ["Stamp", "A new notification is pressed down, then settles: the only overshoot", "stamp"],
  ["Now-notch", "Creeps to the new minute instead of jumping", "creep"]
]

// A setting's name as its card row gives it ("clockAt" -> "Clock position").
function nameOf(key) {
  for (var i = 0; i < CARDS.length; i++)
    for (var j = 0; j < CARDS[i].rows.length; j++)
      if (CARDS[i].rows[j].key === key) return CARDS[i].rows[j].name
  return key
}

// The options a row's segmented control offers, as strings.
function optionsFor(key, OPTIONS) {
  if (key === "sealGlyph") return GLYPHS.concat(["…"])
  if (key === "motion") return MOTION_OPTIONS.slice()
  return (OPTIONS[key] || []).map(String)
}

// Which option is lit for `key` in a resolved style; a typed seal glyph
// outside the four lights "…".
function selected(key, style, glyph) {
  if (key === "sealGlyph") return GLYPHS.indexOf(glyph) >= 0 ? glyph : "…"
  return String(style[key])
}

// How many settings the draft changes from what is saved: every one of the
// sixteen that resolves differently, the seal glyph, and each monitor whose
// overrides differ.
function changes(savedDoc, draftDoc, resolve) {
  var a = resolve(savedDoc), b = resolve(draftDoc)
  var n = 0
  for (var k in b) if (k !== "preset" && k !== "edited" && String(a[k]) !== String(b[k])) n++
  var ma = savedDoc.monitors || {}, mb = draftDoc.monitors || {}
  var names = {}
  for (var x in ma) names[x] = true
  for (var y in mb) names[y] = true
  for (var m in names) if (JSON.stringify(ma[m] || {}) !== JSON.stringify(mb[m] || {})) n++
  return n
}

// "Edited · live on your bar · 2 changes", or how things stand.
function status(n) {
  if (n === 0) return "Saved · as on your bar"
  return "Edited · live on your bar · " + n + (n === 1 ? " change" : " changes")
}

// "Preset · Hanko + edits", for the page's eyebrow.
function presetLine(doc) {
  var edited = doc.edits && Object.keys(doc.edits).length > 0
  return "Preset · " + doc.preset + (edited ? " + edits" : "")
}

// A row is shown when the query (lower case, trimmed) appears in its
// name, detail, key or any option.
function matches(row, query, OPTIONS) {
  var q = String(query || "").trim().toLowerCase()
  if (!q) return true
  var hay = [row.name, row.detail, row.key].concat(optionsFor(row.key, OPTIONS)).join(" ").toLowerCase()
  return hay.indexOf(q) >= 0
}

// Rail pages matching a query, for the search field.
function pageMatches(page, query) {
  var q = String(query || "").trim().toLowerCase()
  return !q || (page.label + " " + page.jp + " " + page.key).toLowerCase().indexOf(q) >= 0
}
