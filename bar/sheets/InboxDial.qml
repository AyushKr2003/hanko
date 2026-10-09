pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// Inbox 報, Dial (盤): how many letters are waiting as the gauge (a full
// ring at ten), the newest sender beside it with Quiet and Clear all, then
// the letters as cards: the app's seal in the corner (solid red when
// urgent), what it says, who and how long ago.
Item {
  id: root

  property var letters: []
  property bool dnd: false
  property date now: new Date()
  property int maxRows: 6
  signal request(string what, var arg)

  readonly property var shown: letters.slice(0, maxRows)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead { sheet: "inbox"; jp: "報"; label: "Inbox · " + StatusJs.count2(root.letters.length); compact: true }
    Item { width: 1; height: Type.px(16) }

    DialHero {
      interactive: false
      value: Math.min(1, root.letters.length / 10)
      muted: root.dnd
      figure: StatusJs.count2(root.letters.length)
      caption: root.dnd ? "quiet" : root.letters.length === 1 ? "letter" : "letters"
      title: root.letters.length ? (root.letters[0].app || "A letter") : "Nothing new"
      lines: root.letters.length ? [StatusJs.age(root.letters[0].timestamp, root.now.getTime()) + " ago", root.dnd ? "Do not disturb is on" : "Newest first"]
                                 : [root.dnd ? "Do not disturb is on" : "Enjoy it."]
      SheetButton { text: "Quiet"; on: root.dnd; onClicked: root.request("dnd", null) }
      SheetButton { plate: true; text: "Clear all"; onClicked: root.request("clear", null) }
    }

    TileSection {
      id: cards
      visible: root.shown.length > 0
      label: "Letters"
      summary: root.letters.length > root.maxRows ? root.maxRows + " of " + root.letters.length : root.letters.length + " in all"
      Repeater {
        model: root.shown
        Tile {
          required property var modelData
          width: cards.tileWidth
          implicitHeight: Type.px(70)
          interactive: false
          mark: modelData.glyph
          urgent: modelData.urgent
          name: modelData.summary || modelData.app
          detail: (modelData.app || "") + (modelData.body ? " · " + modelData.body.replace(/\s+/g, " ") : "")
          note: StatusJs.age(modelData.timestamp, root.now.getTime())
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    SheetButton { ghost: true; text: "Replay"; onClicked: root.request("replay", null) }
  }
}
