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
  readonly property var items: {
    var out = []
    function net() {
      var n = root.network
      if (n) out.push({ key: "network", label: "NET", jp: "接続", glyph: "網", value: n.name, unit: "",
                        level: -1, bars: n.kind === "wifi" ? n.bars : -1, needsYou: n.needsYou })
    }
    function bt() {
      var b = root.bluetooth
      if (!b) return
      var drawn = root.btStyle === "device" || !b.enabled ? "" : root.btStyle
      out.push({ key: "bluetooth", label: "BT", jp: "藍", glyph: "藍", value: b.name, unit: "",
                 level: drawn ? -1 : b.level, bars: -1, needsYou: !!b.needsYou,
                 bt: drawn, devices: b.devices || [], count: b.count || "00" })
    }
    function vol() {
      var v = root.volume
      if (v) out.push({ key: "volume", label: "VOL", jp: "音", glyph: "音", value: String(v.percent), unit: "%",
                        level: v.muted ? 0 : v.level, bars: -1, needsYou: v.needsYou })
    }
    function bri() {
      var b = root.brightness
      if (b) out.push({ key: "brightness", label: "LUM", jp: "明", glyph: "明", value: String(b.percent), unit: "%",
                        level: b.level, bars: -1, needsYou: false })
    }
    function bat() {
      var b = root.battery
      if (b) out.push({ key: "battery", label: "BAT", jp: b.charging ? "充" : "電", glyph: b.charging ? "充" : "電",
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
          width: root.mode === "numerals" ? Type.px(20) : root.ruled ? Type.px(10) * 2 + 1 : Type.px(14)
          height: parent.height
          Rectangle {
            visible: root.mode === "cells" && root.ruled
            anchors.horizontalCenter: parent.horizontalCenter
            y: Type.px(10)
            width: 1
            height: parent.height - Type.px(20)
            color: Ink.line
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

    implicitWidth: root.mode === "cells" ? (root.compact ? cellLine.implicitWidth : cell.implicitWidth)
      : root.mode === "glyphs" ? glyphRow.implicitWidth : numeral.implicitWidth
    implicitHeight: root.barHeight

    MouseArea {
      anchors.fill: parent
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
      anchors.verticalCenterOffset: -1
      spacing: 1

      Row {
        spacing: Type.px(6)
        Text {
          text: reading.r.label
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.px(8)
          font.letterSpacing: 1.6
        }
        Text {
          text: reading.r.jp
          color: Ink.inkFaint
          font.family: Type.jp
          font.pixelSize: Type.px(8.5)
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
        font.pixelSize: Type.px(8)
        font.letterSpacing: 1.6
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
          font.pixelSize: Type.px(10.5)
        }
      }
      FadeText {
        anchors.verticalCenter: parent.verticalCenter
        visible: !reading.r.bt
        text: reading.r.value
        color: reading.valueInk
        font.family: Type.text
        font.pixelSize: Type.px(13)
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
        font.pixelSize: Type.px(8.5)
        font.letterSpacing: 1.6
      }
      BtValue { anchors.verticalCenter: parent.verticalCenter; r: reading.r; mono: true }
      FadeText {
        id: num
        visible: !reading.r.bt
        anchors.verticalCenter: parent.verticalCenter
        text: reading.r.value + (reading.r.key === "battery" ? "%" : "")
        color: reading.valueInk
        font.family: Type.mono
        font.pixelSize: Type.px(11)
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
    FadeText {
      id: big
      visible: !value.r.bt
      width: visible ? implicitWidth : 0
      text: value.r.value
      color: value.ink
      font.family: Type.text
      font.pixelSize: Type.px(12.5)
    }
    Text {
      visible: value.r.unit !== ""
      anchors.baseline: big.baseline
      text: value.r.unit
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.px(8)
    }
    Ticks {
      anchors.verticalCenter: big.verticalCenter
      visible: root.ticksOn && value.r.level >= 0
      count: root.tickCount
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
      font.pixelSize: Type.px(9)
    }
    // Nothing connected: a single empty mark, dashed, so the cell keeps its place.
    Text {
      visible: btv.r.bt === "marks" && btv.devs.length === 0
      anchors.verticalCenter: parent.verticalCenter
      text: "—"
      color: Ink.inkFaint
      font.family: Type.text
      font.pixelSize: Type.px(12.5)
    }

    // ---- count
    FadeText {
      visible: btv.r.bt === "count"
      anchors.verticalCenter: parent.verticalCenter
      text: btv.r.count || "00"
      color: btv.r.needsYou ? Ink.seal : btv.devs.length ? Ink.ink : Ink.inkFaint
      font.family: btv.mono ? Type.mono : Type.text
      font.pixelSize: Type.px(btv.mono ? 11 : 12.5)
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
    spacing: 2
    Repeater {
      model: ticks.count
      Rectangle {
        required property int index
        width: 2
        height: Type.px(9)
        color: index < ticks.lit ? Ink.ink : Ink.inkFaint
        opacity: index < ticks.lit ? 1 : 0.7
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
        anchors.bottom: parent.bottom
        width: 3
        height: Type.px(3 + index * 2)
        color: index < sig.lit ? Ink.ink : Ink.inkFaint
      }
    }
  }
}
