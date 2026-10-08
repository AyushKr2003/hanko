import QtQuick
import "../../core"

// Something you haven't seen (Kata part `unread`), drawn on its card or
// desk cell. Fill the parent; the mark places itself.
//   edge    Margin: a short red edge on the left
//   dogear  Leaf: the corner folded over, in seal ink
//   stamp   Shōji: a small vermilion 未 ("not yet") seal
// `small` is the desk-cell size.
Item {
  id: root

  property var skin: ({})
  property bool small: false
  readonly property string kind: skin.unread || "edge"

  Rectangle {
    visible: root.kind === "edge"
    x: root.small ? root.width - 9 : -1
    y: root.small ? 4 : Type.px(14)
    width: root.small ? 5 : 3
    height: root.small ? 5 : Type.px(16)
    radius: root.small ? 2.5 : 1.5
    color: Ink.seal
  }
  InkShape {
    visible: root.kind === "dogear"
    x: root.width - width; y: 0
    width: root.small ? 6 : Type.px(12); height: width
    path: "M 0 0 L " + width + " 0 L " + width + " " + height + " Z"
    fill: Ink.seal
  }
  KataSeal {
    visible: root.kind === "stamp" && !root.small
    x: root.width - size - Type.px(2); y: Type.px(2)
    skin: ({ seal: "carved", corner: "cut" })
    glyph: "未"; on: true; size: Type.px(18)
  }
  Rectangle {
    visible: root.kind === "stamp" && root.small
    x: root.width - 9; y: 6; width: 4; height: 4; rotation: 45; radius: 1
    color: Ink.seal
  }
}
