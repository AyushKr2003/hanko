.pragma library

// The workspace overview 一覧: workspaces as printed pages in a fixed grid,
// their windows where they really sit. The working principle follows
// AyushKr2003/omarchy-overview (itself after Shanu-Kumawat/quickshell-overview):
// a rows x columns grid holding one group of workspace ids (the group the
// live workspace is in), rows with nothing on them folded away, arrows that
// switch the real workspace while the overview stays open, numbers that jump
// within the group. Pure; tests/unit.mjs runs it. bar/overview/ draws it and
// bar/OverviewWindow.qml acts on it.

var ROWS = 2
var COLUMNS = 5

// The group of ids the live workspace is in: [first, last].
function group(activeId, rows, cols) {
  var per = rows * cols
  var g = Math.floor((Math.max(1, activeId) - 1) / per)
  return [g * per + 1, g * per + per]
}

// spaces: Hypr.spacesFor() rows ({ id, urgent, count, windows, all }).
// -> the pages in grid order: { id, row, col, active, urgent, count,
// windows, folded } with `row` counted over the rows still shown.
function pages(spaces, activeId, rows, cols, foldEmpty) {
  var byId = {}
  for (var i = 0; i < (spaces || []).length; i++) if (spaces[i] && spaces[i].id > 0) byId[spaces[i].id] = spaces[i]
  var span = group(activeId, rows, cols)
  var out = [], shownRow = 0
  for (var r = 0; r < rows; r++) {
    var row = [], live = false
    for (var c = 0; c < cols; c++) {
      var id = span[0] + r * cols + c
      var s = byId[id] || {}
      var count = s.count || 0
      if (count > 0 || id === activeId) live = true
      row.push({ id: id, col: c, active: id === activeId, urgent: !!s.urgent, count: count,
                 windows: s.all || s.windows || [] })
    }
    if (foldEmpty && !live) continue
    for (var k = 0; k < row.length; k++) { row[k].row = shownRow; out.push(row[k]) }
    shownRow++
  }
  return out
}

function rowsShown(list) {
  var n = 0
  for (var i = 0; i < list.length; i++) n = Math.max(n, list[i].row + 1)
  return n
}

// The largest page that fits the room: each page is a header band over a
// screen of the monitor's aspect (height / width).
// -> { pageW, pageH, screenH, width, height }
function fit(rowCount, cols, roomW, roomH, aspect, gap, headH, maxScreenH) {
  aspect = aspect > 0 ? aspect : 0.5625
  rowCount = Math.max(1, rowCount)
  var byW = ((roomW - (cols - 1) * gap) / cols) * aspect
  var byH = (roomH - (rowCount - 1) * gap) / rowCount - headH
  var sh = Math.max(24, Math.min(byW, byH, maxScreenH || 1e9))
  var pw = sh / aspect, ph = sh + headH
  return { pageW: pw, pageH: ph, screenH: sh,
           width: cols * pw + (cols - 1) * gap, height: rowCount * ph + (rowCount - 1) * gap }
}

// Where an arrow key (or hjkl) goes from the live workspace: one column or
// one row along, wrapping inside the group, as omarchy-overview does.
// dir: left | right | up | down.
function step(activeId, dir, rows, cols) {
  var span = group(activeId, rows, cols)
  var at = Math.max(0, Math.min(rows * cols - 1, activeId - span[0]))
  var r = Math.floor(at / cols), c = at % cols
  if (dir === "left") c = (c - 1 + cols) % cols
  else if (dir === "right") c = (c + 1) % cols
  else if (dir === "up") r = (r - 1 + rows) % rows
  else if (dir === "down") r = (r + 1) % rows
  return span[0] + r * cols + c
}

// A number key inside the group: 1-9, and 0 for the tenth. -1 when the
// group has no such page.
function jump(activeId, digit, rows, cols) {
  var n = digit === 0 ? 10 : digit
  if (n < 1 || n > rows * cols) return -1
  return group(activeId, rows, cols)[0] + n - 1
}

// The wheel walks every workspace in the group, wrapping.
function wheel(activeId, delta, rows, cols) {
  var span = group(activeId, rows, cols)
  var id = activeId + delta
  if (id < span[0]) id = span[1]
  if (id > span[1]) id = span[0]
  return id
}

// A workspace showing a fullscreen window shows only that one.
function visibleWindows(windows) {
  var list = windows || []
  for (var i = 0; i < list.length; i++) if (list[i].fullscreen) return [list[i]]
  // Floating windows print over the tiling.
  return list.slice().sort(function(a, b) { return (a.floating ? 1 : 0) - (b.floating ? 1 : 0) })
}

// The header's sums: "04 SPACES · 11 WINDOWS".
function summary(list) {
  var spaces = 0, windows = 0
  for (var i = 0; i < list.length; i++) if (list[i].count > 0) { spaces++; windows += list[i].count }
  function two(v) { return v < 10 ? "0" + v : String(v) }
  return two(spaces) + (spaces === 1 ? " SPACE" : " SPACES") + "  ·  " + two(windows) + (windows === 1 ? " WINDOW" : " WINDOWS")
}

// The keys, as the foot prints them.
var KEYS = [["←  →  ↑  ↓", "switch"], ["1 – 0", "jump"], ["CLICK", "go"], ["DRAG", "move a window"],
            ["MIDDLE", "close a window"], ["ENTER  ESC", "done"]]
