pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// A value from 0 to 100 you drag or scroll (Kata part `slider`). One API,
// three drawings:
//   ruler  Margin: fine ticks; the value is the long tick
//   block  Leaf: ticks inked up to the value, an ink block for a handle
//   brush  Shōji: one sumi stroke whose length is the value, over a ruler
// Ticks sit on whole pixels so the ruler never shimmers.
Item {
  id: root

  property var skin: ({})
  property real value: 50
  property bool thin: false
  property bool muted: false
  property int seed: 4
  signal moved(real value)

  readonly property string kind: skin.slider || "ruler"
  readonly property int ticks: kind === "brush" ? (thin ? 11 : 21) : (thin ? 25 : 49)
  readonly property real step: (width - 2) / (ticks - 1)
  readonly property int at: Math.round(Math.max(0, Math.min(100, value)) / 100 * (ticks - 1))
  readonly property color on: muted ? Ink.seal : Ink.ink

  implicitWidth: Type.px(thin ? 120 : 336)
  implicitHeight: Type.px(thin ? 18 : 30)

  Repeater {
    model: root.ticks
    Rectangle {
      required property int index
      readonly property bool major: root.kind === "brush" ? index % 5 === 0 : index % 4 === 0
      readonly property bool isValue: root.kind === "ruler" && index === root.at
      x: Math.round(index * root.step)
      width: root.kind === "block" ? 1 : (isValue ? 2 : 1.5)
      height: isValue ? root.height
        : root.kind === "brush" ? Type.px(major ? (root.thin ? 4 : 7) : (root.thin ? 2 : 4))
        : Type.px(major ? (root.thin ? 9 : 16) : (root.thin ? 6 : 10))
      y: root.height - height - (isValue ? 0 : 2)
      radius: root.kind === "block" ? 0 : 0.75
      color: isValue ? root.on
        : root.kind === "brush" ? (major ? Ink.ink3 : Ink.ink4)
        : index < root.at ? (root.kind === "block" ? root.on : Ink.ink2) : Ink.ink4
    }
  }
  Rectangle {
    visible: root.kind === "block"
    x: Math.round(root.at * root.step) - 2
    y: root.height - height
    width: Type.px(6); height: Type.px(root.thin ? 13 : 22)
    color: root.on
  }
  Item {
    visible: root.kind === "brush"
    readonly property real h: Type.px(root.thin ? 9 : 16)
    readonly property real len: Math.max(4, Math.round(root.value / 100 * root.width))
    x: -2; y: Type.px(root.thin ? 1 : 3)
    width: len + h; height: h
    InkShape { anchors.fill: parent; path: Brush.stroke(parent.len, parent.h, root.seed); fill: root.on }
    Repeater {
      model: Brush.kasure(parent.len, parent.h, root.seed)
      Rectangle {
        required property var modelData
        x: modelData.x0; y: modelData.y; width: modelData.x1 - modelData.x0; height: modelData.width
        color: Ink.paper; opacity: 0.7
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.SizeHorCursor
    function pick(mx) { root.moved(Math.round(Math.max(0, Math.min(1, mx / width)) * 100)) }
    onPressed: (m) => pick(m.x)
    onPositionChanged: (m) => { if (pressed) pick(m.x) }
    onWheel: (w) => root.moved(Math.max(0, Math.min(100, root.value + (w.angleDelta.y > 0 ? 2 : -2))))
  }
}
