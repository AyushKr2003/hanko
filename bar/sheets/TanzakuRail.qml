pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// The rail the slips hang from: a thin rod across the sheet with a knot at
// each end, and the slips under it laid right to left, as a column of
// vertical writing runs. Put a LeadStrip first, then Tanzaku; a Spacer-like
// Item of any width parts the groups.
Item {
  id: root

  property real reach: Type.px(220)
  default property alias strips: row.data

  width: parent ? parent.width : 0
  implicitHeight: Type.px(6) + row.height

  Rectangle { y: Type.px(2); width: parent.width; height: 2; radius: 1; color: Ink.inkMuted }
  Repeater {
    model: 2
    Rectangle {
      required property int index
      x: index === 0 ? -Type.px(2) : root.width - Type.px(4)
      y: 0
      width: Type.px(6)
      height: width
      radius: width / 2
      color: Ink.inkMuted
    }
  }

  Row {
    id: row
    y: Type.px(3)
    width: parent.width
    layoutDirection: Qt.RightToLeft
    spacing: Type.px(8)
  }
}
