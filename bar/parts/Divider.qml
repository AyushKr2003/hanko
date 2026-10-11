pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A line between parts of a panel (Kata partner `divider`): Shōji's
// lattice, one line with its joints marked where it meets the frame.
// `bleed` reaches past the panel's padding to the frame on both sides.
Item {
  id: root

  property var skin: ({})
  property real bleed: 0

  implicitHeight: 1
  height: implicitHeight

  Rectangle {
    x: -root.bleed; width: root.width + 2 * root.bleed; height: 1
    color: Ink.kLine
  }
  Repeater {
    model: 2
    Rectangle {
      id: joint
      required property int index
      x: joint.index === 0 ? -root.bleed - 3 : root.width + root.bleed - 2
      y: -2; width: 5; height: 5
      color: Ink.paper
      border.width: 1; border.color: Ink.ink4
    }
  }
}
