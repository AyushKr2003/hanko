.pragma library

// The settings window (docs/COMPONENTS.md §6): what its rail lists, how the
// Typesetting 組版 page groups the twenty-six settings into six cards, and the
// small sums its header and action bar print. bar/settings/ draws these.

var RAIL = [
  { group: "01 BAR",    pages: [{ key: "typesetting", label: "Typesetting", jp: "組版" },
                                { key: "presets", label: "Presets", jp: "型" },
                                { key: "parts", label: "Parts", jp: "部品" },
                                { key: "colour", label: "Colour", jp: "色" },
                                { key: "screens", label: "Screens", jp: "画面" }] },
  { group: "02 PANELS", pages: [{ key: "sheets", label: "Sheets", jp: "紙" },
                                { key: "scroll", label: "Scroll", jp: "巻" },
                                { key: "overview", label: "Overview", jp: "一覧" }] },
  { group: "03 FEEL",   pages: [{ key: "motion", label: "Motion", jp: "動" },
                                { key: "keys", label: "Keys", jp: "鍵" }] },
  { group: "04 YOU",    pages: [{ key: "profile", label: "Profile", jp: "印影" },
                                { key: "about", label: "About", jp: "由来" },
                                { key: "credits", label: "Credits", jp: "謝辞" }] }
]

// Old page keys that still open their page (widgets was renamed parts).
var PAGE_ALIASES = { widgets: "parts", advanced: "screens" }

// What each page is for, under its title.
var PAGE_LINES = {
  typesetting: "Click a part of your bar, then pick how it is set. Hover a way to try it; a click keeps it, live on your desktop. Ctrl+Z puts it back.",
  presets: "Patterns for the whole bar. Pick one to see it set as your bar and what it would change; Use puts it on. Your seal, type size, sheets and set-aside parts stay yours.",
  parts: "Everything that can sit on your bar, in the order it sits. Click a part to set it aside; click it again to put it back.",
  colour: "Hanko takes every colour from your Omarchy theme: one paper, four inks stepped from it, one red. Pick a theme here and the whole desk follows.",
  screens: "Each screen can carry a bar of its own. Pick a screen to see and set what differs on it; the rest follow Typesetting.",
  sheets: "A sheet drops from the cell you click. Pick a sheet, then the hand that draws it; hover a hand to see that sheet in it.",
  scroll: "The handscroll unrolls from the rod with every panel on it. Choose what sits between its sections and what follows Inbox.",
  overview: "The workspace overview: every space at once. Choose how it is laid out.",
  motion: "No springs, no glow: paper drops with weight and settles, ink arrives after it, only a new stamp overshoots. The timesheet below is every move Hanko makes; hover a row to play it.",
  keys: "Every key Hanko answers to, where it answers. Hover a key to read what it does; the commands at the foot are for your own Hyprland bindings."
}

// The group and page a rail key names (Typesetting when the key is unknown).
function pageInfo(key) {
  if (PAGE_ALIASES[key]) key = PAGE_ALIASES[key]
  for (var g = 0; g < RAIL.length; g++)
    for (var p = 0; p < RAIL[g].pages.length; p++)
      if (RAIL[g].pages[p].key === key) return { group: RAIL[g].group, page: RAIL[g].pages[p] }
  return pageInfo("typesetting")
}

// Rail pages drawn as full plates (no title, no cards): Profile, About,
// Credits (bar/settings/*Plate.qml).
var PLATES = ["profile", "about", "credits"]

var PRESET_BLURBS = {
  Kamon: "the family crest", Inkan: "the seal only",
  Quiet: "least on screen", Islet: "floating, inset",
  "Shōji": "washi and the seasons",
  Ma: "room between the groups", Shizuka: "quiet until it changes",
  Suji: "five brush lines", "Inrō": "one case for everything"
}

// Each preset's kanji, for the Presets 型 page: what the bar is, in one
// sign. The four studies keep the kanji they were drawn with.
var PRESET_KANJI = {
  Kamon: "家紋", Inkan: "印", Quiet: "素", Islet: "島",
  "Shōji": "障子", Ma: "間", Shizuka: "静", Suji: "筋", "Inrō": "印籠"
}

// The settings a preset card names under its title: how the bar reads at
// a glance (status, clock, height, surface, panels), as small caps.
var PRESET_FACTS = ["status", "clock", "height", "surface", "panels"]
// Under Inkan there is no bar to describe: the form, its corner, its panels.
var INKAN_FACTS = ["form", "inkanAt", "panels"]
function presetFacts(style) {
  var st = style || {}
  if (st.form === "inkan")
    return INKAN_FACTS.map(function(k) { return (k === "inkanAt" ? "seal" : k) + " " + st[k] }).join(" · ")
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

// What a preset would change on your bar (the pattern book, Presets 型): one
// row per setting that resolves differently, in the proof's order, each
// with the part it is set on: [{ key, name, no, part, from, to }]. Panel
// settings (on Scroll and Overview) come last, numbered "—"; a preset that
// also sets the sheets' hands says so. S is core/Style.js.
function presetDiff(doc, name, S) {
  var now = S.resolve(doc), then = S.resolve(S.withPreset(doc, name))
  var out = []
  var seen = {}
  for (var i = 0; i < PROOF.length; i++) {
    var keys = PROOF[i].cast.concat(PROOF[i].also)
    for (var j = 0; j < keys.length; j++) {
      var k = keys[j]
      seen[k] = true
      if (k === "sealGlyph" || String(now[k]) === String(then[k])) continue
      out.push({ key: k, name: nameOf(k), no: PROOF[i].no, part: PROOF[i].name, from: String(now[k]), to: String(then[k]) })
    }
  }
  for (var x = 0; x < S.KEYS.length; x++) {
    var key = S.KEYS[x]
    if (seen[key] || String(now[key]) === String(then[key])) continue
    out.push({ key: key, name: nameOf(key), no: "—", part: "Panels", from: String(now[key]), to: String(then[key]) })
  }
  if (String(now.overview) !== String(then.overview))
    out.push({ key: "overview", name: "Overview", no: "—", part: "Panels", from: String(now.overview), to: String(then.overview) })
  if (JSON.stringify(now.sheetStyles) !== JSON.stringify(then.sheetStyles))
    out.push({ key: "sheetStyles", name: "Sheet hands", no: "—", part: "Panels", from: "yours", to: name === "Shōji" ? "shōji, every sheet" : "the preset's" })
  return out
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
    { key: "form", name: "Form", detail: "The bar, or Inkan: one seal in a corner that prints every sheet" },
    { key: "inkanAt", name: "Seal corner", detail: "Where Inkan's seal sits" },
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

// Typesetting 組版 as a proof (校正, docs/settings-kosei): the bar is set
// large as a galley, each part numbered in the margin; a part picked shows
// its case, a specimen of the part per way it can be set, then the few
// plain choices that go with it. Every setting of CARDS' first five cards
// is here once; the sixth (Panels) is on the Scroll 巻 page.
//   cast   settings drawn as specimens (the part, set each way)
//   also   settings given as words (a segmented row, or the glyph stones)
//   bar    true when the part is drawn only on the bar (not under Inkan)
//   show   the part's name for `hidden` (Style.js PARTS), when it can be
//          set aside as a whole; Status and Indicators are set aside per
//          reading and per stamp on the Parts 部品 page
var PROOF = [
  { key: "seal", show: "seal", no: "01", name: "Seal", jp: "印", bar: false,
    line: "The stamp at the far left. A click opens Omarchy's menu, a right-click a terminal, the wheel steps through your spaces.",
    cast: ["seal"], also: ["sealGlyph"] },
  { key: "spaces", show: "spaces", no: "02", name: "Workspaces", jp: "場", bar: true,
    line: "Your spaces, the one you are on inverted. Click one to go there; the wheel steps.",
    cast: ["spaces"], also: ["numerals"] },
  { key: "title", show: "title", no: "03", name: "Window title", jp: "窓", bar: true,
    line: "The focused window: its app, and what it shows.",
    cast: ["title"], also: [] },
  { key: "clock", show: "clock", no: "04", name: "Clock", jp: "時", bar: true,
    line: "The time and the date. A click drops the Time sheet.",
    cast: ["clock"], also: ["hours", "season", "clockAt"] },
  { key: "media", show: "media", no: "05", name: "Now playing", jp: "曲", bar: true,
    line: "What is playing, while it plays. Click to pause, middle-click for the next track.",
    cast: ["media"], also: [] },
  { key: "status", no: "06", name: "Status", jp: "状", bar: true,
    line: "Network, Bluetooth, volume, light and battery. Each opens its sheet; red only when something needs you.",
    cast: ["status"], also: ["meters", "bluetooth"] },
  { key: "indicators", no: "07", name: "Indicators", jp: "標", bar: true,
    line: "Omarchy's six indicators as stamps: recording, dictation, reminder, stay awake, night light, do not disturb.",
    cast: ["indicatorStyle"], also: ["indicators"] },
  { key: "notif", show: "notif", no: "08", name: "Inbox", jp: "報", bar: true,
    line: "Your notifications. A click opens them, a right-click is do not disturb.",
    cast: ["notif"], also: [] },
  { key: "edge", show: "edge", no: "09", name: "Edge", jp: "縁", bar: true,
    line: "The line along the bar's foot, and the rules between its groups.",
    cast: ["edge"], also: ["rules", "pointer"] },
  { key: "frame", no: "10", name: "Frame", jp: "枠", bar: false,
    line: "What the bar is, its paper and its size. Inkan takes the strip away and leaves one seal in a corner.",
    cast: ["form", "surface"], also: ["height", "typeSize", "float", "position", "grain", "inkanAt"] }
]

// The Scroll 巻 page's card: how panels open, and the scroll's own frame
// (its dividers and end leaf have galleries of their own there).
var PANELS_CARD = { title: "Panels · how they open", rows: CARDS[5].rows.filter(function(r) {
  return ["panels", "sides", "guides", "overview"].indexOf(r.key) >= 0
}) }

// Two indicators lit, for a proof made while none is on (the glyphs and
// icons of core/Extras.js INDICATORS).
var SAMPLE_INDICATORS = [
  { key: "recording", glyph: "写", icon: "\u{f0ec2}", title: "Screen recording", on: false, red: false, count: 0 },
  { key: "dictation", glyph: "言", icon: "\u{f036c}", title: "Dictation", on: false, red: false, count: 0 },
  { key: "reminder",  glyph: "予", icon: "\u{f088c}", title: "Reminder", on: false, red: false, count: 0 },
  { key: "awake",     glyph: "目", icon: "\u{f0176}", title: "Stay awake", on: true, red: false, count: 0 },
  { key: "night",     glyph: "月", icon: "\u{f050e}", title: "Night light", on: true, red: false, count: 0 },
  { key: "dnd",       glyph: "休", icon: "\u{f009b}", title: "Do not disturb", on: false, red: false, count: 0 }
]

function proofPart(key) {
  for (var i = 0; i < PROOF.length; i++) if (PROOF[i].key === key) return PROOF[i]
  return PROOF[0]
}

// The part a setting is set on ("hours" -> clock), or null.
function proofPartOf(setting) {
  for (var i = 0; i < PROOF.length; i++)
    if (PROOF[i].cast.indexOf(setting) >= 0 || PROOF[i].also.indexOf(setting) >= 0) return PROOF[i]
  return null
}

// Each way a cast setting can be set, as its specimen names it: a name in
// plain words and one line on what it looks like.
var WAYS = {
  seal: {
    stamp: ["Stamp", "Your glyph, carved in red"],
    workspace: ["Workspace", "The space you are on, as a numeral"],
    carved: ["Carved", "An outline; inked red when letters wait"],
    none: ["None", "The bar starts with your spaces"] },
  spaces: {
    folio: ["Folio", "Numbered pages, a dot per window"],
    layout: ["Layout", "Each space's real tiling, in small"],
    kanji: ["Kanji", "一 二 三, the live one inverted"],
    dots: ["Dots", "One mark a space; the quietest"],
    brush: ["Brush", "Numerals, a stroke under the live one"] },
  title: {
    cell: ["Cell", "The app over the title, labelled"],
    byline: ["Byline", "The app in italic, then the path"],
    ink: ["Ink", "The app, then what it shows"],
    none: ["None", "No title at all"] },
  clock: {
    stacked: ["Stacked", "The time large, the date beside it"],
    inline: ["Inline", "Time and date on one line"],
    mono: ["Mono", "Your terminal's face, tracked"],
    season: ["Season", "With the solar term of the year"] },
  media: {
    cell: ["Cell", "Artist and song, labelled"],
    underline: ["Underline", "The song, its progress drawn under"],
    ink: ["Ink", "Three level bars, song and artist"],
    none: ["None", "Nothing, even while music plays"] },
  status: {
    cells: ["Cells", "A label over every value"],
    glyphs: ["Glyphs", "A kanji and a figure each"],
    numerals: ["Numerals", "VOL 62 · NET, in mono"],
    ink: ["Ink", "Icons; the battery an ensō"],
    ma: ["Ma 間", "Three groups held apart by space"],
    shizuka: ["Shizuka 静", "Quiet until something changes"],
    suji: ["Suji 筋", "A brush line each, as long as the level"],
    inro: ["Inrō 印籠", "One ruled case of compartments"] },
  indicatorStyle: {
    icon: ["Icon", "Omarchy's own icon"],
    kanji: ["Kanji", "A small red seal"],
    iconname: ["Icon and name", "Named while it is on"],
    kanjiname: ["Kanji and name", "A seal, named while on"] },
  notif: {
    count: ["Count", "INBOX 03 and a red dot"],
    stamps: ["Stamps", "Up to three seals, pressed askew"],
    seal: ["On the seal", "The count moves onto your seal"] },
  edge: {
    hairline: ["Hairline", "One ink line"],
    dayrule: ["Day rule", "The day as a ruler, now in red"],
    rod: ["Rod", "A rod to pull the panels from"],
    rodrule: ["Rod and rule", "The rod, ruled with the day"] },
  form: {
    bar: ["Bar", "The strip across the screen"],
    inkan: ["Inkan 印", "One seal in a corner; it prints every sheet"] },
  surface: {
    solid: ["Solid", "Plain paper"],
    glass: ["Glass", "Paper you can half see through"],
    washi: ["Washi", "Paper with long fibres"] }
}

function wayOf(key, value) {
  var w = WAYS[key] && WAYS[key][String(value)]
  return w ? { name: w[0], line: w[1] } : { name: String(value), line: "" }
}

// The words for an `also` setting: its row name and a short line.
var ALSO = {
  sealGlyph: ["Glyph", "Carved on the stamp; type your own in the last stone"],
  numerals: ["Numerals", "Arabic, or kanji in brush"],
  hours: ["Hours", "Auto follows Omarchy's clock"],
  season: ["Season", "The solar term beside the date"],
  clockAt: ["Sits", "In the middle, or after the inbox"],
  meters: ["Meters", "Ticks beside the quantities"],
  bluetooth: ["Bluetooth", "Device, a mark each, a count, or off"],
  indicators: ["Show", "All six with the off ones faint, or only those on"],
  rules: ["Dividers", "Hairlines between the groups"],
  pointer: ["Pointer", "A brush mark under what you point at"],
  height: ["Height", "At Omarchy's font size 12"],
  typeSize: ["Type", "Hanko's text over Omarchy's font size"],
  float: ["Float", "Flush on the edge, or 8 px off it, framed"],
  position: ["Position", "Top or bottom of the screen"],
  grain: ["Grain", "The washi's fibres"],
  inkanAt: ["Corner", "Where Inkan's seal sits; drag it there too"]
}

function alsoOf(key) {
  var a = ALSO[key]
  return a ? { name: a[0], line: a[1] } : { name: nameOf(key), line: "" }
}

// The settings of a part the draft sets apart from its preset (edits),
// for the red marks in the margin.
function proofEdits(part, doc) {
  var edits = (doc && doc.edits) || {}
  var keys = part.cast.concat(part.also)
  return keys.filter(function(k) { return edits[k] !== undefined })
}

// A part is lit by a search when the query is in its name, kanji, line,
// the names of its settings or of any of their ways.
function proofMatches(part, query, OPTIONS) {
  var q = String(query || "").trim().toLowerCase()
  if (!q) return true
  var hay = [part.name, part.jp, part.line, part.key]
  var keys = part.cast.concat(part.also)
  for (var i = 0; i < keys.length; i++) {
    hay.push(keys[i], nameOf(keys[i]), alsoOf(keys[i]).name)
    var opts = optionsFor(keys[i], OPTIONS)
    for (var j = 0; j < opts.length; j++) {
      hay.push(opts[j])
      if (WAYS[keys[i]]) { var w = wayOf(keys[i], opts[j]); hay.push(w.name, w.line) }
    }
  }
  return hay.join(" ").toLowerCase().indexOf(q) >= 0
}

// The next part along (Left/Right on the page), wrapping.
function proofStep(key, delta) {
  var i = PROOF.indexOf(proofPart(key))
  return PROOF[(i + delta + PROOF.length) % PROOF.length].key
}

// The Motion 動 page: one switch outside the twenty-six (style.json `motion`),
// and the timings it governs (core/Motion.qml holds the numbers).
var MOTION_CARD = { title: "Motion · paper moves like paper", rows: [
  { key: "motion", name: "Motion", detail: "Paper eases every move; still cuts each one to its end frame" }] }
var MOTION_OPTIONS = ["paper", "still"]
var TYPE_SIZE_OPTIONS = ["small", "regular", "large"]
var OVERVIEW_OPTIONS = ["grid", "dynamic", "framed"]
// Shōji's touches, beside the twenty-six (Style.js SEASONS, NUMERALS, GRAINS).
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

// The Parts 部品 page as a sorts tray: every part the bar can carry, in the
// order it sits, grouped, each a sort to set aside or put back. kind:
//   crop   a real crop of the bar (BarCrop.qml)
//   stamp  an indicator's stamp (glyph)
//   tray   a tray app (icon, letter)
//   text   a widget or a leaf, named (glyph)
// ctx as visibilityCards. Every part is a Style.js part name.
function partsTray(ctx) {
  var c = ctx || {}
  var own = c.own || {}
  function sort(part, name, kind, extra) {
    var o = { part: part, name: name, kind: kind, glyph: "", icon: "", letter: "", detail: "" }
    for (var k in (extra || {})) o[k] = extra[k]
    return o
  }
  var groups = [
    { title: "Left · where you are", jp: "左", sorts: [
      sort("seal", "Seal", "crop"), sort("spaces", "Workspaces", "crop"), sort("title", "Window title", "crop")] },
    { title: "Centre · when", jp: "中", sorts: [
      sort("clock", "Clock", "crop"), sort("media", "Now playing", "crop", { detail: "While something plays" })] },
    { title: "Right · readings", jp: "右", sorts: [
      sort("network", "Network", "crop"), sort("bluetooth", "Bluetooth", "crop", { detail: "Where there is an adapter" }),
      sort("volume", "Volume", "crop"), sort("brightness", "Brightness", "crop", { detail: "Where the screen has a backlight" }),
      sort("battery", "Battery", "crop", { detail: "Where there is one" }),
      sort("notif", "Inbox", "crop")] }
  ]
  var marks = []
  if (own.indicators) {
    var inds = c.indicators || []
    for (var i = 0; i < inds.length; i++)
      marks.push(sort("indicator:" + inds[i].key, inds[i].title, "stamp", { glyph: inds[i].glyph, icon: inds[i].icon || "" }))
  }
  if (own.keyboard) marks.push(sort("keyboard", "Keyboard layout", "text", { glyph: "鍵", detail: "With more than one layout" }))
  if (own.mic) marks.push(sort("mic", "Microphone", "text", { glyph: "言", detail: "Its mute mark" }))
  if (own.tray) marks.push(sort("tray", "Tray", "text", { glyph: "盆", detail: "Every tray app at once" }))
  if (marks.length) groups.push({ title: "Marks · Hanko's own", jp: "標", sorts: marks })
  var tray = own.tray ? (c.tray || []) : []
  if (tray.length) groups.push({ title: "Tray apps", jp: "盆", sorts: tray.map(function(t) {
    return sort("tray:" + t.id, t.title || t.id, "tray", { icon: t.icon || "", letter: t.letter || String(t.title || t.id || "·").charAt(0).toUpperCase() })
  }) })
  var hosted = c.hosted || []
  if (hosted.length) groups.push({ title: "Widgets · from your Omarchy bar", jp: "借", sorts: hosted.map(function(h) {
    var name = h.name || prettyId(h.id)
    return sort("hosted:" + h.id, name, "text", { glyph: name.charAt(0).toUpperCase(), detail: h.firstParty ? "Omarchy" : "Third-party" })
  }) })
  groups.push({ title: "Edge and scroll", jp: "縁", sorts: [
    sort("edge", "Edge", "crop", { detail: "The line along the foot" }),
    sort("weather", "Weather leaf", "text", { glyph: "天", detail: "Left of Time on the scroll" }),
    sort("endleaf", "End leaf", "text", { glyph: "跋", detail: "Right of Inbox on the scroll" })] })
  return groups
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
// twenty-six that resolves differently, the seal glyph, and each monitor whose
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

// The last change in words, for the action bar: "Clock · stacked → inline",
// "Preset · Kamon → Ma", "Seal set aside", "DP-2 · Height 40 → 32"; "" when
// the two documents resolve the same.
function describeChange(before, after, resolve) {
  if (!before || !after) return ""
  if (before.preset !== after.preset) return "Preset · " + before.preset + " → " + after.preset
  var hb = before.hidden || [], ha = after.hidden || []
  for (var i = 0; i < ha.length; i++) if (hb.indexOf(ha[i]) < 0) return partName(ha[i]) + " set aside"
  for (var j = 0; j < hb.length; j++) if (ha.indexOf(hb[j]) < 0) return partName(hb[j]) + " put back"
  if (before.sealGlyph !== after.sealGlyph) return "Seal glyph · " + before.sealGlyph + " → " + after.sealGlyph
  var a = resolve(before), b = resolve(after)
  var skip = ["preset", "edited", "hidden", "sheetStyles"]
  for (var k in b) {
    if (skip.indexOf(k) >= 0) continue
    if (String(a[k]) === String(b[k])) continue
    var nm = nameOf(k)
    if (nm === k) nm = { motion: "Motion", panelOpacity: "Panel opacity" }[k] || k
    return nm + " · " + a[k] + " → " + b[k]
  }
  var sa = JSON.stringify(a.sheetStyles || {}), sb = JSON.stringify(b.sheetStyles || {})
  if (sa !== sb) return "Sheet hands"
  var ma = before.monitors || {}, mb = after.monitors || {}
  var names = {}
  for (var x in ma) names[x] = true
  for (var y in mb) names[y] = true
  for (var m in names) {
    var oa = ma[m] || {}, ob = mb[m] || {}
    for (var key in ob) if (String(oa[key]) !== String(ob[key])) return m + " · " + nameOf(key) + " " + ob[key]
    for (var key2 in oa) if (ob[key2] === undefined) return m + " · " + nameOf(key2) + " as the rest"
  }
  return ""
}

// A part name as the Parts page gives it ("indicator:night" -> "Night light").
function partName(part) {
  var p = String(part)
  var fixed = { seal: "Seal", spaces: "Workspaces", title: "Window title", clock: "Clock", media: "Now playing",
                network: "Network", bluetooth: "Bluetooth", volume: "Volume", brightness: "Brightness",
                battery: "Battery", notif: "Inbox", edge: "Edge", keyboard: "Keyboard layout",
                mic: "Microphone", tray: "Tray", weather: "Weather leaf", endleaf: "End leaf" }
  if (fixed[p]) return fixed[p]
  if (p.indexOf("indicator:") === 0) {
    var names = { recording: "Screen recording", dictation: "Dictation", reminder: "Reminder", awake: "Stay awake", night: "Night light", dnd: "Do not disturb" }
    return names[p.slice(10)] || p.slice(10)
  }
  if (p.indexOf("tray:") === 0) return p.slice(5)
  if (p.indexOf("hosted:") === 0) return prettyId(p.slice(7))
  return p
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
