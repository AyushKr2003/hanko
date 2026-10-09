import QtQuick
import "../../../core"

// A shogi piece (koma 駒): the five-sided boxwood piece, narrower at the
// shoulders and peaked, its name brushed on it. Promoted, the character is
// red, as the reverse of a real piece is written. A piece turned away
// (pointing down) belongs to the other side: here, muted.
Item {
  id: root
  property string glyph: ""
  property bool promoted: false
  property bool away: false
  property bool faint: false
  property real size: Type.px(26)

  width: size
  height: size * 1.12
  opacity: faint ? 0.45 : 1

  Canvas {
    id: c
    anchors.fill: parent
    rotation: root.away ? 180 : 0
    onPaint: {
      var g = getContext("2d"), w = width, h = height
      g.reset()
      g.beginPath()
      g.moveTo(w * 0.5, 0.5)
      g.lineTo(w * 0.86, h * 0.2)
      g.lineTo(w - 0.5, h - 0.5)
      g.lineTo(0.5, h - 0.5)
      g.lineTo(w * 0.14, h * 0.2)
      g.closePath()
      g.fillStyle = Ink.bone
      g.fill()
      // The bevel: a hairline inside the edge, as the wood is chamfered.
      g.beginPath()
      g.moveTo(w * 0.5, h * 0.09)
      g.lineTo(w * 0.8, h * 0.25)
      g.lineTo(w * 0.9, h * 0.9)
      g.lineTo(w * 0.1, h * 0.9)
      g.lineTo(w * 0.2, h * 0.25)
      g.closePath()
      g.strokeStyle = Ink.alpha(Ink.boneInk, 0.18)
      g.lineWidth = 1
      g.stroke()
    }
  }
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height * 0.3
    rotation: root.away ? 180 : 0
    text: root.glyph
    color: root.promoted ? Ink.seal : Ink.boneInk
    font.family: Type.brush
    font.pixelSize: root.size * 0.56
  }
}
