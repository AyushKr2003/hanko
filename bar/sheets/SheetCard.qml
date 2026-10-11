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
  // Panel opacity (Style.js panelOpacity): how solid the paper is.
  property real paperOpacity: 1
  property bool atBottom: false
  // Where the bone tear runs, in sheet coordinates.
  property int tearX: 0
  property int tearWidth: 0
  // 0 closed .. 1 fully printed. SheetView animates it.
  property real reveal: 1

  default property alias content: body.data

  implicitWidth: 430
  implicitHeight: body.implicitHeight

  // A soft shadow under the free sides, so the sheet lifts off a busy
  // wallpaper. It grows with the print and never falls on the bar, and it
  // fades out as the paper is made see-through (no shadow under glass).
  Item {
    id: shade
    readonly property int reach: Type.px(14)
    readonly property real strength: Math.max(0, Math.min(1, (root.paperOpacity - 0.5) / 0.4)) * (Ink.light ? 0.10 : 0.30)
    x: -reach
    y: root.atBottom ? press.y - reach : 0
    width: root.width + 2 * reach
    height: press.height + reach
    visible: strength > 0 && press.height > 0
    clip: true
    Repeater {
      model: 7
      Rectangle {
        id: layer
        required property int index
        readonly property int spread: Math.round(shade.reach * (layer.index + 1) / 7)
        x: shade.reach - spread
        y: root.atBottom ? shade.reach - spread + Type.px(2) : -shade.reach
        width: root.width + 2 * spread
        height: press.height + shade.reach + spread - Type.px(2)
        radius: spread
        color: Qt.rgba(0, 0, 0, shade.strength / 7)
      }
    }
  }

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
      color: Ink.alpha(Ink.paper, root.paperOpacity)

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

      // The tear: the cell's width (and a little) in bone, on the bar side,
      // with a faint fall-off either side like ink spreading in the fibres.
      Rectangle {
        x: root.tearX - Type.px(24)
        y: root.atBottom ? parent.height - 1 : 0
        width: root.tearWidth + Type.px(48)
        height: 1
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: Ink.alpha(Ink.bone, 0) }
          GradientStop { position: 0.5; color: Ink.alpha(Ink.bone, 0.35) }
          GradientStop { position: 1; color: Ink.alpha(Ink.bone, 0) }
        }
      }
      Rectangle {
        x: root.tearX
        y: root.atBottom ? parent.height - 2 : 0
        width: root.tearWidth
        height: 2
        color: Ink.bone
      }
    }
  }

  // Crop marks on the free corners, once the sheet is fully printed: two
  // arms each, set off the trim as a printer's are, never touching the paper.
  Repeater {
    model: 2
    Item {
      id: crop
      required property int index
      readonly property int gap: Type.px(4)
      readonly property int arm: Type.px(9)
      readonly property int sx: crop.index === 0 ? -1 : 1
      readonly property int sy: root.atBottom ? -1 : 1
      x: crop.index === 0 ? 0 : root.width - 1
      y: root.atBottom ? 0 : root.height - 1
      opacity: root.reveal >= 1 ? 1 : 0
      Behavior on opacity { enabled: !Motion.still; NumberAnimation { duration: 160 } }
      // Along the far edge, outward from the side.
      Rectangle {
        x: crop.sx < 0 ? -crop.gap - crop.arm : crop.gap + 1
        width: crop.arm
        height: 1
        color: Ink.lineStrong
      }
      // Down the side, outward from the far edge.
      Rectangle {
        y: crop.sy > 0 ? crop.gap + 1 : -crop.gap - crop.arm
        width: 1
        height: crop.arm
        color: Ink.lineStrong
      }
    }
  }
}
