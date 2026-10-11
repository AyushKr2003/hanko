import QtQuick
import "../../core"

// The chosen row's mark, which slides between rows (Kata part `select`):
// Shōji's wash of thin ink with one brush edge. Put it behind the rows and
// move `y`; it slides on the skin's tempo.
Item {
  id: root

  property var skin: ({})

  Behavior on y {
    enabled: Motion.live
    NumberAnimation { duration: Motion.ms(root.skin.open || 240); easing.type: Easing.BezierSpline; easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] }
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: Ink.alpha(Ink.ink, 0.13) }
      GradientStop { position: 0.55; color: Ink.alpha(Ink.ink, 0.06) }
      GradientStop { position: 0.85; color: "transparent" }
    }
  }
  Rectangle {
    x: 0; y: 10; width: 2; height: root.height - 20; radius: 1
    color: Ink.ink
  }
}
