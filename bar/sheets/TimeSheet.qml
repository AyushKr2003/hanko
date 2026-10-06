pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Time.js" as T

// Time 時: where today sits in the year, a two-week ribbon of days (today
// a bone plate, Mondays ruled off), and Elsewhen's other cities with their
// time and distance from yours. Arrows or ‹ › move the ribbon by a week.
Item {
  id: root

  property date now: new Date()
  // Weeks the ribbon is moved from today.
  property int shift: 0
  // core/Time.js zoneRow() shapes.
  property var zones: []

  // what: "shift" (arg: weeks to add, 0 = back to today)
  signal request(string what, var arg)

  readonly property var head: T.heading(now)
  readonly property var days: T.ribbon(now, shift)

  width: parent ? parent.width : 0
  implicitHeight: column.implicitHeight + Type.px(22) + Type.px(18)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead {
      jp: "時"
      label: "Time · Week " + root.head.week
      title: root.head.title
      blurb: root.head.blurb
    }

    GroupHead {
      title: root.days.month
      actions: [{ text: "‹", name: "back" }, { text: "Today", name: "today" }, { text: "›", name: "on" }]
      onPicked: function(name) {
        root.request("shift", name === "back" ? root.shift - 1 : name === "on" ? root.shift + 1 : 0)
      }
    }

    // The ribbon sits 20 px under its head, between two hairlines.
    Item { width: 1; height: Type.px(20) - 1 }
    Rectangle { width: parent.width; height: 1; color: Ink.line }

    Row {
      id: ribbon
      width: parent.width
      Repeater {
        model: root.days.days
        Rectangle {
          id: day
          required property var modelData
          width: ribbon.width / 14
          height: Type.px(46)
          color: modelData.today ? Ink.bone : "transparent"
          readonly property color ink: modelData.today ? Ink.boneInk
            : modelData.weekend || modelData.past ? Ink.inkFaint : Ink.inkDim

          Rectangle {
            visible: day.modelData.weekStart
            y: Type.px(4)
            width: 1
            height: parent.height - Type.px(8)
            color: Ink.line
          }
          Column {
            anchors.centerIn: parent
            spacing: Type.px(4)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: day.modelData.letter
              color: day.modelData.today ? Ink.boneInk : Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.px(7.5)
              font.letterSpacing: 1
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: day.modelData.day
              color: day.ink
              font.family: Type.mono
              font.pixelSize: Type.px(10.5)
            }
          }
        }
      }
    }

    Rectangle { width: parent.width; height: 1; color: Ink.line }

    GroupHead {
      title: "Elsewhen"
      summary: root.zones.length + (root.zones.length === 1 ? " zone" : " zones")
    }

    Repeater {
      model: root.zones
      SheetRow {
        id: zone
        required property var modelData
        required property int index
        name: modelData.label
        detail: modelData.date
        last: index === root.zones.length - 1

        Row {
          spacing: Type.px(10)
          Text {
            id: zoneTime
            text: zone.modelData.time
            color: zone.modelData.ready ? Ink.ink : Ink.inkFaint
            font.family: Type.display
            font.pixelSize: Type.px(20)
            font.weight: Font.Normal
            font.variableAxes: { "opsz": 24, "wght": 400 }
          }
          Text {
            anchors.baseline: zoneTime.baseline
            width: Type.px(26)
            text: zone.modelData.rel
            color: Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.px(11)
          }
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
