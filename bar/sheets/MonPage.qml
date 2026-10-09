pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A section of crests, as a crest book sets them: a heading with its kanji
// and a rule, then the mon in a grid (four to a row), each over its caption.
Column {
  id: root

  property string jp: ""
  property string label: ""
  property string summary: ""
  property int columns: 4
  default property alias crests: grid.data
  readonly property real cellWidth: (width - (columns - 1) * grid.columnSpacing) / columns

  width: parent ? parent.width : 0
  topPadding: Type.px(20)
  spacing: Type.px(14)

  Item {
    width: parent.width
    height: Type.px(14)
    Row {
      id: head
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(8)
      Text { anchors.verticalCenter: parent.verticalCenter; text: root.jp; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(14) }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label.toUpperCase()
        color: Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.eyebrow
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackEyebrow
      }
    }
    Rectangle {
      x: head.width + Type.px(12)
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, sum.x - x - Type.px(12))
      height: 1
      color: Ink.lineSoft
    }
    Text {
      id: sum
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: root.summary.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }
  Grid {
    id: grid
    width: parent.width
    columns: root.columns
    columnSpacing: Type.px(10)
    rowSpacing: Type.px(16)
  }
}
