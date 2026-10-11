import QtQuick
import "../../core"

// Paper you feel more than see: washi's long fibres (Shōji), painted once
// per size with a fixed seed, so the same panel always has the same paper.
// level 0 draws nothing.
Canvas {
  id: root

  property int level: 1           // 0 smooth, 1 fine, 2 toothy

  visible: level > 0
  renderStrategy: Canvas.Cooperative
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onLevelChanged: requestPaint()
  Connections { target: Ink; function onLightChanged() { root.requestPaint() } }

  onPaint: {
    var g = getContext("2d")
    g.clearRect(0, 0, width, height)
    if (level <= 0 || width <= 0 || height <= 0) return
    var seed = 31
    var r = function() { seed = (seed * 16807) % 2147483647; return seed / 2147483647 }
    var light = Ink.light
    var area = width * height
    var fibres = Math.round(area / 320 / 320 * 220 * level)
    for (var j = 0; j < fibres; j++) {
      var x = r() * width, y = r() * height, a = r() * 6.28, l = 8 + r() * 46
      g.strokeStyle = light ? "rgba(0,0,0,0.05)" : "rgba(255,255,255,0.04)"
      g.lineWidth = 0.4 + r() * 0.7
      g.beginPath(); g.moveTo(x, y)
      g.quadraticCurveTo(x + Math.cos(a + 0.6) * l * 0.5, y + Math.sin(a + 0.6) * l * 0.5, x + Math.cos(a) * l, y + Math.sin(a) * l)
      g.stroke()
    }
  }
}
