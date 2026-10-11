import QtQuick
import "../../core"

// The plain hero the Shōgi and Soroban hands open with: the figure in
// Fraunces, and beside it the italic line and a mono caption.
//   62  through Studio Monitors
//       MASTER ON THE FOURTH FILE
Row {
  id: root
  property var hero: ({ figure: "—", unit: "", line: "", caption: "", red: false })
  // The hand's own words under the line (where the reading stands).
  property string caption: hero.caption

  spacing: Type.px(10)

  Row {
    spacing: Type.px(3)
    Text {
      id: figure
      text: root.hero.figure
      color: root.hero.red ? Ink.seal : Ink.ink
      font.family: Type.display
      font.pixelSize: Type.px(44)
      font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(44), 380)
      font.features: { "tnum": 1 }
    }
    Text {
      visible: root.hero.unit !== ""
      y: Type.px(9)
      text: root.hero.unit
      color: Ink.inkMuted
      font.family: Type.display
      font.pixelSize: Type.px(16)
      font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(16))
    }
  }
  Column {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(8)
    spacing: Type.px(2)
    Text {
      text: root.hero.line
      color: Ink.ink
      font.family: Type.display
      font.italic: true
      font.pixelSize: Type.px(16)
      font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(16), 360)
    }
    Text {
      visible: text !== ""
      text: root.caption.toUpperCase()
      color: root.hero.red ? Ink.seal : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }
}
