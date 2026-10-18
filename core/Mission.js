.pragma library

// The third overview, `overview: mission` 見開き (a spread): the live
// workspace's windows laid out side by side at the largest size that fits,
// a strip of this screen's workspaces over them, and a search field that
// finds windows, apps, Omarchy menu actions and sums as you type. Ported
// from AyushKr2003/omarchy-overview's mission control (its layout, its
// strip, its keys, its search sources), printed in Hanko's paper and ink.
// Pure; tests/unit.mjs runs it. bar/overview/MissionView.qml draws it and
// bar/OverviewWindow.qml acts on it.

// ---------------------------------------------------------------- layout
// windows: [{ key, w, h, cx, cy }] (size and centre, in any one unit);
// area: { x, y, w, h } where the tiles may go; opts: { gap, labelHeight,
// maxScale }. Every row count from 1 to n is tried and the one that draws
// the windows largest wins (ties go to fewer rows). Rows are cut by each
// window's vertical centre and read left to right by its horizontal one, so
// the spread reads in the desk's order.
// -> { scale, rows, slots: { key: { x, y, w, h, row } } }
function layout(windows, area, opts) {
  var gap = Math.max(0, opts && opts.gap !== undefined ? opts.gap : 24)
  var labelHeight = Math.max(0, opts && opts.labelHeight ? opts.labelHeight : 0)
  var maxScale = opts && opts.maxScale ? opts.maxScale : 1
  var result = { scale: 1, rows: 0, slots: {} }
  var n = (windows || []).length
  if (n === 0 || !(area.w > 0) || !(area.h > 0)) return result

  var byY = windows.slice().sort(function(a, b) { return (a.cy - b.cy) || (a.cx - b.cx) })
  var best = null
  for (var rowCount = 1; rowCount <= n; rowCount++) {
    var rows = splitRows(byY, rowCount)
    var scale = maxScale, sumHeights = 0
    for (var r = 0; r < rows.length; r++) {
      var widths = 0, tallest = 1
      for (var i = 0; i < rows[r].length; i++) { widths += Math.max(1, rows[r][i].w); tallest = Math.max(tallest, rows[r][i].h) }
      scale = Math.min(scale, (area.w - gap * (rows[r].length - 1)) / widths)
      sumHeights += tallest
    }
    scale = Math.min(scale, (area.h - gap * (rows.length - 1) - labelHeight * rows.length) / sumHeights)
    if (!(scale > 0)) continue
    if (!best || scale > best.scale * 1.0001) best = { scale: scale, rows: rows }
  }
  if (!best) return result

  var s = best.scale
  var heights = best.rows.map(function(row) {
    var t = 1
    for (var i = 0; i < row.length; i++) t = Math.max(t, row[i].h)
    return t * s
  })
  var total = gap * (best.rows.length - 1) + labelHeight * best.rows.length
  for (var h = 0; h < heights.length; h++) total += heights[h]
  var y = area.y + (area.h - total) / 2
  for (var k = 0; k < best.rows.length; k++) {
    var row = best.rows[k]
    var rowW = gap * (row.length - 1)
    for (var j = 0; j < row.length; j++) rowW += Math.max(1, row[j].w) * s
    var x = area.x + (area.w - rowW) / 2
    for (var m = 0; m < row.length; m++) {
      var w = Math.max(1, row[m].w) * s, hh = Math.max(1, row[m].h) * s
      result.slots[row[m].key] = { x: Math.round(x), y: Math.round(y + (heights[k] - hh) / 2), w: Math.round(w), h: Math.round(hh), row: k }
      x += w + gap
    }
    y += heights[k] + labelHeight + gap
  }
  result.scale = s
  result.rows = best.rows.length
  return result
}

// Contiguous runs of the y-sorted windows, as even in count as can be, each
// read left to right.
function splitRows(sorted, rowCount) {
  var rows = [], base = Math.floor(sorted.length / rowCount), extra = sorted.length % rowCount, at = 0
  for (var r = 0; r < rowCount; r++) {
    var count = base + (extra > 0 ? 1 : 0)
    if (extra > 0) extra--
    var row = sorted.slice(at, at + count).sort(function(a, b) { return a.cx - b.cx })
    at += count
    if (row.length > 0) rows.push(row)
  }
  return rows
}

// The slot keys in reading order (row, then x), for the keyboard.
function order(slots) {
  return Object.keys(slots || {}).sort(function(a, b) { return (slots[a].row - slots[b].row) || (slots[a].x - slots[b].x) })
}

// The rect nearest `from` in a direction (left | right | up | down), or -1.
// Off-axis distance counts double, so the pick stays in line.
function neighbour(rects, from, direction) {
  var o = rects[from]
  if (!o) return rects.length > 0 ? 0 : -1
  var ox = o.x + o.w / 2, oy = o.y + o.h / 2, bestIndex = -1, bestScore = Infinity
  for (var i = 0; i < rects.length; i++) {
    if (i === from) continue
    var dx = rects[i].x + rects[i].w / 2 - ox, dy = rects[i].y + rects[i].h / 2 - oy
    var along, across
    if (direction === "left") { along = -dx; across = dy }
    else if (direction === "right") { along = dx; across = dy }
    else if (direction === "up") { along = -dy; across = dx }
    else { along = dy; across = dx }
    if (along <= 1) continue
    var score = along + 2 * Math.abs(across)
    if (score < bestScore) { bestScore = score; bestIndex = i }
  }
  return bestIndex
}

function lerp(a, b, t) { return a + (b - a) * t }

// The spread's windows: every window of the live workspace, floating ones
// too, tiled under floating (so a float keeps its place on top while it
// zooms out), the last focused on top within each.
function windowsOf(spaces, activeId) {
  for (var i = 0; i < (spaces || []).length; i++) {
    if (spaces[i].id !== activeId) continue
    var list = (spaces[i].all || spaces[i].windows || []).slice()
    return list.sort(function(a, b) {
      if (!!a.floating !== !!b.floating) return a.floating ? 1 : -1
      return (b.focus === undefined ? 0 : b.focus) - (a.focus === undefined ? 0 : a.focus)
    })
  }
  return []
}

// ---------------------------------------------------------------- strip
// This screen's numbered workspaces, the live one always among them, then
// "new" (the first id nobody uses). -> ["ws:1", "ws:3", "new"]
function stripKeys(spaces, activeId) {
  var ids = []
  for (var i = 0; i < (spaces || []).length; i++) if (spaces[i].id > 0 && ids.indexOf(spaces[i].id) < 0) ids.push(spaces[i].id)
  if (activeId > 0 && ids.indexOf(activeId) < 0) ids.push(activeId)
  ids.sort(function(a, b) { return a - b })
  var keys = ids.map(function(id) { return "ws:" + id })
  keys.push("new")
  return keys
}

function idOfKey(key) { return String(key).indexOf("ws:") === 0 ? Number(String(key).slice(3)) : -1 }

// The lowest id no workspace on any screen uses.
function freeId(allIds) {
  var id = 1
  while ((allIds || []).indexOf(id) >= 0) id++
  return id
}

// One cell's size: the screen's shape, as tall as the strip allows, narrower
// when there are many.
function stripCell(count, stripH, roomW, aspect, gap) {
  aspect = aspect > 0 ? aspect : 0.5625
  if (count <= 0 || stripH <= 0) return { w: 0, h: 0 }
  var natural = stripH / aspect
  var w = Math.max(24, Math.min(natural, (roomW - (count - 1) * gap) / count))
  return { w: w, h: w * aspect }
}

// The workspace one along the strip from the live one, or -1 past the ends.
function stepId(keys, activeId, delta) {
  var ids = keys.map(idOfKey).filter(function(id) { return id > 0 })
  var at = ids.indexOf(activeId) + delta
  return at >= 0 && at < ids.length ? ids[at] : -1
}

// ---------------------------------------------------------------- search
function words(text) {
  return String(text || "").toLowerCase().split(/\s+/).filter(function(w) { return w.length > 0 })
}

// -1 when a term is missing; 3 when the name starts with the first term, 2
// when one of its words does, 1 otherwise.
function score(haystack, primary, terms) {
  var hay = String(haystack || "").toLowerCase()
  for (var i = 0; i < terms.length; i++) if (hay.indexOf(terms[i]) < 0) return -1
  var head = String(primary || "").toLowerCase(), first = terms[0] || ""
  if (head.indexOf(first) === 0) return 3
  if (head.split(/[^a-z0-9]+/).some(function(w) { return w.indexOf(first) === 0 })) return 2
  return 1
}

function ranked(list, most) {
  return list.sort(function(a, b) { return b.score - a.score }).slice(0, most)
}

// spaces: Hypr.workspaces rows. -> window results, best first.
function findWindows(q, spaces) {
  var terms = words(q), out = []
  for (var i = 0; i < (spaces || []).length; i++) {
    var sp = spaces[i], list = sp.all || sp.windows || []
    for (var j = 0; j < list.length; j++) {
      var w = list[j]
      var s = score([w.title, w.cls, w.name].join(" "), w.title || w.name, terms)
      if (s < 0) continue
      out.push({ kind: "window", key: "window:" + w.address, title: w.title || w.name || "Window",
                 subtitle: (w.name || w.cls || "") + "  ·  space " + sp.id, category: "window",
                 score: s, cls: w.cls || w.name || "", address: w.address, space: sp.id })
    }
  }
  return ranked(out, 6)
}

// apps: [{ id, name, comment, genericName, keywords, icon }] (DesktopEntries).
function findApps(q, apps) {
  var terms = words(q), out = []
  for (var i = 0; i < (apps || []).length; i++) {
    var a = apps[i]
    if (!a || !a.id || a.noDisplay) continue
    var s = score([a.name, a.genericName, a.comment, (a.keywords || []).join(" "), a.id].join(" "), a.name, terms)
    if (s < 0) continue
    out.push({ kind: "app", key: "app:" + a.id, title: a.name || a.id, subtitle: a.genericName || a.comment || "",
               category: "app", score: s, id: a.id, icon: a.icon || "" })
  }
  return ranked(out, 8)
}

function findMenu(q, entries) {
  var terms = words(q), out = []
  for (var i = 0; i < (entries || []).length; i++) {
    var e = entries[i], s = score(e.searchText, e.label, terms)
    if (s < 0) continue
    out.push({ kind: "menu", key: "menu:" + e.id, title: e.label, subtitle: e.path, category: "menu", score: s, action: e.action })
  }
  return ranked(out, 6)
}

function findSum(q) {
  var v = evaluate(q)
  if (v === null) return []
  var text = format(v)
  return [{ kind: "calc", key: "calc", title: "= " + text, subtitle: "Enter copies it", category: "calc", score: 9, value: text }]
}

// Every source, in the order the results list prints them.
function find(q, sources) {
  var t = String(q || "").trim()
  if (!t) return []
  sources = sources || {}
  return [].concat(findSum(t), findWindows(t, sources.spaces), findApps(t, sources.apps), findMenu(t, sources.menu))
}

// The categories' heads: kanji that are the thing itself.
var CATEGORIES = {
  calc: { jp: "算", name: "SUM" },
  window: { jp: "窓", name: "WINDOWS" },
  app: { jp: "具", name: "APPS" },
  menu: { jp: "品書", name: "OMARCHY MENU" }
}

// ------------------------------------------------------- the Omarchy menu
// Read-only: Omarchy's menu JSONC (its defaults, then the user's extension),
// flattened to the leaves that run something.
function stripJsonc(raw) {
  return String(raw || "").replace(/^\s*\/\/[^\n]*(\n|$)/gm, "").replace(/,(\s*[}\]])/g, "$1")
}

function parseMenu(raw) {
  try {
    var parsed = JSON.parse(stripJsonc(raw) || "{}")
    var items = parsed && parsed.items && typeof parsed.items === "object" ? parsed.items : parsed
    return items && typeof items === "object" && !Array.isArray(items) ? items : {}
  } catch (e) {
    return {}
  }
}

function menuEntries(defaultsRaw, userRaw) {
  var merged = {}
  var sources = [parseMenu(defaultsRaw), parseMenu(userRaw)]
  for (var s = 0; s < sources.length; s++) {
    for (var id in sources[s]) {
      var next = {}, prev = merged[id] || {}
      for (var a in prev) next[a] = prev[a]
      for (var b in sources[s][id]) next[b] = sources[s][id][b]
      merged[id] = next
    }
  }
  function labelFor(id) { return String(merged[id] && merged[id].label ? merged[id].label : id.split(".").pop()) }
  var out = []
  for (var key in merged) {
    var item = merged[key]
    // Rows guarded by a shell condition only make sense inside the menu.
    if (!item || !item.action || item.provider || item.when || item.disabled) continue
    var parts = key.split("."), parents = []
    for (var i = 1; i < parts.length; i++) parents.push(labelFor(parts.slice(0, i).join(".")))
    var aliases = Array.isArray(item.aliases) ? item.aliases.join(" ") : String(item.aliases || "")
    var terms = Array.isArray(item.searchTerms) ? item.searchTerms.join(" ") : ""
    out.push({ id: key, label: String(item.label || parts[parts.length - 1]), path: parents.length ? parents.join(" › ") : "Omarchy menu",
               action: String(item.action), searchText: [item.label, aliases, terms, item.description || "", parents.join(" ")].join(" ") })
  }
  return out
}

// ------------------------------------------------------------ the sums
// + - * / % ^, brackets, unary minus, decimals, pi, e and a few functions,
// without eval. null when the text isn't a sum worth answering.
var FUNCTIONS = { sqrt: Math.sqrt, abs: Math.abs, sin: Math.sin, cos: Math.cos, tan: Math.tan, ln: Math.log,
                  log: function(v) { return Math.log(v) / Math.LN10 }, round: Math.round, floor: Math.floor, ceil: Math.ceil }
var CONSTANTS = { pi: Math.PI, e: Math.E }

function tokenize(text) {
  var tokens = [], re = /\s*(?:(\d+(?:[.,]\d+)?|\.\d+)|([a-z]+)|(\*\*|[-+*/%^()×÷]))/g, at = 0
  while (at < text.length) {
    re.lastIndex = at
    var m = re.exec(text)
    if (!m || m.index !== at) {
      if (/^\s*$/.test(text.slice(at))) break
      return null
    }
    at = re.lastIndex
    if (m[1] !== undefined) tokens.push({ type: "num", value: Number(m[1].replace(",", ".")) })
    else if (m[2] !== undefined) tokens.push({ type: "name", value: m[2] })
    else tokens.push({ type: "op", value: m[3] === "**" ? "^" : m[3] === "×" ? "*" : m[3] === "÷" ? "/" : m[3] })
  }
  return tokens
}

function evaluate(text) {
  var source = String(text || "").trim().replace(/^=\s*/, "").toLowerCase()
  if (!source || source.length > 200) return null
  var tokens = tokenize(source)
  if (!tokens || tokens.length === 0) return null
  // A bare number or word is not a sum.
  var sum = tokens.some(function(t) { return (t.type === "op" && t.value !== "(" && t.value !== ")") || (t.type === "name" && FUNCTIONS[t.value]) })
  if (!sum) return null

  var pos = 0
  function peek() { return tokens[pos] }
  function take() { return tokens[pos++] }
  function expect(op) { var t = take(); if (!t || t.type !== "op" || t.value !== op) throw new Error("expect") }
  function primary() {
    var t = take()
    if (!t) throw new Error("end")
    if (t.type === "num") return t.value
    if (t.type === "name") {
      if (CONSTANTS[t.value] !== undefined) return CONSTANTS[t.value]
      var fn = FUNCTIONS[t.value]
      if (!fn) throw new Error("name")
      var next = peek()
      if (next && next.type === "op" && next.value === "(") { take(); var v = expression(); expect(")"); return fn(v) }
      return fn(unary())
    }
    if (t.value === "(") { var inner = expression(); expect(")"); return inner }
    throw new Error("token")
  }
  function unary() {
    var t = peek()
    if (t && t.type === "op" && (t.value === "-" || t.value === "+")) { take(); var v = unary(); return t.value === "-" ? -v : v }
    return power()
  }
  function power() {
    var base = primary(), t = peek()
    if (t && t.type === "op" && t.value === "^") { take(); return Math.pow(base, unary()) }
    return base
  }
  function term() {
    var v = unary()
    for (;;) {
      var t = peek()
      if (!t || t.type !== "op" || (t.value !== "*" && t.value !== "/" && t.value !== "%")) break
      take()
      var rhs = unary()
      if (t.value === "*") v *= rhs
      else if (t.value === "/") v /= rhs
      else v %= rhs
    }
    return v
  }
  function expression() {
    var v = term()
    for (;;) {
      var t = peek()
      if (!t || t.type !== "op" || (t.value !== "+" && t.value !== "-")) break
      take()
      var rhs = term()
      v = t.value === "+" ? v + rhs : v - rhs
    }
    return v
  }
  try {
    var value = expression()
    return pos === tokens.length && isFinite(value) ? value : null
  } catch (e) {
    return null
  }
}

function format(value) {
  if (!isFinite(value)) return ""
  if (Math.floor(value) === value && Math.abs(value) < 1e15) return String(value)
  return String(Number(value.toPrecision(12)))
}

// The keys, as the foot prints them.
var KEYS = [["←  →  ↑  ↓", "choose"], ["TAB", "strip · windows"], ["PGUP  PGDN", "switch"], ["TYPE", "search"],
            ["ENTER", "go"], ["DRAG", "move · hold to swap"], ["MIDDLE  DEL", "close a window"], ["ESC", "done"]]
