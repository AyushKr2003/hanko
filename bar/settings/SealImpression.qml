import QtQuick
import "../../core"
import "../../core/Scroll.js" as Scroll

// A seal pressed hard onto paper: your seal glyph knocked out of a red
// square with a double frame, the ink worn where a real impression wears
// (towards the edges, in grain), set in 1-bit cells. Drawn once per size
// and theme; the Profile plate's hero, original to Hanko. The glyph is a
// real Text over the painted face: Canvas can't be trusted to find a CJK
// face by name.
Item {
  id: root

  property string glyph: "印"
  property color ink: Ink.seal
  property color paper: Ink.paper
  // Varies the wear, so two machines press two different seals.
  property real seed: 0

  Canvas {
    id: face
    anchors.fill: parent
    readonly property var key: [root.ink, root.paper, root.seed]
    onKeyChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      var ink = root.ink, paper = root.paper, seed = root.seed
      var ctx = getContext("2d")
      ctx.reset()
      var w = Math.floor(Math.min(width, height))
      if (w <= 8) return
      var r = w * 0.035
      // The stamp's face: a red square, rounded a little.
      ctx.fillStyle = ink
      ctx.beginPath()
      ctx.moveTo(r, 0); ctx.lineTo(w - r, 0); ctx.quadraticCurveTo(w, 0, w, r)
      ctx.lineTo(w, w - r); ctx.quadraticCurveTo(w, w, w - r, w)
      ctx.lineTo(r, w); ctx.quadraticCurveTo(0, w, 0, w - r)
      ctx.lineTo(0, r); ctx.quadraticCurveTo(0, 0, r, 0)
      ctx.fill()
      // The inner frame, cut out to the paper.
      ctx.strokeStyle = paper
      ctx.lineWidth = Math.max(2, w * 0.022)
      var f = w * 0.085
      ctx.strokeRect(f, f, w - 2 * f, w - 2 * f)

      // Wear: paper shows through in grain, more towards the edges, never
      // enough to lose the glyph.
      var cell = Math.max(2, Math.round(w / 200))
      var k = w * 0.04
      for (var y = 0; y < w; y += cell) for (var x = 0; x < w; x += cell) {
        var edge = Math.min(x, y, w - x, w - y) / w
        var rim = Math.max(0, 1 - edge * 9)
        var grain = Scroll.fbm(x / k + seed, y / k - seed)
        var cover = 0.99 - 0.55 * rim - 0.6 * Math.max(0, 0.46 - grain)
        var t = (Scroll.BAYER[Math.floor(y / cell) % 4][Math.floor(x / cell) % 4] + 0.5) / 16
        if (t > cover) { ctx.fillStyle = paper; ctx.fillRect(x, y, cell, cell) }
      }
    }
  }

  Text {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -root.height * 0.01
    text: root.glyph || "印"
    color: root.paper
    font.family: Type.jpSerif
    font.pixelSize: Math.round(Math.min(root.width, root.height) * 0.6)
    font.weight: Font.Medium
  }
}
