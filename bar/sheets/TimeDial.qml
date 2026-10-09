pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Time.js" as T
import "../../core/Edge.js" as E

// Time 時, Dial (盤): a clock face as the hero (hour ticks, two hands, and
// round its rim the day spent so far, the now-notch in red at its end),
// the day and date beside it, two weeks as a calendar block (today on a
// bone plate) and the other cities as tiles. Arrows or ‹ › move the weeks.
Item {
  id: root

  property date now: new Date()
  property int shift: 0
  property var zones: []
  signal request(string what, var arg)

  readonly property var head: T.heading(now)
  readonly property var days: T.ribbon(now, shift)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(18)

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "time"; jp: "時"; label: "Time · Week " + root.head.week; compact: true }
    Item { width: 1; height: Type.px(16) }

    DialHero {
      face: clockFace
      title: root.head.title
      lines: [Qt.formatDate(root.now, "d MMMM yyyy"), root.head.blurb]
      SheetButton { text: "‹ Week"; onClicked: root.request("shift", root.shift - 1) }
      SheetButton { text: "Week ›"; onClicked: root.request("shift", root.shift + 1) }
    }

    TileSection {
      id: cal
      label: root.days.month
      summary: root.shift === 0 ? "this fortnight" : (root.shift > 0 ? "+" : "") + root.shift + (Math.abs(root.shift) === 1 ? " week" : " weeks")
      columns: 7
      Repeater {
        model: root.days.days
        Rectangle {
          id: day
          required property var modelData
          width: cal.tileWidth
          height: Type.px(40)
          radius: 3
          color: modelData.today ? Ink.bone : "transparent"
          border.width: 1
          border.color: modelData.today ? Ink.bone : Ink.lineSoft
          Column {
            anchors.centerIn: parent
            spacing: Type.px(2)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: day.modelData.letter
              color: day.modelData.today ? Ink.boneInk : Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.tag
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: day.modelData.day
              color: day.modelData.today ? Ink.boneInk : day.modelData.weekend || day.modelData.past ? Ink.inkMuted : Ink.ink
              font.family: Type.mono
              font.pixelSize: Type.figure
            }
          }
          MouseArea {
            anchors.fill: parent
            enabled: !day.modelData.today && root.shift !== 0
            cursorShape: Qt.PointingHandCursor
            onClicked: root.request("shift", 0)
          }
        }
      }
    }

    TileSection {
      id: cities
      visible: root.zones.length > 0
      label: "Elsewhen"
      summary: root.zones.length + (root.zones.length === 1 ? " zone" : " zones")
      Repeater {
        model: root.zones
        Tile {
          required property var modelData
          width: cities.tileWidth
          interactive: false
          name: modelData.time + "  " + modelData.label
          detail: modelData.date
          note: modelData.rel
        }
      }
    }
  }

  Component {
    id: clockFace
    Canvas {
      id: face
      readonly property real frac: E.dayFraction(root.now)
      readonly property var key: [root.now.getHours(), root.now.getMinutes(), width, Ink.ink]
      onKeyChanged: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - Type.px(12)
        // The day spent, round the rim from midnight at the top.
        c.lineCap = "round"
        c.lineWidth = Type.px(2)
        c.strokeStyle = Ink.line
        c.beginPath(); c.arc(cx, cy, r + Type.px(6), 0, 2 * Math.PI); c.stroke()
        var top = -Math.PI / 2, at = top + 2 * Math.PI * face.frac
        c.lineWidth = Type.px(3)
        c.strokeStyle = Ink.inkDim
        c.beginPath(); c.arc(cx, cy, r + Type.px(6), top, at, false); c.stroke()
        c.strokeStyle = Ink.seal
        c.lineWidth = 2
        c.beginPath(); c.moveTo(cx + (r + Type.px(1)) * Math.cos(at), cy + (r + Type.px(1)) * Math.sin(at))
        c.lineTo(cx + (r + Type.px(12)) * Math.cos(at), cy + (r + Type.px(12)) * Math.sin(at)); c.stroke()
        // Hour ticks, the quarters longer.
        for (var i = 0; i < 12; i++) {
          var a = top + i * Math.PI / 6, q = i % 3 === 0
          c.strokeStyle = q ? Ink.inkDim : Ink.line
          c.lineWidth = q ? 2 : 1
          var r1 = r - Type.px(q ? 12 : 7)
          c.beginPath(); c.moveTo(cx + r1 * Math.cos(a), cy + r1 * Math.sin(a)); c.lineTo(cx + r * Math.cos(a), cy + r * Math.sin(a)); c.stroke()
        }
        // The hands.
        var h = root.now.getHours() % 12, m = root.now.getMinutes()
        var ah = top + (h + m / 60) * Math.PI / 6, am = top + m * Math.PI / 30
        c.strokeStyle = Ink.ink
        c.lineWidth = Type.px(4)
        c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + r * 0.52 * Math.cos(ah), cy + r * 0.52 * Math.sin(ah)); c.stroke()
        c.lineWidth = Type.px(2)
        c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + r * 0.8 * Math.cos(am), cy + r * 0.8 * Math.sin(am)); c.stroke()
        c.fillStyle = Ink.ink
        c.beginPath(); c.arc(cx, cy, Type.px(4), 0, 2 * Math.PI); c.fill()
      }
    }
  }

  Keys.onLeftPressed: root.request("shift", root.shift - 1)
  Keys.onRightPressed: root.request("shift", root.shift + 1)
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_T || event.key === Qt.Key_Home) { root.request("shift", 0); event.accepted = true }
  }
}
