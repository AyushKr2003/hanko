.pragma library

// Battō 抜刀 (docs/kaze, mockup 08): the menu's top-level kinds as a rail
// of crests down the card's left edge (a ring and one kanji each), the one
// you are in inverted. plugins/hanko.menu draws it from Omarchy's menu
// items; this file decides which items get a crest, and which.

var CRESTS = {
  apps: "器", learn: "学", trigger: "動", style: "彩", setup: "設",
  install: "入", remove: "除", update: "新", about: "由", system: "政"
}

// The crest for a top-level menu: its own, else the first kanji of its
// label, else 文.
function crestFor(id, label) {
  if (CRESTS[id]) return CRESTS[id]
  var m = /[㐀-鿿]/.exec(String(label || ""))
  return m ? m[0] : "文"
}

// The rail: every item whose parent is the root and that opens a menu
// (`kind: "menu"` or children), in the menu's order.
//   items   { id: { parent, kind, label, … } }   order  [id, …]
function rail(items, order, childCount) {
  var out = []
  for (var i = 0; i < (order || []).length; i++) {
    var id = order[i], it = items[id]
    if (!it || id === "root" || (it.parent || "root") !== "root") continue
    var opens = it.kind === "menu" || it.provider || (childCount ? childCount(id) > 0 : false)
    if (!opens) continue
    out.push({ id: id, crest: crestFor(id, it.label), label: String(it.label || id) })
  }
  return out
}

// The top-level menu an item lives under ("style.theme" → "style").
function topOf(id) {
  var s = String(id || "root")
  return s === "root" ? "root" : s.split(".")[0]
}
