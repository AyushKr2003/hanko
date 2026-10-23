import QtQuick
import "../../core"

// The moon as it stands on a day: the lit part filled in ink, the dark part
// a hairline ring, as an almanac prints it (lit on the right while it
// waxes). `age` is days since new (core/Almanac.js moon()).
Canvas {
  id: root

  property real age: 0
  property color tint: Ink.ink
  property color ring: Ink.inkFaint
  property real size: Type.px(14)
  readonly property real synodic: 29.530588853

  width: size
  height: size
  onAgeChanged: requestPaint()
  onTintChanged: requestPaint()
  onRingChanged: requestPaint()
  onSizeChanged: requestPaint()

  onPaint: {
    var g = getContext("2d"), r = width / 2 - 0.75, cx = width / 2, cy = height / 2
    g.reset()
    g.lineWidth = 1
    g.strokeStyle = root.ring
    g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.stroke()
    var phase = ((root.age % synodic) + synodic) % synodic / synodic
    var k = Math.cos(2 * Math.PI * phase)
    var waxing = phase < 0.5
    if (k > 0.995) return
    g.fillStyle = root.tint
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
  }
}
