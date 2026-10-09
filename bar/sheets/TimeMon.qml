pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Time.js" as T
import "../../core/Mon.js" as Mon

// Time 時, Mon (紋): the hour as the sheet's mon, twelve stars round the ring
// lit to the hour, the time beside it; the week as seven crests bearing
// their weekday kanji in the ring (丸に月, 丸に火 …), today inked red and the
// days gone faint; the other cities as a line under them. Arrows move the
// week; T, or a click on any day, brings it back.
Item {
  id: root

  property date now: new Date()
  property int shift: 0
  property var zones: []
  signal request(string what, var arg)

  readonly property var head: T.heading(now)
  readonly property var week: {
    var out = [], base = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 3 + 7 * shift)
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    for (var i = 0; i < 7; i++) {
      var d = new Date(base.getFullYear(), base.getMonth(), base.getDate() + i)
      out.push({ dow: d.getDay(), date: d.getDate(), today: d.getTime() === today.getTime(), past: d < today,
                 label: Qt.formatDate(d, "ddd d") })
    }
    return out
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(20)

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "time"; jp: "時"; label: "Time · Week " + root.head.week; compact: true }
    Item { width: 1; height: Type.px(18) }

    MonHero {
      kind: "hours"
      level: ((root.now.getHours() % 12) + root.now.getMinutes() / 60) / 12
      figure: Qt.formatTime(root.now, "HH:mm")
      title: root.head.title + ", " + Qt.formatDate(root.now, "d MMMM")
      lines: [root.head.blurb]
      SheetButton { text: "‹"; onClicked: root.request("shift", root.shift - 1) }
      SheetButton { text: "Today"; on: root.shift === 0; onClicked: root.request("shift", 0) }
      SheetButton { text: "›"; onClicked: root.request("shift", root.shift + 1) }
    }

    MonPage {
      id: days
      jp: "週"
      label: "The week"
      summary: root.shift === 0 ? "this week" : (root.shift > 0 ? "+" : "") + root.shift + (Math.abs(root.shift) === 1 ? " week" : " weeks")
      columns: 7
      Repeater {
        model: root.week
        CrestCell {
          required property var modelData
          width: days.cellWidth
          kind: "moji"
          glyph: Mon.WEEKDAYS[modelData.dow]
          selected: modelData.today
          faint: modelData.past
          interactive: root.shift !== 0
          name: String(modelData.date)
          onClicked: root.request("shift", 0)
        }
      }
    }

    Item { width: 1; height: Type.px(14) }
    Text {
      visible: root.zones.length > 0
      width: parent.width
      elide: Text.ElideRight
      text: root.zones.map(function(z) { return z.label.toUpperCase() + "  " + z.time + " " + z.rel }).join("   ·   ")
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }

  Keys.onLeftPressed: root.request("shift", root.shift - 1)
  Keys.onRightPressed: root.request("shift", root.shift + 1)
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_T || event.key === Qt.Key_Home) { root.request("shift", 0); event.accepted = true }
  }
}
