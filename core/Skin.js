.pragma library

// Skin: Shōji's parts (bar/parts) as the concrete tokens they draw with.
// Shōji was a design of its own (Kata 型, docs/kata) and is part of Hanko
// now: its values on the bar, its sheet hand and its framed overview all
// wear this skin, with the style's season, numerals, grain and panel
// opacity (fromStyle). Components take it as a plain `skin` prop (props in,
// signals out). Sizes are at Omarchy's 12px base; scale them with Type.px().

// Each tempo: how a panel arrives (open), how it goes (leave), how things
// settle inside it. Curves are QML Easing.BezierSpline control points.
var TEMPOS = {
  johakyu: { open: 340, openCurve: [0.62, 0.02, 0.18, 1, 1, 1], leave: 160, leaveCurve: [0.5, 0, 0.75, 0, 1, 1] }
}
var SETTLE = { duration: 200, curve: [0.16, 1, 0.3, 1, 1, 1] }
// Panels and controls, per corner: the panel, a row or control, a chip.
var RADII = { cut: [0, 0, 0] }
var GRAIN = { smooth: 0, fine: 1, toothy: 2 }
// Shōji's washi lets the desk show through.
var OPACITY = { washi: 0.86 }

// Shōji's variant of every part (they were Kata's PARTS, one variant each).
var SHOJI = { surface: "washi", arrive: "slide", pointer: "brush", select: "wash", slider: "brush", ring: "enso",
              seal: "carved", unread: "stamp", sign: "tategaki", notify: "rows", overview: "framed", hold: "stroke",
              corner: "cut", divider: "lattice", tempo: "johakyu" }

// The skin for a resolved style (core/Style.js resolve): Shōji's parts with
// the style's touches and panel opacity.
function fromStyle(style) {
  style = style || {}
  var k = { design: "shoji", touches: { season: style.season || "kanji", numerals: style.numerals || "arabic", grain: style.grain || "fine" } }
  for (var p in SHOJI) k[p] = SHOJI[p]
  return skin(k, style.panelOpacity || 0)
}

// `panelOpacity` (Style.js, 30..100; 0 = the part's own) overrides the
// surface's opacity for every panel.
function skin(k, panelOpacity) {
  k = k || {}
  var t = TEMPOS[k.tempo] || TEMPOS.johakyu
  var r = RADII[k.corner] || RADII.cut
  var touches = k.touches || {}
  return {
    design: k.design || "classic",
    surface: k.surface, arrive: k.arrive, pointer: k.pointer, select: k.select, slider: k.slider,
    ring: k.ring, seal: k.seal, unread: k.unread, sign: k.sign, corner: k.corner, divider: k.divider, tempo: k.tempo,
    notify: k.notify, overview: k.overview, hold: k.hold,
    radius: r[0], radiusRow: r[1], radiusChip: r[2],
    // The lattice marks its joints where it meets the frame.
    joints: k.divider === "lattice",
    open: t.open, openCurve: t.openCurve, leave: t.leave, leaveCurve: t.leaveCurve,
    settle: SETTLE.duration, settleCurve: SETTLE.curve,
    opacity: panelOpacity > 0 ? panelOpacity / 100 : OPACITY[k.surface] === undefined ? 1 : OPACITY[k.surface],
    grain: GRAIN[touches.grain] === undefined ? 0 : GRAIN[touches.grain],
    season: touches.season || "off",
    kanjiNumerals: touches.numerals === "kanji",
    // Where a panel hangs: a little below the bar, on its rail.
    gap: k.arrive === "slide" ? 6 : 0,
    // One panel travels along the rail instead of closing and reopening.
    travels: k.arrive === "slide"
  }
}
