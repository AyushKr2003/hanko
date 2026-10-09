import QtQuick
import "../../core"

// A Prose sheet's index line, as a book's footnotes: a mono number, the
// name, a dotted leader and a note. The one in use has its number inverted
// on a bone plate; any other is a click away.
Item {
  id: root

  property int number: 1
  property string name: ""
  property string note: ""
  property bool selected: false
  property bool interactive: true
  // Needs you (an urgent letter): the number in red, never a plate.
  property bool urgent: false

  signal clicked()

  width: parent ? parent.width : 0
  implicitHeight: Type.px(26)

  Rectangle {
    id: num
    anchors.verticalCenter: parent.verticalCenter
    width: Type.px(22)
    height: Type.px(16)
    radius: 2
    color: root.selected ? Ink.bone : "transparent"
    Text {
      anchors.centerIn: parent
      text: (root.number < 10 ? "0" : "") + root.number
      color: root.selected ? Ink.boneInk : root.urgent ? Ink.seal : Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.tag
    }
  }
  Text {
    id: nameText
    x: num.width + Type.px(10)
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, root.width - x - noteText.implicitWidth - Type.px(40))
    elide: Text.ElideRight
    text: root.name
    color: hover.containsMouse && root.interactive ? Ink.ink : root.selected ? Ink.ink : Ink.inkDim
    font.family: Type.text
    font.pixelSize: Type.note
    font.underline: hover.containsMouse && root.interactive
  }
  // The leader, dotted, from the name to the note.
  Row {
    x: nameText.x + nameText.width + Type.px(8)
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: Type.px(3)
    spacing: Type.px(4)
    Repeater {
      model: Math.max(0, Math.floor((noteText.x - nameText.x - nameText.width - Type.px(16)) / Type.px(5)))
      Rectangle { width: 1; height: 1; color: Ink.inkFaint }
    }
  }
  Text {
    id: noteText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: root.note.toUpperCase()
    color: Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }
  MouseArea {
    id: hover
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
