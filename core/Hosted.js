.pragma library

// Other widgets on Hanko's bar (docs/ROADMAP.md, Phase 9). Omarchy's
// shell.json lists the bar's widgets under bar.layout.{left,center,right}.
// Hanko draws some of them as part of its own design, draws its own
// versions of a few more (the tray, the indicators, the keyboard layout and
// the microphone, in its ink), and hosts everything else from the host's
// widget registry: weather, system updates, agents, third-party widgets.

// Parts of the bar Hanko already is.
var DRAWN = ["omarchy.menu", "omarchy.workspaces", "omarchy.active-window", "omarchy.clock",
             "omarchy.elsewhen", "omarchy.audio", "omarchy.network", "omarchy.power",
             "omarchy.media", "omarchy.notifications", "omarchy.spacer", "omarchy.monitor", "omarchy.bluetooth"]
// Widgets Hanko draws its own way.
var OWN = { "omarchy.tray": "tray", "omarchy.indicators": "indicators",
            "omarchy.keyboard-layout": "keyboard", "omarchy.microphone": "mic" }
// What Omarchy ships on the bar when shell.json says nothing.
var DEFAULT_OWN = ["indicators", "keyboard", "tray"]

function entryId(entry) {
  return typeof entry === "string" ? entry : (entry && entry.id ? String(entry.id) : "")
}

function entrySettings(entry) {
  return entry && typeof entry === "object" ? entry : {}
}

// The bar's sections in reading order, as Omarchy's BarModel.js has them:
// centerBegin and centerEnd hang off the centre box's two edges. (Its
// "tray" section is what the tray's drawer holds, not the bar.)
var SECTIONS = ["left", "centerBegin", "center", "centerEnd", "right"]

// Every layout entry in reading order.
function entries(barConfig) {
  var layout = barConfig && barConfig.layout ? barConfig.layout : null
  var out = []
  if (!layout) return out
  for (var s = 0; s < SECTIONS.length; s++) {
    var list = Array.isArray(layout[SECTIONS[s]]) ? layout[SECTIONS[s]] : []
    for (var i = 0; i < list.length; i++) if (entryId(list[i])) out.push(list[i])
  }
  return out
}

// The widgets to host, in layout order: not drawn by Hanko, not one of its
// own, registered with the host (`has(id)`), each once unless the widget
// allows several (`allowMultiple(id)`). [{ id, key, settings }], where key
// is unique per slot.
function hosted(barConfig, has, allowMultiple) {
  var out = []
  var seen = {}
  var list = entries(barConfig)
  for (var i = 0; i < list.length; i++) {
    var id = entryId(list[i])
    if (DRAWN.indexOf(id) >= 0 || OWN[id]) continue
    if (has && !has(id)) continue
    var n = seen[id] || 0
    if (n > 0 && !(allowMultiple && allowMultiple(id))) continue
    seen[id] = n + 1
    out.push({ id: id, key: n ? id + "#" + n : id, settings: entrySettings(list[i]) })
  }
  return out
}

// Which of Hanko's own widgets the layout asks for: { tray, indicators,
// keyboard, mic } booleans. A layout that lists nothing gets Omarchy's
// defaults.
function own(barConfig) {
  var list = entries(barConfig)
  var out = { tray: false, indicators: false, keyboard: false, mic: false }
  if (list.length === 0) {
    for (var d = 0; d < DEFAULT_OWN.length; d++) out[DEFAULT_OWN[d]] = true
    return out
  }
  for (var i = 0; i < list.length; i++) {
    var k = OWN[entryId(list[i])]
    if (k) out[k] = true
  }
  return out
}

// A hosted cell's name in BarSurface.rightCells ("hosted:omarchy.weather"),
// and back.
function cell(id) { return "hosted:" + id }
function idOfCell(c) { return String(c || "").indexOf("hosted:") === 0 ? String(c).slice(7) : "" }
