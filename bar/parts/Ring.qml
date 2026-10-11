import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// Battery and other progress (Kata part `ring`): Shōji's ensō, a brush
// circle that closes as it fills; the gap is what is left, with a faint
// ring so a low value still reads. size < 30 is the bar's small mark;
// larger is a panel's hero.
Item {
  id: root

  property var skin: ({})
  property real value: 100
  property int size: Type.px(17)
  property bool alert: false
  property color tint: Ink.ink2

  readonly property bool small: size < 30
  readonly property color col: alert ? Ink.seal : (small ? tint : Ink.ink)

  implicitWidth: size
  implicitHeight: size

  Rectangle {
    readonly property real w: root.small ? 2.6 : root.size * 0.095
    anchors.centerIn: parent
    width: root.size - w * 1.5; height: width; radius: width / 2
    color: "transparent"
    border.width: root.small ? w * 0.45 : 1
    border.color: root.small ? Ink.alpha(root.col, 0.28) : Ink.ink4
  }
  InkShape {
    anchors.fill: parent
    path: Brush.enso(root.value / 100, root.size, root.small ? 2.6 : root.size * 0.095, root.small ? 2 : 9)
    fill: root.col
  }
}
