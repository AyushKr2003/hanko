pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// One notification (Kata part `notify`), in the Letters panel: Shōji's
// row between lattice lines, its 未 seal on the right (the unread part).
// A click asks to unfold it (`toggled`; the whole summary and body) when it
// runs past its row; the × under the seal asks `putAway`.
Item {
  id: root

  property var skin: ({})
  property var letter: ({})
  property date now: new Date()
  property bool first: false
  property bool expanded: false
  // The summary or the body runs past its lines, so unfolding shows more.
  readonly property bool more: summary.truncated || bodyText.truncated
  signal toggled()
  signal putAway()

  // Te 手 (core/Cursor.js): Enter unfolds it; the × is a stop of its own.
  readonly property bool keyStop: true
  function keyPress() { if (root.more || root.expanded) root.toggled() }

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
        id: summary
        width: parent.width
        elide: root.expanded ? Text.ElideNone : Text.ElideRight
        wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
        text: root.letter.summary || root.letter.app || ""
        color: root.letter.urgent ? Ink.seal : Ink.ink
        font.family: Type.text; font.pixelSize: Type.px(13.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes
      }
      Text {
        id: bodyText
        visible: !!root.letter.body
        width: parent.width; wrapMode: Text.Wrap; maximumLineCount: root.expanded ? 1000 : 2; elide: Text.ElideRight
        text: root.letter.body || ""
        color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
      }
    }
    UnreadMark { anchors.fill: parent; skin: root.skin }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.more || root.expanded
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
  // Put away, under the 未 seal.
  Text {
    x: root.width - width
    y: Type.px(24)
    width: Type.px(22); height: Type.px(20)
    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    readonly property bool keyStop: true
    function keyPress() { root.putAway() }
    text: "×"
    color: away.containsMouse ? Ink.ink : Ink.ink3
    font.family: Type.text; font.pixelSize: Type.px(15)
    MouseArea { id: away; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.putAway() }
  }
}
