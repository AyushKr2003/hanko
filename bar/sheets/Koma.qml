pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A shogi piece (koma 駒): the five-sided boxwood piece, narrower at the
// shoulders and peaked, its name brushed on it. Promoted, the character is
// red, as the reverse of a real piece is written. A piece turned away
// (pointing down) belongs to the other side: here, muted. Faint: a piece
// that is out of play (a day gone, a monitor switched off). On dark paper
// the piece is a bone plate; on light paper, where bone is ink, it stays
// pale wood with an inked edge.
Item {
  id: root
  property string glyph: ""
  property bool promoted: false
  property bool away: false
  property bool faint: false
  property bool lifted: false
  property real size: Type.px(26)
  readonly property color wood: Ink.light ? Ink.alpha(Ink.ink, 0.07) : Ink.bone
  readonly property color letter: Ink.light ? Ink.ink : Ink.boneInk

  width: size
  height: size * 1.12
  opacity: faint ? 0.42 : 1
  onWoodChanged: c.requestPaint()

  // Lifted: picked up off the board, as a hand raises a piece to move it.
  transform: Translate { y: root.lifted ? -Type.px(2) : 0 }

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
      g.fillStyle = root.wood
      g.fill()
      if (Ink.light) { g.strokeStyle = Ink.inkMuted; g.lineWidth = 1; g.stroke() }
      // The bevel: a hairline inside the edge, as the wood is chamfered.
      g.beginPath()
      g.moveTo(w * 0.5, h * 0.09)
      g.lineTo(w * 0.8, h * 0.25)
      g.lineTo(w * 0.9, h * 0.9)
      g.lineTo(w * 0.1, h * 0.9)
      g.lineTo(w * 0.2, h * 0.25)
      g.closePath()
      g.strokeStyle = Ink.alpha(root.letter, 0.18)
      g.lineWidth = 1
      g.stroke()
    }
  }
  // A two-character name is written down the piece, as 飛車 and 角行 are.
  readonly property bool pair: glyph.length > 1
  Text {
    visible: !root.pair
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height * (root.away ? 0.16 : 0.3)
    rotation: root.away ? 180 : 0
    text: root.glyph
    color: root.promoted ? Ink.seal : root.letter
    font.family: Type.brush
    font.pixelSize: root.size * 0.56
  }
  Column {
    visible: root.pair
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height * 0.24
    Repeater {
      model: root.pair ? root.glyph.slice(0, 2).split("") : []
      Text {
        id: half
        required property string modelData
        width: root.size * 0.5
        height: root.size * 0.37
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: half.modelData
        color: root.promoted ? Ink.seal : root.letter
        font.family: Type.brush
        font.pixelSize: root.size * 0.34
      }
    }
  }
}
