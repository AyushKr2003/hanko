pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Time.js" as T
import "../../core/Season.js" as Season
import "../parts"

// Time 時: the day in a sentence, the month with today ringed (an ensō when
// the ring part is the ensō), the micro-season of the seventy-two written
// down the page when the season touch is on, and the other cities.
Item {
  id: root

  property var skin: ({})
  property date now: new Date()
  property var zones: []
  signal request(string sheet, string what, var arg)

  readonly property var season: Season.at(now)
  readonly property bool showSeason: (skin.season || "off") !== "off"
  readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  readonly property var cells: {
    var y = now.getFullYear(), m = now.getMonth()
    var lead = (new Date(y, m, 1).getDay() + 6) % 7
    var count = new Date(y, m + 1, 0).getDate()
    var out = []
    for (var i = 0; i < lead; i++) out.push({ day: 0 })
    for (var d = 1; d <= count; d++) out.push({ day: d, today: d === now.getDate(), past: d < now.getDate() })
    return out
  }
  readonly property real colW: showSeason ? (width - Type.px(20)) / 2 : width

  implicitHeight: Math.max(left.implicitHeight, right.visible ? right.implicitHeight : 0)

  Column {
    id: left
    width: root.colW
    spacing: Type.px(4)
    Text {
      text: T.heading(root.now).title + ", "
      color: Ink.ink
      font.family: Type.display; font.pixelSize: Type.px(30); font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(30), 360)
      Text {
        anchors.left: parent.right; anchors.baseline: parent.baseline
        text: T.ordinal(root.now.getDate())
        color: Ink.ink2
        font.family: Type.display; font.italic: true; font.pixelSize: Type.px(30); font.weight: Font.Normal
      }
    }
    Text {
      text: root.months[root.now.getMonth()] + " " + root.now.getFullYear() + " · week " + T.isoWeek(root.now)
      color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12.5)
      bottomPadding: Type.px(10)
    }
    Grid {
      columns: 7
      Repeater {
        model: ["M", "T", "W", "T", "F", "S", "S"]
        Text { required property string modelData; width: left.width / 7; height: Type.px(22); horizontalAlignment: Text.AlignHCenter; text: modelData; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11.5) }
      }
      Repeater {
        model: root.cells
        Item {
          id: c
          required property var modelData
          width: left.width / 7; height: Type.px(32)
          Ring {
            visible: !!c.modelData.today
            anchors.centerIn: parent
            skin: root.skin; size: Type.px(34); value: 97
          }
          Text {
            anchors.centerIn: parent
            visible: c.modelData.day > 0
            text: c.modelData.day
            color: c.modelData.today ? Ink.ink : c.modelData.past ? Ink.ink3 : Ink.ink2
            font.family: Type.text; font.pixelSize: Type.px(12.5)
            font.weight: c.modelData.today ? Font.DemiBold : Font.Normal
            font.features: { "tnum": 1 }
          }
        }
      }
    }
    Divider { visible: root.zones.length > 0 && !root.showSeason; skin: root.skin; width: parent.width; bleed: Type.px(20) }
    Repeater {
      model: root.showSeason ? [] : root.zones
      Zone { required property var modelData; zone: modelData; width: left.width }
    }
  }

  Column {
    id: right
    visible: root.showSeason
    x: root.colW + Type.px(20)
    width: root.colW
    spacing: Type.px(12)
    Text {
      text: root.season.sekkiKanji + "  " + root.season.sekkiName + " · " + root.season.sekkiRomaji
      color: Ink.ink3; font.family: Type.jp; font.pixelSize: Type.px(12.5)
    }
    Row {
      spacing: Type.px(14)
      Column {
        Repeater {
          model: Array.from(root.season.koKanji)
          Text { required property string modelData; text: modelData; color: Ink.ink; font.family: Type.jpSerif; font.weight: Font.Medium; font.pixelSize: Type.px(32) }
        }
      }
      Column {
        width: right.width - Type.px(50)
        spacing: Type.px(6)
        Text {
          width: parent.width; wrapMode: Text.WordWrap
          text: root.season.koName
          color: Ink.ink
          font.family: Type.display; font.pixelSize: Type.px(22); font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(22), 380)
        }
        Text {
          width: parent.width; wrapMode: Text.WordWrap
          text: "One of the seventy-two seasons, about five days long. Next: " + Season.KO[(root.season.ko + 1) % 72][1].toLowerCase() + "."
          color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12)
        }
      }
    }
    Divider { visible: root.zones.length > 0; skin: root.skin; width: parent.width; bleed: Type.px(20) }
    Repeater {
      model: root.zones
      Zone { required property var modelData; zone: modelData; width: right.width }
    }
  }

  component Zone: Item {
    id: z
    property var zone: ({})
    height: Type.px(36)
    Column {
      anchors.verticalCenter: parent.verticalCenter
      Text { text: z.zone.label || ""; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(13) }
      Text { text: z.zone.day || z.zone.date || ""; color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(11.5) }
    }
    Text {
      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
      text: z.zone.time || ""
      color: Ink.ink
      font.family: Type.display; font.pixelSize: Type.px(18); font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(18), 400)
    }
  }
}
