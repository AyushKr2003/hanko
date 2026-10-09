pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// One notification (Kata part `notify`), in the Letters panel: Shōji's
// row between lattice lines, its 未 seal on the right (the unread part).
// `opened` on a click.
Item {
  id: root

  property var skin: ({})
  property var letter: ({})
  property date now: new Date()
  property bool first: false
  signal opened()

  implicitHeight: body.implicitHeight + Type.px(22)
  width: parent ? parent.width : implicitWidth
  height: implicitHeight

  Item {
    id: paper
    width: root.width; height: root.height

    // lattice lines between letters
    Divider { visible: !root.first; skin: root.skin; width: parent.width; bleed: Type.px(20) }

    Column {
      id: body
      y: Type.px(11)
      width: parent.width - Type.px(24)
      spacing: Type.px(3)
      Text {
        text: root.letter.app + " · " + StatusJs.age(root.letter.timestamp, root.now)
        color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12)
      }
      Text {
        width: parent.width; elide: Text.ElideRight
        text: root.letter.summary || root.letter.app || ""
        color: root.letter.urgent ? Ink.seal : Ink.ink
        font.family: Type.text; font.pixelSize: Type.px(13.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes
      }
      Text {
        visible: !!root.letter.body
        width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
        text: root.letter.body || ""
        color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
      }
    }
    UnreadMark { anchors.fill: parent; skin: root.skin }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.opened()
  }
}
