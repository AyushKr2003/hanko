pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Time 時 as an almanac in the Odoshi hand (Koyomi 暦,
// docs/koyomi/README.md): the month is a suit of armour. The crown plate
// (kanmuri-ita) holds the picked day; under it each week is a lame of
// small scales, a run of scales for each day, laced densely (kebiki) for
// the days gone and knotted red for today, bare with their lacing holes
// (sugake) for the days to come. Under each day its date, the solar term
// that starts on it or its weather. The picked day is framed. Then the
// year as one lame of twelve months, the season's six terms as another,
// each laced as far as we are. A turn of the month settles the lames one
// below another, top to bottom, the way the plates of a suit fall into
// place as it is lifted on.
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
    Item { width: 1; height: Type.px(14) }

    // ------------------------------------------------ the crown plate
    Rectangle {
      width: parent.width
      height: Type.px(78)
      color: Ink.alpha(Ink.bone, 0.03)
      border.width: 1
      border.color: Ink.lineStrong
      Rectangle { anchors.fill: parent; anchors.margins: Type.px(4); color: "transparent"; border.width: 1; border.color: Ink.lineSoft }
      Row {
        x: Type.px(18)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(16)
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.leaf.weekdayJp.charAt(0)
          color: root.leaf.offset === 0 ? Ink.seal : Ink.ink
          font.family: Type.brush
          font.pixelSize: Type.px(36)
        }
        Text {
          id: dayFig
          anchors.verticalCenter: parent.verticalCenter
          text: String(root.leaf.day)
          color: Ink.ink
          font.family: Type.display
          font.pixelSize: Type.px(44)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(44), 360)
        }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          Text { text: root.leaf.weekday + ", " + ko.view.name + " " + ko.view.y; color: Ink.ink; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(16) }
          Text { text: (root.leaf.when + " · " + ko.view.wafu + " " + ko.view.english).toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        }
      }
      Column {
        anchors.right: parent.right
        anchors.rightMargin: Type.px(18)
        anchors.verticalCenter: parent.verticalCenter
        Text { anchors.right: parent.right; text: root.leaf.sekki.jp; color: Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(24) }
        Text { anchors.right: parent.right; text: root.leaf.sekki.romaji.toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
      }
    }
    // The cords that hang the lames from the plate.
    Item {
      width: parent.width
      height: Type.px(10)
      Repeater {
        model: 7
        Rectangle { required property int index; x: (index + 0.5) * column.width / 7 - 1; width: 2; height: parent.height; color: Ink.alpha(Ink.ink, 0.35) }
      }
    }

    // ------------------------------------------------ the month's lames
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
    Item {
      id: suit
      width: parent.width
      readonly property real dayW: width / 7
      readonly property real lameH: Type.px(46)
      height: 6 * lameH

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(w) { ko.wheel(w.angleDelta.y) }
      }

      Repeater {
        model: ko.k.weeks
        Item {
          id: plate
          required property var modelData
          required property int index
          width: suit.width
          height: suit.lameH
          y: index * suit.lameH - (1 - settle) * Type.px(12)
          // Settled one below another on a turn.
          property real settle: 1
          opacity: settle
          NumberAnimation on settle {
            id: settleAnim
            running: false
            from: 0; to: 1
            duration: Motion.nuki
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.nukiCurve
          }
          Timer { id: settleWait; interval: Motion.nukiHold + (ko.dir > 0 ? plate.index : 5 - plate.index) * 46; onTriggered: settleAnim.start() }
          // Set in on a turn: made for the new month (onCompleted) or kept
          // from the last (turned), whichever Qt does first.
          function enter() { settleAnim.stop(); settle = 0; settleWait.restart() }
          Component.onCompleted: if (ko.entering) plate.enter()
          Connections { target: ko; function onTurned() { plate.enter() } }

          Lame {
            width: parent.width
            marks: plate.modelData.map(function(c) { return { laced: c.inMonth && (c.past || c.today), red: c.today } })
            opacity: 1
          }
          Repeater {
            model: plate.modelData
            Item {
              id: scale
              required property var modelData
              required property int index
              readonly property var c: modelData
              x: index * suit.dayW
              width: suit.dayW
              height: suit.lameH
              opacity: c.inMonth ? 1 : 0.35
              readonly property bool keyStop: true
              readonly property bool keyChosen: c.picked
              function keyPress() { ko.day(scale.c) }
              // A day out of the month: its scales left bare and pale.
              Rectangle { visible: !scale.c.inMonth; width: parent.width; height: Type.px(24); color: Ink.alpha(Ink.paper, 0.5) }
              Row {
                x: Type.px(4)
                y: Type.px(27)
                spacing: Type.px(5)
                Text {
                  text: scale.c.day
                  color: scale.c.today ? Ink.seal : scale.c.picked ? Ink.ink : Ink.inkMuted
                  font.family: Type.mono
                  font.pixelSize: Type.tag
                  font.weight: scale.c.picked ? Font.DemiBold : Font.Normal
                }
                Text {
                  visible: text !== ""
                  text: scale.c.term !== "" ? scale.c.term : scale.c.sky ? scale.c.sky.jp + " " + scale.c.sky.hi : ""
                  color: scale.c.term !== "" ? Ink.ink : Ink.inkFaint
                  font.family: scale.c.term !== "" ? Type.jp : Type.mono
                  font.pixelSize: scale.c.term !== "" ? Type.px(10) : Type.tag
                }
              }
              MoonMark {
                visible: scale.c.moon !== ""
                anchors.right: parent.right
                anchors.rightMargin: Type.px(6)
                y: Type.px(29)
                size: Type.px(8)
                age: scale.c.moon === "full" ? 14.77 : 0
              }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ko.day(scale.c) }
            }
          }
        }
      }
      // The picked day's frame.
      Rectangle {
        readonly property int at: {
          for (var w = 0; w < 6; w++) for (var d = 0; d < 7; d++) if (ko.k.weeks[w][d].picked) return w * 7 + d
          return -1
        }
        visible: at >= 0
        x: (at % 7) * suit.dayW
        y: Math.floor(at / 7) * suit.lameH - Type.px(3)
        width: suit.dayW
        height: suit.lameH - Type.px(4)
        color: "transparent"
        border.width: 1
        border.color: Ink.ink
        Behavior on x { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
        Behavior on y { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
      }
    }

    // ------------------------------------------------ the year and the season
    Item { width: 1; height: Type.px(10) }
    LacedLine {
      label: "年 " + ko.view.y
      marks: ko.k.year.map(function(m) { return { laced: ko.view.y < ko.k.today.getFullYear() || (ko.view.y === ko.k.today.getFullYear() && m.m <= ko.k.today.getMonth()), red: m.current, label: m.jp.replace("月", "") } })
      chosen: ko.view.m
      onPicked: function(i) { ko.month(i) }
    }
    LacedLine {
      label: "節 " + root.leaf.season.name
      marks: {
        var out = []
        for (var i = 0; i < 6; i++) out.push({ laced: i <= root.leaf.sekki.index % 6, red: root.leaf.offset === 0 && i === root.leaf.sekki.index % 6, label: String(i + 1) })
        return out
      }
      chosen: root.leaf.sekki.index % 6
      note: root.leaf.sekki.english + " · day " + root.leaf.sekki.day + " of " + root.leaf.sekki.days
    }
    Item { width: 1; height: Type.px(8) }
    Flow {
      width: parent.width
      spacing: Type.px(22)
      Text { text: root.leaf.ko.jp + "  " + root.leaf.ko.english; color: Ink.inkDim; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(14) }
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

  // A short lame with its label at the left: the year, the season.
  component LacedLine: Item {
    id: ll
    property string label: ""
    property var marks: []
    property int chosen: -1
    property string note: ""
    signal picked(int index)
    readonly property real labelW: Type.px(110)
    readonly property real lameW: ll.note !== "" ? Type.px(200) : column.width - labelW
    width: column.width
    height: Type.px(48)
    Text {
      y: Type.px(5)
      width: ll.labelW
      text: ll.label.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
    Lame {
      id: ln
      x: ll.labelW
      width: ll.lameW
      marks: ll.marks
      onScaleClicked: function(i) { ll.picked(i) }
    }
    Rectangle {
      visible: ll.chosen >= 0
      x: ll.labelW + ll.chosen * ll.lameW / Math.max(1, ll.marks.length)
      y: -Type.px(3)
      width: ll.lameW / Math.max(1, ll.marks.length)
      height: Type.px(44)
      color: "transparent"
      border.width: 1
      border.color: Ink.ink
      Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
    }
    Text {
      visible: ll.note !== ""
      x: ll.labelW + ll.lameW + Type.px(14)
      y: Type.px(5)
      width: ll.width - x
      elide: Text.ElideRight
      text: ll.note
      color: Ink.inkDim
      font.family: Type.text
      font.pixelSize: Type.px(12)
    }
    // The months are stops: Enter turns to one.
    Repeater {
      model: ll.note === "" ? ll.marks.length : 0
      Item {
        id: stop
        required property int index
        x: ll.labelW + stop.index * ll.lameW / Math.max(1, ll.marks.length)
        width: ll.lameW / Math.max(1, ll.marks.length)
        height: Type.px(40)
        readonly property bool keyStop: true
        readonly property bool keyChosen: stop.index === ll.chosen
        function keyPress() { ll.picked(stop.index) }
      }
    }
  }
}
