.pragma library

// Sheets 紙 (docs/COMPONENTS.md, "Panels"; panels: sheets): which sheets
// exist, which bar cell each one drops from, which Omarchy panel ids it
// answers to, and where it lands. bar/SheetWindow.qml and the harness both
// place sheets with these, so the geometry is tested here.

// In the order Tab walks them, which is the order they sit on the bar.
var SHEETS = [
  { key: "time",    no: "01", jp: "時", label: "TIME",    width: 500, anchors: ["clock"],
    omarchy: ["omarchy.clock", "omarchy.elsewhen"] },
  { key: "sound",   no: "02", jp: "音", label: "SOUND",   width: 430, anchors: ["volume"],
    omarchy: ["omarchy.audio"] },
  { key: "network", no: "03", jp: "網", label: "NETWORK", width: 430, anchors: ["network"],
    omarchy: ["omarchy.network"] },
  { key: "power",   no: "04", jp: "電", label: "POWER",   width: 420, anchors: ["battery", "brightness"],
    omarchy: ["omarchy.power"] },
  { key: "inbox",   no: "06", jp: "報", label: "INBOX",   width: 460, anchors: ["notif"],
    omarchy: [] }
]

// Kept clear of the screen's sides, as the mockups do.
var SCREEN_MARGIN = 8
// A sheet from the right zone hangs mostly to the left of its cell and
// reaches this far past the cell's right end.
var OVERHANG = 40
// The tear (the bone line where the sheet leaves the bar) runs this far
// past each end of the cell.
var TEAR_REACH = 8

function byKey(key) {
  for (var i = 0; i < SHEETS.length; i++) if (SHEETS[i].key === key) return SHEETS[i]
  return null
}

// The sheet that opens for a click on a bar cell, or "".
function forCell(cell) {
  for (var i = 0; i < SHEETS.length; i++)
    if (SHEETS[i].anchors.indexOf(cell) >= 0) return SHEETS[i].key
  return ""
}

// The sheet standing in for one of Omarchy's bar-widget panels, or "".
function forOmarchyId(id) {
  for (var i = 0; i < SHEETS.length; i++)
    if (SHEETS[i].omarchy.indexOf(String(id || "")) >= 0) return SHEETS[i].key
  return ""
}

// The Omarchy id a cell stands for (togglePanelAt counts these), or "".
function omarchyIdForCell(cell) {
  var s = byKey(forCell(cell))
  return s && s.omarchy.length ? s.omarchy[0] : ""
}

// Tab and Shift+Tab: the next sheet among those that can open, wrapping.
function step(key, delta, available) {
  var keys = []
  for (var i = 0; i < SHEETS.length; i++)
    if (!available || available.indexOf(SHEETS[i].key) >= 0) keys.push(SHEETS[i].key)
  if (!keys.length) return ""
  var at = keys.indexOf(key)
  if (at < 0) return keys[0]
  return keys[(at + delta % keys.length + keys.length) % keys.length]
}

// `togglePanelAt right N`: the Nth distinct Omarchy panel among the right
// zone's cells, 1-based, so the hotkey still means "the Nth thing on the
// right" in Hanko. "" when there is none.
function panelAt(cells, index) {
  var ids = []
  for (var i = 0; i < (cells || []).length; i++) {
    var id = omarchyIdForCell(cells[i])
    if (id && ids.indexOf(id) < 0) ids.push(id)
  }
  var n = parseInt(index, 10)
  return n >= 1 && n <= ids.length ? ids[n - 1] : ""
}

// Where a sheet of `width` lands for a cell at [cellX, cellX + cellW) on a
// screen `screenW` wide: centred under the clock, hanging left from a
// right-zone cell, never past the margins. The tear is in sheet coordinates.
function place(key, cellX, cellW, width, screenW) {
  var x
  if (key === "time") x = cellX + cellW / 2 - width / 2
  else x = cellX + cellW - width + OVERHANG
  x = Math.round(Math.max(SCREEN_MARGIN, Math.min(screenW - width - SCREEN_MARGIN, x)))
  var tearX = Math.max(0, Math.round(cellX - x - TEAR_REACH))
  var tearEnd = Math.min(width, Math.round(cellX + cellW - x + TEAR_REACH))
  return { x: x, tearX: tearX, tearWidth: Math.max(0, tearEnd - tearX) }
}
