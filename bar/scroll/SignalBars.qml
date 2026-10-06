pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Four rising bars, `lit` of them inked, the rest at a quarter.
Row {
  id: root
  property int lit: 0
  property color ink: Ink.inkMuted
  spacing: 2
  Repeater {
    model: 4
    Rectangle {
      id: bar
      required property int index
      anchors.bottom: parent.bottom
      width: 3
      height: [5, 8, 11, 14][bar.index]
      color: root.ink
      opacity: bar.index < root.lit ? 1 : 0.25
    }
  }
}
