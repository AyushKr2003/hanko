import QtQuick
import "../../core"

// The Dial sheets' hero (盤): one arc gauge, 270° from lower left to lower
// right like an instrument's, ticked every tenth, inked up to the value, a
// head at the value and the figure set large in its middle. After the
// constant-state displays of synths and hi-fi (four things always visible,
// nothing nested), it shows one reading big and lets you turn it: drag
// round the arc, or scroll. Red only for the master, or what needs you.
Item {
  id: root

  property real value: 0          // 0..1, or < 0 for no reading
  property bool red: false
  property bool muted: false
  property string figure: ""
  property string unit: ""
  property string caption: ""
  property bool interactive: true
  property real step: 0.05

  signal moved(real value)

  implicitWidth: Type.px(176)
  implicitHeight: implicitWidth

  readonly property real v: Math.max(0, Math.min(1, value))
  readonly property real start: 135
  readonly property real sweep: 270
  readonly property color tone: red ? Ink.seal : muted ? Ink.inkMuted : Ink.ink

  Canvas {
    id: arc
    anchors.fill: parent
    readonly property var key: [root.v, root.tone, root.muted, root.value < 0, width, Ink.line]
    onKeyChanged: requestPaint()
    onPaint: {
      var c = getContext("2d")
      c.reset()
      var cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - Type.px(10)
      var a0 = root.start * Math.PI / 180, a1 = (root.start + root.sweep) * Math.PI / 180
      var av = (root.start + root.sweep * root.v) * Math.PI / 180
      // The track.
      c.lineWidth = Type.px(2)
      c.lineCap = "round"
      c.strokeStyle = Ink.line
      c.beginPath(); c.arc(cx, cy, r, a0, a1, false); c.stroke()
      // Ticks, every tenth, the fifth longer.
      for (var i = 0; i <= 10; i++) {
        var a = (root.start + root.sweep * i / 10) * Math.PI / 180
        var long = i % 5 === 0
        var r1 = r + Type.px(5), r2 = r + Type.px(long ? 10 : 7)
        c.strokeStyle = i / 10 <= root.v && root.value >= 0 && !root.muted ? Ink.inkDim : Ink.line
        c.lineWidth = 1
        c.beginPath(); c.moveTo(cx + r1 * Math.cos(a), cy + r1 * Math.sin(a)); c.lineTo(cx + r2 * Math.cos(a), cy + r2 * Math.sin(a)); c.stroke()
      }
      if (root.value < 0) return
      // The inked part.
      c.lineWidth = Type.px(4)
      c.strokeStyle = root.tone
      if (root.muted) c.setLineDash([Type.px(2), Type.px(5)])
      c.beginPath(); c.arc(cx, cy, r, a0, Math.max(a0 + 0.001, av), false); c.stroke()
      c.setLineDash([])
      // The head: a dot standing on the arc.
      c.fillStyle = Ink.paper
      c.beginPath(); c.arc(cx + r * Math.cos(av), cy + r * Math.sin(av), Type.px(6), 0, 2 * Math.PI); c.fill()
      c.lineWidth = Type.px(2)
      c.strokeStyle = root.tone
      c.beginPath(); c.arc(cx + r * Math.cos(av), cy + r * Math.sin(av), Type.px(6), 0, 2 * Math.PI); c.stroke()
    }
  }

  Column {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -Type.px(2)
    spacing: Type.px(2)
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      Text {
        id: fig
        readonly property int size: root.figure.length > 4 ? Type.px(26) : Type.px(44)
        text: root.figure
        color: root.red && root.muted ? Ink.seal : root.value < 0 ? Ink.inkFaint : Ink.ink
        font.family: Type.display
        font.pixelSize: fig.size
        font.weight: Font.Normal
        font.variableAxes: Type.axes(fig.size)
        font.features: { "tnum": 1, "lnum": 1 }
      }
      Text {
        visible: root.unit !== ""
        y: Type.px(8)
        text: root.unit
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
      }
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(implicitWidth, root.width * 0.62)
      elide: Text.ElideRight
      horizontalAlignment: Text.AlignHCenter
      text: root.caption.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    function at(mx, my) {
      var a = Math.atan2(my - height / 2, mx - width / 2) * 180 / Math.PI
      var d = a - root.start
      while (d < 0) d += 360
      if (d > root.sweep) d = d - root.sweep < (360 - root.sweep) / 2 ? root.sweep : 0
      return d / root.sweep
    }
    onPressed: function(m) { root.moved(at(m.x, m.y)) }
    onPositionChanged: function(m) { if (pressed) root.moved(at(m.x, m.y)) }
    onWheel: function(w) { root.moved(Math.max(0, Math.min(1, root.v + (w.angleDelta.y > 0 ? root.step : -root.step)))) }
  }
}
