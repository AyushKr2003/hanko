import QtQuick
import "../../core"

// Something you haven't seen (Kata part `unread`), drawn on its card or
// desk cell: Shōji's small vermilion 未 ("not yet") seal. Fill the parent;
// the mark places itself. `small` is the desk-cell size, a red diamond.
Item {
  id: root

  property var skin: ({})
  property bool small: false

  KataSeal {
    visible: !root.small
    x: root.width - size - Type.px(2); y: Type.px(2)
    skin: root.skin
    glyph: "未"; on: true; size: Type.px(18)
  }
  Rectangle {
    visible: root.small
    x: root.width - 9; y: 6; width: 4; height: 4; rotation: 45; radius: 1
    color: Ink.seal
  }
}
