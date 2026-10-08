import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// Battery and other progress (Kata part `ring`):
//   glyph  Margin and Leaf: a battery outline that fills (rounded or cut,
//          by the corner partner)
//   enso   Shōji: a brush circle that closes as it fills; the gap is what
//          is left, with a faint ring so a low value still reads
// size < 30 is the bar's small mark; larger is a panel's hero.
Item {
  id: root

  property var skin: ({})
  property real value: 100
  property int size: Type.px(17)
  property bool alert: false
  property color tint: Ink.ink2

  readonly property string kind: skin.ring || "glyph"
  readonly property bool small: size < 30
  readonly property color col: alert ? Ink.seal : (small ? tint : Ink.ink)
  readonly property real cut: skin.corner === "cut" ? 0 : 1

  implicitWidth: kind === "glyph" && small ? Math.round(size * 1.3) : size
  implicitHeight: kind === "glyph" && small ? Math.round(size * 0.7) : size

  // the battery glyph
  Item {
    visible: root.kind === "glyph"
    anchors.centerIn: parent
    width: root.small ? root.implicitWidth : root.size * 0.78
    height: root.small ? root.implicitHeight : root.size * 0.42
    Rectangle {
      width: parent.width - Math.max(2, parent.width * 0.09); height: parent.height
      radius: root.cut * parent.height * 0.3
      color: "transparent"; border.width: root.small ? 1.3 : 2.5; border.color: root.col
      Rectangle {
        x: parent.border.width + 1; y: parent.border.width + 1
        height: parent.height - 2 * y
        width: Math.max(1, (parent.width - 2 * x) * Math.max(0, Math.min(100, root.value)) / 100)
        radius: root.cut * height * 0.25
        color: root.col
      }
    }
    Rectangle {
      x: parent.width - width; y: parent.height * 0.3
      width: Math.max(1.5, parent.width * 0.07); height: parent.height * 0.4
      color: root.col
    }
  }
  // the ensō
  Rectangle {
    visible: root.kind === "enso"
    readonly property real w: root.small ? 2.6 : root.size * 0.095
    anchors.centerIn: parent
    width: root.size - w * 1.5; height: width; radius: width / 2
    color: "transparent"
    border.width: root.small ? w * 0.45 : 1
    border.color: root.small ? Ink.alpha(root.col, 0.28) : Ink.ink4
  }
  InkShape {
    visible: root.kind === "enso"
    anchors.fill: parent
    path: Brush.enso(root.value / 100, root.size, root.small ? 2.6 : root.size * 0.095, root.small ? 2 : 9)
    fill: root.col
  }
}
