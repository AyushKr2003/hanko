import QtQuick
import "../../core"

// A small heading inside a panel ("Plays on", "Nearby").
Item {
  id: root
  property var skin: ({})
  property string text: ""
  property string note: ""
  width: parent ? parent.width : 0
  implicitHeight: Type.px(26)
  Text {
    anchors.bottom: parent.bottom; anchors.bottomMargin: Type.px(6)
    text: root.text
    color: Ink.ink3
    font.family: Type.text
    font.pixelSize: Type.px(12.5)
  }
  Text {
    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: Type.px(6)
    text: root.note
    color: Ink.ink3
    font.family: Type.text; font.pixelSize: Type.px(12)
  }
}
