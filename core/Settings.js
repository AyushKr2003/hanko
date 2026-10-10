.pragma library

// The settings window (docs/COMPONENTS.md §6): what its rail lists, how the
// Typesetting 組版 page groups the twenty-four settings into six cards, and the
// small sums its header and action bar print. bar/settings/ draws these.

var RAIL = [
  { group: "00 YOU",    pages: [{ key: "profile", label: "Profile", jp: "印影" }] },
  { group: "01 BAR",    pages: [{ key: "presets", label: "Presets", jp: "型" },
                                { key: "typesetting", label: "Typesetting", jp: "組版" },
                                { key: "colour", label: "Colour", jp: "色" },
                                { key: "widgets", label: "Widgets", jp: "部品" }] },
  { group: "02 PANELS", pages: [{ key: "sheets", label: "Sheets", jp: "紙" },
                                { key: "scroll", label: "Scroll", jp: "巻" }] },
  { group: "03 FEEL",   pages: [{ key: "motion", label: "Motion", jp: "動" },
                                { key: "keys", label: "Keys", jp: "鍵" }] },
  { group: "04 HANKO",  pages: [{ key: "about", label: "About", jp: "由来" },
                                { key: "credits", label: "Credits", jp: "謝辞" }] }
]

// The group and page a rail key names (Typesetting when the key is unknown).
function pageInfo(key) {
  for (var g = 0; g < RAIL.length; g++)
    for (var p = 0; p < RAIL[g].pages.length; p++)
      if (RAIL[g].pages[p].key === key) return { group: RAIL[g].group, page: RAIL[g].pages[p] }
  return pageInfo("typesetting")
}

// Rail pages drawn as full plates (no title, no cards): Profile, About,
// Credits (bar/settings/*Plate.qml).
var PLATES = ["profile", "about", "credits"]

var PRESET_BLURBS = {
  Sheet: "the printed bar", Scroll: "the handscroll", Kamon: "the family crest",
  Quiet: "least on screen", Instrument: "most on screen", Islet: "floating, inset",
  "Shōji": "washi and the seasons",
  Ma: "room between the groups", Shizuka: "quiet until it changes",
  Suji: "five brush lines", "Inrō": "one case for everything"
}

// Each preset's kanji, for the Presets 型 page: what the bar is, in one
// sign. The four studies keep the kanji they were drawn with.
var PRESET_KANJI = {
  Sheet: "帳", Scroll: "巻", Kamon: "家紋", Quiet: "素", Instrument: "計", Islet: "島",
  "Shōji": "障子", Ma: "間", Shizuka: "静", Suji: "筋", "Inrō": "印籠"
}

// The settings a preset card names under its title: how the bar reads at
// a glance (status, clock, height, surface, panels), as small caps.
var PRESET_FACTS = ["status", "clock", "height", "surface", "panels"]
function presetFacts(style) {
  var st = style || {}
  return PRESET_FACTS.map(function(k) {
    return k === "height" ? st.height + " px" : k + " " + st[k]
  }).join(" · ")
}

// A preset is shown on the Presets page when the query (any case) is in
// its name, kanji, blurb or the values it sets.
function presetMatches(name, query, presets) {
  var q = String(query || "").trim().toLowerCase()
  if (!q) return true
  var p = (presets && presets[name]) || {}
  var hay = [name, String(name).replace(/ō/g, "o"), PRESET_KANJI[name] || "", PRESET_BLURBS[name] || ""]
  // A preset's old name finds it too (hanko → Kamon).
  if (name === "Kamon") hay.push("hanko")
  for (var k in p) hay.push(String(p[k]))
  return hay.join(" ").toLowerCase().indexOf(q) >= 0
}

// Seal glyphs offered as one-tap choices; anything else is typed under
// Advanced (or with the "…" button).
// The four Kan: 鑑 (as in 印鑑, the registered seal; a mirror, a model),
// 漢 (as in 漢字), 観 (to behold) and 寛 (at ease). "…" takes any other.
var GLYPHS = ["鑑", "漢", "観", "寛"]

var CARDS = [
  { title: "Left · where you are", rows: [
    { key: "seal", name: "Seal", detail: "Fixed glyph, your workspace, or Shōji's carved seal" },
    { key: "spaces", name: "Workspaces", detail: "How spaces are drawn" },
    { key: "numerals", name: "Numerals", detail: "Workspace numbers in brush and on Shōji's panels" },
    { key: "title", name: "Window title", detail: "Cell, byline, Shōji's ink or hidden" }] },
  { title: "Centre · when", rows: [
    { key: "clock", name: "Clock", detail: "Typeface of the time; season adds the solar term" },
    { key: "hours", name: "Hours", detail: "24-hour or 12-hour; auto follows Omarchy's clock" },
    { key: "season", name: "Season", detail: "The solar term by the clock and in Shōji's Time" },
    { key: "clockAt", name: "Clock position", detail: "" },
    { key: "media", name: "Now playing", detail: "" }] },
  { title: "Right · how things are", rows: [
    { key: "status", name: "Status", detail: "Cells, glyphs, numerals, Shōji's ink; or the studies: ma's groups, shizuka's folding, suji's lines, the inrō case" },
    { key: "meters", name: "Meters", detail: "Ticks beside quantities" },
    { key: "notif", name: "Notifications", detail: "" },
    { key: "bluetooth", name: "Bluetooth", detail: "A BT 双 cell for your devices" },
    { key: "indicators", name: "Indicators", detail: "All six, the off ones faint, or only what is on" },
    { key: "indicatorStyle", name: "Indicator marks", detail: "Icon or kanji, alone or named while on" }] },
  { title: "Edge", rows: [
    { key: "edge", name: "Bottom edge", detail: "Hairline, day rule, rod, both" },
    { key: "rules", name: "Dividers", detail: "Hairlines between groups" },
    { key: "pointer", name: "Pointer", detail: "A brush mark under the cell you point at" }] },
  { title: "Frame", rows: [
    { key: "height", name: "Height", detail: "px at font size 12" },
    { key: "typeSize", name: "Type size", detail: "Hanko's text over Omarchy's font size" },
    { key: "surface", name: "Surface", detail: "Washi is Shōji's paper, with fibres" },
    { key: "float", name: "Float", detail: "Flush on the edge, or inset 8 px off it in a hairline frame" },
    { key: "grain", name: "Paper grain", detail: "The washi's fibres" },
    { key: "position", name: "Position", detail: "" }] },
  { title: "Panels", rows: [
    { key: "panels", name: "Panels open as", detail: "Flush sheets or one scroll" },
    { key: "interlude", name: "Scroll dividers", detail: "What sits between the scroll's sections" },
    { key: "endleaf", name: "Scroll end leaf", detail: "What sits after Inbox" },
    { key: "sides", name: "Scroll sides", detail: "Bare paper, or paper curling under" },
    { key: "guides", name: "Scroll guides", detail: "The tabs on top, the position bar at the foot, both or none" },
    { key: "overview", name: "Overview", detail: "Printed pages in a grid, Ryoku's busy spaces and a +, or Shōji's washi in lattice frames" },
    { key: "sealGlyph", name: "Seal glyph", detail: "Used when seal is fixed" }] }
]

// The Motion 動 page: one switch outside the twenty-four (style.json `motion`),
// and the timings it governs (core/Motion.qml holds the numbers).
var MOTION_CARD = { title: "Motion · paper moves like paper", rows: [
  { key: "motion", name: "Motion", detail: "Paper eases every move; still cuts each one to its end frame" }] }
var MOTION_OPTIONS = ["paper", "still"]
var TYPE_SIZE_OPTIONS = ["small", "regular", "large"]
var OVERVIEW_OPTIONS = ["grid", "dynamic", "framed"]
// Shōji's touches, beside the twenty-four (Style.js SEASONS, NUMERALS, GRAINS).
var TOUCH_OPTIONS = { season: ["off", "kanji", "english"], numerals: ["arabic", "kanji"], grain: ["smooth", "fine", "toothy"],
                     hours: ["auto", "24h", "12h"] }

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

// The interludes as the Scroll 巻 page and the Typesetting row show them:
// a kanji for the segmented control, a name and a line for the gallery.
var INTERLUDES = [
  { key: "ma",       jp: "間", name: "Ma",       detail: "Space alone" },
  { key: "hairline", jp: "罫", name: "Hairline", detail: "One fading rule with a ring" },
  { key: "folio",    jp: "柱", name: "Folio",    detail: "A ruler with both numbers" },
  { key: "kotoba",   jp: "詞", name: "Kotoba",   detail: "The next name, set vertically" },
  { key: "tsugime",  jp: "継", name: "Tsugime",  detail: "A paper join" },
  { key: "seal",     jp: "鑑", name: "Seal",     detail: "A seal pressed across the join" },
  { key: "jiku",     jp: "軸", name: "Jiku",     detail: "A slim inner roller" },
  { key: "fuda",     jp: "札", name: "Fuda",     detail: "An index tab" },
  { key: "su",       jp: "数", name: "Su",       detail: "The next number, large" }
]

function interludeOf(key) {
  for (var i = 0; i < INTERLUDES.length; i++) if (INTERLUDES[i].key === key) return INTERLUDES[i]
  return INTERLUDES[0]
}

// value -> kanji, for the Typesetting row's segmented control.
function interludeLabels() {
  var out = {}
  for (var i = 0; i < INTERLUDES.length; i++) out[INTERLUDES[i].key] = INTERLUDES[i].jp
  return out
}

// The end leaves as the Scroll 巻 page and the Typesetting row show them
// (core/Leaf.js KINDS draws them; the unit tests keep the two in step).
var ENDLEAVES = [
  { key: "okugaki", jp: "奥", name: "Okugaki", detail: "A colophon: the machine, and seals" },
  { key: "koyomi",  jp: "暦", name: "Koyomi",  detail: "The month, the season, the moon" },
  { key: "kiki",    jp: "機", name: "Kiki",    detail: "CPU, memory, disk and heat" },
  { key: "shimai",  jp: "終", name: "Shimai",  detail: "Lock, suspend, log out, shut down" },
  { key: "iro",     jp: "色", name: "Iro",     detail: "Omarchy's themes, to switch" },
  { key: "dougu",   jp: "具", name: "Dōgu",    detail: "Screenshot, picker, stay awake" },
  { key: "shuchu",  jp: "集", name: "Shūchū",  detail: "A focus timer" },
  { key: "hikae",   jp: "控", name: "Hikae",   detail: "Today's list and the clipboard" },
  { key: "batsu",   jp: "跋", name: "Batsu",   detail: "The end of the scroll" }
]

function endleafOf(key) {
  for (var i = 0; i < ENDLEAVES.length; i++) if (ENDLEAVES[i].key === key) return ENDLEAVES[i]
  return ENDLEAVES[1]
}

function endleafLabels() {
  var out = {}
  for (var i = 0; i < ENDLEAVES.length; i++) out[ENDLEAVES[i].key] = ENDLEAVES[i].jp
  return out
}

// A setting's name as its card row gives it ("clockAt" -> "Clock position").
function nameOf(key) {
  for (var i = 0; i < CARDS.length; i++)
    for (var j = 0; j < CARDS[i].rows.length; j++)
      if (CARDS[i].rows[j].key === key) return CARDS[i].rows[j].name
  return key
}

// The Widgets 部品 page: every part the bar can show, as cards of
// `show:<part>` rows (Style.js withShown). Hanko's own parts are always
// listed; the marks, tray apps and hosted widgets as your Omarchy bar
// layout and machine have them. ctx:
//   { own: { indicators, keyboard, mic, tray },   (core/Hosted.js own())
//     indicators: [{ key, glyph, title }],        (core/Extras.js INDICATORS)
//     tray: [{ id, title }],                      (the tray as it is now)
//     hosted: [{ id, name, description, firstParty }] }
function visibilityCards(ctx) {
  var c = ctx || {}
  var own = c.own || {}
  function row(part, name, detail) { return { key: "show:" + part, name: name, detail: detail || "" } }
  var cards = [
    { title: "Left · where you are", rows: [
      row("seal", "Seal", "The stamp at the far left"),
      row("spaces", "Workspaces", "Your spaces"),
      row("title", "Window title", "The focused window")] },
    { title: "Centre · when", rows: [
      row("clock", "Clock", "The time and date"),
      row("media", "Now playing", "What is playing, while it plays"),
      row("weather", "Weather leaf 天", "Left of Time on the scroll"),
      row("endleaf", "End leaf 跋", "Right of Inbox on the scroll")] },
    { title: "Right · readings", rows: [
      row("network", "Network 網", "NET"),
      row("bluetooth", "Bluetooth 双", "BT, where there is an adapter"),
      row("volume", "Volume 音", "VOL"),
      row("brightness", "Brightness 明", "LUM, where the screen has a backlight"),
      row("battery", "Battery 電", "BAT, where there is one"),
      row("notif", "Notifications 報", "The inbox")] }
  ]
  var marks = []
  if (own.indicators) {
    var inds = c.indicators || []
    for (var i = 0; i < inds.length; i++)
      marks.push(row("indicator:" + inds[i].key, inds[i].title + " " + inds[i].glyph, "Indicator stamp"))
  }
  if (own.keyboard) marks.push(row("keyboard", "Keyboard layout", "Only with more than one layout"))
  if (own.mic) marks.push(row("mic", "Microphone", "Its mute mark"))
  if (own.tray) marks.push(row("tray", "Tray 盆", "Every tray app at once"))
  if (marks.length) cards.push({ title: "Marks · Hanko's own", rows: marks })
  var tray = own.tray ? (c.tray || []) : []
  if (tray.length) cards.push({ title: "Tray apps", rows: tray.map(function(t) {
    return row("tray:" + t.id, t.title || t.id, "In the tray now")
  }) })
  var hosted = c.hosted || []
  if (hosted.length) cards.push({ title: "Widgets · from your Omarchy bar", rows: hosted.map(function(h) {
    return row("hosted:" + h.id, h.name || prettyId(h.id),
               (h.firstParty ? "Omarchy" : "Third-party") + (h.description ? " · " + h.description : ""))
  }) })
  cards.push({ title: "Edge", rows: [row("edge", "Bottom edge", "The rule, rod or day rule along the bar")] })
  return cards
}

// "omarchy.system-updates" -> "System updates".
function prettyId(id) {
  var s = String(id || "").replace(/^.*\./, "").replace(/[-_]+/g, " ")
  return s.charAt(0).toUpperCase() + s.slice(1)
}

// The options a row's segmented control offers, as strings.
function optionsFor(key, OPTIONS) {
  if (String(key).indexOf("show:") === 0) return ["shown", "hidden"]
  if (key === "sealGlyph") return GLYPHS.concat(["…"])
  if (key === "motion") return MOTION_OPTIONS.slice()
  if (key === "typeSize") return TYPE_SIZE_OPTIONS.slice()
  if (key === "overview") return OVERVIEW_OPTIONS.slice()
  if (TOUCH_OPTIONS[key]) return TOUCH_OPTIONS[key].slice()
  return (OPTIONS[key] || []).map(String)
}

// Which option is lit for `key` in a resolved style; a typed seal glyph
// outside the four lights "…".
function selected(key, style, glyph) {
  if (key === "sealGlyph") return GLYPHS.indexOf(glyph) >= 0 ? glyph : "…"
  return String(style[key])
}

// How many settings the draft changes from what is saved: every one of the
// twenty-four that resolves differently, the seal glyph, and each monitor whose
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
// The action bar's words. Changes are saved as they are made; `n` is how
// many this visit made, which Undo walks back.
function status(n) {
  if (n === 0) return "Saved · every change is kept as you make it"
  return "Saved · " + n + (n === 1 ? " change" : " changes") + " · Ctrl+Z undoes"
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
