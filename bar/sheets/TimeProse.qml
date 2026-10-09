pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Time.js" as T

// Time 時, Prose (文): "Tuesday, the 6th of October, week 41: day 279 of
// 365, 2h 16m left in it. In Tokyo it is already Wednesday, 06:44. See last
// week or next." Those two move the fortnight, the weekday brings it back
// to today; the fortnight is a ribbon of figures and the cities an index.
Item {
  id: root

  property date now: new Date()
  property int shift: 0
  property var zones: []
  signal request(string what, var arg)

  readonly property var head: T.heading(now)
  readonly property var days: T.ribbon(now, shift)

  function ordinal(n) {
    var s = ["th", "st", "nd", "rd"], v = n % 100
    return n + (s[(v - 20) % 10] || s[v] || s[0])
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(22)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "time"; jp: "時"; label: "Time · Week " + root.head.week; compact: true }
    Item { width: 1; height: Type.px(16) }

    ProseText {
      id: line
      text: {
        var s = line.word("today", root.head.title) + ", the " + root.ordinal(root.now.getDate()) + " of " + Qt.formatDate(root.now, "MMMM")
        s += ", week " + root.head.week + ": " + line.em(root.head.blurb.replace(" · ", ", ")) + ". "
        var far = root.zones.filter(function(z) { return z.ready })
        if (far.length) {
          var z = far[0]
          s += "In " + line.em(z.label) + " it is " + z.time + (z.date ? ", " + z.date.split(" · ")[0] : "") + "."
        }
        if (root.shift !== 0) s += " Showing " + (root.shift > 0 ? "+" : "") + root.shift + (Math.abs(root.shift) === 1 ? " week" : " weeks") + "; " + line.word("today", "back to today") + "."
        else s += " See " + line.word("back", "last week") + " or " + line.word("on", "next") + "."
        return s
      }
      onPicked: function(a) {
        if (a === "today") root.request("shift", 0)
        else if (a === "back") root.request("shift", root.shift - 1)
        else if (a === "on") root.request("shift", root.shift + 1)
      }
    }

    // The fortnight as a line of figures, today inverted.
    Item { width: 1; height: Type.px(14) }
    Row {
      id: ribbon
      width: parent.width
      Repeater {
        model: root.days.days
        Item {
          id: d
          required property var modelData
          width: ribbon.width / 14
          height: Type.px(30)
          Rectangle {
            anchors.centerIn: parent
            width: Type.px(24)
            height: Type.px(24)
            radius: 12
            color: d.modelData.today ? Ink.bone : "transparent"
          }
          Text {
            anchors.centerIn: parent
            text: Number(d.modelData.day)
            color: d.modelData.today ? Ink.boneInk : d.modelData.weekend || d.modelData.past ? Ink.inkFaint : Ink.inkDim
            font.family: Type.display
            font.pixelSize: Type.px(15)
            font.features: { "lnum": 1 }
          }
        }
      }
    }

    ProseIndex {
      visible: root.zones.length > 0
      label: "Elsewhen"
      summary: root.zones.length + (root.zones.length === 1 ? " zone" : " zones")
      Repeater {
        model: root.zones
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: modelData.label + "  ·  " + modelData.date
          note: modelData.time + "  " + modelData.rel
          interactive: false
        }
      }
    }
  }

  Keys.onLeftPressed: root.request("shift", root.shift - 1)
  Keys.onRightPressed: root.request("shift", root.shift + 1)
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_T || event.key === Qt.Key_Home) { root.request("shift", 0); event.accepted = true }
  }
}
