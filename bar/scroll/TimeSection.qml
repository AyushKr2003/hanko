pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Time.js" as T

// 01 // TIME: "Tuesday, the sixth", the week and day of the year and the
// first Elsewhen city, then a ribbon of eighteen days you drag (or scroll)
// a week at a time.
ScrollSection {
  id: root

  property date now: new Date()
  property int shift: 0
  // core/Time.js zoneRow() shapes.
  property var zones: []

  signal request(string what, var arg)

  readonly property var head: T.heading(now)
  readonly property var days: T.ribbon(now, shift, 18)
  readonly property var first: zones.length && zones[0].ready ? zones[0] : null

  title: head.title + ", <i><font color='" + Ink.inkMuted + "'>" + T.ordinal(now.getDate()) + "</font></i>"
  caption: "Week " + head.week + " · day " + T.dayOfYear(now) + " of " + T.daysInYear(now.getFullYear())
    + (first ? " · " + first.label + " " + first.time + (first.day ? " " + first.day : "") : "")

  Column {
    width: parent.width
    topPadding: Type.px(20)
    spacing: Type.px(12)

    Item {
      width: parent.width
      height: ribbon.height + 2

      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Row {
        id: ribbon
        y: 1
        width: parent.width
        Repeater {
          model: root.days.days
          Rectangle {
            id: day
            required property var modelData
            width: ribbon.width / root.days.days.length
            height: Type.px(46)
            color: modelData.today ? Ink.bone : "transparent"
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
                color: day.modelData.today ? Ink.boneInk
                  : day.modelData.weekend || day.modelData.past ? Ink.inkFaint : Ink.inkDim
                font.family: Type.mono
                font.pixelSize: Type.px(10.5)
              }
            }
          }
        }
      }
      Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.line }

      // Drag the ribbon a week at a time; a click puts it back on today.
      MouseArea {
        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true
        property real startX: 0
        property int startShift: 0
        property bool moved: false
        onPressed: function(mouse) { startX = mouse.x; startShift = root.shift; moved = false }
        onPositionChanged: function(mouse) {
          var weeks = Math.round((startX - mouse.x) / (ribbon.width / root.days.days.length * 7))
          if (weeks !== 0) moved = true
          if (startShift + weeks !== root.shift) root.request("shift", startShift + weeks)
        }
        onClicked: if (!moved) root.request("shift", 0)
        onWheel: function(wheel) { root.request("shift", root.shift + (wheel.angleDelta.y > 0 ? -1 : 1)) }
      }
    }

    Text {
      text: (root.days.current + " ← drag the ribbon → " + root.days.after).toUpperCase()
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(9)
      font.letterSpacing: Type.px(1.8)
    }
  }
}
