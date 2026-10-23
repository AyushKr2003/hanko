import QtQuick
import "../../core"

// The moon as it stands on a day, as an almanac prints it: the lit part in
// the lighter of the surface's two tones, the dark part in the darker, a
// hairline round it (lit on the right while it waxes). So on dark paper the
// full moon is a bright disc and the new moon a ring, and on light paper,
// as a printed calendar has them, the full moon ○ and the new moon ●.
// `ink` and `paper` are the surface's: a bone plate passes its own.
// `age` is days since new (core/Almanac.js moon()).
Canvas {
  id: root

  property real age: 0
  property color ink: Ink.inkDim
  property color paper: Ink.paper
  property real size: Type.px(14)
  readonly property real synodic: 29.530588853
  readonly property bool lightPaper: paper.hslLightness > 0.5

  width: size
  height: size
  onAgeChanged: requestPaint()
  onInkChanged: requestPaint()
  onPaperChanged: requestPaint()
  onSizeChanged: requestPaint()

  onPaint: {
    var g = getContext("2d"), r = width / 2 - 0.75, cx = width / 2, cy = height / 2
    g.reset()
    var lit = root.lightPaper ? root.paper : root.ink
    var dark = root.lightPaper ? root.ink : root.paper
    g.lineWidth = 1
    g.fillStyle = dark
    g.strokeStyle = root.ink
    g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.fill(); g.stroke()
    var phase = ((root.age % synodic) + synodic) % synodic / synodic
    var k = Math.cos(2 * Math.PI * phase)
    var waxing = phase < 0.5
    if (k > 0.995) return
    g.fillStyle = lit
    g.beginPath()
    // The lit limb, top to bottom down the lit side, then the terminator back.
    var n = 24, i, t
    for (i = 0; i <= n; i++) {
      t = -Math.PI / 2 + Math.PI * i / n
      var lx = cx + (waxing ? 1 : -1) * r * Math.cos(t), ly = cy + r * Math.sin(t)
      if (i === 0) g.moveTo(lx, ly); else g.lineTo(lx, ly)
    }
    for (i = n; i >= 0; i--) {
      t = -Math.PI / 2 + Math.PI * i / n
      g.lineTo(cx + (waxing ? 1 : -1) * k * r * Math.cos(t), cy + r * Math.sin(t))
    }
    g.closePath()
    g.fill()
    // The rim again over the lit part, so a full moon on light paper keeps it.
    g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.stroke()
  }
}
