pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Time 時 as an almanac in the Soroban hand (Koyomi 暦,
// docs/koyomi/README.md). The picked date is set on the abacus as a clerk
// would set it, year, month and day on their rods, the day lacquered red.
// Under it the month is a tray of six wires, one a week, a bead for each
// day in its weekday's place: the days gone counted (filled), today red,
// the days ahead resting, outlined, with their weather under them; the day
// a solar term starts carries its name above its bead. The picked day is
// ringed. Then the year on one wire of twelve, the season's terms on a
// wire of six and the term's kō on a wire of three, each counted as far
// as we are. A turn of the month is gohasan 御破算, the clearing of the
// abacus: every bead is swept to the wire's far end, then flicked back to
// its day, one after another.
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

  // The date on the rods: 2026 · 10 · 23, a spare rod between.
  readonly property var rods: {
    var parts = [{ n: ko.k.picked.getFullYear(), digits: 4, red: false }, { n: ko.k.picked.getMonth() + 1, digits: 2, red: false },
                 { n: ko.k.picked.getDate(), digits: 2, red: true }]
    var out = []
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) out.push({ spare: true, digit: 0, red: false })
      for (var d = parts[i].digits - 1; d >= 0; d--) out.push({ spare: false, digit: Math.floor(parts[i].n / Math.pow(10, d)) % 10, red: parts[i].red })
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

    Row {
      width: parent.width
      spacing: Type.px(22)

      // ------------------------------------------------ the date, set
      Item {
        id: frame
        readonly property real pad: Type.px(8)
        readonly property real pitch: Type.px(26)
        readonly property real bw: Type.px(22)
        readonly property real bh: Type.px(10)
        readonly property real heaven: pad + bh * 2 + Type.px(3)
        readonly property real beamH: Type.px(4)
        width: root.rods.length * pitch + 2 * pad
        height: heaven + beamH + bh * 5 + Type.px(5) + pad
        Rectangle { anchors.fill: parent; color: Ink.alpha(Ink.bone, 0.03); border.width: Type.px(3); border.color: Ink.lineStrong; radius: 2 }
        Repeater {
          model: root.rods
          Rectangle { required property int index; x: frame.pad + index * frame.pitch + frame.pitch / 2; y: Type.px(3); width: 1; height: frame.height - Type.px(6); color: Ink.line }
        }
        Rectangle {
          x: Type.px(3); y: frame.heaven
          width: frame.width - Type.px(6); height: frame.beamH
          color: Ink.lineStrong
          Repeater {
            model: root.rods
            Rectangle {
              required property var modelData
              required property int index
              visible: modelData.spare
              x: frame.pad - Type.px(3) + index * frame.pitch + frame.pitch / 2 - width / 2
              anchors.verticalCenter: parent.verticalCenter
              width: Type.px(4); height: width; radius: width / 2
              color: Ink.paper
            }
          }
        }
        Repeater {
          model: root.rods
          Item {
            id: rod
            required property var modelData
            required property int index
            readonly property int d: modelData.digit
            readonly property color tint: modelData.red ? Ink.seal : Ink.ink
            visible: !modelData.spare
            x: frame.pad + index * frame.pitch + (frame.pitch - frame.bw) / 2
            width: frame.bw
            height: frame.height
            Bead {
              width: frame.bw; height: frame.bh
              y: rod.d >= 5 ? frame.heaven - frame.bh : frame.pad
              counted: rod.d >= 5; tint: rod.tint
              Behavior on y { enabled: Motion.live; NumberAnimation { duration: Motion.ms(120); easing.type: Easing.OutCubic } }
            }
            Repeater {
              model: 4
              Bead {
                id: e
                required property int index
                width: frame.bw; height: frame.bh
                y: e.index < rod.d % 5 ? frame.heaven + frame.beamH + e.index * frame.bh
                                      : frame.height - frame.pad - (4 - e.index) * frame.bh
                counted: e.index < rod.d % 5; tint: rod.tint
                Behavior on y { enabled: Motion.live; NumberAnimation { duration: Motion.ms(120); easing.type: Easing.OutCubic } }
              }
            }
          }
        }
      }
      Column {
        anchors.verticalCenter: frame.verticalCenter
        spacing: Type.px(4)
        Text { text: root.leaf.weekday + ", " + root.leaf.day + " " + ko.view.name; color: Ink.ink; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(19) }
        Text { text: (ko.view.y + " · " + (ko.view.m + 1) + " · " + root.leaf.day + " — set on the rods").toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        Text { text: root.leaf.when.toUpperCase(); color: root.leaf.offset === 0 ? Ink.seal : Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
      }
    }

    // ------------------------------------------------ the month's tray
    Item { width: 1; height: Type.px(16) }
    Item {
      width: parent.width
      height: Type.px(20)
      Repeater {
        model: ["月", "火", "水", "木", "金", "土", "日"]
        Text {
          required property string modelData
          required property int index
          x: tray.beamW + index * tray.slot
          width: tray.slot
          horizontalAlignment: Text.AlignHCenter
          text: modelData
          color: index >= 5 ? Ink.inkFaint : Ink.inkMuted
          font.family: Type.brush
          font.pixelSize: Type.px(12)
        }
      }
    }
    Item {
      id: tray
      width: parent.width
      readonly property real beamW: Type.px(6)
      readonly property real wireW: width - beamW
      readonly property real slot: wireW / 7
      readonly property real wireH: Type.px(46)
      height: 6 * wireH + Type.px(6)

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(w) { ko.wheel(w.angleDelta.y) }
      }

      Rectangle { anchors.fill: parent; color: Ink.alpha(Ink.bone, 0.025); border.width: Type.px(2); border.color: Ink.lineStrong; radius: 2 }
      // The beam down the left, where a count starts.
      Rectangle { x: Type.px(2); y: Type.px(2); width: tray.beamW; height: tray.height - Type.px(4); color: Ink.lineStrong }

      Repeater {
        model: ko.k.weeks
        Item {
          id: wire
          required property var modelData
          required property int index
          y: Type.px(3) + index * tray.wireH
          width: tray.width
          height: tray.wireH
          Rectangle { x: tray.beamW; y: Type.px(20); width: tray.wireW - Type.px(2); height: 1; color: Ink.line }
          Repeater {
            model: wire.modelData
            Item {
              id: bead
              required property var modelData
              required property int index
              readonly property var c: modelData
              readonly property int order: wire.index * 7 + index
              readonly property real home: tray.beamW + index * tray.slot
              width: tray.slot
              height: tray.wireH
              opacity: c.inMonth ? 1 : 0.32

              readonly property bool keyStop: true
              readonly property bool keyChosen: c.picked
              function keyPress() { ko.day(bead.c) }

              // Gohasan: swept to the far end, then flicked home in turn.
              property real swept: 0
              x: home + swept * (tray.width - home - tray.slot)
              NumberAnimation on swept {
                id: flick
                running: false
                to: 0
                duration: Motion.ms(170)
                easing.type: Easing.OutQuart
              }
              Timer { id: wait; interval: Motion.nukiHold + (ko.dir > 0 ? bead.order : 41 - bead.order) * 11; onTriggered: flick.start() }
              Component.onCompleted: if (ko.entering) { swept = 1; wait.start() }

              // A term starting, beside its bead on the wire; a full or new
              // moon on the other side.
              Text {
                visible: bead.c.term !== ""
                x: parent.width / 2 + Type.px(18)
                y: Type.px(20) - height / 2
                text: bead.c.term
                color: Ink.ink
                font.family: Type.jp
                font.pixelSize: Type.px(10)
              }
              MoonMark {
                visible: bead.c.moon !== ""
                x: parent.width / 2 - Type.px(18) - width
                y: Type.px(20) - height / 2
                size: Type.px(8)
                age: bead.c.moon === "full" ? 14.77 : 0
                tint: Ink.inkDim
                ring: Ink.inkMuted
              }
              // Ringed: the picked day.
              Rectangle {
                visible: bead.c.picked
                anchors.horizontalCenter: parent.horizontalCenter
                y: Type.px(20) - height / 2
                width: Type.px(34); height: Type.px(22); radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: Ink.ink
              }
              Bead {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Type.px(20) - height / 2
                width: Type.px(bead.c.today ? 28 : 24)
                height: Type.px(bead.c.today ? 14 : 12)
                counted: bead.c.past || bead.c.today
                tint: bead.c.today ? Ink.seal : Ink.ink
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Type.px(29)
                text: bead.c.day + (bead.c.sky ? " " + bead.c.sky.jp : "")
                color: bead.c.today ? Ink.seal : bead.c.picked ? Ink.ink : Ink.inkMuted
                font.family: Type.mono
                font.pixelSize: Type.tag
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ko.day(bead.c)
              }
            }
          }
        }
      }
    }

    // ------------------------------------------------ the counts
    Item { width: 1; height: Type.px(16) }
    Wire {
      label: "年 The year · " + ko.view.y
      count: ko.k.year.length
      counted: ko.view.m
      names: ko.k.year.map(function(m) { return m.jp.replace("月", "") })
      red: ko.k.year.findIndex(function(m) { return m.current })
      ring: ko.view.m
      note: ko.view.wafu + " " + ko.view.romaji
      onBeadClicked: function(i) { ko.month(i) }
    }
    Wire {
      label: "節 " + root.leaf.season.name + "'s terms"
      count: 6
      counted: root.leaf.sekki.index % 6
      names: []
      red: root.leaf.offset === 0 ? root.leaf.sekki.index % 6 : -1
      ring: root.leaf.sekki.index % 6
      note: root.leaf.sekki.jp + " " + root.leaf.sekki.romaji + " · " + root.leaf.sekki.english + " · day " + root.leaf.sekki.day + " of " + root.leaf.sekki.days
    }
    Wire {
      label: "候 Its kō"
      count: 3
      counted: (root.leaf.ko.no - 1) % 3
      names: []
      red: root.leaf.offset === 0 ? (root.leaf.ko.no - 1) % 3 : -1
      ring: (root.leaf.ko.no - 1) % 3
      note: root.leaf.ko.jp + " · " + root.leaf.ko.english
    }

    Item { width: 1; height: Type.px(10) }
    Flow {
      width: parent.width
      spacing: Type.px(22)
      Row {
        spacing: Type.px(8)
        MoonMark { anchors.verticalCenter: parent.verticalCenter; size: Type.px(16); age: root.leaf.moon.age }
        Text { anchors.verticalCenter: parent.verticalCenter; text: root.leaf.moon.jp + " · " + root.leaf.moon.name + " · " + Math.round(root.leaf.moon.lit * 100) + "%"; color: Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(12) }
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
          text: modelData.label.toUpperCase() + "  " + modelData.time + "  " + modelData.rel
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
          topPadding: Type.px(3)
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

  // A wire of beads counted from the beam: `counted` of them pushed home,
  // the `red` one lacquered (now), the `ring` one ringed (the picked).
  component Wire: Item {
    id: wr
    property string label: ""
    property int count: 0
    property int counted: 0
    property var names: []
    property int red: -1
    property int ring: -1
    property string note: ""
    signal beadClicked(int index)
    readonly property real labelW: Type.px(150)
    readonly property real beadW: Type.px(24)
    readonly property real wireW: wr.count * (beadW + Type.px(4)) + Type.px(10)
    width: column.width
    height: Type.px(38)
    Text {
      width: wr.labelW
      y: Type.px(4)
      elide: Text.ElideRight
      text: wr.label.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
    Rectangle { x: wr.labelW; y: 0; width: Type.px(4); height: Type.px(22); color: Ink.lineStrong }
    Rectangle { x: wr.labelW + Type.px(4); y: Type.px(11); width: wr.wireW; height: 1; color: Ink.line }
    Repeater {
      model: wr.count
      Item {
        id: wb
        required property int index
        x: wr.labelW + Type.px(8) + wb.index * (wr.beadW + Type.px(4))
        width: wr.beadW
        height: wr.height
        readonly property bool keyStop: wr.names.length > 0
        readonly property bool keyChosen: wb.index === wr.ring
        function keyPress() { wr.beadClicked(wb.index) }
        Rectangle {
          visible: wb.index === wr.ring
          anchors.horizontalCenter: parent.horizontalCenter
          y: Type.px(11) - height / 2
          width: wr.beadW + Type.px(6); height: Type.px(20); radius: height / 2
          color: "transparent"; border.width: 1; border.color: Ink.ink
        }
        Bead {
          across: true
          anchors.horizontalCenter: parent.horizontalCenter
          y: Type.px(11) - height / 2
          width: Type.px(14); height: Type.px(18)
          counted: wb.index <= wr.counted
          tint: wb.index === wr.red ? Ink.seal : Ink.ink
        }
        Text {
          visible: wr.names.length > 0
          anchors.horizontalCenter: parent.horizontalCenter
          y: Type.px(23)
          text: wr.names[wb.index] || ""
          color: wb.index === wr.ring ? Ink.ink : Ink.inkFaint
          font.family: Type.jp
          font.pixelSize: Type.px(9)
        }
        MouseArea { anchors.fill: parent; enabled: wr.names.length > 0; cursorShape: Qt.PointingHandCursor; onClicked: wr.beadClicked(wb.index) }
      }
    }
    Text {
      x: wr.labelW + Type.px(16) + wr.wireW
      y: Type.px(4)
      width: wr.width - x
      elide: Text.ElideRight
      text: wr.note
      color: Ink.inkDim
      font.family: Type.text
      font.pixelSize: Type.px(12)
    }
  }
}
