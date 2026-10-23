pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Time 時 as an almanac in the Kasumi hand (Koyomi 暦,
// docs/koyomi/README.md): the month as the mist bands of a gold screen
// (suyari-gasumi), one band a week. Gold leaf is laid along each band as
// far as the days have gone, the week of today gilded up to today and
// sealed there in red; the weeks to come are thin mist, the gold not yet
// laid. The days float in the bands. A day a solar term starts is marked
// with a small square of leaf (kirihaku) and the term's name; the full and
// new moons sit beside their days, the forecast under them. The picked day
// is underlined. Then the year as twelve slips of mist, and the leaf of
// the picked day. A turn of the month is the mist moving: the bands drift
// in from alternate sides, slower than any other hand, and settle.
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

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(16)

    SheetHead { sheet: "time"; jp: "時"; label: "Time · " + ko.view.romaji + " " + ko.view.wafu; compact: true }

    // The scene: the day, and the month's old name as a title slip.
    Item {
      width: parent.width
      height: Type.px(92)
      Text {
        anchors.right: parent.right
        anchors.rightMargin: Type.px(4)
        y: Type.px(6)
        text: ko.view.wafu
        color: Ink.alpha(Ink.bone, 0.9)
        font.family: Type.brush
        font.pixelSize: Type.px(44)
      }
      Column {
        y: Type.px(10)
        spacing: Type.px(2)
        Text {
          text: root.leaf.weekday + ", " + root.leaf.day + " " + ko.view.name
          color: Ink.ink
          font.family: Type.display
          font.pixelSize: Type.px(30)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(30), 360)
        }
        Text {
          text: root.leaf.sekki.romaji + ", " + root.leaf.sekki.english.toLowerCase() + " · " + root.leaf.ko.english.toLowerCase()
          color: Ink.inkDim
          font.family: Type.display
          font.italic: true
          font.pixelSize: Type.px(15)
        }
        Text {
          text: (root.leaf.when + " · " + ko.view.y + " · " + ko.view.english).toUpperCase()
          color: root.leaf.offset === 0 ? Ink.seal : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
          topPadding: Type.px(4)
        }
      }
    }

    Item {
      width: parent.width
      height: Type.px(18)
      Repeater {
        model: ["月", "火", "水", "木", "金", "土", "日"]
        Text {
          required property string modelData
          required property int index
          x: index * column.width / 7
          width: column.width / 7
          horizontalAlignment: Text.AlignHCenter
          text: modelData
          color: index >= 5 ? Ink.inkFaint : Ink.inkMuted
          font.family: Type.brush
          font.pixelSize: Type.px(12)
        }
      }
    }

    // ------------------------------------------------ the bands
    Item {
      id: screen
      width: parent.width
      readonly property real dayW: width / 7
      readonly property real bandH: Type.px(52)
      height: 6 * bandH

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(w) { ko.wheel(w.angleDelta.y) }
      }

      Repeater {
        model: ko.k.weeks
        Item {
          id: band
          required property var modelData
          required property int index
          readonly property var days: modelData
          // How far the gold is laid along this week: to the end of the
          // days gone, through today.
          readonly property real gilt: {
            var n = 0
            for (var i = 0; i < 7; i++) if (days[i].past || days[i].today) n = i + 1
            return n / 7
          }
          readonly property bool sealed: days.some(function(c) { return c.today })
          readonly property int side: index % 2 === 0 ? -1 : 1
          width: screen.width
          height: screen.bandH
          y: index * screen.bandH
          x: (1 - drift) * band.side * ko.dir * Type.px(46)
          // The mist drifting in on a turn.
          property real drift: 1
          opacity: 0.15 + 0.85 * drift
          NumberAnimation on drift {
            id: driftAnim
            running: false
            from: 0; to: 1
            duration: Motion.ms(560 + band.index * 50)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.unrollCurve
          }
          // Set in on a turn: made for the new month (onCompleted) or kept
          // from the last (turned), whichever Qt does first.
          function enter() { drift = 0; driftAnim.restart() }
          Component.onCompleted: if (ko.entering) band.enter()
          Connections { target: ko; function onTurned() { band.enter() } }

          // The thin mist under every week, then the gold laid on it.
          MistBand { y: Type.px(8); width: parent.width; level: 1; gilt: false }
          MistBand {
            visible: band.gilt > 0
            y: Type.px(8)
            width: parent.width
            level: band.gilt
            gilt: true
            lead: band.sealed
          }
          Repeater {
            model: band.days
            Item {
              id: dd
              required property var modelData
              required property int index
              readonly property var c: modelData
              readonly property bool onGold: index < band.gilt * 7 - 0.01
              x: index * screen.dayW
              width: screen.dayW
              height: screen.bandH
              opacity: c.inMonth ? 1 : 0.35
              readonly property bool keyStop: true
              readonly property bool keyChosen: c.picked
              function keyPress() { ko.day(dd.c) }
              Text {
                id: fig
                anchors.horizontalCenter: parent.horizontalCenter
                y: Type.px(13)
                text: dd.c.day
                color: dd.onGold ? Ink.boneInk : dd.c.picked ? Ink.ink : Ink.inkDim
                font.family: Type.display
                font.italic: true
                font.pixelSize: Type.px(17)
                font.weight: dd.c.picked ? Font.DemiBold : Font.Normal
              }
              // The term: a square of leaf, its name beside.
              Row {
                visible: dd.c.term !== ""
                anchors.left: fig.right
                anchors.leftMargin: Type.px(4)
                y: Type.px(14)
                spacing: Type.px(2)
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(5); height: width; rotation: 45; color: dd.onGold ? Ink.boneInk : Ink.bone }
                Text { text: dd.c.term; color: dd.onGold ? Ink.boneInk : Ink.ink; font.family: Type.jp; font.pixelSize: Type.px(10) }
              }
              MoonMark {
                visible: dd.c.moon !== "" && dd.c.term === ""
                anchors.left: fig.right
                anchors.leftMargin: Type.px(5)
                y: Type.px(18)
                size: Type.px(8)
                age: dd.c.moon === "full" ? 14.77 : 0
                ink: dd.onGold ? Ink.boneInk : Ink.inkDim
                paper: dd.onGold ? Ink.bone : Ink.paper
              }
              Text {
                visible: !!dd.c.sky
                anchors.horizontalCenter: parent.horizontalCenter
                y: Type.px(36)
                text: dd.c.sky ? dd.c.sky.jp + " " + dd.c.sky.hi : ""
                color: Ink.inkFaint
                font.family: Type.mono
                font.pixelSize: Type.tag
              }
              // Today: the seal where the gold stops.
              Rectangle {
                visible: dd.c.today
                anchors.right: parent.right
                anchors.rightMargin: Type.px(8)
                y: Type.px(16)
                width: Type.px(11); height: width; radius: 1
                color: Ink.seal
              }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ko.day(dd.c) }
            }
          }
        }
      }
      // The picked day, underlined.
      Rectangle {
        readonly property int at: {
          for (var w = 0; w < 6; w++) for (var d = 0; d < 7; d++) if (ko.k.weeks[w][d].picked) return w * 7 + d
          return -1
        }
        visible: at >= 0
        x: (at % 7) * screen.dayW + screen.dayW * 0.3
        y: Math.floor(at / 7) * screen.bandH + Type.px(48)
        width: screen.dayW * 0.4
        height: 2
        color: Ink.ink
        Behavior on x { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
        Behavior on y { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
      }
    }

    // ------------------------------------------------ the year
    Item { width: 1; height: Type.px(12) }
    Row {
      id: year
      width: parent.width
      spacing: Type.px(4)
      Repeater {
        model: ko.k.year
        Item {
          id: mo
          required property var modelData
          readonly property var mm: modelData
          width: (year.width - 11 * year.spacing) / 12
          height: Type.px(44)
          readonly property bool keyStop: true
          readonly property bool keyChosen: mm.shown
          function keyPress() { ko.month(mo.mm.m) }
          MistBand { width: parent.width; level: 1; gilt: mo.mm.shown; lead: mo.mm.shown }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Type.px(8)
            text: mo.mm.wafu
            color: mo.mm.shown ? Ink.boneInk : mo.mm.season === root.leaf.season.key ? Ink.ink : Ink.inkMuted
            font.family: Type.jp
            font.pixelSize: Type.px(10)
          }
          Rectangle {
            visible: mo.mm.current
            anchors.horizontalCenter: parent.horizontalCenter
            y: Type.px(36)
            width: Type.px(6); height: width; radius: 1
            color: Ink.seal
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ko.month(mo.mm.m) }
        }
      }
    }

    Item { width: 1; height: Type.px(8) }
    Flow {
      width: parent.width
      spacing: Type.px(22)
      Text { text: root.leaf.ko.jp + " · kō " + root.leaf.ko.no + " of 72"; color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(12) }
      Row {
        spacing: Type.px(8)
        MoonMark { anchors.verticalCenter: parent.verticalCenter; size: Type.px(16); age: root.leaf.moon.age }
        Text { anchors.verticalCenter: parent.verticalCenter; text: root.leaf.moon.jp + " · " + root.leaf.moon.name; color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(12) }
      }
      Row {
        visible: ko.skyLine !== ""
        spacing: Type.px(8)
        Text { anchors.verticalCenter: parent.verticalCenter; text: ko.skyMark; color: Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(16) }
        Text { anchors.verticalCenter: parent.verticalCenter; text: ko.skyLine + (ko.skyNote ? " · " + ko.skyNote : ""); color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(12) }
      }
      Repeater {
        model: root.zones
        Text {
          required property var modelData
          topPadding: Type.px(3)
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
