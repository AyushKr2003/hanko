.pragma library

// The bar's edge (docs/COMPONENTS.md, "Edge"): where the day rule's ticks
// fall, how much of the day is spent, and how far the rod has to be pulled.
// bar/Edge.qml draws from these, so the maths is tested without a shell.

var HOURS = 24
// Every sixth hour is a major tick (06, 12, 18).
var MAJOR_EVERY = 6
// How far (px, before scaling) the rod must be dragged to count as a pull.
var PULL_THRESHOLD = 24

// The part of the day spent at `date`, 0 at midnight up to (not reaching) 1.
// Minutes only: the bar's clock ticks once a minute.
function dayFraction(date) {
  var d = date instanceof Date ? date : new Date(date)
  if (isNaN(d.getTime())) return 0
  return (d.getHours() * 60 + d.getMinutes()) / (HOURS * 60)
}

// The 23 inner hour ticks (01..23; midnight sits on both ends, unmarked).
function hourTicks() {
  var out = []
  for (var h = 1; h < HOURS; h++)
    out.push({ hour: h, fraction: h / HOURS, major: h % MAJOR_EVERY === 0 })
  return out
}

// A fraction of `length` as a whole pixel, kept inside [0, length - width]
// so a mark of `width` px never spills past either end.
function at(fraction, length, width) {
  var w = Math.max(0, Number(width) || 0)
  var x = Math.round(Math.max(0, Math.min(1, Number(fraction) || 0)) * length)
  return Math.max(0, Math.min(Math.max(0, length - w), x))
}

// Where the edge runs along the bar: full width, or held in from each end
// for the rod's caps and for the inset frame.
function span(mode, width, inset) {
  var pad = 0
  if (mode === "rod" || mode === "rodrule") pad = inset ? 14 : 10
  else if (inset) pad = 10
  return { left: pad, width: Math.max(0, width - 2 * pad) }
}

// A drag on the rod is a pull once it travels far enough away from the bar:
// down for a bar at the top, up for one at the bottom.
function pulled(dy, atBottom, threshold) {
  var t = threshold === undefined ? PULL_THRESHOLD : threshold
  return (atBottom ? -dy : dy) >= t
}
