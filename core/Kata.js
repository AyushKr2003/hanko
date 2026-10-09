.pragma library

// Kata 型: one engine for every design (docs/kata on the revision1 branch).
//
// Shōji is the one Kata design: a preset over PARTS, nine main parts and
// three whole-screen ones, three partners that follow the part they belong
// with (`auto`), and three touches that are plain switches. Classic (shown
// as Hanko) is today's Typeset bar (Style.js), drawn by its own code until
// it is ported onto the parts. Margin and Leaf were removed; a file that
// names them loads as Hanko, and a saved `borrow` is ignored.
//
// style.json gains two optional keys beside the Typeset ones:
//   { "design": "shoji", "touches": { "season": "english" },
//     "monitors": { "DP-2": { "design": "classic" } } }
// Pure JavaScript with no QML dependency, so tests/unit.mjs runs it under Node.

// v: variant -> the design it comes from. Main parts come first; partners
// name the part they follow.
var PARTS = {
  surface: { main: true, v: { washi: "shoji" } },
  arrive:  { main: true, v: { slide: "shoji" } },
  pointer: { main: true, v: { brush: "shoji" } },
  select:  { main: true, v: { wash: "shoji" } },
  slider:  { main: true, v: { brush: "shoji" } },
  ring:    { main: true, v: { enso: "shoji" } },
  seal:    { main: true, v: { carved: "shoji" } },
  unread:  { main: true, v: { stamp: "shoji" } },
  sign:    { main: true, v: { tategaki: "shoji" } },
  // The second wave (K6): whole-screen pieces with the same mechanism.
  notify:   { main: true, v: { rows: "shoji" } },
  overview: { main: true, v: { framed: "shoji" } },
  hold:     { main: true, v: { stroke: "shoji" } },
  corner:  { main: false, follows: "surface", v: { cut: "shoji" } },
  divider: { main: false, follows: "surface", v: { lattice: "shoji" } },
  tempo:   { main: false, follows: "arrive", v: { johakyu: "shoji" } }
}
var PART_KEYS = Object.keys(PARTS)
var MAIN_PARTS = PART_KEYS.filter(function(k) { return PARTS[k].main })

// What an `auto` partner becomes, from the part it follows.
var AUTO = {
  corner:  { washi: "cut" },
  divider: { washi: "lattice" },
  tempo:   { slide: "johakyu" }
}

// Switches that work with every design.
var TOUCHES = {
  season:   ["off", "kanji", "english"],
  numerals: ["arabic", "kanji"],
  grain:    ["smooth", "fine", "toothy"]
}
var TOUCH_KEYS = Object.keys(TOUCHES)

var DESIGNS = {
  shoji:  { parts: { surface: "washi", arrive: "slide", pointer: "brush", select: "wash", slider: "brush", ring: "enso", seal: "carved", unread: "stamp", sign: "tategaki",
                    notify: "rows", overview: "framed", hold: "stroke" },
            touches: { season: "kanji", numerals: "arabic", grain: "fine" } }
}
var CLASSIC = "classic"
var DESIGN_NAMES = [CLASSIC, "shoji"]
// Hanko (id "classic", kept so saved files still load) stays the default until the Kata bar is complete.
var DEFAULT_DESIGN = CLASSIC
// Designs that were removed, and what a file naming them loads as.
var RETIRED = { margin: CLASSIC, leaf: CLASSIC }
var LABELS = { classic: "Hanko", shoji: "Shōji" }
var PART_LABELS = { surface: "surface", arrive: "panels", pointer: "pointer", select: "selection", slider: "slider", ring: "battery",
                    seal: "seal", unread: "unread mark", sign: "panel name",
                    notify: "letters", overview: "overview", hold: "hold to confirm", corner: "corners", divider: "dividers", tempo: "tempo" }

function designName(name) {
  var n = String(name === undefined || name === null ? "" : name).toLowerCase()
  if (n === "shōji") n = "shoji"
  if (n === "hanko") n = CLASSIC   // the main bar is stored as "classic"
  if (RETIRED[n]) n = RETIRED[n]
  return DESIGN_NAMES.indexOf(n) >= 0 ? n : ""
}

function isVariant(part, value) {
  return !!PARTS[part] && (value === "auto" || PARTS[part].v[String(value)] !== undefined)
}

// The Kata keys of a style document (or a monitor's overrides), cleaned:
// unknown designs and touches are dropped with a warning, so a file written
// by a newer Hanko degrades instead of failing. `borrow` (parts taken from
// another design, when there were several) means nothing now and is dropped
// quietly: it was valid when it was written.
function clean(doc, warnings, where) {
  var out = {}
  doc = doc && typeof doc === "object" ? doc : {}
  var at = where ? " (" + where + ")" : ""
  if (doc.design !== undefined) {
    var d = designName(doc.design)
    if (d) out.design = d
    else if (warnings) warnings.push("unknown design " + doc.design + at)
  }
  if (doc.touches && typeof doc.touches === "object") {
    var t = {}
    for (var j in doc.touches) {
      var tv = String(doc.touches[j])
      if (TOUCHES[j] && TOUCHES[j].indexOf(tv) >= 0) t[j] = tv
      else if (warnings) warnings.push(TOUCHES[j] ? "ignored touch " + j + "=" + tv + at : "ignored unknown touch " + j + at)
    }
    if (Object.keys(t).length) out.touches = t
  }
  return out
}

function merged(a, b) {
  var out = {}
  var k
  for (k in a || {}) out[k] = a[k]
  for (k in b || {}) out[k] = b[k]
  return out
}

// The style document's Kata keys, then the named monitor's, into one flat
// object: { design, classic, <part>: variant, touches, warnings }. A monitor
// that names its own design starts from that design; touches merge over the
// document's.
function resolve(doc, monitor) {
  var warnings = []
  var top = clean(doc, warnings)
  var mons = doc && doc.monitors && typeof doc.monitors === "object" ? doc.monitors : {}
  var mine = monitor && mons[monitor] ? clean(mons[monitor], warnings, monitor) : {}
  var design = mine.design || top.design || DEFAULT_DESIGN
  var touchEdits = merged(top.touches, mine.touches)
  var out = { design: design, classic: design === CLASSIC, warnings: warnings }
  var base = DESIGNS[design] || DESIGNS.shoji   // Classic resolves Shōji's parts, unused until it is ported
  var i, k
  for (i = 0; i < PART_KEYS.length; i++) {
    k = PART_KEYS[i]
    out[k] = PARTS[k].main ? base.parts[k] : null
  }
  for (k in AUTO) out[k] = AUTO[k][out[PARTS[k].follows]]
  out.touches = merged(base.touches, touchEdits)
  return out
}

// Edits that return a new document (or null for a value the key does not
// take). Touches are kept across a design change: they belong to the
// person, not the design. Each edit drops a leftover `borrow`.
function copyDoc(doc) {
  var next = JSON.parse(JSON.stringify(doc && typeof doc === "object" ? doc : {}))
  delete next.borrow
  return next
}

// A removed design is not something to pick, only something to load.
function withDesign(doc, name) {
  if (RETIRED[String(name === undefined || name === null ? "" : name).toLowerCase()]) return null
  var d = designName(name)
  if (!d) return null
  var next = copyDoc(doc)
  if (d === DEFAULT_DESIGN) delete next.design
  else next.design = d
  return next
}

function withTouch(doc, key, value) {
  if (!TOUCHES[key] || TOUCHES[key].indexOf(String(value)) < 0) return null
  var next = copyDoc(doc)
  var t = next.touches && typeof next.touches === "object" ? next.touches : {}
  var design = resolve(next).design
  var base = (DESIGNS[design] || DESIGNS.shoji).touches
  if (base[key] === String(value)) delete t[key]
  else t[key] = String(value)
  if (Object.keys(t).length) next.touches = t
  else delete next.touches
  return next
}

// The design's name, as Settings and `hanko design` print it.
function describe(style) {
  return LABELS[style.design] || style.design
}
