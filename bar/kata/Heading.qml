import QtQuick
import "../../core"

// A small heading inside a panel ("Plays on", "Nearby"). Leaf sets its
// section heads in tracked capitals, the only caps in the system.
Item {
  id: root
  property var skin: ({})
  property string text: ""
  property string note: ""
  width: parent ? parent.width : 0
  implicitHeight: Type.px(26)
  Text {
    anchors.bottom: parent.bottom; anchors.bottomMargin: Type.px(6)
    text: root.skin.surface === "card" ? root.text.toUpperCase() : root.text
    color: Ink.ink3
    font.family: Type.text
    font.pixelSize: root.skin.surface === "card" ? Type.px(10.5) : Type.px(12.5)
    font.letterSpacing: root.skin.surface === "card" ? Type.px(1) : 0
    font.weight: root.skin.surface === "card" ? Font.Medium : Font.Normal
  }
  Text {
    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: Type.px(6)
    text: root.note
    color: Ink.ink3
    font.family: Type.text; font.pixelSize: Type.px(12)
  }
}
