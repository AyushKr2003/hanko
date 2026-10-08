import QtQuick
import "../../core"

// The chosen row's mark, which slides between rows (Kata part `select`):
//   tint   Margin: a faint ink tint with a hairline inside
//   plate  Leaf: a solid ink plate; the row's text turns paper (`inverts`)
//   wash   Shōji: a wash of thin ink with one brush edge
// Put it behind the rows and move `y`; it slides on the skin's tempo.
Item {
  id: root

  property var skin: ({})
  readonly property string kind: skin.select || "tint"
  readonly property bool inverts: kind === "plate"

  Behavior on y {
    enabled: Motion.live
    NumberAnimation { duration: Motion.ms(root.skin.open || 240); easing.type: Easing.BezierSpline; easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] }
  }

  Rectangle {
    anchors.fill: parent
    visible: root.kind !== "wash"
    radius: root.kind === "tint" ? (root.skin.radiusRow === undefined ? 10 : root.skin.radiusRow) : 0
    color: root.kind === "plate" ? Ink.ink : Ink.alpha(Ink.ink, 0.07)
    border.width: root.kind === "tint" ? 1 : 0
    border.color: Ink.alpha(Ink.ink, 0.06)
  }
  Rectangle {
    visible: root.kind === "plate"
    y: root.height; width: root.width; height: 1
    color: Ink.shade
  }
  Rectangle {
    anchors.fill: parent
    visible: root.kind === "wash"
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Ink.alpha(Ink.ink, 0.13) }
      GradientStop { position: 0.55; color: Ink.alpha(Ink.ink, 0.06) }
      GradientStop { position: 0.85; color: "transparent" }
    }
  }
  Rectangle {
    visible: root.kind === "wash"
    x: 0; y: 10; width: 2; height: root.height - 20; radius: 1
    color: Ink.ink
  }
}
