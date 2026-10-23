pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// The year as a dial (Koyomi 暦): seventy-two kō round a ring that starts
// at the top with 立春, spring's first day, and runs clockwise. The four
// seasons are four arcs of hairline parted by a gap at each 立; the twenty-
// four solar terms are ticks, long at a season's start. The year so far is
// inked over the ring; today is a red notch (red is now), the picked day
// an ink one when it is another. The season's kanji sits in the middle.
Item {
  id: root

  // Places in kō (0..72), fractional.
  property real now: 0
  property real picked: 0
  property string glyph: ""
  property string caption: ""
  property real size: Type.px(150)
  // 0..1: how much of the ring is drawn (a hand draws it in as it opens).
  property real drawn: 1

  width: size
  height: size

  Canvas {
    id: c
    anchors.fill: parent
    readonly property real now: root.now
    readonly property real picked: root.picked
    readonly property real drawn: root.drawn
    readonly property color ink: Ink.ink
    readonly property color faint: Ink.inkFaint
    readonly property color line: Ink.line
    readonly property color seal: Ink.seal
    onNowChanged: requestPaint()
    onPickedChanged: requestPaint()
    onDrawnChanged: requestPaint()
    onInkChanged: requestPaint()
    onPaint: {
      var g = getContext("2d"), w = width, cx = w / 2, cy = w / 2
      var r = w / 2 - Type.px(12)
      var at = function(ko) { return -Math.PI / 2 + ko / 72 * Math.PI * 2 }
      g.reset()
      g.lineCap = "butt"
      var gap = 0.05
      // The four seasons: hairline arcs.
      for (var s = 0; s < 4; s++) {
        var a0 = at(s * 18) + gap, a1 = at(s * 18 + 18) - gap
        g.strokeStyle = c.line
        g.lineWidth = 1
        g.beginPath(); g.arc(cx, cy, r, a0, a0 + (a1 - a0) * c.drawn); g.stroke()
      }
      // The year so far, in ink, a little heavier, season by season.
      g.strokeStyle = c.ink
      g.lineWidth = Type.px(2.2)
      for (var q = 0; q < 4; q++) {
        var b0 = at(q * 18) + gap, b1 = Math.min(at(q * 18 + 18) - gap, at(c.now * c.drawn))
        if (b1 > b0) { g.beginPath(); g.arc(cx, cy, r, b0, b1); g.stroke() }
      }
      // The twenty-four terms: ticks outside the ring.
      for (var t = 0; t < 24; t++) {
        var a = at(t * 3), long = t % 6 === 0
        if (t / 24 > c.drawn) break
        g.strokeStyle = long ? c.ink : c.faint
        g.lineWidth = 1
        var r0 = r + Type.px(3), r1 = r + Type.px(long ? 10 : 6)
        g.beginPath(); g.moveTo(cx + r0 * Math.cos(a), cy + r0 * Math.sin(a)); g.lineTo(cx + r1 * Math.cos(a), cy + r1 * Math.sin(a)); g.stroke()
      }
      // The picked day (ink) and today (red): notches across the ring.
      var notch = function(ko, col, len, wd) {
        var a = at(ko)
        g.strokeStyle = col
        g.lineWidth = wd
        g.beginPath()
        g.moveTo(cx + (r - len) * Math.cos(a), cy + (r - len) * Math.sin(a))
        g.lineTo(cx + (r + len) * Math.cos(a), cy + (r + len) * Math.sin(a))
        g.stroke()
      }
      if (c.drawn >= 1 && Math.abs(c.picked - c.now) > 0.5) notch(c.picked, c.ink, Type.px(7), Type.px(2))
      if (c.drawn >= 1) notch(c.now, c.seal, Type.px(8), Type.px(2.5))
    }
  }

  // The four seasons named round the dial.
  Repeater {
    model: ["春", "夏", "秋", "冬"]
    Text {
      id: name
      required property string modelData
      required property int index
      readonly property real a: -Math.PI / 2 + (index * 18 + 9) / 72 * Math.PI * 2
      readonly property real rr: root.size / 2 - Type.px(27)
      x: root.size / 2 + name.rr * Math.cos(name.a) - width / 2
      y: root.size / 2 + name.rr * Math.sin(name.a) - height / 2
      text: name.modelData
      color: name.modelData === root.glyph ? Ink.inkDim : Ink.inkFaint
      font.family: Type.jp
      font.pixelSize: Type.px(11)
      opacity: root.drawn
    }
  }
  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: Ink.ink
    font.family: Type.brush
    font.pixelSize: root.size * 0.24
  }
  // Under the dial, not in it: the four names keep the ring.
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.bottom
    anchors.topMargin: Type.px(4)
    visible: root.caption !== ""
    text: root.caption.toUpperCase()
    color: Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }
}
