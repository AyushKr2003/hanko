pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Status.js" as StatusJs

// Status 音 and meters 目盛 (docs/COMPONENTS.md):
//   cells     NET 接続 / VOL 音 / BAT 電 label-over-value cells
//   glyphs    a boxed kanji is the icon, the number is the state
//   numerals  mono labels and numbers on one line
// meters: ticks puts a ruler beside each quantity (ten in cells, four with
// glyphs, five with numerals) and Wi-Fi bars in cells; off is numbers only.
// The red rule: a reading turns red only when it needs you (muted, low
// battery, offline). Scroll on volume or brightness to change it. Values
// fade through to the next one (FadeText).
Item {
  id: root

  property string mode: "cells"
  property string meters: "ticks"
  property bool ruled: true
  property int barHeight: 40
  // core/Status.js shapes, or null when the machine has no such thing.
  property var volume: null
  property var network: null
  property var battery: null
  property var brightness: null
  // core/Blue.js cell(), or null (no adapter, or bluetooth: off).
  property var bluetooth: null
  // How the BT cell reads (style `bluetooth`): device | marks | count.
  property string btStyle: "device"

  // name: volume | network | battery | brightness; how: click | middle | right | up | down
  signal action(string name, string how)

  readonly property bool compact: barHeight <= Type.px(32)
  readonly property bool ticksOn: meters === "ticks"
  readonly property int tickCount: mode === "cells" ? 10 : mode === "glyphs" ? 4 : 5

  // The readings, in the order each style reads them.
  // The bar's kanji are the plainest that say it, few strokes so they stay
  // clean at gloss size: 波 waves (network), 双 a pair (Bluetooth), 耳 ear (volume),
  // 光 light (brightness), 力 power (battery; 充 while charging). The
  // sheets keep their fuller heads (網, 藍, 音, 電, 明).
  readonly property var items: {
    var out = []
    function net() {
      var n = root.network
      if (n) out.push({ key: "network", label: "NET", jp: "波", glyph: "波", value: n.name, unit: "",
                        level: -1, bars: n.kind === "wifi" ? n.bars : -1, needsYou: n.needsYou })
    }
    function bt() {
      var b = root.bluetooth
      if (!b) return
      var drawn = root.btStyle === "device" || !b.enabled ? "" : root.btStyle
      out.push({ key: "bluetooth", label: "BT", jp: "双", glyph: "双", value: b.name, unit: "",
                 level: drawn ? -1 : b.level, bars: -1, needsYou: !!b.needsYou,
                 bt: drawn, devices: b.devices || [], count: b.count || "00" })
    }
    function vol() {
      var v = root.volume
      if (v) out.push({ key: "volume", label: "VOL", jp: "耳", glyph: "耳", value: String(v.percent), unit: "%",
                        level: v.muted ? 0 : v.level, bars: -1, needsYou: v.needsYou })
    }
    function bri() {
      var b = root.brightness
      if (b) out.push({ key: "brightness", label: "LUM", jp: "光", glyph: "光", value: String(b.percent), unit: "%",
                        level: b.level, bars: -1, needsYou: false })
    }
    function bat() {
      var b = root.battery
      if (b) out.push({ key: "battery", label: "BAT", jp: b.charging ? "充" : "力", glyph: b.charging ? "充" : "力",
                        value: String(b.percent), unit: "%", level: b.level, bars: -1, needsYou: b.needsYou })
    }
    if (mode === "cells") { net(); bt(); vol(); bri(); bat() }
    else { vol(); net(); bt(); bri(); bat() }
    return out
  }

  // The drawn reading for a key (volume, network, ...), for anchoring a
  // sheet under it; null when it isn't showing.
  function cellFor(key) {
    return _cells[key] || null
  }
  // key -> the drawn Reading; kept by the delegates themselves.
  property var _cells: ({})

  visible: items.length > 0
  implicitWidth: visible ? row.implicitWidth : 0
  implicitHeight: barHeight

  Row {
    id: row
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    spacing: root.mode === "glyphs" ? Type.px(14) : 0

    Repeater {
      model: root.items

      Row {
        id: slot
        required property var modelData
        required property int index
        height: row.height
        Component.onCompleted: root._cells[slot.modelData.key] = readingItem
        Component.onDestruction: if (root._cells[slot.modelData.key] === readingItem) delete root._cells[slot.modelData.key]

        // Cells are ruled off by hairlines; numerals by a middle dot.
        Item {
          visible: slot.index > 0 && root.mode !== "glyphs"
          // Readings are one group, held together by space (proximity), not
          // fenced by lines: the bar's rules are kept for its zones.
          width: root.mode === "numerals" ? Type.px(20) : root.mode === "cells" ? Type.px(22) : root.ruled ? Type.px(10) * 2 + 1 : Type.px(14)
          height: parent.height
          Rectangle {
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(parent.height * 0.42)
            color: Ink.alpha(Ink.bone, Ink.light ? 0.16 : 0.13)
          }
          Text {
            visible: root.mode === "numerals"
            anchors.centerIn: parent
            text: "·"
            color: Ink.inkFaint
            font.family: Type.mono
            font.pixelSize: Type.px(11)
          }
        }

        Reading {
          id: readingItem
          anchors.verticalCenter: parent.verticalCenter
          r: slot.modelData
        }
      }
    }
  }

  // ------------------------------------------------------------ one reading
  component Reading: Item {
    id: reading
    property var r: ({})
    readonly property color valueInk: r.needsYou ? Ink.seal : Ink.ink
    readonly property bool quantity: r.level >= 0
    // Lit: under the pointer, or just changed. A changed reading's label
    // inks up for a moment and settles back (show on change, as a game's
    // HUD does), so a glance tells you what moved.
    readonly property string val: String(r.value === undefined ? "" : r.value) + "|" + r.level
    property bool fresh: false
    onValChanged: if (Motion.live) { fresh = true; settle.restart() }
    Timer { id: settle; interval: 900; onTriggered: reading.fresh = false }
    readonly property bool lit: readingHover.containsMouse || fresh
    readonly property color labelInk: lit ? Ink.ink : Ink.inkMuted

    implicitWidth: root.mode === "cells" ? (root.compact ? cellLine.implicitWidth : cell.implicitWidth)
      : root.mode === "glyphs" ? glyphRow.implicitWidth : numeral.implicitWidth
    implicitHeight: root.barHeight

    // Under the pointer a reading sits on a faint plate, so you see which
    // cell a click or a scroll will reach before you make it.
    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: -Type.px(6)
      anchors.rightMargin: -Type.px(6)
      anchors.topMargin: Type.px(5)
      anchors.bottomMargin: Type.px(5)
      radius: 3
      color: Ink.alpha(Ink.bone, readingHover.pressed ? (Ink.light ? 0.12 : 0.1) : (Ink.light ? 0.07 : 0.055))
      opacity: readingHover.containsMouse ? 1 : 0
      Behavior on opacity { enabled: !Motion.still; NumberAnimation { duration: 120 } }
    }

    MouseArea {
      id: readingHover
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        root.action(reading.r.key, mouse.button === Qt.MiddleButton ? "middle" : mouse.button === Qt.RightButton ? "right" : "click")
      }
      onWheel: function(wheel) { root.action(reading.r.key, wheel.angleDelta.y > 0 ? "up" : "down") }
    }

    // ---- cells: label over value
    Column {
      id: cell
      visible: root.mode === "cells" && !root.compact
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: readingHover.pressed ? 0 : -1
      spacing: 1

      Row {
        spacing: Type.px(6)
        Text {
          text: reading.r.label
          color: reading.labelInk
          Behavior on color { enabled: Motion.live; ColorAnimation { duration: 200 } }
          font.family: Type.mono
          font.pixelSize: Type.label
          font.weight: Type.labelWeight
          font.letterSpacing: Type.trackLabel
        }
        Text {
          text: reading.r.jp
          color: reading.labelInk
          Behavior on color { enabled: Motion.live; ColorAnimation { duration: 200 } }
          font.family: Type.jp
          font.pixelSize: Type.gloss
        }
      }
      Value { r: reading.r; ink: reading.valueInk }
    }

    // ---- cells at 32 px: label, then value
    Row {
      id: cellLine
      visible: root.mode === "cells" && root.compact
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(7)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: reading.r.label
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackLabel
      }
      Value { anchors.verticalCenter: parent.verticalCenter; r: reading.r; ink: reading.valueInk }
    }

    // ---- glyphs: boxed kanji, then the state
    Row {
      id: glyphRow
      visible: root.mode === "glyphs"
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(7)

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(17)
        height: width
        radius: 2
        color: reading.r.needsYou ? Ink.seal : "transparent"
        border.width: reading.r.needsYou ? 0 : 1
        border.color: Ink.inkMuted
        Text {
          anchors.centerIn: parent
          anchors.verticalCenterOffset: -0.5
          text: reading.r.glyph
          color: reading.r.needsYou ? Ink.paper : Ink.inkDim
          font.family: Type.jp
          font.pixelSize: Type.glossMid
        }
      }
      FadeText {
        anchors.verticalCenter: parent.verticalCenter
        visible: !reading.r.bt
        text: reading.r.value
        color: reading.valueInk
        font.family: Type.text
        font.pixelSize: Type.value
        font.weight: Type.valueWeight
        font.variableAxes: Type.valueAxes
      }
      BtValue { anchors.verticalCenter: parent.verticalCenter; r: reading.r; boxed: false }
      Ticks {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.ticksOn && reading.quantity
        count: root.tickCount
        level: reading.r.level
      }
    }

    // ---- numerals: VOL 62
    Row {
      id: numeral
      visible: root.mode === "numerals"
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(7)
      Text {
        anchors.baseline: num.baseline
        text: reading.r.label
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackLabel
      }
      BtValue { anchors.verticalCenter: parent.verticalCenter; r: reading.r; mono: true }
      FadeText {
        id: num
        visible: !reading.r.bt
        anchors.verticalCenter: parent.verticalCenter
        text: reading.r.value + (reading.r.key === "battery" ? "%" : "")
        color: reading.valueInk
        font.family: Type.mono
        font.pixelSize: Type.figure
        font.letterSpacing: 0.6
      }
      Ticks {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.ticksOn && reading.quantity
        count: root.tickCount
        level: reading.r.level
      }
    }
  }

  // The value line of a cell: "62 %" with its ruler, or "Kumo" with bars.
  component Value: Row {
    id: value
    property var r: ({})
    property color ink: Ink.ink
    spacing: Type.px(5)
    BtValue { anchors.verticalCenter: big.verticalCenter; r: value.r }
    RollText {
      id: big
      visible: !value.r.bt
      width: visible ? implicitWidth : 0
      figure: String(value.r.value === undefined ? "" : value.r.value)
      color: value.ink
      // Something that needs you (low battery, offline) breathes slowly, so
      // it is told by more than its red: a game's low-health pulse, kept to
      // a slow ebb of the ink, never a flash.
      SequentialAnimation on opacity {
        running: !!value.r.needsYou && Motion.live
        loops: Animation.Infinite
        onRunningChanged: if (!running) big.opacity = 1
        NumberAnimation { to: 0.5; duration: 1100; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
      }
      font.family: Type.text
      font.pixelSize: Type.value
      font.weight: Type.valueWeight
      font.variableAxes: Type.valueAxes
      // Tabular figures: 61 → 62 never nudges the cells after it.
      font.features: { "tnum": 1 }
    }
    Text {
      visible: value.r.unit !== ""
      anchors.baseline: big.baseline
      text: value.r.unit
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
    }
    Ticks {
      anchors.verticalCenter: big.verticalCenter
      visible: root.ticksOn && value.r.level >= 0
      // A device's charge is a side note to its name: half a meter, so the
      // BT cell doesn't outweigh the volume and battery it sits with.
      count: value.r.key === "bluetooth" ? Math.round(root.tickCount / 2) : root.tickCount
      level: value.r.level
    }
    SignalBars {
      anchors.bottom: big.baseline
      visible: root.ticksOn && value.r.bars >= 0
      lit: value.r.bars
    }
  }

  // The BT cell's value when it isn't the device's name (bluetooth: marks
  // or count). marks: one kanji mark per connected device (耳 headphones,
  // 鍵 keyboard, 鼠 mouse, 響 speaker, 話 phone, 遊 controller, 機, 器),
  // boxed in hairline like the glyph style's icons, with its charge drawn
  // as ink filling the box (or, unboxed, a rule under the mark); a device
  // that needs charging is sealed red.
  // count: how many are connected, and a dot for each.
  component BtValue: Row {
    id: btv
    property var r: ({})
    property bool boxed: true
    property bool mono: false
    readonly property var devs: r.devices || []
    readonly property int shownMarks: Math.min(devs.length, 4)
    visible: !!r.bt
    width: visible ? implicitWidth : 0
    spacing: Type.px(r.bt === "count" ? 6 : 5)

    // ---- marks
    Repeater {
      model: btv.r.bt === "marks" ? btv.shownMarks : 0
      Item {
        id: m
        required property int index
        readonly property var d: btv.devs[index]
        // Only the mark counts toward the line's height; its charge hangs
        // below it, so the BT cell keeps the same baseline as its neighbours.
        width: Type.px(btv.boxed ? 15 : 13)
        height: width
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
          id: plate
          width: parent.width
          height: width
          radius: 2
          color: m.d.low ? Ink.seal : "transparent"
          border.width: btv.boxed && !m.d.low ? 1 : 0
          border.color: Ink.inkMuted
          // Boxed, the charge fills the box from the foot like ink in a well.
          Rectangle {
            visible: btv.boxed && !m.d.low && m.d.level >= 0
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: Math.round((parent.height - 2) * Math.max(0, m.d.level))
            radius: 1
            color: Ink.alpha(Ink.ink, 0.2)
          }
          Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -0.5
            text: m.d.mark
            color: m.d.low ? Ink.paper : btv.boxed ? Ink.inkDim : Ink.ink
            font.family: Type.jp
            font.pixelSize: Type.px(btv.boxed ? 9.5 : 11.5)
          }
        }
        // Unboxed, the charge is a rule under the mark, inked to the level.
        Rectangle {
          visible: !btv.boxed && m.d.level >= 0
          anchors.top: plate.bottom
          anchors.topMargin: Type.px(2)
          width: plate.width
          height: 2
          color: Ink.lineSoft
          Rectangle {
            width: Math.max(2, Math.round(parent.width * m.d.level))
            height: parent.height
            color: m.d.low ? Ink.seal : Ink.ink
          }
        }
      }
    }
    Text {
      visible: btv.r.bt === "marks" && btv.devs.length > btv.shownMarks
      anchors.verticalCenter: parent.verticalCenter
      text: "+" + (btv.devs.length - btv.shownMarks)
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
    }
    // Nothing connected: a single empty mark, dashed, so the cell keeps its place.
    Text {
      visible: btv.r.bt === "marks" && btv.devs.length === 0
      anchors.verticalCenter: parent.verticalCenter
      text: "—"
      color: Ink.inkFaint
      font.family: Type.text
      font.pixelSize: Type.value
    }

    // ---- count
    FadeText {
      visible: btv.r.bt === "count"
      anchors.verticalCenter: parent.verticalCenter
      text: btv.r.count || "00"
      color: btv.r.needsYou ? Ink.seal : btv.devs.length ? Ink.ink : Ink.inkFaint
      font.family: btv.mono ? Type.mono : Type.text
      font.pixelSize: btv.mono ? Type.figure : Type.value
      font.letterSpacing: 0.6
    }
    Row {
      visible: btv.r.bt === "count" && btv.devs.length > 0
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(3)
      Repeater {
        model: btv.r.bt === "count" ? Math.min(btv.devs.length, 6) : 0
        Rectangle {
          required property int index
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(4)
          height: width
          radius: width / 2
          color: btv.devs[index].low ? Ink.seal : Ink.ink
        }
      }
    }
  }

  // A ruler of thin ticks, lit from the left.
  component Ticks: Row {
    id: ticks
    property int count: 10
    property real level: 0
    readonly property int lit: StatusJs.ticks(level, count)
    // Where the last fill ended, so the cascade starts from there.
    property int from: 0
    onLitChanged: Qt.callLater(function() { ticks.from = ticks.lit })
    spacing: 2
    Repeater {
      model: ticks.count
      Rectangle {
        id: tick
        required property int index
        width: 2
        height: Type.px(9)
        color: index < ticks.lit ? Ink.ink : Ink.inkFaint
        opacity: index < ticks.lit ? 1 : 0.7
        // A meter fills (or drains) tick by tick, like a game's gauge,
        // the nearest tick first; the whole run stays under 240 ms.
        Behavior on color {
          enabled: Motion.live
          SequentialAnimation {
            PauseAnimation { duration: Math.min(150, 15 * Math.abs(tick.index - ticks.from)) }
            ColorAnimation { duration: 80 }
          }
        }
      }
    }
  }

  // Four rising Wi-Fi bars.
  component SignalBars: Row {
    id: sig
    property int lit: 0
    spacing: 2
    Repeater {
      model: 4
      Rectangle {
        required property int index
        // Bottom-aligned by y, not anchors: a Repeater's delegate has no
        // parent yet when its anchors are first read (a warning per bar).
        y: Type.px(9) - height
        width: 3
        height: Type.px(3 + index * 2)
        color: index < sig.lit ? Ink.ink : Ink.inkFaint
      }
    }
  }
}
