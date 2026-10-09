pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// Inbox 報, Prose (文): "Three letters, the newest from Signal 2m ago: "See
// you at 8 by the station." Do not disturb is off." The count replays them
// as toasts, the state toggles quiet, "clear them" clears; the letters are
// an index below.
Item {
  id: root

  property var letters: []
  property bool dnd: false
  property date now: new Date()
  property int maxRows: 6
  signal request(string what, var arg)

  readonly property var shown: letters.slice(0, maxRows)
  readonly property var words: ["No", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(22)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "inbox"; jp: "報"; label: "Inbox · " + StatusJs.count2(root.letters.length); compact: true }
    Item { width: 1; height: Type.px(16) }

    ProseText {
      id: line
      text: {
        var n = root.letters.length
        if (!n) return "Nothing new. Do not disturb is " + line.word("dnd", root.dnd ? "on" : "off") + "."
        var first = root.letters[0]
        var what = String(first.body || first.summary || "").replace(/\s+/g, " ")
        if (what.length > 60) what = what.slice(0, 58) + "…"
        var s = line.word("replay", (root.words[n] || n) + (n === 1 ? " letter" : " letters"))
        s += ", the newest from " + line.em(first.app || "someone") + " " + StatusJs.age(first.timestamp, root.now.getTime()) + " ago"
        s += what ? ": “" + what + "”. " : ". "
        s += "Do not disturb is " + line.word("dnd", root.dnd ? "on" : "off") + "; " + line.word("clear", "clear them") + "."
        return s
      }
      onPicked: function(a) {
        if (a === "replay") root.request("replay", null)
        else if (a === "dnd") root.request("dnd", null)
        else if (a === "clear") root.request("clear", null)
      }
    }

    ProseIndex {
      visible: root.shown.length > 0
      label: "Letters"
      summary: root.letters.length > root.maxRows ? root.maxRows + " of " + root.letters.length : "newest first"
      Repeater {
        model: root.shown
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: (modelData.summary || modelData.app) + (modelData.app && modelData.summary ? " · " + modelData.app : "")
          note: StatusJs.age(modelData.timestamp, root.now.getTime())
          urgent: modelData.urgent
          interactive: false
        }
      }
    }
  }
}
