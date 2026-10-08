pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// One notification (Kata part `notify`), in the Letters panel:
//   cards    Margin: a soft card; swipe it aside to put it away
//   tickets  Leaf: a ticket with a perforated stub; pull it down and it
//            tears off at the perforation
//   rows     Shōji: a row between lattice lines, its 未 seal on the right
// Every variant takes the same data and says the same things: `dismissed`
// when it is put away, `opened` on a click. The unread mark is the unread part.
Item {
  id: root

  property var skin: ({})
  property var letter: ({})
  property date now: new Date()
  property bool first: false
  signal dismissed()
  signal opened()

  readonly property string kind: skin.notify || "cards"
  // How far the letter has been pulled: x for cards, y for tickets.
  property real pull: 0
  readonly property real threshold: kind === "tickets" ? Type.px(26) : width * 0.35
  readonly property int stub: kind === "tickets" ? Type.px(44) : 0

  implicitHeight: body.implicitHeight + Type.px(22)
  width: parent ? parent.width : implicitWidth
  height: implicitHeight
  // a swiped card goes out of the panel's edge, not over it
  clip: kind === "cards" && pull !== 0
  opacity: 1 - Math.min(0.85, Math.abs(pull) / (threshold * 2.2))

  Behavior on pull { enabled: !area.pressed && !Motion.still; NumberAnimation { duration: Motion.ms(root.skin.settle || 200); easing.type: Easing.OutCubic } }

  Item {
    id: paper
    width: root.width; height: root.height
    x: root.kind === "cards" ? root.pull : 0

    // cards: a card on paper (soft) or a bordered card
    Rectangle {
      visible: root.kind === "cards"
      anchors.fill: parent
      radius: root.skin.radiusRow || 0
      color: root.skin.surface === "card" ? Ink.paper : "transparent"
      border.width: root.skin.surface === "card" ? 0 : 1
      border.color: Ink.kLine
    }
    // tickets: the body, then the stub beyond a perforation that tears
    Item {
      visible: root.kind === "tickets"
      anchors.fill: parent
      Rectangle { width: parent.width - root.stub; height: parent.height; color: Ink.paper }
      Rectangle { y: parent.height; width: parent.width - root.stub; height: 2; color: Ink.shade }
      Rectangle {
        x: parent.width - root.stub; y: root.pull
        width: root.stub; height: parent.height
        color: Ink.paper2
        rotation: root.pull * 0.12
        transformOrigin: Item.TopLeft
        Text {
          anchors.centerIn: parent
          rotation: -90
          text: StatusJs.age(root.letter.timestamp, root.now)
          color: Ink.ink3; font.family: Type.mono; font.pixelSize: Type.px(11)
        }
      }
      // the perforation: a column of small holes, with notches at both ends
      Column {
        x: parent.width - root.stub - 1; y: Type.px(4)
        spacing: Type.px(4)
        Repeater {
          model: Math.max(0, Math.floor((root.height - Type.px(8)) / Type.px(7)))
          Rectangle { width: 2; height: Type.px(3); color: Ink.sunk }
        }
      }
      Rectangle { x: parent.width - root.stub - Type.px(5); y: -Type.px(5); width: Type.px(10); height: width; radius: width / 2; color: Ink.sunk }
      Rectangle { x: parent.width - root.stub - Type.px(5); y: parent.height - Type.px(5); width: Type.px(10); height: width; radius: width / 2; color: Ink.sunk }
    }
    // rows: lattice lines between letters
    Divider { visible: root.kind === "rows" && !root.first; skin: root.skin; width: parent.width; bleed: Type.px(20) }

    Column {
      id: body
      x: root.kind === "rows" ? 0 : Type.px(14)
      y: Type.px(11)
      width: parent.width - 2 * x - Type.px(24) - root.stub
      spacing: Type.px(3)
      Text {
        visible: root.kind !== "tickets"
        text: root.letter.app + " · " + StatusJs.age(root.letter.timestamp, root.now)
        color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12)
      }
      Text {
        visible: root.kind === "tickets"
        text: String(root.letter.app || "").toUpperCase()
        color: Ink.ink3; font.family: Type.mono; font.pixelSize: Type.px(11); font.letterSpacing: 1.2
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
    UnreadMark { x: 0; y: 0; width: parent.width - root.stub; height: parent.height; skin: root.skin }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    property real downX: 0
    property real downY: 0
    property bool moved: false
    onPressed: function(m) { downX = m.x; downY = m.y; moved = false }
    onPositionChanged: function(m) {
      var d = root.kind === "tickets" ? Math.max(0, m.y - downY) : root.kind === "cards" ? m.x - downX : 0
      if (Math.abs(d) > Type.px(4)) moved = true
      root.pull = d
    }
    onReleased: {
      if (Math.abs(root.pull) >= root.threshold) root.dismissed()
      root.pull = 0
    }
    onClicked: if (!moved) root.opened()
  }
}
