pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// The paper a sheet is printed on (Sheet grammar, docs/COMPONENTS.md,
// "Panels"). It hangs flush from the bar: no gap, no bubble, and no rule
// on the side that joins the bar; a bone tear marks where it left the cell.
// Crop marks sit on the two free corners. It prints top-down when it opens
// (bottom-up from a bar at the bottom), as if fed through a press.
Item {
  id: root

  // The bar sits below the sheet (position: bottom); the sheet rises.
  property bool atBottom: false
  // Where the bone tear runs, in sheet coordinates.
  property int tearX: 0
  property int tearWidth: 0
  // 0 closed .. 1 fully printed. SheetView animates it.
  property real reveal: 1

  default property alias content: body.data

  implicitWidth: 430
  implicitHeight: body.implicitHeight

  // The printed part: the paper grows away from the bar as `reveal` runs.
  Item {
    id: press
    width: parent.width
    height: Math.round(root.height * root.reveal)
    y: root.atBottom ? root.height - height : 0
    clip: true

    Rectangle {
      id: paper
      width: root.width
      height: root.height
      y: root.atBottom ? press.height - root.height : 0
      color: Ink.paper

      Column {
        id: body
        width: parent.width
      }

      // Hairlines on every side but the one joined to the bar.
      Rectangle { x: 0; width: 1; height: parent.height; color: Ink.line }
      Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: Ink.line }
      Rectangle {
        y: root.atBottom ? 0 : parent.height - 1
        width: parent.width
        height: 1
        color: Ink.line
      }

      // The tear: the cell's width (and a little) in bone, on the bar side.
      Rectangle {
        x: root.tearX
        y: root.atBottom ? parent.height - 1 : 0
        width: root.tearWidth
        height: 1
        color: Ink.bone
      }
    }
  }

  // Crop marks on the free corners, once the sheet is fully printed.
  Repeater {
    model: 2
    Item {
      id: crop
      required property int index
      x: (crop.index === 0 ? 0 : root.width) - 5
      y: (root.atBottom ? 0 : root.height) - 5
      width: 9
      height: 9
      opacity: root.reveal >= 1 ? 1 : 0
      Behavior on opacity { enabled: !Motion.still; NumberAnimation { duration: 120 } }
      Rectangle { x: 4; width: 1; height: 9; color: Ink.lineStrong }
      Rectangle { y: 4; width: 9; height: 1; color: Ink.lineStrong }
    }
  }
}
