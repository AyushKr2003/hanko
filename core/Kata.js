.pragma library

// Kata 型: one engine for every design (docs/kata on the revision1 branch).
//
// Margin, Leaf and Shōji share the bar's anatomy, the one-panel model, the
// panel contents and the rules; they differ in a dozen small parts. A design
// is a preset over PARTS: nine main parts a person can borrow from another
// design, three partners that follow the part they belong with (`auto`),
// and three touches that are plain switches. Classic is today's Typeset bar
// (Style.js), drawn by its own code until it is ported onto the parts.
//
// style.json gains three optional keys beside the Typeset ones:
//   { "design": "shoji", "borrow": { "slider": "ruler" }, "touches": { "season": "english" },
//     "monitors": { "DP-2": { "design": "margin" } } }
// Pure JavaScript with no QML dependency, so tests/unit.mjs runs it under Node.

// v: variant -> the design it comes from. Main parts come first; partners
// name the part they follow.
var PARTS = {
  surface: { main: true, v: { paper: "margin", card: "leaf", washi: "shoji" } },
  arrive:  { main: true, v: { fold: "margin", slip: "leaf", slide: "shoji" } },
  pointer: { main: true, v: { thread: "margin", crop: "leaf", brush: "shoji" } },
  select:  { main: true, v: { tint: "margin", plate: "leaf", wash: "shoji" } },
  slider:  { main: true, v: { ruler: "margin", block: "leaf", brush: "shoji" } },
  ring:    { main: true, v: { glyph: "margin", enso: "shoji" } },
  seal:    { main: true, v: { outline: "margin", deboss: "leaf", carved: "shoji" } },
  unread:  { main: true, v: { edge: "margin", dogear: "leaf", stamp: "shoji" } },
  sign:    { main: true, v: { eyebrow: "margin", tabs: "leaf", tategaki: "shoji" } },
  // The second wave (K6): whole-screen pieces with the same mechanism.
  // Hold is Leaf's soak, which Margin shares; Shōji draws a brush stroke.
  notify:   { main: true, v: { cards: "margin", tickets: "leaf", rows: "shoji" } },
  overview: { main: true, v: { miniatures: "margin", contact: "leaf", framed: "shoji" } },
  hold:     { main: true, v: { soak: "leaf", stroke: "shoji" } },
  corner:  { main: false, follows: "surface", v: { soft: "margin", cut: "leaf" } },
  divider: { main: false, follows: "surface", v: { hairline: "margin", score: "leaf", lattice: "shoji" } },
  tempo:   { main: false, follows: "arrive", v: { spring: "margin", snap: "leaf", johakyu: "shoji" } }
}
var PART_KEYS = Object.keys(PARTS)
var MAIN_PARTS = PART_KEYS.filter(function(k) { return PARTS[k].main })

// What an `auto` partner becomes, from the part it follows.
var AUTO = {
  corner:  { paper: "soft", card: "cut", washi: "cut" },
  divider: { paper: "hairline", card: "score", washi: "lattice" },
  tempo:   { fold: "spring", slip: "snap", slide: "johakyu" }
}

// Switches that work with every design.
var TOUCHES = {
  season:   ["off", "kanji", "english"],
  numerals: ["arabic", "kanji"],
  grain:    ["smooth", "fine", "toothy"]
}
var TOUCH_KEYS = Object.keys(TOUCHES)

var DESIGNS = {
  margin: { parts: { surface: "paper", arrive: "fold", pointer: "thread", select: "tint", slider: "ruler", ring: "glyph", seal: "outline", unread: "edge", sign: "eyebrow",
                    notify: "cards", overview: "miniatures", hold: "soak" },
            touches: { season: "off", numerals: "arabic", grain: "smooth" } },
  leaf:   { parts: { surface: "card", arrive: "slip", pointer: "crop", select: "plate", slider: "block", ring: "glyph", seal: "deboss", unread: "dogear", sign: "tabs",
                    notify: "tickets", overview: "contact", hold: "soak" },
            touches: { season: "off", numerals: "arabic", grain: "fine" } },
  shoji:  { parts: { surface: "washi", arrive: "slide", pointer: "brush", select: "wash", slider: "brush", ring: "enso", seal: "carved", unread: "stamp", sign: "tategaki",
                    notify: "rows", overview: "framed", hold: "stroke" },
            touches: { season: "kanji", numerals: "arabic", grain: "fine" } }
}
var CLASSIC = "classic"
var DESIGN_NAMES = [CLASSIC, "margin", "leaf", "shoji"]
// Today's bar stays the default until the Kata bar is complete.
var DEFAULT_DESIGN = CLASSIC
var LABELS = { classic: "Classic", margin: "Margin", leaf: "Leaf", shoji: "Shōji" }
var PART_LABELS = { surface: "surface", arrive: "panels", pointer: "pointer", select: "selection", slider: "slider", ring: "battery",
                    seal: "seal", unread: "unread mark", sign: "panel name",
                    notify: "letters", overview: "overview", hold: "hold to confirm", corner: "corners", divider: "dividers", tempo: "tempo" }

function designName(name) {
  var n = String(name === undefined || name === null ? "" : name).toLowerCase()
  if (n === "shōji") n = "shoji"
  return DESIGN_NAMES.indexOf(n) >= 0 ? n : ""
}

function isVariant(part, value) {
  return !!PARTS[part] && (value === "auto" || PARTS[part].v[String(value)] !== undefined)
}

// The Kata keys of a style document (or a monitor's overrides), cleaned:
// unknown designs, parts and values are dropped with a warning, so a file
// written by a newer Hanko degrades instead of failing.
function clean(doc, warnings, where) {
  var out = {}
  doc = doc && typeof doc === "object" ? doc : {}
  var at = where ? " (" + where + ")" : ""
  if (doc.design !== undefined) {
    var d = designName(doc.design)
    if (d) out.design = d
    else if (warnings) warnings.push("unknown design " + doc.design + at)
  }
  if (doc.borrow && typeof doc.borrow === "object") {
    var b = {}
    for (var k in doc.borrow) {
      var v = String(doc.borrow[k])
      if (isVariant(k, v)) { if (v !== "auto") b[k] = v }
      else if (warnings) warnings.push(PARTS[k] ? "ignored borrow " + k + "=" + v + at : "ignored unknown part " + k + at)
    }
    if (Object.keys(b).length) out.borrow = b
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
// object: { design, classic, <part>: variant, touches, borrowed, warnings }.
// A monitor that names its own design starts from that design; borrows and
// touches merge over the document's.
function resolve(doc, monitor) {
  var warnings = []
  var top = clean(doc, warnings)
  var mons = doc && doc.monitors && typeof doc.monitors === "object" ? doc.monitors : {}
  var mine = monitor && mons[monitor] ? clean(mons[monitor], warnings, monitor) : {}
  var design = mine.design || top.design || DEFAULT_DESIGN
  var borrow = merged(top.borrow, mine.borrow)
  var touchEdits = merged(top.touches, mine.touches)
  var out = { design: design, classic: design === CLASSIC, warnings: warnings }
  var base = DESIGNS[design] || DESIGNS.margin   // Classic resolves Margin's parts, unused until it is ported
  var i, k
  for (i = 0; i < PART_KEYS.length; i++) {
    k = PART_KEYS[i]
    out[k] = borrow[k] !== undefined ? borrow[k] : (PARTS[k].main ? base.parts[k] : null)
  }
  for (k in AUTO) if (out[k] === null) out[k] = AUTO[k][out[PARTS[k].follows]]
  out.touches = merged(base.touches, touchEdits)
  // What differs from the design: a main part not its own, a partner not what auto would give.
  out.borrowed = Object.keys(borrow).filter(function(p) {
    if (out.classic) return true
    return PARTS[p].main ? base.parts[p] !== borrow[p] : AUTO[p][out[PARTS[p].follows]] !== borrow[p]
  }).sort(function(a, b) { return PART_KEYS.indexOf(a) - PART_KEYS.indexOf(b) })
  return out
}

// Edits that return a new document (or null for a value the key does not
// take). Picking a design drops the borrows, as choosing a preset drops the
// Typeset edits; touches are kept, they belong to the person, not the design.
function copyDoc(doc) { return JSON.parse(JSON.stringify(doc && typeof doc === "object" ? doc : {})) }

function withDesign(doc, name) {
  var d = designName(name)
  if (!d) return null
  var next = copyDoc(doc)
  if (d === DEFAULT_DESIGN) delete next.design
  else next.design = d
  delete next.borrow
  return next
}

// Borrowing a design's own part, or `auto`, gives it back.
function withBorrow(doc, part, value) {
  if (!isVariant(part, value)) return null
  var next = copyDoc(doc)
  var b = next.borrow && typeof next.borrow === "object" ? next.borrow : {}
  var design = resolve(next).design
  var own = PARTS[part].main && DESIGNS[design] && DESIGNS[design].parts[part] === value
  if (value === "auto" || own) delete b[part]
  else b[part] = String(value)
  if (Object.keys(b).length) next.borrow = b
  else delete next.borrow
  return next
}

function withTouch(doc, key, value) {
  if (!TOUCHES[key] || TOUCHES[key].indexOf(String(value)) < 0) return null
  var next = copyDoc(doc)
  var t = next.touches && typeof next.touches === "object" ? next.touches : {}
  var design = resolve(next).design
  var base = (DESIGNS[design] || DESIGNS.margin).touches
  if (base[key] === String(value)) delete t[key]
  else t[key] = String(value)
  if (Object.keys(t).length) next.touches = t
  else delete next.touches
  return next
}

// A coherent surprise: one of the three designs and two or three parts
// borrowed from the other two. rng() returns [0, 1).
function surprised(doc, rng) {
  var names = ["margin", "leaf", "shoji"]
  var d = names[Math.floor(rng() * names.length)]
  var pool = MAIN_PARTS.slice()
  var count = 2 + Math.floor(rng() * 2)
  var next = withDesign(doc, d)
  for (var i = 0; i < count && pool.length; i++) {
    var part = pool.splice(Math.floor(rng() * pool.length), 1)[0]
    var others = Object.keys(PARTS[part].v).filter(function(v) { return v !== DESIGNS[d].parts[part] })
    next = withBorrow(next, part, others[Math.floor(rng() * others.length)])
  }
  return next
}

// "Shōji with Margin's slider, Leaf's seal"
function describe(style) {
  var base = LABELS[style.design] || style.design
  if (style.classic || !style.borrowed || !style.borrowed.length) return base
  return base + " with " + style.borrowed.map(function(p) {
    return (LABELS[PARTS[p].v[style[p]]] || "") + "’s " + PART_LABELS[p]
  }).join(", ")
}
