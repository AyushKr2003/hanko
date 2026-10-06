import QtQuick
import "../../core"
import "../../core/Scroll.js" as Scroll

// A narrow ink-wash sliver between two sections, ordered-dithered in the
// theme's ink so it stays two-tone. Painted once per size, seed and theme.
Canvas {
  id: root

  property int seed: 0
  readonly property color ink: Ink.ink

  onInkChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var w = Math.floor(width), h = Math.floor(height)
    if (w <= 0 || h <= 0) return
    var px = Scroll.sliver(w, h, seed)
    ctx.fillStyle = ink
    // Runs of inked pixels per row, as one rectangle each.
    for (var y = 0; y < h; y++) {
      var start = -1
      for (var x = 0; x <= w; x++) {
        var on = x < w && px[y * w + x] === 1
        if (on && start < 0) start = x
        else if (!on && start >= 0) { ctx.fillRect(start, y, x - start, 1); start = -1 }
      }
    }
  }
}
