import QtQuick
import "../../core"

// The small × that puts one letter away for good. Faint until the pointer
// (or the keyboard) is on it, then ink. `tint` for paper it sits on.
Text {
  id: root

  property color tint: Ink.inkFaint
  signal clicked()

  // Te 手 (core/Cursor.js): Enter or Space puts the letter away.
  readonly property bool keyStop: true
  function keyPress() { root.clicked() }

  text: "×"
  color: hover.containsMouse ? Ink.ink : root.tint
  font.family: Type.text
  font.pixelSize: Type.px(15)
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
  width: Type.px(20)
  height: Type.px(20)

  MouseArea {
    id: hover
    anchors.fill: parent
    anchors.margins: -Type.px(4)
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
