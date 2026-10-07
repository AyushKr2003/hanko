import QtQuick
import "../../core"

// A mono, tracked button with a hairline frame. `plate` inverts it into a
// bone plate (the main action); `ghost` recedes it. `on` inverts it too,
// for a button that shows a state (MUTE while muted).
Rectangle {
  id: root

  property string text: ""
  property bool plate: false
  property bool ghost: false
  property bool on: false

  signal clicked()

  readonly property bool inverted: plate || on

  implicitWidth: label.implicitWidth + Type.px(24)
  implicitHeight: label.implicitHeight + Type.px(14)
  radius: 3
  color: inverted ? Ink.bone : hover.containsMouse ? Ink.lineSoft : "transparent"
  border.width: 1
  border.color: inverted ? Ink.bone : ghost ? Ink.line : Ink.lineStrong

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text.toUpperCase()
    color: root.inverted ? Ink.boneInk : root.ghost ? Ink.inkFaint : Ink.ink
    font.family: Type.mono
    font.pixelSize: Type.label
    font.weight: Type.labelWeight
    font.letterSpacing: Type.trackLabel
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
