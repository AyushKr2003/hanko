pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// How a panel says what it is (Kata part `sign`): Shōji's tategaki, the
// name written down the panel's right edge in Mincho, English beside it.
// The panel lays it out as a column down that edge.
Item {
  id: root

  property var skin: ({})
  property string kanji: "音"
  property string name: "Sound"

  implicitWidth: Type.px(52)
  implicitHeight: column.implicitHeight

  Column {
    id: column
    width: root.width
    topPadding: Type.px(18)
    spacing: Type.px(14)
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Type.px(4)
      Repeater {
        model: Array.from(root.kanji)
        Text {
          required property string modelData
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData
          color: Ink.ink
          font.family: Type.jpSerif; font.weight: Font.Medium; font.pixelSize: Type.px(24)
        }
      }
    }
    // Latin in a vertical line turns 90°, as Japanese print sets it.
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: en.implicitHeight; height: en.implicitWidth
      Text {
        id: en
        anchors.centerIn: parent
        rotation: 90
        text: root.name
        color: Ink.ink3
        font.family: Type.text; font.pixelSize: Type.px(11.5)
      }
    }
  }
}
