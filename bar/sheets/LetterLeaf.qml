import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// One letter unfolded in full, under a hand that only has room for its
// first words (Tanzaku's slips, the craft hands): who sent it and when,
// what it says, all of the body. Close folds it back; Put away deletes it.
Column {
  id: root

  // A core/Status.js notifications() letter, or null for nothing open.
  property var letter: null
  property date now: new Date()
  signal closed()
  signal putAway()

  visible: !!letter
  width: parent ? parent.width : 0
  topPadding: Type.px(12)
  spacing: Type.px(4)

  Rectangle { width: parent.width; height: 1; color: Ink.line }
  Item {
    width: parent.width
    height: Type.px(26)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - away.width - Type.px(12)
      elide: Text.ElideRight
      text: root.letter ? ((root.letter.app || "Letter") + "  ·  " + StatusJs.age(root.letter.timestamp, root.now.getTime())).toUpperCase() : ""
      color: root.letter && root.letter.urgent ? Ink.seal : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
    Row {
      id: away
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(8)
      SheetButton { ghost: true; text: "Close"; onClicked: root.closed() }
      SheetButton { text: "Put away"; onClicked: root.putAway() }
    }
  }
  Text {
    width: parent.width
    wrapMode: Text.Wrap
    text: root.letter ? (root.letter.summary || root.letter.app || "") : ""
    color: Ink.ink
    font.family: Type.text
    font.pixelSize: Type.row
  }
  Text {
    visible: text !== ""
    width: parent.width
    wrapMode: Text.Wrap
    text: root.letter ? root.letter.body || "" : ""
    color: Ink.inkDim
    font.family: Type.text
    font.pixelSize: Type.note
    lineHeight: 1.25
  }
}
