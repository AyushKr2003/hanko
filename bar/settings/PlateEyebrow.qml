import QtQuick
import "../../core"

// A plate's register line: a short ink rule, a kanji, a dot, a tracked
// mono label (── 印影 · SEAL REGISTER).
Row {
  id: root
  property string jp: ""
  property string label: ""
  spacing: Type.px(8)
  Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(18); height: 1; color: Ink.ink }
  Text { anchors.verticalCenter: parent.verticalCenter; text: root.jp; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.label }
  Text { anchors.verticalCenter: parent.verticalCenter; text: "·"; color: Ink.inkFaint; font.family: Type.text; font.pixelSize: Type.label }
  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.eyebrow
    font.letterSpacing: Type.trackEyebrow
    font.capitalization: Font.AllUppercase
  }
}
