import QtQuick
import "../../core"

// The strip at a sheet's foot: a hairline over it, a small ink square and
// a mono note on the left (`■ INPUT · SHURE MV7`), buttons on the right.
Item {
  id: root

  property string note: ""
  default property alias buttons: right.data

  width: parent ? parent.width : 0
  implicitHeight: Math.max(right.height, noteText.height) + Type.px(24)

  Rectangle { width: parent.width; height: 1; color: Ink.line }

  // The note gives way to the buttons.
  Row {
    anchors.left: parent.left
    anchors.leftMargin: Type.px(22)
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(0, right.x - Type.px(22) - Type.px(12))
    spacing: Type.px(10)
    visible: root.note !== ""

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: Type.px(6)
      height: Type.px(6)
      color: Ink.ink
    }
    Text {
      id: noteText
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, parent.width - Type.px(16))
      elide: Text.ElideRight
      text: root.note.toUpperCase()
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.px(9.5)
      font.letterSpacing: Type.px(1.8)
    }
  }

  Row {
    id: right
    anchors.right: parent.right
    anchors.rightMargin: Type.px(22)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(10)
  }
}
