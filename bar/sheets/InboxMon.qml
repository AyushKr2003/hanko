pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// Inbox 報, Mon (紋): the count beside the sheet's own mon (報 in the ring),
// then each letter as a crest bearing its app's mark in the ring (丸に文字),
// what it says and how long ago under it; an urgent one drawn in red, and
// under do not disturb every crest faint.
Item {
  id: root

  property var letters: []
  property bool dnd: false
  property date now: new Date()
  property int maxRows: 8
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
    Item { width: 1; height: Type.px(18) }

    MonHero {
      kind: "moji"
      glyph: root.dnd ? "休" : "報"
      figure: StatusJs.count2(root.letters.length)
      title: root.letters.length ? "the newest from " + (root.letters[0].app || "someone") : "nothing new"
      lines: [root.dnd ? "Do not disturb is on" : root.letters.length ? StatusJs.age(root.letters[0].timestamp, root.now.getTime()) + " ago" : "Enjoy it."]
      SheetButton { text: "Quiet"; on: root.dnd; onClicked: root.request("dnd", null) }
    }

    MonPage {
      id: page
      visible: root.shown.length > 0
      jp: "文"
      label: "Letters"
      summary: root.letters.length > root.maxRows ? root.maxRows + " of " + root.letters.length : "newest first"
      Repeater {
        model: root.shown
        CrestCell {
          required property var modelData
          width: page.cellWidth
          kind: "moji"
          glyph: modelData.glyph
          urgent: modelData.urgent
          faint: root.dnd
          interactive: false
          name: modelData.summary || modelData.app
          note: StatusJs.age(modelData.timestamp, root.now.getTime())
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    SheetButton { ghost: true; text: "Replay"; onClicked: root.request("replay", null) }
    SheetButton { plate: true; text: "Clear all"; onClicked: root.request("clear", null) }
  }
}
