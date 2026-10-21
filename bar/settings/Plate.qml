import QtQuick
import "../../core"
import "../../core/Dither.js" as Dither

// The sample plate behind the preview bar: a dithered marbled orb in the
// theme's ink, rising from the bottom right, so glass and inset have
// something to sit over. Ordered dither in 2 px cells keeps it two-tone.
Canvas {
  id: root

  readonly property color ink: Ink.ink
  // The orb's centre and radius, as fractions of the height (the default
  // rises from below the bottom right; About draws it as a whole moon).
  property real cxw: 0.74
  property real cyh: 1.9
  property real rh: 1.75
  onInkChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var w = Math.floor(width), h = Math.floor(height)
    if (w <= 0 || h <= 0) return
    var cell = 2
    var cx = w * cxw, cy = h * cyh, r = h * rh
    ctx.fillStyle = ink
    for (var y = 0; y < h; y += cell) for (var x = Math.max(0, Math.floor((cx - r) / cell) * cell); x < Math.min(w, cx + r); x += cell) {
      var dx = (x - cx) / r, dy = (y - cy) / r, rr = dx * dx + dy * dy
      if (rr >= 1) continue
      var dz = Math.sqrt(1 - rr)
      var light = Math.max(0, -0.5 * dx - 0.6 * dy + 0.62 * dz)
      var vein = Math.abs(Dither.fbm(x / 70, y / 40) - 0.5) < 0.03 ? -0.35 : 0
      var v = Math.min(1, Math.max(0, light * 0.9 + vein))
      var t = (Dither.BAYER[Math.floor(y / cell) % 4][Math.floor(x / cell) % 4] + 0.5) / 16
      if (v > t) ctx.fillRect(x, y, cell, cell)
    }
  }
}
