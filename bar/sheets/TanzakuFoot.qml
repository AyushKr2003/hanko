import QtQuick
import "../../core"

// The quiet line under a Tanzaku rail: what a click or a pull does.
Text {
  width: parent ? parent.width : 0
  topPadding: Type.px(10)
  horizontalAlignment: Text.AlignRight
  elide: Text.ElideRight
  color: Ink.inkFaint
  font.family: Type.mono
  font.pixelSize: Type.tag
  font.letterSpacing: Type.trackTag
  font.capitalization: Font.AllUppercase
}
