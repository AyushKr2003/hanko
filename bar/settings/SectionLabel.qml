import QtQuick
import "../../core"

// A section's label on a plate: its kanji, tracked caps and a hairline to
// the column's end (登録 REGISTER ─────). Shared by Profile, About and
// Credits so their sections read as one system.
Item {
  id: sl
  property string jp: ""
  property string text: ""
  width: parent ? parent.width : 0
  height: Type.px(14)
  Row {
    id: slRow
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(8)
    Text { anchors.verticalCenter: parent.verticalCenter; text: sl.jp; color: Ink.inkMuted; font.family: Type.jp; font.pixelSize: Type.tag }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: sl.text.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackEyebrow
    }
  }
  Rectangle {
    x: slRow.width + Type.px(12)
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(0, sl.width - x)
    height: 1
    color: Ink.lineSoft
  }
}
