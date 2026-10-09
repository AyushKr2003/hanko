pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// What a panel is made of (Kata part `surface`): Shōji's washi, translucent
// paper with fibres, lit from the top edge, casting a long faint shadow.
Item {
  id: root

  property var skin: ({})

  // How solid the paper is (skin.opacity: the design's, or the panel opacity
  // setting). Shadows sit under the whole sheet, so they fade out as the
  // paper clears, gone by half: glass casts no shadow.
  readonly property real paperOpacity: skin.opacity === undefined ? 0.86 : skin.opacity
  readonly property real shadowOpacity: Math.max(0, Math.min(1, (paperOpacity - 0.5) / 0.36))

  // The washi casts a long, faint shadow onto the desk, stacked soft.
  Repeater {
    model: 3
    Rectangle {
      id: fall
      opacity: root.shadowOpacity
      required property int index
      x: 4 - fall.index * 2; y: 10 + fall.index * 5
      width: root.width - 8 + fall.index * 4; height: root.height - 4
      color: Ink.alpha("black", Ink.light ? 0.02 : 0.09)
    }
  }

  Rectangle {
    id: sheet
    anchors.fill: parent
    color: Ink.alpha(Ink.paper, root.paperOpacity)
    border.width: 1
    border.color: Ink.ink4
    clip: true

    Fibres {
      anchors.fill: parent
      level: Math.max(1, root.skin.grain || 0)
    }
    // Light through paper: brightest at the top edge.
    Rectangle {
      anchors.left: parent.left; anchors.right: parent.right
      height: parent.height * 0.4
      gradient: Gradient {
        GradientStop { position: 0; color: Ink.alpha(Ink.ink, 0.05) }
        GradientStop { position: 1; color: "transparent" }
      }
    }
  }
}
