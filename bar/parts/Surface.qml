pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// What a panel is made of (Kata part `surface`):
//   paper  Margin: flat paper, a hairline frame, a soft shadow below
//   card   Leaf: a cut edge that catches light, a shaded underside, hard
//          offset shadows that never blur
//   washi  Shōji: translucent paper with fibres, lit from the top edge
// `hangs` squares and opens the top edge, for a panel that comes out of the bar.
Item {
  id: root

  property var skin: ({})
  property bool hangs: false
  property bool lifted: false     // Leaf's height 2: a dragged or held sheet

  readonly property string kind: skin.surface || "paper"
  readonly property int r: skin.radius === undefined ? 16 : skin.radius

  // Margin's soft shadow, stacked rather than blurred.
  Repeater {
    model: root.kind === "paper" ? 4 : 0
    Rectangle {
      id: layer
      required property int index
      x: -layer.index * 2; y: 6 + layer.index * 5
      width: root.width + layer.index * 4; height: root.height
      radius: root.r + layer.index * 2
      color: Ink.alpha("black", Ink.light ? 0.035 : 0.12)
    }
  }
  // Leaf's hard shadows: 0,2 and 2,4 (lifted 0,3 and 4,8).
  Rectangle {
    visible: root.kind === "card"
    x: root.lifted ? 4 : 2; y: root.lifted ? 8 : 4
    width: root.width; height: root.height
    color: Ink.shade2
  }
  Rectangle {
    visible: root.kind === "card"
    y: root.lifted ? 3 : 2
    width: root.width; height: root.height
    color: Ink.shade
  }
  // Shōji's washi casts a long, faint shadow onto the desk, stacked soft.
  Repeater {
    model: root.kind === "washi" ? 3 : 0
    Rectangle {
      id: fall
      required property int index
      x: 4 - fall.index * 2; y: 10 + fall.index * 5
      width: root.width - 8 + fall.index * 4; height: root.height - 4
      color: Ink.alpha("black", Ink.light ? 0.02 : 0.09)
    }
  }

  Rectangle {
    id: sheet
    anchors.fill: parent
    anchors.topMargin: root.hangs && root.kind === "paper" ? -root.r : 0
    radius: root.kind === "paper" ? root.r : 0
    color: root.kind === "washi" ? Ink.alpha(Ink.paper, root.skin.opacity || 0.86) : Ink.paper
    border.width: root.kind === "card" ? 0 : 1
    border.color: root.kind === "washi" ? Ink.ink4 : Ink.kLine
    clip: true

    Fibres {
      anchors.fill: parent
      kind: root.kind === "card" ? "grain" : "washi"
      level: root.kind === "paper" ? 0 : Math.max(1, root.skin.grain || 0)
    }
    // Light through paper: brightest at the top edge.
    Rectangle {
      visible: root.kind === "washi"
      anchors.left: parent.left; anchors.right: parent.right
      height: parent.height * 0.4
      gradient: Gradient {
        GradientStop { position: 0; color: Ink.alpha(Ink.ink, 0.05) }
        GradientStop { position: 1; color: "transparent" }
      }
    }
  }
  // Paper hanging from the bar: the top edge is the bar's own line.
  Rectangle {
    visible: root.hangs && root.kind === "paper"
    x: 1; width: root.width - 2; height: root.r + 1; y: -root.r
    color: Ink.paper
  }
  // Leaf's cut: light along the top, shade along the bottom and sides.
  Rectangle { visible: root.kind === "card" && !root.hangs; width: root.width; height: 1; color: Ink.cut }
  Rectangle { visible: root.kind === "card"; y: root.height - 1; width: root.width; height: 1; color: Ink.edge }
  Rectangle { visible: root.kind === "card"; width: 1; height: root.height; color: Ink.edgeSide }
  Rectangle { visible: root.kind === "card"; x: root.width - 1; width: 1; height: root.height; color: Ink.edgeSide }
}
