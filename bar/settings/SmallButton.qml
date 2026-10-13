import QtQuick
import "../../core"

// A small framed button in tracked mono: the action bar's and the pages'.
// `plate` inverts it (the one thing to do); `faint` when it would do nothing.
Rectangle {
  id: button
  property string label: ""
  property bool plate: false
  property bool faint: false
  signal clicked()
  width: buttonText.implicitWidth + 2 * Type.px(14)
  height: Type.px(32)
  radius: 3
  color: plate && !faint ? Ink.bone : buttonHover.containsMouse ? Ink.lineSoft : "transparent"
  border.width: 1
  border.color: plate && !faint ? Ink.bone : faint ? Ink.line : Ink.lineStrong
  Text {
    id: buttonText
    anchors.centerIn: parent
    text: button.label.toUpperCase()
    color: button.plate && !button.faint ? Ink.boneInk : button.faint ? Ink.inkFaint : Ink.ink
    font.family: Type.mono
    font.pixelSize: Type.px(10)
    font.letterSpacing: Type.px(1.8)
  }
  MouseArea {
    id: buttonHover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: button.clicked()
  }
}
