pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Time.js" as T

// Time 時, Tanzaku (短冊): the time on the first slip, the day's spent part
// washed down it, then a week of slips, one a day, each headed with its
// weekday kanji (月 火 水 木 金 土 日) and its date at the foot; today inked
// and sealed, days gone a little paler. The other cities run under the rail.
// Left/Right on the week (or ‹ ›) move it; T or a click on a day brings it back.
Item {
  id: root

  property date now: new Date()
  property int shift: 0
  property string timeFormat: "HH:mm"
  property var zones: []
  signal request(string what, var arg)

  readonly property var head: T.heading(now)
  readonly property var kanji: ["日", "月", "火", "水", "木", "金", "土"]
  readonly property var week: {
    var out = [], base = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 3 + 7 * shift)
    for (var i = 0; i < 7; i++) {
      var d = new Date(base.getFullYear(), base.getMonth(), base.getDate() + i)
      out.push({ dow: d.getDay(), date: d.getDate(), today: d.toDateString() === now.toDateString(),
                 past: d < new Date(now.getFullYear(), now.getMonth(), now.getDate()), month: Qt.formatDate(d, "MMM") })
    }
    return out
  }
  // The time down the lead slip: hours, minutes, and AM or PM on a 12-hour clock.
  readonly property bool twelve: /AP/i.test(timeFormat)
  readonly property var timeLines: {
    var h = now.getHours(), two = function(n) { return (n < 10 ? "0" : "") + n }
    var out = [two(twelve ? (h % 12 || 12) : h), two(now.getMinutes())]
    if (twelve) out.push(h < 12 ? "AM" : "PM")
    return out
  }
  // The slips are as long as the lead slip needs for the stacked time and
  // the day's caption, never shorter than the other sheets' slips.
  readonly property real reach: Math.max(Type.px(220), Math.ceil(lead.natural))
  readonly property real spent: (now.getHours() * 60 + now.getMinutes()) / 1440

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(20)

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "time"; jp: "時"; label: "Time · Week " + root.head.week; compact: true }
    Item { width: 1; height: Type.px(18) }

    TanzakuRail {
      LeadStrip {
        id: lead
        mark: "時"
        lines: root.timeLines
        reach: root.reach
        caption: root.head.title + " · " + Qt.formatDate(root.now, "d MMM")
        level: root.spent
      }
      Repeater {
        model: root.week
        Tanzaku {
          required property var modelData
          mark: root.kanji[modelData.dow]
          reach: root.reach
          name: modelData.today ? "Today" : modelData.month + " " + modelData.date
          foot: String(modelData.date)
          selected: modelData.today
          dashed: modelData.past && !modelData.today
          interactive: root.shift !== 0
          onClicked: root.request("shift", 0)
        }
      }
    }

    // Elsewhen, under the rail: the week arrows held at the left, the cities
    // set from the right and wrapping to a second line rather than pushing
    // the arrows off the sheet.
    Item { width: 1; height: Type.px(12) }
    Item {
      width: parent.width
      height: Math.max(weekNav.implicitHeight, cities.implicitHeight)

      Text {
        id: weekNav
        text: "‹ week ›"
        // Te 手 (core/Cursor.js): Left/Right move the week, Enter brings it back.
        readonly property bool keyStop: true
        readonly property bool keyStep: true
        function keyAdjust(d) { root.request("shift", root.shift + d) }
        function keyPress() { root.request("shift", 0) }
        color: Ink.inkDim
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: function(m) { root.request("shift", root.shift + (m.x < parent.width / 2 ? -1 : 1)) }
        }
      }
      Flow {
        id: cities
        anchors.right: parent.right
        width: parent.width - weekNav.implicitWidth - Type.px(18)
        layoutDirection: Qt.RightToLeft
        spacing: Type.px(18)
        Repeater {
          model: root.zones
          Text {
            required property var modelData
            text: modelData.label.toUpperCase() + "  " + modelData.time + "  " + modelData.rel
            color: Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackTag
          }
        }
      }
    }
  }
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_T || event.key === Qt.Key_Home) { root.request("shift", 0); event.accepted = true }
  }
}
