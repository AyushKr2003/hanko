pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One hairline row in a sheet: an optional `//` lead, a name with a small
// description under it, and a mono note on the right (`LIVE`, `PAIRED`).
// The selected row inverts into a bone plate. Put anything else (a ruler,
// a large time) in `trailing`.
Item {
  id: root

  property string name: ""
  property string detail: ""
  property string note: ""
  property bool selected: false
  // Show the `//` lead column (selected rows fill it).
  property bool lead: false
  property bool interactive: false
  property bool last: false
  // Width of the name column when the row carries a ruler; 0 = natural.
  property int nameWidth: 0
  property int minHeight: Type.px(46)
  default property alias trailing: extra.data

  signal clicked()

  width: parent ? parent.width : 0
  implicitHeight: Math.max(minHeight, texts.implicitHeight + Type.px(14))

  Rectangle {
    anchors.fill: parent
    radius: 2
    color: root.selected ? Ink.bone : hover.containsMouse && root.interactive ? Ink.lineSoft : "transparent"
  }

  Rectangle {
    visible: !root.selected && !root.last
    anchors.bottom: parent.bottom
    width: parent.width
    height: 1
    color: Ink.lineSoft
  }

  Row {
    id: line
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Type.px(10)
    anchors.rightMargin: Type.px(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(12)

    Text {
      visible: root.lead
      width: Type.px(18)
      anchors.verticalCenter: parent.verticalCenter
      text: root.selected ? "//" : ""
      color: root.selected ? Ink.boneInk : Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(12)
    }

    Column {
      id: texts
      width: root.nameWidth > 0 ? root.nameWidth : implicitWidth
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(2)
      Text {
        width: root.nameWidth > 0 ? parent.width : implicitWidth
        elide: Text.ElideRight
        text: root.name
        color: root.selected ? Ink.boneInk : Ink.ink
        font.family: Type.text
        font.pixelSize: Type.px(14.5)
      }
      Text {
        visible: text !== ""
        width: root.nameWidth > 0 ? parent.width : implicitWidth
        elide: Text.ElideRight
        text: root.detail
        color: root.selected ? Ink.boneInk : Ink.inkMuted
        font.family: Type.text
        font.pixelSize: Type.px(12)
      }
    }
  }

  // Right-hand side: the trailing items, then the note.
  Row {
    anchors.right: parent.right
    anchors.rightMargin: Type.px(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(10)
    layoutDirection: Qt.RightToLeft

    Text {
      visible: text !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.note.toUpperCase()
      color: root.selected ? Ink.boneInk : Ink.inkDim
      font.family: Type.mono
      font.pixelSize: Type.px(11)
      font.letterSpacing: 0.6
    }
    Item {
      id: extra
      anchors.verticalCenter: parent.verticalCenter
      width: childrenRect.width
      height: childrenRect.height
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
