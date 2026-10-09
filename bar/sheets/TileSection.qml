import QtQuick
import "../../core"

// A labelled grid of tiles on a Dial sheet: a mono label and its count over
// the tiles, two (or `columns`) to a row.
Column {
  id: root

  property string label: ""
  property string summary: ""
  property int columns: 2
  default property alias tiles: grid.data
  readonly property real tileWidth: (width - (columns - 1) * grid.columnSpacing) / columns

  width: parent ? parent.width : 0
  topPadding: Type.px(18)
  spacing: Type.px(8)

  Item {
    width: parent.width
    height: Type.px(14)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.label.toUpperCase()
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.eyebrow
      font.weight: Type.labelWeight
      font.letterSpacing: Type.trackEyebrow
    }
    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: root.summary.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: Type.trackLabel
    }
  }
  Grid {
    id: grid
    width: parent.width
    columns: root.columns
    columnSpacing: Type.px(8)
    rowSpacing: Type.px(8)
  }
}
