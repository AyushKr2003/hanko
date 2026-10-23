pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Time 時 as an almanac page, in the Ledger hand (Koyomi 暦,
// docs/koyomi/README.md): the month printed as a ruled table of six weeks,
// today a bone plate with the red notch, the picked day framed in ink;
// the day a solar term starts carries its name, the full and new moons
// their marks, the days ahead their forecast. Beside it, the year's dial
// and the picked day's leaf: its season, term, microseason, moon and sky.
// Under it, the year as twelve columns of months, then Elsewhen.
// A turn of the month sets the weeks in line by line from the side it came
// from, the way a compositor drops lines into a galley.
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
  implicitHeight: column.implicitHeight + Type.px(22) + foot.implicitHeight

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(18)

    SheetHead {
      sheet: "time"
      jp: "時"
      label: "Time · " + ko.view.romaji + " " + ko.view.wafu
      title: root.leaf.weekday
      blurb: root.leaf.day + " " + ko.view.name + " " + ko.view.y + " · " + root.leaf.sekki.romaji + ", "
        + root.leaf.sekki.english.toLowerCase() + (ko.k.moved ? " · " + root.leaf.when.toLowerCase() : "")
    }

    Row {
      id: spread
      width: parent.width
      spacing: Type.px(24)
      readonly property real sideW: Type.px(176)
      readonly property real gridW: width - sideW - spacing

      // ------------------------------------------------ the month
      Column {
        id: month
        width: spread.gridW

        GroupHead {
          title: ko.view.name + " " + ko.view.y + "  " + ko.view.jp
          actions: [{ text: "‹", name: "back" }, { text: "Today", name: "today" }, { text: "›", name: "on" }]
          onPicked: function(name) { ko.go(name === "back" ? "month-" : name === "on" ? "month+" : "today") }
        }
        Row {
          Repeater {
            model: ["M 月", "T 火", "W 水", "T 木", "F 金", "S 土", "S 日"]
            Text {
              required property string modelData
              required property int index
              width: month.width / 7
              height: Type.px(24)
              verticalAlignment: Text.AlignVCenter
              horizontalAlignment: Text.AlignHCenter
              text: modelData
              color: index >= 5 ? Ink.inkFaint : Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackTag
            }
          }
        }

        Item {
          id: table
          readonly property real cw: month.width / 7
          readonly property real ch: Type.px(50)
          width: month.width
          height: 6 * ch + 1

          WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(w) { ko.wheel(w.angleDelta.y) }
          }

          Rectangle { width: parent.width; height: 1; color: Ink.line }

          // The picked day's frame: slides to the day, as the cursor does.
          Rectangle {
            id: frame
            readonly property int at: {
              for (var w = 0; w < 6; w++) for (var d = 0; d < 7; d++) if (ko.k.weeks[w][d].picked) return w * 7 + d
              return -1
            }
            visible: at >= 0
            x: (at % 7) * table.cw + 1
            y: Math.floor(at / 7) * table.ch + 2
            width: table.cw - 2
            height: table.ch - 3
            color: "transparent"
            border.width: 1
            border.color: Ink.ink
            Behavior on x { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
            Behavior on y { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
          }

          Repeater {
            model: ko.k.weeks
            Item {
              id: week
              required property var modelData
              required property int index
              readonly property real home: index * table.ch
              width: table.width
              height: table.ch
              y: home
              // Set in from the side the month came from: the first line
              // first going on, the last line first going back.
              property real setIn: 1
              opacity: setIn
              transform: Translate { y: (1 - week.setIn) * ko.dir * Type.px(14) }
              NumberAnimation on setIn {
                id: setAnim
                running: false
                from: 0; to: 1
                duration: Motion.nuki
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.nukiCurve
              }
              Timer {
                id: setDelay
                interval: (ko.dir > 0 ? week.index : 5 - week.index) * 38
                onTriggered: setAnim.start()
              }
              // Set in on a turn: made for the new month (onCompleted) or kept
              // from the last (turned), whichever Qt does first.
              function enter() { setAnim.stop(); setIn = 0; setDelay.restart() }
              Component.onCompleted: if (ko.entering) week.enter()
              Connections { target: ko; function onTurned() { week.enter() } }

              Rectangle { y: table.ch; width: parent.width; height: 1; color: Ink.lineSoft }

              Repeater {
                model: week.modelData
                Item {
                  id: cell
                  required property var modelData
                  required property int index
                  readonly property var c: modelData
                  x: index * table.cw
                  width: table.cw
                  height: table.ch
                  opacity: c.inMonth ? 1 : 0.38

                  readonly property bool keyStop: true
                  readonly property bool keyChosen: c.picked
                  function keyPress() { ko.day(cell.c) }

                  Rectangle {
                    visible: cell.c.today
                    anchors.fill: parent
                    anchors.margins: Type.px(3)
                    color: Ink.bone
                    Rectangle {
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.bottom: parent.bottom
                      anchors.bottomMargin: Type.px(4)
                      width: Type.px(10)
                      height: 2
                      color: Ink.seal
                    }
                  }
                  readonly property color ink: c.today ? Ink.boneInk : c.picked ? Ink.ink
                    : c.past ? Ink.inkFaint : c.weekend ? Ink.inkMuted : Ink.inkDim
                  Text {
                    x: Type.px(7)
                    y: Type.px(6)
                    text: (cell.c.day < 10 ? "0" : "") + cell.c.day
                    color: cell.ink
                    font.family: Type.mono
                    font.pixelSize: Type.figure
                    font.weight: cell.c.picked || cell.c.today ? Font.DemiBold : Font.Normal
                  }
                  // A solar term starts: its name in the corner.
                  Text {
                    visible: cell.c.term !== ""
                    anchors.right: parent.right
                    anchors.rightMargin: Type.px(6)
                    y: Type.px(6)
                    text: cell.c.term
                    color: cell.c.today ? Ink.boneInk : Ink.ink
                    font.family: Type.jp
                    font.pixelSize: Type.px(11)
                  }
                  // The full and new moon.
                  MoonMark {
                    visible: cell.c.moon !== "" && cell.c.term === ""
                    anchors.right: parent.right
                    anchors.rightMargin: Type.px(7)
                    y: Type.px(8)
                    size: Type.px(9)
                    age: cell.c.moon === "full" ? 14.77 : 0
                    ink: cell.c.today ? Ink.boneInk : Ink.inkDim
                    paper: cell.c.today ? Ink.bone : Ink.paper
                  }
                  // The forecast.
                  Text {
                    visible: !!cell.c.sky
                    x: Type.px(7)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Type.px(cell.c.today ? 9 : 6)
                    text: cell.c.sky ? cell.c.sky.jp + " " + cell.c.sky.hi : ""
                    color: cell.c.today ? Ink.boneInk : Ink.inkMuted
                    font.family: Type.mono
                    font.pixelSize: Type.tag
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ko.day(cell.c)
                  }
                }
              }
            }
          }
        }
      }

      // ------------------------------------------------ the day's leaf
      Column {
        id: side
        width: spread.sideW
        spacing: Type.px(10)
        topPadding: Type.px(18)

        SeasonDial {
          id: dial
          anchors.horizontalCenter: parent.horizontalCenter
          size: Type.px(150)
          now: ko.koNow
          picked: ko.koPicked
          glyph: root.leaf.season.jp
          caption: "Day " + root.leaf.season.day + " of " + root.leaf.season.days
        }
        Item { width: 1; height: Type.px(16) }
        Row {
          spacing: Type.px(10)
          Text {
            text: root.leaf.sekki.jp
            color: Ink.ink
            font.family: Type.brush
            font.pixelSize: Type.px(26)
          }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { text: root.leaf.sekki.romaji; color: Ink.ink; font.family: Type.display; font.pixelSize: Type.px(16); font.variableAxes: Type.axes(Type.px(16)) }
            Text { text: root.leaf.sekki.english; color: Ink.inkMuted; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(12.5) }
          }
        }
        // The term's three kō as one rule: how far through it the day is.
        Item {
          id: koRule
          width: side.width
          height: Type.px(14)
          readonly property int inTerm: (root.leaf.ko.no - 1) % 3
          Repeater {
            model: 3
            Rectangle {
              id: third
              required property int index
              x: third.index * (side.width + Type.px(4)) / 3
              y: Type.px(6)
              width: (side.width - Type.px(8)) / 3
              height: 2
              color: Ink.lineSoft
              Rectangle {
                height: parent.height
                width: parent.width * (third.index < koRule.inTerm ? 1 : third.index === koRule.inTerm ? root.leaf.ko.through : 0)
                color: Ink.ink
              }
            }
          }
        }
        Text {
          width: side.width
          wrapMode: Text.WordWrap
          text: "Kō " + root.leaf.ko.no + "  " + root.leaf.ko.jp
          color: Ink.inkDim
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
        Text {
          width: side.width
          wrapMode: Text.WordWrap
          text: root.leaf.ko.english
          color: Ink.ink
          font.family: Type.display
          font.italic: true
          font.pixelSize: Type.px(15)
        }
        Text {
          width: side.width
          wrapMode: Text.WordWrap
          text: (root.leaf.next.in === 1 ? "Tomorrow " : "In " + root.leaf.next.in + " days ") + root.leaf.next.jp + " " + root.leaf.next.romaji
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
          font.capitalization: Font.AllUppercase
        }
        Rectangle { width: side.width; height: 1; color: Ink.lineSoft }
        Row {
          spacing: Type.px(10)
          MoonMark { anchors.verticalCenter: parent.verticalCenter; size: Type.px(20); age: root.leaf.moon.age }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { text: root.leaf.moon.jp + "  " + Math.round(root.leaf.moon.lit * 100) + "%"; color: Ink.ink; font.family: Type.jp; font.pixelSize: Type.px(12) }
            Text { text: root.leaf.moon.name; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(11) }
          }
        }
        Row {
          visible: ko.skyLine !== ""
          spacing: Type.px(10)
          Text { anchors.verticalCenter: parent.verticalCenter; width: Type.px(20); horizontalAlignment: Text.AlignHCenter; text: ko.skyMark; color: Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(20) }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: side.width - Type.px(30)
            Text { width: parent.width; elide: Text.ElideRight; text: ko.skyLine; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.px(12) }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: ko.skyNote; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(11) }
          }
        }
      }
    }

    // ------------------------------------------------ the year
    GroupHead {
      title: "The year · " + ko.view.y
      summary: root.leaf.season.name + " · " + Math.round(root.leaf.season.through * 100) + "% through"
    }
    Row {
      id: yearRow
      width: parent.width
      Repeater {
        model: ko.k.year
        Item {
          id: mo
          required property var modelData
          readonly property var mm: modelData
          width: yearRow.width / 12
          height: Type.px(50)
          readonly property bool keyStop: true
          readonly property bool keyChosen: mm.shown
          function keyPress() { ko.month(mo.mm.m) }
          Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: mo.mm.shown ? Ink.bone : hover.containsMouse ? Ink.lineSoft : "transparent"
          }
          Column {
            anchors.centerIn: parent
            spacing: Type.px(2)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: mo.mm.jp
              color: mo.mm.shown ? Ink.boneInk : Ink.inkDim
              font.family: Type.jp
              font.pixelSize: Type.px(12)
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: mo.mm.wafu
              color: mo.mm.shown ? Ink.boneInk : Ink.inkFaint
              font.family: Type.jp
              font.pixelSize: Type.px(9)
            }
          }
          // This month: the red notch.
          Rectangle {
            visible: mo.mm.current
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Type.px(3)
            width: Type.px(10)
            height: 2
            color: Ink.seal
          }
          // The season under its months, in four rules.
          Rectangle {
            y: parent.height + Type.px(4)
            width: parent.width - (mo.mm.m === 0 || mo.mm.m === 1 || mo.mm.m === 4 || mo.mm.m === 7 || mo.mm.m === 10 ? Type.px(3) : 0)
            height: 2
            color: mo.mm.season === root.leaf.season.key ? Ink.ink : Ink.line
          }
          MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ko.month(mo.mm.m)
          }
        }
      }
    }
    Item { width: 1; height: Type.px(8) }

    GroupHead {
      visible: root.zones.length > 0
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
            font.variableAxes: Type.axes(Type.px(20))
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
