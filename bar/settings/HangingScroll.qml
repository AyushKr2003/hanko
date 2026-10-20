pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Dither.js" as Dither

// The Credits plate's art: a hanging scroll (kakejiku) between two rollers,
// a mountain landscape in 1-bit ink on its paper and the painter's small
// red seal in the corner. It dissolves to the left, into the type. Drawn
// in code from the theme's ink; original to Hanko.
Item {
  id: root
  // The paper's edges, as fractions (the kanji line is placed from them).
  readonly property real paperL: width * 0.2
  readonly property real paperR: width * 0.86
  readonly property real paperT: height * 0.07
  readonly property real paperB: height * 0.93
  readonly property real sealSize: (paperR - paperL) * 0.09

  Canvas {
    id: art
    anchors.fill: parent
    readonly property var key: [Ink.ink, Ink.seal]
    onKeyChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      var ink = Ink.ink, seal = Ink.seal
      var ctx = getContext("2d")
      ctx.reset()
      var w = Math.floor(width), h = Math.floor(height)
      if (w <= 20 || h <= 20) return
      var cell = Math.max(2, Math.round(h / 300))
      var left = root.paperL, right = root.paperR, top = root.paperT, bottom = root.paperB
      var pw = right - left, ph = bottom - top
      // The landscape: three ridges, nearer ones darker, mist between.
      function ridge(u, base, amp, f, s) { return base - amp * Dither.fbm(u * f + s, s * 0.7) }
      ctx.fillStyle = ink
      for (var y = top; y < bottom; y += cell) for (var x = left; x < right; x += cell) {
        var u = (x - left) / pw, v = (y - top) / ph
        var d = 0
        var r1 = ridge(u, 0.62, 0.34, 2.2, 1.7), r2 = ridge(u, 0.78, 0.26, 3.1, 4.2), r3 = ridge(u, 0.95, 0.18, 4.4, 8.9)
        if (v > r3) d = 0.78
        else if (v > r2) d = 0.52 - 0.25 * (v - r2) / Math.max(0.01, r3 - r2)
        else if (v > r1) d = 0.34 - 0.24 * (v - r1) / Math.max(0.01, r2 - r1)
        // The moon, high on the left of the paper.
        var mx = (u - 0.3) * pw, my = (v - 0.2) * ph, mr = pw * 0.12
        if (mx * mx + my * my < mr * mr) d = Math.max(d, 0.16)
        d *= 0.55 + 0.45 * Math.min(1, (x / w) * 2.2)
        var t = (Dither.BAYER[Math.floor(y / cell) % 4][Math.floor(x / cell) % 4] + 0.5) / 16
        if (d > t) ctx.fillRect(x, y, cell, cell)
      }
      // The paper's edges and the two rollers with their caps.
      ctx.strokeStyle = Qt.rgba(ink.r, ink.g, ink.b, 0.35)
      ctx.lineWidth = 1
      ctx.strokeRect(left + 0.5, top + 0.5, pw - 1, ph - 1)
      var rollH = Math.max(6, h * 0.018)
      ctx.fillStyle = ink
      ctx.fillRect(left - w * 0.03, top - rollH, pw + w * 0.06, rollH)
      ctx.fillRect(left - w * 0.03, bottom, pw + w * 0.06, rollH)
      ctx.fillRect(left - w * 0.05, top - rollH * 1.3, w * 0.025, rollH * 1.6)
      ctx.fillRect(right + w * 0.025, top - rollH * 1.3, w * 0.025, rollH * 1.6)
      ctx.fillRect(left - w * 0.05, bottom - rollH * 0.3, w * 0.025, rollH * 1.6)
      ctx.fillRect(right + w * 0.025, bottom - rollH * 0.3, w * 0.025, rollH * 1.6)
      // The cord it hangs from.
      ctx.beginPath(); ctx.moveTo(left + pw * 0.2, top - rollH); ctx.lineTo(left + pw / 2, 0); ctx.lineTo(left + pw * 0.8, top - rollH); ctx.stroke()
      // The painter's seal.
      var ss = root.sealSize
      ctx.fillStyle = seal
      ctx.fillRect(right - ss * 1.6, bottom - ss * 1.6, ss, ss)
    }
  }

  // A vertical line of thanks, top right of the paper.
  Column {
    x: root.paperR - root.sealSize * 1.1 - width / 2
    y: root.paperT + (root.paperB - root.paperT) * 0.06
    Repeater {
      model: ["感", "謝"]
      Text {
        required property string modelData
        text: modelData
        color: Ink.alpha(Ink.ink, 0.85)
        font.family: Type.jpSerif
        font.pixelSize: Math.round((root.paperR - root.paperL) * 0.07)
      }
    }
  }
}
