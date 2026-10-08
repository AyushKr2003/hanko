pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A group's head inside a sheet: `// OUTPUT`, a quiet summary on the right
// (`3 DEVICES`), and a hairline under both. The summary can be made of
// clickable parts (`‹ TODAY ›`): pass `actions` and listen to `picked`.
// The hairline thickens to a short ink rule under the head's own words, the
// way a printed section head is underscored, so each group starts with a
// mark you can find at a glance.
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
      font.pixelSize: Type.eyebrow
      font.letterSpacing: Type.trackEyebrow
    }
    Text {
      text: root.title.toUpperCase()
      color: Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.eyebrow
      font.weight: Type.labelWeight
      font.letterSpacing: Type.trackEyebrow
    }
  }

  Text {
    visible: root.actions.length === 0
    anchors.right: parent.right
    anchors.verticalCenter: head.verticalCenter
    text: root.summary.toUpperCase()
    color: Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.label
    font.letterSpacing: Type.trackLabel
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
        color: hover.containsMouse ? Ink.ink : Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.letterSpacing: Type.trackLabel
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
  Rectangle {
    anchors.bottom: parent.bottom
    width: head.width
    height: 2
    color: Ink.inkMuted
  }
}
