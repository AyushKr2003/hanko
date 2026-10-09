.pragma library

// Skin: a resolved Kata style (core/Kata.js resolve) as the concrete tokens
// the parts draw with. Components take the result as a plain `skin` prop
// (props in, signals out), so every monitor can wear its own design and the
// harness can render any of them. Sizes are at Omarchy's 12px base; scale
// them with Type.px().

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

// `panelOpacity` (Style.js, 30..100; 0 = the design's own) overrides the
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
