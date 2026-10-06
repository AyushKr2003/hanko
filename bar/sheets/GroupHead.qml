pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A group's head inside a sheet: `// OUTPUT`, a quiet summary on the right
// (`3 DEVICES`), and a hairline under both. The summary can be made of
// clickable parts (`‹ TODAY ›`): pass `actions` and listen to `picked`.
Item {
  id: root

  property string title: ""
  property string summary: ""
  // [{ text, name }]: drawn in place of `summary`, each one clickable.
  property var actions: []

  signal picked(string name)

  width: parent ? parent.width : 0
  // The 20 px above a group belongs to the head, so groups stack in a Column.
  implicitHeight: Type.px(20) + head.height + Type.px(8) + 1

  Row {
    id: head
    y: Type.px(20)
    spacing: Type.px(10)

    Text {
      text: "//"
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(10)
      font.letterSpacing: Type.px(2)
    }
    Text {
      text: root.title.toUpperCase()
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.px(10)
      font.letterSpacing: Type.px(2)
    }
  }

  Text {
    visible: root.actions.length === 0
    anchors.right: parent.right
    anchors.verticalCenter: head.verticalCenter
    text: root.summary.toUpperCase()
    color: Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Type.px(9)
    font.letterSpacing: Type.px(1.6)
  }

  Row {
    visible: root.actions.length > 0
    anchors.right: parent.right
    anchors.verticalCenter: head.verticalCenter
    spacing: Type.px(8)

    Repeater {
      model: root.actions
      Text {
        id: act
        required property var modelData
        text: String(act.modelData.text).toUpperCase()
        color: hover.containsMouse ? Ink.ink : Ink.inkFaint
        font.family: Type.mono
        font.pixelSize: Type.px(9)
        font.letterSpacing: Type.px(1.6)
        MouseArea {
          id: hover
          anchors.fill: parent
          anchors.margins: -Type.px(4)
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.picked(act.modelData.name)
        }
      }
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom
    width: parent.width
    height: 1
    color: Ink.line
  }
}
