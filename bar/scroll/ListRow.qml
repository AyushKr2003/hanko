import QtQuick
import "../../core"

// A list row in the scroll (fresh, not the sheets' rows): a mono index, a
// name (with an optional line under it), a mono note on the right, and a
// bone plate when it is the one in use. `leading` takes a stamp; `trailing`
// signal bars.
Item {
  id: root

  property int position: 0
  property string name: ""
  property string detail: ""
  property string note: ""
  // Ages and values with units keep their own case.
  property bool upperNote: true
  property bool on: false
  property bool interactive: false
  // Draw the hairline above this row (not next to a plate).
  property bool ruled: false
  property int rowHeight: Type.px(detail ? 52 : 40)
  property Component leading: null
  property Component trailing: null

  signal clicked()

  width: parent ? parent.width : 0
  height: rowHeight

  Rectangle {
    anchors.fill: parent
    radius: 3
    color: root.on ? Ink.bone : hover.containsMouse && root.interactive ? Ink.lineSoft : "transparent"
  }
  Rectangle {
    visible: root.ruled && !root.on
    width: parent.width
    height: 1
    color: Ink.lineSoft
  }

  Row {
    anchors.left: parent.left
    anchors.leftMargin: Type.px(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(12)

    Text {
      visible: !root.leading
      width: Type.px(16)
      anchors.verticalCenter: parent.verticalCenter
      text: (root.position < 9 ? "0" : "") + (root.position + 1)
      color: root.on ? Ink.boneInk : Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(9.5)
      font.letterSpacing: 1
    }
    Loader {
      active: !!root.leading
      visible: active
      anchors.verticalCenter: parent.verticalCenter
      sourceComponent: root.leading
    }
    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(2)
      Text {
        text: root.name
        color: root.on ? Ink.boneInk : Ink.ink
        font.family: Type.text
        font.pixelSize: Type.px(14)
      }
      Text {
        visible: root.detail !== ""
        text: root.detail
        color: root.on ? Ink.boneInk : Ink.inkMuted
        font.family: Type.text
        font.pixelSize: Type.px(12)
      }
    }
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: Type.px(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(8)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: text !== ""
      text: root.upperNote ? root.note.toUpperCase() : root.note
      color: root.on ? Ink.boneInk : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.px(9.5)
      font.letterSpacing: Type.px(1.6)
    }
    Loader {
      active: !!root.trailing
      visible: active
      anchors.verticalCenter: parent.verticalCenter
      sourceComponent: root.trailing
    }
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
