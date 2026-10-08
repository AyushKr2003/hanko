.pragma library

// Skin: a resolved Kata style (core/Kata.js resolve) as the concrete tokens
// the parts draw with. Components take the result as a plain `skin` prop
// (props in, signals out), so every monitor can wear its own design and the
// harness can render any of them. Sizes are at Omarchy's 12px base; scale
// them with Type.px().

// Each tempo: how a panel arrives (open), how it goes (leave), how things
// settle inside it. Curves are QML Easing.BezierSpline control points.
var TEMPOS = {
  spring:  { open: 240, openCurve: [0.32, 1.24, 0.46, 1, 1, 1], leave: 140, leaveCurve: [0.5, 0, 0.75, 0, 1, 1] },
  snap:    { open: 220, openCurve: [0.22, 1, 0.36, 1, 1, 1], leave: 140, leaveCurve: [0.55, 0, 1, 0.45, 1, 1] },
  johakyu: { open: 340, openCurve: [0.62, 0.02, 0.18, 1, 1, 1], leave: 160, leaveCurve: [0.5, 0, 0.75, 0, 1, 1] }
}
var SETTLE = { duration: 200, curve: [0.16, 1, 0.3, 1, 1, 1] }
// Panels and controls, per corner: the panel, a row or control, a chip.
var RADII = { soft: [16, 10, 7], cut: [0, 0, 0] }
var GRAIN = { smooth: 0, fine: 1, toothy: 2 }
// Shōji's washi lets the desk show through; paper and card are opaque.
var OPACITY = { paper: 1, card: 1, washi: 0.86 }

function skin(k) {
  k = k || {}
  var t = TEMPOS[k.tempo] || TEMPOS.spring
  var r = RADII[k.corner] || RADII.soft
  var touches = k.touches || {}
  return {
    design: k.design || "classic",
    surface: k.surface, arrive: k.arrive, pointer: k.pointer, select: k.select, slider: k.slider,
    ring: k.ring, seal: k.seal, unread: k.unread, sign: k.sign, corner: k.corner, divider: k.divider, tempo: k.tempo,
    radius: r[0], radiusRow: r[1], radiusChip: r[2],
    // A score is two lines (dark over light); hairline and lattice one.
    dividerWidth: k.divider === "score" ? 2 : 1,
    // The lattice marks its joints where it meets the frame.
    joints: k.divider === "lattice",
    open: t.open, openCurve: t.openCurve, leave: t.leave, leaveCurve: t.leaveCurve,
    settle: SETTLE.duration, settleCurve: SETTLE.curve,
    // Fraunces' SOFT axis: paper's figures are soft, card and washi are cut sharp.
    soft: k.surface === "paper" ? 30 : 0,
    opacity: OPACITY[k.surface] === undefined ? 1 : OPACITY[k.surface],
    grain: GRAIN[touches.grain] === undefined ? 0 : GRAIN[touches.grain],
    season: touches.season || "off",
    kanjiNumerals: touches.numerals === "kanji",
    // Where a panel hangs: from the bar's edge (fold), flush under it (slip)
    // or a little below on its rail (slide).
    gap: k.arrive === "slide" ? 6 : k.arrive === "slip" ? 0 : -1,
    // One panel travels along the rail instead of closing and reopening.
    travels: k.arrive === "slide"
  }
}
