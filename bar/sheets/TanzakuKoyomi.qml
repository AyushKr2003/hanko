pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Time 時 as an almanac in the Tanzaku hand (Koyomi 暦,
// docs/koyomi/README.md): a pillar calendar (hashira-goyomi, the tall
// almanac strips of Edo houses), the month's days hung from one rail as
// slips, right to left as a column of writing runs, each with its weekday
// and its date written down it in kanji. The day a solar term starts hangs
// longer, the term written below its date; the picked day is pulled down
// a little, as you would pull a slip to read it; today is inked and
// sealed. The days ahead carry their weather at the foot, and with a wind
// in the forecast the slips stir on their cords. At the right end the lead
// slip holds the picked day; under the rail, its leaf, then the twelve
// months on a rail of their own. A turn of the month hangs the new slips
// one after another, in the order they are read.
Item {
  id: root

  property date now: new Date()
  property int pick: 0
  property var sky: null
  property var zones: []
  signal request(string what, var arg)

  KoyomiState {
    id: ko
    now: root.now
    pick: root.pick
    sky: root.sky
    onRequest: function(what, arg) { root.request(what, arg) }
  }
  readonly property var leaf: ko.leaf
  // The month's own days, in order.
  readonly property var days: {
    var out = []
    for (var w = 0; w < 6; w++) for (var d = 0; d < 7; d++) if (ko.k.weeks[w][d].inMonth) out.push(ko.k.weeks[w][d])
    return out
  }
  readonly property int mondays: days.filter(function(c, i) { return i > 0 && c.dow === 0 }).length

  // The wind in the forecast stirs the slips: up to 1.4° at 25 km/h.
  readonly property real sway: Motion.live && root.sky && root.sky.now ? Math.min(1.4, root.sky.now.speed / 18) : 0
  property real phase: 0
  NumberAnimation on phase {
    running: root.sway > 0 && root.visible
    from: 0; to: Math.PI * 2
    duration: 5200
    loops: Animation.Infinite
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(16)

    SheetHead { sheet: "time"; jp: "時"; label: "Time · " + ko.view.romaji + " " + ko.view.wafu + " · " + ko.view.jp + " " + ko.view.y; compact: true }
    Item { width: 1; height: Type.px(16) }

    // ------------------------------------------------ the pillar of days
    Item {
      id: pillar
      width: parent.width
      readonly property real leadW: Type.px(66)
      readonly property real gap: Type.px(3)
      readonly property real weekGap: Type.px(8)
      readonly property real room: width - leadW - Type.px(14)
      readonly property real slipW: Math.floor((room - root.mondays * weekGap - (root.days.length - 1) * gap) / Math.max(1, root.days.length))
      readonly property real cord: Type.px(10)
      readonly property real base: Type.px(128)
      height: cord + base + Type.px(64)

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(w) { ko.wheel(w.angleDelta.y) }
      }

      // The rail, a knot at each end.
      Rectangle { y: Type.px(2); width: parent.width; height: 2; radius: 1; color: Ink.inkMuted }
      Repeater {
        model: [0, 1]
        Rectangle {
          required property int modelData
          x: modelData === 0 ? -Type.px(2) : pillar.width - Type.px(4)
          width: Type.px(6); height: width; radius: width / 2
          color: Ink.inkMuted
        }
      }

      // The lead slip: the picked day.
      Item {
        id: lead
        x: pillar.width - pillar.leadW
        width: pillar.leadW
        height: pillar.height
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: Type.px(3); width: 1; height: pillar.cord; color: Ink.lineStrong }
        Rectangle {
          id: leadPaper
          y: pillar.cord + Type.px(3)
          width: parent.width
          height: pillar.base + Type.px(52)
          color: Ink.alpha(Ink.bone, 0.06)
          border.width: 1
          border.color: Ink.lineStrong
          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Type.px(10)
            spacing: Type.px(2)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.leaf.weekdayJp.charAt(0)
              color: Ink.inkMuted
              font.family: Type.brush
              font.pixelSize: Type.px(16)
            }
            Item { width: 1; height: Type.px(4) }
            Repeater {
              model: Array.from(root.leaf.dayJp + "日")
              Text {
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                color: Ink.ink
                font.family: Type.brush
                font.pixelSize: Type.px(26)
              }
            }
          }
          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Type.px(10)
            spacing: 0
            Repeater {
              model: Array.from(root.leaf.sekki.jp)
              Text {
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                color: Ink.inkDim
                font.family: Type.jp
                font.pixelSize: Type.px(13)
              }
            }
            Rectangle {
              visible: root.leaf.offset === 0
              anchors.horizontalCenter: parent.horizontalCenter
              width: Type.px(10); height: width; radius: 1; rotation: -6
              color: Ink.seal
            }
          }
        }
      }

      // The days, right to left from the lead slip.
      Repeater {
        model: root.days
        Item {
          id: slip
          required property var modelData
          required property int index
          readonly property var c: modelData
          // Mondays part the weeks.
          readonly property int weeksBefore: root.days.slice(1, index + 1).filter(function(d) { return d.dow === 0 }).length
          x: pillar.room - (index + 1) * pillar.slipW - index * pillar.gap - weeksBefore * pillar.weekGap
          width: pillar.slipW
          height: pillar.height

          readonly property real length: pillar.base + (c.term !== "" ? Type.px(34) : 0) + (c.picked ? Type.px(16) : 0)
          readonly property bool keyStop: true
          readonly property bool keyChosen: c.picked
          function keyPress() { ko.day(slip.c) }

          // Hung one after another on a turn, in the order they are read.
          property real hang: 1
          opacity: hang
          Component.onCompleted: if (ko.entering) { hang = 0; hangDelay.start() }
          Timer {
            id: hangDelay
            interval: (ko.dir > 0 ? slip.index : root.days.length - 1 - slip.index) * 16
            onTriggered: hangAnim.start()
          }
          NumberAnimation on hang {
            id: hangAnim
            running: false
            from: 0; to: 1
            duration: Motion.nuki
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.nukiCurve
          }

          Item {
            id: swing
            width: parent.width
            height: pillar.cord + slip.length
            y: Type.px(3) - (1 - slip.hang) * Type.px(18)
            transformOrigin: Item.Top
            rotation: root.sway * Math.sin(root.phase + slip.index * 0.55) + (pointer.containsMouse && !slip.c.picked ? 1.6 : 0)
            Behavior on rotation { enabled: Motion.live && pointer.containsMouse; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: pillar.cord; color: Ink.lineStrong }
            Rectangle {
              id: paper
              y: pillar.cord
              width: parent.width
              height: slip.length
              radius: 1
              color: slip.c.today ? Ink.bone : Ink.alpha(Ink.bone, slip.c.picked ? 0.12 : pointer.containsMouse ? 0.08 : 0.035)
              border.width: 1
              border.color: slip.c.today ? Ink.bone : slip.c.picked ? Ink.ink : Ink.line
              opacity: slip.c.past && !slip.c.today ? 0.55 : 1
              Behavior on height { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }

              readonly property color ink: slip.c.today ? Ink.boneInk : slip.c.weekend ? Ink.inkMuted : Ink.ink
              Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Type.px(5)
                spacing: -Type.px(1)
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: slip.c.kanji
                  color: slip.c.today ? Ink.boneInk : Ink.inkMuted
                  font.family: Type.jp
                  font.pixelSize: Math.min(Type.px(10), pillar.slipW - 3)
                }
                Item { width: 1; height: Type.px(5) }
                Repeater {
                  model: Array.from(slip.c.jp)
                  Text {
                    required property string modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    color: paper.ink
                    font.family: Type.brush
                    font.pixelSize: Math.min(Type.px(11), pillar.slipW - 2)
                  }
                }
                Item { width: 1; height: Type.px(8); visible: slip.c.term !== "" }
                Repeater {
                  model: slip.c.term !== "" ? Array.from(slip.c.term) : []
                  Text {
                    required property string modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    color: slip.c.today ? Ink.boneInk : Ink.ink
                    font.family: Type.jp
                    font.weight: Font.Bold
                    font.pixelSize: Math.min(Type.px(11), pillar.slipW - 2)
                  }
                }
              }
              // The moon, full or new, low on the slip.
              MoonMark {
                visible: slip.c.moon !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Type.px(slip.c.sky ? 22 : 7)
                size: Math.min(Type.px(8), pillar.slipW - 4)
                age: slip.c.moon === "full" ? 14.77 : 0
                tint: paper.ink
                ring: slip.c.today ? Ink.boneInk : Ink.inkMuted
              }
              // The weather at the foot.
              Text {
                visible: !!slip.c.sky
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Type.px(slip.c.today ? 16 : 5)
                text: slip.c.sky ? slip.c.sky.jp : ""
                color: slip.c.today ? Ink.boneInk : Ink.inkDim
                font.family: Type.brush
                font.pixelSize: Math.min(Type.px(11), pillar.slipW - 2)
              }
              Rectangle {
                visible: slip.c.today
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Type.px(4)
                width: Math.min(Type.px(8), pillar.slipW - 4); height: width; radius: 1; rotation: -6
                color: Ink.seal
              }
            }
          }
          MouseArea {
            id: pointer
            y: pillar.cord
            width: parent.width
            height: slip.length
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ko.day(slip.c)
          }
        }
      }
    }

    // ------------------------------------------------ the day's leaf
    Rectangle { width: parent.width; height: 1; color: Ink.lineSoft }
    Item { width: 1; height: Type.px(14) }
    Row {
      id: leafRow
      width: parent.width
      spacing: Type.px(20)
      readonly property real col: (width - 2 * spacing) / 3
      Column {
        width: leafRow.col
        spacing: Type.px(3)
        Text { text: root.leaf.sekki.jp + "  " + root.leaf.sekki.romaji; color: Ink.ink; font.family: Type.jp; font.pixelSize: Type.px(14) }
        Text { text: (root.leaf.sekki.english + " · day " + root.leaf.sekki.day + " of " + root.leaf.sekki.days).toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        Item { width: 1; height: Type.px(4) }
        Text { width: parent.width; wrapMode: Text.WordWrap; text: root.leaf.ko.jp + "  " + root.leaf.ko.english; color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(12) }
      }
      Row {
        width: leafRow.col
        spacing: Type.px(10)
        MoonMark { anchors.verticalCenter: parent.verticalCenter; size: Type.px(22); age: root.leaf.moon.age }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          Text { text: root.leaf.moon.jp; color: Ink.ink; font.family: Type.jp; font.pixelSize: Type.px(14) }
          Text { text: (root.leaf.moon.name + " · " + Math.round(root.leaf.moon.lit * 100) + "%").toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        }
      }
      Row {
        width: leafRow.col
        spacing: Type.px(10)
        visible: ko.skyLine !== ""
        Text { anchors.verticalCenter: parent.verticalCenter; text: ko.skyMark; color: Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(24) }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: leafRow.col - Type.px(34)
          Text { width: parent.width; elide: Text.ElideRight; text: ko.skyLine; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.px(12) }
          Text { width: parent.width; wrapMode: Text.WordWrap; text: ko.skyNote.toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        }
      }
    }

    // ------------------------------------------------ the twelve months
    Item { width: 1; height: Type.px(18) }
    Item {
      id: months
      width: parent.width
      height: Type.px(6) + Type.px(8) + Type.px(62)
      readonly property real mw: (width - 11 * Type.px(5)) / 12
      Rectangle { y: Type.px(2); width: parent.width; height: 1; color: Ink.inkMuted }
      Repeater {
        model: ko.k.year
        Item {
          id: mo
          required property var modelData
          required property int index
          readonly property var mm: modelData
          // Right to left: 一月 at the right end.
          x: months.width - (index + 1) * months.mw - index * Type.px(5)
          y: Type.px(2)
          width: months.mw
          height: months.height
          readonly property bool keyStop: true
          readonly property bool keyChosen: mm.shown
          function keyPress() { ko.month(mo.mm.m) }
          Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: Type.px(8); color: Ink.lineStrong }
          Rectangle {
            y: Type.px(8)
            width: parent.width
            height: Type.px(62) - (mo.mm.season === root.leaf.season.key ? 0 : Type.px(10))
            color: mo.mm.shown ? Ink.bone : Ink.alpha(Ink.bone, monthHover.containsMouse ? 0.08 : 0.035)
            border.width: 1
            border.color: mo.mm.shown ? Ink.bone : Ink.line
            Behavior on height { enabled: Motion.live; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
            Column {
              anchors.horizontalCenter: parent.horizontalCenter
              y: Type.px(5)
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: mo.mm.jp.replace("月", ""); color: mo.mm.shown ? Ink.boneInk : Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(13) }
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: mo.mm.seasonJp; color: mo.mm.shown ? Ink.alpha(Ink.boneInk, 0.7) : Ink.inkFaint; font.family: Type.jp; font.pixelSize: Type.px(9) }
            }
            Rectangle {
              visible: mo.mm.current
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Type.px(4)
              width: Type.px(7); height: width; radius: 1; rotation: -6
              color: Ink.seal
            }
          }
          MouseArea {
            id: monthHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ko.month(mo.mm.m)
          }
        }
      }
    }

    Item { width: 1; height: Type.px(12); visible: root.zones.length > 0 }
    Flow {
      width: parent.width
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

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: "Wheel or [ ] a month · T today"
    SheetButton { text: "‹ Month"; ghost: true; onClicked: ko.go("month-") }
    SheetButton { text: "Today"; plate: ko.k.moved; onClicked: ko.go("today") }
    SheetButton { text: "Month ›"; ghost: true; onClicked: ko.go("month+") }
  }

  Keys.onPressed: function(event) { if (ko.key(event)) event.accepted = true }
}
