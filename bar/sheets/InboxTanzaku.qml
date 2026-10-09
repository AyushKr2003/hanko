pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// Inbox 報, Tanzaku (短冊): how many letters are waiting on the first slip,
// then each letter hung as a slip, newest at the right: the app's mark at
// its head, what it says down it, how long ago at its foot, and a red seal
// under an urgent one. Under do not disturb the slips hang dashed.
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
    bottomPadding: Type.px(18)

    SheetHead { sheet: "inbox"; jp: "報"; label: "Inbox · " + StatusJs.count2(root.letters.length); compact: true }
    Item { width: 1; height: Type.px(18) }

    TanzakuRail {
      LeadStrip {
        mark: "報"
        figure: StatusJs.count2(root.letters.length)
        caption: root.dnd ? "quiet" : root.letters.length === 1 ? "letter" : "letters"
      }
      Repeater {
        model: root.shown
        Tanzaku {
          required property var modelData
          mark: modelData.glyph
          name: (modelData.summary || modelData.app) + (modelData.body ? " · " + modelData.body.replace(/\s+/g, " ") : "")
          foot: StatusJs.age(modelData.timestamp, root.now.getTime())
          urgent: modelData.urgent
          dashed: root.dnd
          interactive: false
        }
      }
    }
    TanzakuFoot { text: root.letters.length ? "Newest at the right" : "Nothing new" }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    SheetButton { text: "Quiet"; on: root.dnd; onClicked: root.request("dnd", null) }
    SheetButton { ghost: true; text: "Replay"; onClicked: root.request("replay", null) }
    SheetButton { plate: true; text: "Clear all"; onClicked: root.request("clear", null) }
  }
}
