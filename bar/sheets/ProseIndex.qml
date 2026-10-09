import QtQuick
import "../../core"

// A Prose sheet's index: a quiet label and a hairline over numbered lines
// (IndexRow), like the notes under a paragraph.
Column {
  id: root
  property string label: ""
  property string summary: ""
  default property alias rows: list.data

  width: parent ? parent.width : 0
  topPadding: Type.px(18)
  spacing: Type.px(6)

  Item {
    width: parent.width
    height: Type.px(14)
    Text {
      id: lab
      anchors.verticalCenter: parent.verticalCenter
      text: root.label.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackEyebrow
    }
    Rectangle {
      x: lab.width + Type.px(10)
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, sum.x - x - Type.px(10))
      height: 1
      color: Ink.lineSoft
    }
    Text {
      id: sum
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: root.summary.toUpperCase()
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }
  Column { id: list; width: parent.width }
}
