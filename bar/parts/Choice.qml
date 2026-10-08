pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One of a few (a segmented control), drawn by the surface:
//   paper  Margin: a sunk tray, an ink knob with soft corners
//   card   Leaf: a debossed slot, an ink plate
//   washi  Shōji: three sliding doors (fusuma) in a frame; the ink door slides
Item {
  id: root

  property var skin: ({})
  property var options: []          // [{ key, label }]
  property string current: ""
  signal picked(string key)

  readonly property string kind: skin.surface || "paper"
  readonly property int index: {
    for (var i = 0; i < options.length; i++) if (options[i].key === current) return i
    return -1
  }
  readonly property real pad: kind === "washi" ? 0 : Type.px(3)
  readonly property real cellW: options.length ? (width - 2 * pad) / options.length : 0

  implicitHeight: Type.px(38)

  Rectangle {
    anchors.fill: parent
    radius: root.kind === "paper" ? (root.skin.radiusRow || 10) + 1 : 0
    color: root.kind === "paper" ? Ink.sunk : root.kind === "card" ? Ink.paper2 : "transparent"
    border.width: root.kind === "card" ? 0 : 1
    border.color: root.kind === "washi" ? Ink.ink4 : Ink.kLine
  }
  Rectangle { visible: root.kind === "card"; width: parent.width; height: 1; color: Ink.shadeIn }
  Rectangle { visible: root.kind === "card"; width: 1; height: parent.height; color: Ink.shadeIn }
  Rectangle { visible: root.kind === "card"; y: parent.height - 1; width: parent.width; height: 1; color: Ink.cut }
  Repeater {
    model: root.kind === "washi" ? Math.max(0, root.options.length - 1) : 0
    Rectangle { required property int index; x: (index + 1) * root.cellW; width: 1; height: root.height; color: Ink.kLine }
  }
  Rectangle {
    visible: root.index >= 0
    x: root.pad + root.index * root.cellW
    y: root.pad
    width: root.cellW; height: root.height - 2 * root.pad
    radius: root.kind === "paper" ? (root.skin.radiusRow || 10) : 0
    color: Ink.ink
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(root.skin.open || 200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] } }
  }
  Repeater {
    model: root.options
    Item {
      id: opt
      required property var modelData
      required property int index
      x: root.pad + index * root.cellW
      y: root.pad
      width: root.cellW; height: root.height - 2 * root.pad
      Text {
        anchors.centerIn: parent
        text: opt.modelData.label
        color: opt.index === root.index ? Ink.paper : Ink.ink3
        font.family: Type.text; font.pixelSize: Type.px(12.5)
        font.weight: opt.index === root.index ? Font.Medium : Font.Normal
        font.variableAxes: Type.valueAxes
      }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(opt.modelData.key) }
    }
  }
}
