import QtQuick
import "../../core"

// The edge label a plate carries, read bottom-up along its left side.
Item {
  id: root
  property string text: ""
  width: 1
  height: 1
  Text {
    anchors.centerIn: parent
    rotation: -90
    text: root.text
    color: Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.px(2.2)
  }
}
