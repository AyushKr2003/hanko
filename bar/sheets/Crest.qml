pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A kamon 家紋, the crest a samurai house wore on its banners and armour,
// drawn the way crest makers drew them: with compass and ruler only, perfect
// circles and straight lines, in a ring (丸), symmetric, and in one colour
// (a crest is the same crest in black or in red). Kinds, all real crest
// families:
//   kuyo    九曜, nine stars: a centre circle and eight round it; as many of
//           the eight are inked as the level reaches (a gauge in crest form)
//   hours   twelve stars round the ring, inked to the hour, for Time
//   bars    一つ引き, 二つ引き, 三つ引き: one to three bars across the ring (`count`)
//   hishi   菱, the lozenge
//   igeta   井桁, the well frame
//   wa      輪違い, two rings interlaced
//   moji    丸に文字, a character in the ring (`glyph`, brushed)
// `inked` reverses it, a solid disc in seal red with the motif cut out in
// paper: the crest you bear, as stamped on a banner. Under the pointer a
// crest turns a twelfth of a turn, as a mon's symmetry allows.
Item {
  id: root

  property string kind: "kuyo"
  property real level: -1
  property int count: 1
  property string glyph: ""
  property bool inked: false
  property bool urgent: false
  property bool faint: false
  property real turn: 0

  readonly property color tone: inked ? Ink.seal : urgent ? Ink.seal : faint ? Ink.inkMuted : Ink.ink
  readonly property color cut: Ink.paper

  implicitWidth: Type.px(56)
  implicitHeight: implicitWidth

  Item {
    id: face
    anchors.fill: parent
    rotation: root.turn
    Behavior on rotation { enabled: Motion.live; NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

    Canvas {
      id: art
      anchors.fill: parent
      antialiasing: true
      readonly property var key: [root.kind, root.level, root.count, root.inked, root.tone, root.faint, width, Ink.paper]
      onKeyChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var s = Math.min(width, height), cx = width / 2, cy = height / 2
        var R = s / 2 - 1.5
        var ink = root.tone, cut = root.cut
        var fg = root.inked ? cut : ink
        var lw = Math.max(1.2, s / 34)
        function ring(x, y, r, w, col) { c.lineWidth = w; c.strokeStyle = col; c.beginPath(); c.arc(x, y, r, 0, 2 * Math.PI); c.stroke() }
        function disc(x, y, r, col) { c.fillStyle = col; c.beginPath(); c.arc(x, y, r, 0, 2 * Math.PI); c.fill() }

        // The ring (丸): a solid disc when inked, else a drawn ring.
        if (root.inked) disc(cx, cy, R, ink)
        else ring(cx, cy, R - lw / 2, lw, ink)
        var r = R - lw * 2.6   // the field inside the ring

        if (root.kind === "kuyo" || root.kind === "hours") {
          var n = root.kind === "hours" ? 12 : 8
          var lit = root.level < 0 ? -1 : Math.round(Math.max(0, Math.min(1, root.level)) * n)
          // Kuyō's eight stars stand apart round a larger centre, as the crest draws them.
          var orbit = r * (root.kind === "hours" ? 0.74 : 0.68)
          var star = root.kind === "hours" ? r * 0.14 : r * 0.17
          for (var i = 0; i < n; i++) {
            var a = -Math.PI / 2 + i * 2 * Math.PI / n
            var x = cx + orbit * Math.cos(a), y = cy + orbit * Math.sin(a)
            if (lit < 0 || i < lit) disc(x, y, star, fg)
            else ring(x, y, star - lw / 2, lw * 0.8, root.inked ? cut : Ink.alpha(ink, 0.45))
          }
          if (root.kind === "kuyo") {
            if (lit !== 0) disc(cx, cy, r * 0.27, fg)
            else ring(cx, cy, r * 0.27 - lw / 2, lw * 0.8, root.inked ? cut : Ink.alpha(ink, 0.45))
          }
        } else if (root.kind === "bars") {
          var k = Math.max(1, Math.min(3, root.count))
          var bh = r * (k === 1 ? 0.42 : k === 2 ? 0.34 : 0.26), gap = bh * 0.55
          var total = k * bh + (k - 1) * gap
          c.save(); c.beginPath(); c.arc(cx, cy, r + lw * 0.6, 0, 2 * Math.PI); c.clip()
          c.fillStyle = fg
          for (var b = 0; b < k; b++) c.fillRect(cx - R, cy - total / 2 + b * (bh + gap), 2 * R, bh)
          c.restore()
        } else if (root.kind === "hishi") {
          c.fillStyle = fg
          c.beginPath(); c.moveTo(cx, cy - r * 0.86); c.lineTo(cx + r * 0.58, cy); c.lineTo(cx, cy + r * 0.86); c.lineTo(cx - r * 0.58, cy); c.closePath(); c.fill()
          c.fillStyle = root.inked ? ink : Ink.paper
          c.beginPath(); c.moveTo(cx, cy - r * 0.42); c.lineTo(cx + r * 0.28, cy); c.lineTo(cx, cy + r * 0.42); c.lineTo(cx - r * 0.28, cy); c.closePath(); c.fill()
        } else if (root.kind === "igeta") {
          var w = r * 0.2, o = r * 0.3, L = r * 0.9
          c.fillStyle = fg
          c.fillRect(cx - o - w / 2, cy - L, w, 2 * L); c.fillRect(cx + o - w / 2, cy - L, w, 2 * L)
          c.fillRect(cx - L, cy - o - w / 2, 2 * L, w); c.fillRect(cx - L, cy + o - w / 2, 2 * L, w)
        } else if (root.kind === "wa") {
          ring(cx - r * 0.3, cy, r * 0.5, lw * 1.8, fg)
          ring(cx + r * 0.3, cy, r * 0.5, lw * 1.8, fg)
        }
      }
    }

    // 丸に文字: the character, brushed, in the ring.
    Text {
      visible: root.kind === "moji"
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -parent.height * 0.02
      text: root.glyph
      color: root.inked ? Ink.paper : root.tone
      font.family: Type.brush
      font.pixelSize: Math.round(parent.height * 0.5)
    }
  }
}
