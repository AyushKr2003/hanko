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

// ---------------------------------------------------------------- dynamic
// The second layout, `overview: dynamic`: Ryoku's overview, kept close to
// how Ryoku draws and drives it (shell/modules/overview there). Desktops are
// blocks of PER_DESKTOP workspace ids; the strip on top shows the ones that
// hold workspaces and one more to start; below, the viewed desktop's
// workspaces that have windows (and the live one) as full cells, then one
// "+" cell that opens the next free workspace. Tab, the arrows and the wheel
// move a selection; Enter or a click goes and closes.

var PER_DESKTOP = 10

function deskOf(id) { return id > 0 ? Math.floor((id - 1) / PER_DESKTOP) : 0 }

// ids: the numbered workspaces this screen holds. -> [desk, …, new desk].
function deskList(ids, activeId, allIds) {
  var seen = {}, top = deskOf(activeId)
  for (var i = 0; i < ids.length; i++) { seen[deskOf(ids[i])] = true; top = Math.max(top, deskOf(ids[i])) }
  seen[deskOf(activeId)] = true
  var out = []
  for (var d = 0; d <= top; d++) if (seen[d]) out.push(d)
  var globalTop = top
  for (var j = 0; j < (allIds || []).length; j++) globalTop = Math.max(globalTop, deskOf(allIds[j]))
  out.push(globalTop + 1)
  return out
}

// One dot per workspace in a desktop, true when it holds windows.
function deskDots(spaces, desk) {
  var out = []
  for (var i = 0; i < spaces.length; i++) if (deskOf(spaces[i].id) === desk) out.push(spaces[i].count > 0)
  return out
}

// The first id no workspace uses in this desktop; past a full desktop, the
// first id of the next empty one.
function newWsId(allIds, desk) {
  var used = {}
  for (var i = 0; i < allIds.length; i++) used[allIds[i]] = true
  for (var id = desk * PER_DESKTOP + 1; id <= desk * PER_DESKTOP + PER_DESKTOP; id++) if (!used[id]) return id
  var top = 0
  for (var j = 0; j < allIds.length; j++) top = Math.max(top, deskOf(allIds[j]))
  return (top + 1) * PER_DESKTOP + 1
}

// spaces: this screen's workspaces ({ id, count, windows/all, urgent }).
// -> the cells: windowed (or live) workspaces of the desktop, then "+".
function slots(spaces, activeId, desk, allIds) {
  var out = []
  var list = (spaces || []).filter(function(s) { return s && s.id > 0 && deskOf(s.id) === desk })
  list.sort(function(a, b) { return a.id - b.id })
  for (var i = 0; i < list.length; i++) {
    var s = list[i]
    if (s.count > 0 || s.id === activeId)
      out.push({ id: s.id, pos: s.id - desk * PER_DESKTOP, add: false, active: s.id === activeId,
                 urgent: !!s.urgent, count: s.count || 0, windows: s.all || s.windows || [] })
  }
  if (activeId > 0 && deskOf(activeId) === desk && !out.some(function(c) { return c.id === activeId }))
    out.push({ id: activeId, pos: activeId - desk * PER_DESKTOP, add: false, active: true, urgent: false, count: 0, windows: [] })
  out.sort(function(a, b) { return a.id - b.id })
  out.push({ id: newWsId(allIds || [], desk), pos: out.length + 1, add: true, active: false, urgent: false, count: 0, windows: [] })
  return out
}

// Pack n cells into rows for a cell height h (cells are h / aspect wide),
// wrapping when a row would pass availW. null when one cell can't fit.
function packRows(n, h, aspect, availW, gap) {
  var w = h / aspect
  if (w > availW) return null
  var rows = [], row = [], rowW = 0
  for (var i = 0; i < n; i++) {
    var add = (row.length ? gap : 0) + w
    if (rowW + add > availW && row.length) { rows.push(row); row = []; rowW = 0; add = w }
    row.push(i); rowW += add
  }
  if (row.length) rows.push(row)
  return { rows: rows, blockH: rows.length * h + Math.max(0, rows.length - 1) * gap }
}

// The largest cell height (lo..hi, in steps) whose packing fits; rows are
// centred, the block too. -> { items: [{ x, y, w, h }], cellH, height }
function lay(n, availW, availH, aspect, gap, lo, hi, stepPx) {
  aspect = aspect > 0 ? aspect : 0.5625
  var chosen = null, ch = lo
  for (var h = Math.min(hi, availH); h >= lo; h -= stepPx) {
    var p = packRows(n, h, aspect, availW, gap)
    if (p && p.blockH <= availH) { chosen = p; ch = h; break }
  }
  if (!chosen) { chosen = packRows(n, lo, aspect, availW, gap) || { rows: [[]], blockH: lo }; ch = lo }
  var w = ch / aspect, items = []
  var y0 = Math.max(0, (availH - chosen.blockH) / 2)
  for (var r = 0; r < chosen.rows.length; r++) {
    var ids = chosen.rows[r]
    var rw = ids.length * w + Math.max(0, ids.length - 1) * gap
    var x = (availW - rw) / 2
    for (var c = 0; c < ids.length; c++) items[ids[c]] = { x: x + c * (w + gap), y: y0 + r * (ch + gap), w: w, h: ch }
  }
  return { items: items, cellH: ch, height: chosen.blockH }
}

// The selection, one along, wrapping.
function cycle(selected, delta, n) {
  if (n <= 0) return 0
  return ((selected + delta) % n + n) % n
}

var DYNAMIC_HINT = "SCROLL / TAB  CYCLE      ALT+TAB  DESKTOP      DRAG  MOVE      ✕  CLOSE      CLICK / ENTER  GO      ESC  DISMISS"

// The layouts `overview` takes (style.json, beside the counted settings).
var LAYOUTS = ["grid", "dynamic", "mission"]
