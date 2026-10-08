pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// What your pointer (or keyboard) is on (Kata part `pointer`). Give it the
// target's box in the parent's coordinates; it moves there on the skin's tempo.
//   thread  Margin: the bar's line thickens under it
//   crop    Leaf: four crop marks snap around it, with its name below
//   brush   Shōji: a faint brush mark under it
Item {
  id: root

  property var skin: ({})
  property rect target: Qt.rect(0, 0, 0, 0)
  property real lineY: target.y + target.height   // the bar's bottom line, for thread and brush
  property string label: ""
  property bool shown: target.width > 0
  readonly property string kind: skin.pointer || "thread"

  opacity: shown ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: Motion.ms(120) } }

  readonly property var curve: skin.openCurve || [0.16, 1, 0.3, 1, 1, 1]
  readonly property int dur: Motion.ms(Math.min(skin.open || 160, 220))

  Item {
    id: box
    x: root.kind === "crop" ? root.target.x + 2 : root.target.x
    y: root.target.y
    width: root.kind === "crop" ? root.target.width - 4 : root.target.width
    height: root.target.height
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: root.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
    Behavior on width { enabled: Motion.live; NumberAnimation { duration: root.dur; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
  }

  Rectangle {
    visible: root.kind === "thread"
    x: box.x + Type.px(6); width: Math.max(0, box.width - Type.px(12))
    y: root.lineY - 2; height: 2; radius: 1
    color: Ink.ink
  }
  Repeater {
    model: root.kind === "crop" ? 4 : 0
    Item {
      id: corner
      required property int index
      readonly property bool atRight: corner.index % 2 === 1
      readonly property bool atBottom: corner.index > 1
      x: box.x + (corner.atRight ? box.width - 7 : 0) + (corner.atRight ? 1 : -1)
      y: box.y + Type.px(5) + (corner.atBottom ? box.height - Type.px(10) - 7 : 0) + (corner.atBottom ? 1 : -1)
      width: 7; height: 7
      Rectangle { x: corner.atRight ? 5.5 : 0; width: 1.5; height: 7; color: Ink.ink }
      Rectangle { y: corner.atBottom ? 5.5 : 0; width: 7; height: 1.5; color: Ink.ink }
    }
  }
  Rectangle {
    visible: root.kind === "crop" && root.label !== ""
    x: box.x + (box.width - width) / 2; y: box.y + box.height + Type.px(2)
    width: tip.implicitWidth + Type.px(14); height: tip.implicitHeight + Type.px(10)
    color: Ink.ink
    Text {
      id: tip
      anchors.centerIn: parent
      text: root.label
      color: Ink.paper
      font.family: Type.text; font.pixelSize: Type.px(11.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes
    }
  }
  InkShape {
    visible: root.kind === "brush"
    readonly property real w: Math.max(8, Math.min(Type.px(40), box.width - Type.px(10)) - 6)
    x: box.x + (box.width - w - 6) / 2; y: root.lineY - Type.px(11)
    width: w + 6; height: 4
    path: Brush.stroke(w, 4, 9)
    fill: Ink.ink3
  }
}
