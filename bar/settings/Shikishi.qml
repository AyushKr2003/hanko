import QtQuick
import "../../core"

// Your seal glyph written as a one-character work (一字書) and signed the
// way calligraphy is: the work large in ink, and in its lower left the
// rakkan (落款), a signature running down the margin over two small seals,
// as a work carries them: a square hakubun (白文, your name's initial cut
// white out of vermilion) for the name, and a round shubun (朱文, the glyph
// standing in vermilion) for the pen name. Drawn crisp in vector,
// so the only red on the Profile plate is two small, exact marks.
Item {
  id: root

  property string glyph: "印"
  property string name: ""
  property string date: ""

  readonly property real s: Math.min(width, height)
  readonly property string initial: (name || "?").charAt(0).toUpperCase()

  // The work: the glyph, large, a little right of centre so the signature
  // has its margin.
  Text {
    id: work
    x: Math.round(root.width * 0.56 - width / 2)
    y: Math.round(root.height * 0.46 - height / 2)
    text: root.glyph
    color: Ink.ink
    font.family: Type.jpSerif
    font.weight: Font.Black
    font.pixelSize: Math.round(root.s * 0.6)
  }

  // The rakkan, down the left margin: the signature, then the seals.
  Column {
    id: rakkan
    x: Math.round(root.s * 0.1)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Math.round(root.s * 0.08)
    spacing: Math.round(root.s * 0.022)

    // The signature, set down the margin as a name is brushed down a work.
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: sig.implicitHeight
      height: sig.implicitWidth
      Text {
        id: sig
        readonly property int size: Math.max(Type.px(11), Math.round(root.s * 0.034))
        anchors.centerIn: parent
        rotation: 90
        text: root.name + (root.date ? "  ·  " + root.date : "")
        color: Ink.inkDim
        font.family: Type.display
        font.italic: true
        font.pixelSize: sig.size
        font.variableAxes: Type.axes(sig.size)
      }
    }

    // Hakubun, the name seal: your initial cut white out of vermilion.
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.round(root.s * 0.1)
      height: width
      radius: Math.max(1, width * 0.04)
      color: Ink.seal
      Text {
        id: nameSeal
        readonly property int size: Math.round(parent.width * 0.62)
        anchors.centerIn: parent
        text: root.initial
        color: Ink.paper
        font.family: Type.display
        font.weight: Font.DemiBold
        font.pixelSize: nameSeal.size
        font.variableAxes: Type.axes(nameSeal.size, 600)
      }
    }

    // Shubun, the pen-name seal: the glyph standing in vermilion in a ring.
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.round(root.s * 0.086)
      height: width
      radius: width / 2
      color: "transparent"
      border.width: Math.max(1.5, width * 0.07)
      border.color: Ink.seal
      Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -parent.width * 0.02
        text: root.glyph
        color: Ink.seal
        font.family: Type.jpSerif
        font.weight: Font.Bold
        font.pixelSize: Math.round(parent.width * 0.52)
      }
    }
  }
}
