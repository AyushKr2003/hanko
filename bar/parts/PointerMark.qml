pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// What your pointer (or keyboard) is on (Kata part `pointer`). Give it the
// target's box in the parent's coordinates; it moves there on the skin's
// tempo. Shōji draws a faint brush mark under it.
Item {
  id: root

  property var skin: ({})
  property rect target: Qt.rect(0, 0, 0, 0)
  property real lineY: target.y + target.height   // the bar's bottom line
  property bool shown: target.width > 0

  opacity: shown ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: Motion.ms(120) } }

  readonly property var curve: skin.openCurve || [0.16, 1, 0.3, 1, 1, 1]
  readonly property int dur: Motion.ms(Math.min(skin.open || 160, 220))

  Item {
    id: box
    x: root.target.x
    y: root.target.y
    width: root.target.width
    height: root.target.height
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: root.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
    Behavior on width { enabled: Motion.live; NumberAnimation { duration: root.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
  }

  InkShape {
    readonly property real w: Math.max(8, Math.min(Type.px(40), box.width - Type.px(10)) - 6)
    x: box.x + (box.width - w - 6) / 2; y: root.lineY - Type.px(11)
    width: w + 6; height: 4
    path: Brush.stroke(w, 4, 9)
    fill: Ink.ink3
  }
}
