pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One lame of a samurai's armour (Odoshi 縅): a row of small lacquered
// scales (kozane) with rounded heads. As far as its level the lame is laced
// densely (kebiki: the braid covers each scale in two close bands), beyond
// it sparsely (sugake: bare scales, their two lacing holes, a pair of cords
// every third). `stitched` adds the red cross-knots (hishinui) along the
// foot that an armour's last plate carries. `marks` laces scale by scale
// instead ({ laced, red, label }), for a lame whose scales are days.
// Settable: a click on a scale laces to it, the wheel a scale at a time.
Item {
  id: root

  property real level: 0
  // How many scales; 0 fits them to the width, about 19 px each.
  property int count: 0
  property color tint: Ink.ink
  property bool stitched: false
  property bool dashed: false
  property var marks: []
  property bool settable: false
  readonly property real scaleH: Type.px(24)
  readonly property int n: marks.length > 0 ? marks.length : count > 0 ? count : Math.max(12, Math.round(width / Type.px(19)))
  readonly property int laced: Math.round(Math.max(0, Math.min(1, level)) * n)
  readonly property bool labelled: marks.length > 0 && marks[0].label !== undefined
  signal picked(real level)
  signal scaleClicked(int index)

  implicitHeight: scaleH + (stitched ? Type.px(8) : 0) + (labelled ? Type.px(16) : 0)
  height: implicitHeight
  opacity: dashed ? 0.55 : 1

  onLevelChanged: art.requestPaint()
  onTintChanged: art.requestPaint()
  onMarksChanged: art.requestPaint()
  onWidthChanged: art.requestPaint()

  Canvas {
    id: art
    width: parent.width
    height: root.scaleH + (root.stitched ? Type.px(8) : 0)
    onPaint: {
      var g = getContext("2d"), W = width, H = root.scaleH
      g.reset()
      // A wide step (a day) is laced as a run of ordinary scales, parted
      // from the next by a gap, so every scale keeps its armour size.
      var n = root.n, step = W / n
      var sub = root.marks.length ? Math.max(1, Math.round(step / Type.px(19))) : 1
      var gap = sub > 1 ? Type.px(3) : 0
      var w = (step - gap) / sub
      for (var i = 0; i < n; i++) {
        var m = root.marks.length ? root.marks[i] : null
        var laced = m ? !!m.laced : i < root.laced
        var tint = m && m.red ? Ink.seal : root.tint
        for (var j = 0; j < sub; j++) {
          var x = i * step + gap / 2 + j * w
          // The scale: lacquered, its top rounded off.
          g.fillStyle = Ink.alpha(Ink.bone, 0.07)
          g.strokeStyle = Ink.lineSoft
          g.lineWidth = 1
          g.beginPath()
          g.moveTo(x + 1, H - 0.5)
          g.lineTo(x + 1, 3)
          g.quadraticCurveTo(x + w / 2, -1, x + w - 1, 3)
          g.lineTo(x + w - 1, H - 0.5)
          g.closePath()
          g.fill(); g.stroke()
          if (laced) {
            // Kebiki: the cord covers the scale in two close bands.
            var cw = (w - 4) / 2
            g.fillStyle = tint
            g.fillRect(x + 2, 0, cw - 0.5, H * 0.72)
            g.fillRect(x + 2 + cw + 0.5, 0, cw - 0.5, H * 0.72)
            // The twist of the braid: fine ticks across it.
            g.strokeStyle = Ink.alpha(Ink.paper, 0.2)
            for (var t = 3; t < H * 0.72; t += 4) {
              g.beginPath(); g.moveTo(x + 2, t + 1.5); g.lineTo(x + 2 + cw - 0.5, t); g.stroke()
              g.beginPath(); g.moveTo(x + 2 + cw + 0.5, t); g.lineTo(x + w - 2, t + 1.5); g.stroke()
            }
          } else {
            // Sugake: bare scale, its two lacing holes, a pair of cords every third.
            g.fillStyle = Ink.inkFaint
            g.fillRect(x + w / 2 - 2.5, H * 0.3, 1.5, 1.5)
            g.fillRect(x + w / 2 + 1, H * 0.3, 1.5, 1.5)
            if ((i * sub + j) % 3 === 0) {
              g.fillStyle = Ink.alpha(root.tint, 0.3)
              g.fillRect(x + w / 2 - 2, 0, 1, H * 0.72)
              g.fillRect(x + w / 2 + 1, 0, 1, H * 0.72)
            }
          }
        }
      }
      if (root.stitched) {
        // Hishinui: red cross-knots along the foot.
        g.strokeStyle = Ink.seal
        g.lineWidth = 1.5
        for (var k = 0; k < n * sub; k++) {
          var cx = Math.floor(k / sub) * step + gap / 2 + (k % sub) * w + w / 2, cy = H + 4
          g.beginPath(); g.moveTo(cx - 3, cy - 3); g.lineTo(cx + 3, cy + 3); g.stroke()
          g.beginPath(); g.moveTo(cx + 3, cy - 3); g.lineTo(cx - 3, cy + 3); g.stroke()
        }
      }
    }
  }

  // Labels under the scales (a week's dates).
  Repeater {
    model: root.labelled ? root.marks : []
    Text {
      required property var modelData
      required property int index
      x: index * root.width / root.n
      y: art.height + Type.px(3)
      width: root.width / root.n
      horizontalAlignment: Text.AlignHCenter
      text: modelData.label
      color: modelData.red ? Ink.seal : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.settable || root.marks.length > 0
    cursorShape: Qt.PointingHandCursor
    onClicked: function(m) {
      var i = Math.max(0, Math.min(root.n - 1, Math.floor(m.x / (root.width / root.n))))
      if (root.settable) root.picked((i + 1) / root.n)
      root.scaleClicked(i)
    }
    onWheel: function(w) {
      if (!root.settable) return
      root.picked(Math.max(0, Math.min(root.n, root.laced + (w.angleDelta.y > 0 ? 1 : -1))) / root.n)
    }
  }
}
