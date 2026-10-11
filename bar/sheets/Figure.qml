import QtQuick
import "../../core"

// A panel's hero figure: Fraunces, tabular, with a unit.
// An Item around the row, so a MouseArea child can fill it.
Item {
  id: root
  property var skin: ({})
  property string value: ""
  property string unit: ""
  property int size: Type.px(64)
  property color color: Ink.ink
  implicitWidth: line.implicitWidth
  implicitHeight: line.implicitHeight
  width: implicitWidth
  height: implicitHeight
  Row {
    id: line
    spacing: Type.px(4)
    Text {
      id: n
      text: root.value
      color: root.color
      font.family: Type.display; font.pixelSize: root.size; font.weight: Font.Normal
      font.variableAxes: Type.axes(root.size, 330)
      font.features: { "tnum": 1, "lnum": 1 }
    }
    Text {
      visible: root.unit !== ""
      anchors.baseline: n.baseline
      text: root.unit
      color: Ink.ink3
      font.family: Type.display; font.pixelSize: Math.round(root.size * 0.3); font.weight: Font.Normal
    }
  }
}
