.pragma library

// The ink ramp: the theme's foreground walked toward its background until
// each tier lands on a fixed contrast against the paper (WCAG ratios). The
// Typeset mockups were drawn with this same tier() function.
// Colours here are "#rrggbb" strings; Ink.qml turns them into QML colours.

var TIERS = { ink: 12, inkDim: 9, inkMuted: 6.2, inkFaint: 4.6 }

function hexToRgb(hex) {
  var h = String(hex || "").replace("#", "")
  if (h.length === 8) h = h.substr(2) // QML's #aarrggbb
  if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2]
  return [0, 2, 4].map(function(i) { return parseInt(h.substr(i, 2), 16) || 0 })
}

function rgbToHex(c) {
  return "#" + c.map(function(v) {
    var s = Math.max(0, Math.min(255, Math.round(v))).toString(16)
    return s.length < 2 ? "0" + s : s
  }).join("")
}

// t = 1 is all a, t = 0 is all b.
function mix(a, b, t) {
  var A = hexToRgb(a), B = hexToRgb(b)
  return rgbToHex(A.map(function(v, i) { return v * t + B[i] * (1 - t) }))
}

function luminance(hex) {
  var c = hexToRgb(hex).map(function(v) {
    v /= 255
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
  })
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
}

function contrast(a, b) {
  var x = luminance(a), y = luminance(b)
  return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
}

// The faintest mix of fg into bg that still reaches `target`. A theme whose
// foreground is already below the target keeps its foreground.
function tier(fg, bg, target) {
  var t = 1, c = mix(fg, bg, 1)
  while (t > 0.2) {
    var next = mix(fg, bg, t - 0.01)
    if (contrast(next, bg) < target) break
    t -= 0.01
    c = next
  }
  return c
}

function isLight(bg) {
  return luminance(bg) > 0.4
}

function ramp(fg, bg) {
  return {
    ink: tier(fg, bg, TIERS.ink),
    inkDim: tier(fg, bg, TIERS.inkDim),
    inkMuted: tier(fg, bg, TIERS.inkMuted),
    inkFaint: tier(fg, bg, TIERS.inkFaint)
  }
}
