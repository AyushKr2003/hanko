pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Time 時 as an almanac in the Shōgi hand (Koyomi 暦,
// docs/koyomi/README.md): the month is the board. Its files are the seven
// weekdays, 月 to 日, written over it where a board writes its numbers; its
// ranks are the six weeks, 一 to 六, down its right side. Today holds the
// king (玉, red: it is you); the day a solar term starts holds a piece
// named for the term, written down it as 飛車 is; the full and new moons
// sit where a board's hoshi dots would. The picked day is framed, and the
// frame slides from square to square. Beside the board, the season as two
// short ranks (the four seasons, then its six terms), each with its piece
// on the square of where we are; under it, the week ahead waits on the
// piece stand as its weather. A turn of the month sets the pieces out one
// by one, in the order a player sets up a board.
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
  readonly property var files: ["月", "火", "水", "木", "金", "土", "日"]
  readonly property var ranks: ["一", "二", "三", "四", "五", "六"]
  readonly property var wide: ["１", "２", "３", "４", "５", "６", "７"]
  // Where the picked day stands, in shogi's own notation: the file counted
  // from the right (日 is １), then the rank.
  readonly property int at: {
    for (var w = 0; w < 6; w++) for (var d = 0; d < 7; d++) if (ko.k.weeks[w][d].picked) return w * 7 + d
    return -1
  }
  readonly property string square: at < 0 ? "" : wide[6 - at % 7] + ranks[Math.floor(at / 7)]
  // The week ahead, for the stand.
  readonly property var ahead: {
    var out = []
    for (var i = 0; i < 7; i++) {
      var d = new Date(ko.k.today.getFullYear(), ko.k.today.getMonth(), ko.k.today.getDate() + i)
      var key = d.getFullYear() + "-" + (d.getMonth() < 9 ? "0" : "") + (d.getMonth() + 1) + "-" + (d.getDate() < 10 ? "0" : "") + d.getDate()
      var s = root.sky && root.sky.days ? root.sky.days[key] : null
      out.push({ kanji: root.files[(d.getDay() + 6) % 7], day: d.getDate(), sky: s || null, offset: i })
    }
    return out
  }

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

    // The hero: the picked day, and its square.
    Row {
      spacing: Type.px(14)
      Text {
        id: big
        text: String(root.leaf.day)
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.hero
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.hero, 340)
      }
      Column {
        anchors.verticalCenter: big.verticalCenter
        Text { text: root.leaf.weekday + ", " + ko.view.name + " " + ko.view.y; color: Ink.ink; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(17) }
        Text {
          text: (root.leaf.when + " · " + (root.leaf.offset === 0 ? "the king on " : "on ") + root.square).toUpperCase()
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
      }
    }
    Item { width: 1; height: Type.px(12) }

    Row {
      id: spread
      width: parent.width
      spacing: Type.px(22)

      // ------------------------------------------------ the board
      Item {
        id: board
        readonly property real cw: Type.px(58)
        readonly property real ch: Type.px(62)
        width: 7 * cw + Type.px(22)
        height: Type.px(18) + 6 * ch

        WheelHandler {
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: function(w) { ko.wheel(w.angleDelta.y) }
        }

        // The files: the weekdays, over the board.
        Repeater {
          model: root.files
          Text {
            required property int index
            required property string modelData
            x: index * board.cw
            width: board.cw
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            color: index >= 5 ? Ink.inkFaint : Ink.inkMuted
            font.family: Type.brush
            font.pixelSize: Type.px(12)
          }
        }
        // The ranks: the weeks, down the right.
        Repeater {
          model: root.ranks
          Text {
            required property int index
            required property string modelData
            x: 7 * board.cw + Type.px(8)
            y: Type.px(18) + index * board.ch + (board.ch - height) / 2
            text: modelData
            color: Ink.inkMuted
            font.family: Type.brush
            font.pixelSize: Type.px(13)
          }
        }

        Rectangle {
          id: grid
          y: Type.px(18)
          width: 7 * board.cw
          height: 6 * board.ch
          color: Ink.alpha(Ink.bone, 0.035)
          border.width: 1
          border.color: Ink.lineStrong
          Repeater {
            model: 6
            Rectangle { required property int index; x: (index + 1) * board.cw; width: 1; height: grid.height; color: Ink.line }
          }
          Repeater {
            model: 5
            Rectangle { required property int index; y: (index + 1) * board.ch; width: grid.width; height: 1; color: Ink.line }
          }

          // The days.
          Repeater {
            model: ko.k.weeks
            Repeater {
              id: rank
              required property var modelData
              required property int index
              readonly property int w: index
              model: modelData
              Item {
                id: sq
                required property var modelData
                required property int index
                readonly property var c: modelData
                readonly property int order: rank.w * 7 + index
                x: index * board.cw
                y: rank.w * board.ch
                width: board.cw
                height: board.ch
                opacity: c.inMonth ? 1 : 0.4

                readonly property bool keyStop: true
                readonly property bool keyChosen: c.picked
                function keyPress() { ko.day(sq.c) }

                // The days gone, washed faintly, as a level's crossed squares are.
                Rectangle {
                  visible: sq.c.past && sq.c.inMonth
                  x: 1; y: 1
                  width: board.cw - 1
                  height: board.ch - 1
                  color: Ink.alpha(Ink.bone, 0.045)
                }
                Text {
                  x: Type.px(5)
                  y: Type.px(4)
                  text: sq.c.day
                  color: sq.c.today ? Ink.seal : sq.c.picked ? Ink.ink : sq.c.past ? Ink.inkFaint : Ink.inkDim
                  font.family: Type.mono
                  font.pixelSize: Type.tag
                }
                MoonMark {
                  visible: sq.c.moon !== ""
                  x: Type.px(5)
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: Type.px(5)
                  size: Type.px(9)
                  age: sq.c.moon === "full" ? 14.77 : 0
                  tint: Ink.inkDim
                  ring: Ink.inkMuted
                }
                Text {
                  visible: !!sq.c.sky
                  anchors.right: parent.right
                  anchors.rightMargin: Type.px(5)
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: Type.px(3)
                  text: sq.c.sky ? sq.c.sky.jp : ""
                  color: Ink.inkMuted
                  font.family: Type.brush
                  font.pixelSize: Type.px(11)
                }
                // The piece: the king today, a term's piece where one starts.
                Koma {
                  id: piece
                  visible: sq.c.today || sq.c.term !== ""
                  anchors.centerIn: parent
                  anchors.verticalCenterOffset: Type.px(1)
                  size: Type.px(sq.c.today ? 30 : 32)
                  glyph: sq.c.today ? "玉" : sq.c.term
                  promoted: sq.c.today
                  faint: sq.c.past && !sq.c.today
                  lifted: hover.containsMouse
                  // Set out one by one on a turn.
                  property real set: 1
                  opacity: set
                  transform: Translate { y: (1 - piece.set) * -Type.px(8) }
                  NumberAnimation on set {
                    id: setAnim
                    running: false
                    from: 0; to: 1
                    duration: Motion.nuki
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.nukiCurve
                  }
                  Timer { id: setDelay; interval: Motion.nukiHold + (ko.dir > 0 ? sq.order : 41 - sq.order) * 9; onTriggered: setAnim.start() }
                  Component.onCompleted: if (ko.entering && visible) { set = 0; setDelay.start() }
                }
                MouseArea {
                  id: hover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: ko.day(sq.c)
                }
              }
            }
          }

          // The picked day's frame, sliding square to square.
          Rectangle {
            visible: root.at >= 0
            x: (root.at % 7) * board.cw + Type.px(2)
            y: Math.floor(root.at / 7) * board.ch + Type.px(2)
            width: board.cw - Type.px(3)
            height: board.ch - Type.px(3)
            color: "transparent"
            border.width: 1
            border.color: Ink.ink
            Behavior on x { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
            Behavior on y { enabled: Motion.live && !ko.entering; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
          }
        }
      }

      // ------------------------------------------------ the season, as ranks
      Column {
        id: side
        width: spread.width - board.width - spread.spacing
        spacing: Type.px(8)

        Text { text: "季 THE SEASON"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag; topPadding: Type.px(2) }
        Rank {
          names: ["春", "夏", "秋", "冬"]
          on: ["spring", "summer", "autumn", "winter"].indexOf(root.leaf.season.key)
          glyph: root.leaf.season.jp
        }
        Text { text: (root.leaf.season.name + " · day " + root.leaf.season.day + " of " + root.leaf.season.days).toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        Item { width: 1; height: Type.px(6) }
        Text { text: "節 ITS TERMS"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        Rank {
          names: ["1", "2", "3", "4", "5", "6"]
          on: root.leaf.sekki.index % 6
          glyph: root.leaf.sekki.jp
        }
        Text { text: root.leaf.sekki.romaji + " · " + root.leaf.sekki.english; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.px(13) }
        Text { text: ("Day " + root.leaf.sekki.day + " of " + root.leaf.sekki.days + " · next " + root.leaf.next.jp + " in " + root.leaf.next.in).toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        Item { width: 1; height: Type.px(6) }
        Rectangle { width: side.width; height: 1; color: Ink.lineSoft }
        Text { width: side.width; wrapMode: Text.WordWrap; text: root.leaf.ko.jp + "  " + root.leaf.ko.english; color: Ink.inkDim; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(14) }
        Row {
          spacing: Type.px(8)
          MoonMark { anchors.verticalCenter: parent.verticalCenter; size: Type.px(16); age: root.leaf.moon.age }
          Text { anchors.verticalCenter: parent.verticalCenter; text: root.leaf.moon.jp + " · " + root.leaf.moon.name; color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(12) }
        }
        Row {
          visible: ko.skyLine !== ""
          spacing: Type.px(8)
          Text { anchors.verticalCenter: parent.verticalCenter; text: ko.skyMark; color: Ink.ink; font.family: Type.brush; font.pixelSize: Type.px(16) }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { text: ko.skyLine; color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(12) }
            Text { width: side.width - Type.px(26); wrapMode: Text.WordWrap; text: ko.skyNote; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(11) }
          }
        }
      }
    }

    // ------------------------------------------------ the piece stand
    Item { width: 1; height: Type.px(16) }
    Row {
      spacing: Type.px(10)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "駒台"; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(13) }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: (root.sky ? "The week ahead · its weather on the stand" : "The week ahead · on the stand").toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
    }
    Item { width: 1; height: Type.px(8) }
    Item {
      id: stand
      width: parent.width
      readonly property real slot: width / 7
      readonly property real piece: Type.px(28)
      height: piece * 1.12 + Type.px(34)
      Rectangle {
        y: stand.piece * 1.12 + Type.px(2)
        width: stand.width
        height: Type.px(5)
        color: Ink.alpha(Ink.bone, 0.10)
        border.width: 1
        border.color: Ink.lineStrong
      }
      Repeater {
        model: root.ahead
        Item {
          id: held
          required property var modelData
          required property int index
          x: index * stand.slot
          width: stand.slot
          height: stand.height
          readonly property bool keyStop: true
          function keyPress() { root.request("pick", held.modelData.offset) }
          Koma {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Type.px(2)
            size: stand.piece
            glyph: held.modelData.sky ? held.modelData.sky.jp : held.modelData.kanji
            promoted: held.index === 0
            faint: !held.modelData.sky
            lifted: standHover.containsMouse
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: stand.piece * 1.12 + Type.px(12)
            text: (held.modelData.kanji + " " + held.modelData.day + (held.modelData.sky ? " · " + held.modelData.sky.hi : "")).toUpperCase()
            color: held.index === 0 ? Ink.ink : Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.letterSpacing: Type.trackTag
          }
          MouseArea { id: standHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.request("pick", held.modelData.offset) }
        }
      }
    }

    Item { width: 1; height: Type.px(8); visible: root.zones.length > 0 }
    Text {
      visible: root.zones.length > 0
      text: root.zones.map(function(z) { return z.label.toUpperCase() + "  " + z.time + "  " + z.rel }).join("     ")
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
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

  // A short rank of squares with one piece on it: where we are.
  component Rank: Item {
    id: rk
    property var names: []
    property int on: 0
    property string glyph: ""
    readonly property real cw: Math.min(Type.px(36), side.width / Math.max(1, names.length))
    width: names.length * cw
    height: cw * 1.08 + Type.px(14)
    Repeater {
      model: rk.names
      Item {
        id: rsq
        required property int index
        required property string modelData
        x: rsq.index * rk.cw
        width: rk.cw
        height: rk.height
        Rectangle {
          width: rk.cw + 1
          height: rk.cw * 1.08
          color: rsq.index < rk.on ? Ink.alpha(Ink.bone, 0.06) : "transparent"
          border.width: 1
          border.color: Ink.line
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: rk.cw * 1.08 + Type.px(2)
          text: rsq.modelData
          color: rsq.index === rk.on ? Ink.ink : Ink.inkFaint
          font.family: /^\d$/.test(rsq.modelData) ? Type.mono : Type.jp
          font.pixelSize: Type.tag
        }
      }
    }
    Koma {
      x: rk.on * rk.cw + (rk.cw - width) / 2
      y: (rk.cw * 1.08 - height) / 2
      size: rk.cw * (rk.glyph.length > 1 ? 0.9 : 0.78)
      glyph: rk.glyph
      Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(Motion.slide); easing.type: Easing.OutCubic } }
    }
  }
}
