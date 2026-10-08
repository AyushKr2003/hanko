import QtQuick
import "../../core"

// The edge label a plate carries, read bottom-up along its left side.
Item {
  id: root
  property string text: ""
  // How long the label runs along the edge, so a plate can drop it when it
  // would run off a short window.
  readonly property real length: label.implicitWidth
  width: 1
  height: 1
  Text {
    id: label
    anchors.centerIn: parent
    rotation: -90
    text: root.text
    color: Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.px(2.2)
  }
}
