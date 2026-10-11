pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Status.js" as StatusJs
import "parts" as Parts

// Status 音 and meters 目盛 (docs/COMPONENTS.md):
//   cells     NET 接続 / VOL 音 / BAT 電 label-over-value cells
//   glyphs    a boxed kanji is the icon, the number is the state
//   numerals  mono labels and numbers on one line
//   ink       Shōji's: a line icon and a figure each (Wi-Fi's name and the
//             Bluetooth device's come out when you point at them), the
//             battery an ensō (the Ring part) that closes as it fills;
//             meters don't apply
//   ma        間 three groups held apart by space (links, levels, then the
//             marks): kanji, figure, and a hairline fill under each level
//   shizuka   静 quiet until something changes: network and battery stay;
//             Bluetooth, volume and brightness wait as faint kanji and
//             unfold for two seconds when they move, or while the pointer
//             is on the zone; a reading that needs you stays open, red
//   suji      筋 a kanji and one short brush line each, its length the
//             level, the rest of the range dotted; the figure comes out on
//             reach (pointer, or a change)
//   inro      印籠 one ruled case: a compartment each, kanji over value;
//             the one under the pointer is a bone plate
// ma, shizuka, suji and inro are the right-side studies (docs/right-side);
// meters don't apply to them (shizuka's unfolded reading carries five ticks).
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
  // ink: Shōji's skin, for the ensō; and the reading pointed at by other
  // means than the mouse (the harness), whose name comes out as on reach.
  property var skin: ({})
  property string reachKey: ""

  // name: volume | network | battery | brightness; how: click | middle | right | up | down
  signal action(string name, string how)

  readonly property bool compact: barHeight <= Type.px(32)
  readonly property bool ticksOn: meters === "ticks" && (mode === "cells" || mode === "glyphs" || mode === "numerals")
  // The right-side studies (docs/right-side), which share the cells' order.
  readonly property bool study: mode === "ma" || mode === "shizuka" || mode === "suji" || mode === "inro"
  // shizuka: the pointer is somewhere on the zone, so every reading unfolds.
  readonly property bool pointed: zoneHover.hovered
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
      if (n) out.push({ src: n, key: "network", label: "NET", jp: "波", glyph: "波", value: n.name, unit: "",
                        level: -1, bars: n.kind === "wifi" ? n.bars : -1, needsYou: n.needsYou,
                        brief: StatusJs.short(n.name), fill: StatusJs.fill("network", n), link: true })
    }
    function bt() {
      var b = root.bluetooth
      if (!b) return
      var drawn = root.btStyle === "device" || !b.enabled ? "" : root.btStyle
      out.push({ src: b, key: "bluetooth", label: "BT", jp: "双", glyph: "双", value: b.name, unit: "",
                 level: drawn ? -1 : b.level, bars: -1, needsYou: !!b.needsYou,
                 bt: drawn, devices: b.devices || [], count: b.count || "00",
                 brief: StatusJs.short(b.name), fill: StatusJs.fill("bluetooth", b), link: true })
    }
    function vol() {
      var v = root.volume
      if (v) out.push({ src: v, key: "volume", label: "VOL", jp: "耳", glyph: "耳", value: String(v.percent), unit: "%",
                        level: v.muted ? 0 : v.level, bars: -1, needsYou: v.needsYou,
                        brief: String(v.percent), fill: StatusJs.fill("volume", v), link: false })
    }
    function bri() {
      var b = root.brightness
      if (b) out.push({ src: b, key: "brightness", label: "LUM", jp: "光", glyph: "光", value: String(b.percent), unit: "%",
                        level: b.level, bars: -1, needsYou: false,
                        brief: String(b.percent), fill: StatusJs.fill("brightness", b), link: false })
    }
    function bat() {
      var b = root.battery
      if (b) out.push({ src: b, key: "battery", label: "BAT", jp: b.charging ? "充" : "力", glyph: b.charging ? "充" : "力",
                        value: String(b.percent), unit: "%", level: b.level, bars: -1, needsYou: b.needsYou,
                        brief: String(b.percent), fill: StatusJs.fill("battery", b), link: false })
    }
    if (mode === "cells" || mode === "ink" || study) { net(); bt(); vol(); bri(); bat() }
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

  HoverHandler { id: zoneHover }

  // inro: the case, one hairline frame round every compartment.
  Rectangle {
    visible: root.mode === "inro"
    anchors.verticalCenter: parent.verticalCenter
    width: row.implicitWidth
    height: root.caseHeight
    radius: 2
    color: "transparent"
    border.width: 1
    border.color: Ink.line
  }
  readonly property int caseHeight: Math.round(barHeight - Type.px(compact ? 8 : 9))

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
        // Changed in place, so say so: bindings that look a cell up (the
        // brush pointer) re-run once the cells exist.
        Component.onCompleted: { root._cells[slot.modelData.key] = readingItem; root._cellsChanged() }
        Component.onDestruction: if (root._cells[slot.modelData.key] === readingItem) { delete root._cells[slot.modelData.key]; root._cellsChanged() }

        // Cells are ruled off by hairlines; numerals by a middle dot.
        Item {
          visible: slot.index > 0 && root.mode !== "glyphs" && root.mode !== "ink"
          // Readings are one group, held together by space (proximity), not
          // fenced by lines: the bar's rules are kept for its zones. ma
          // opens a wider pause where the links end and the levels begin.
          readonly property bool groupEnds: slot.index > 0 && !!root.items[slot.index - 1].link && !slot.modelData.link
          width: root.mode === "numerals" ? Type.px(20) : root.mode === "cells" ? Type.px(22)
            : root.mode === "ma" ? (groupEnds ? Type.px(30) : Type.px(16))
            : root.mode === "shizuka" ? Type.px(14)
            : root.mode === "suji" ? Type.px(18)
            : root.mode === "inro" ? 1
            : root.ruled ? Type.px(10) * 2 + 1 : Type.px(14)
          height: parent.height
          // inro: the hairline between two compartments, the case's height.
          Rectangle {
            visible: root.mode === "inro"
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: root.caseHeight
            color: Ink.line
          }
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
    // shizuka holds an unfolded reading open for two seconds.
    Timer { id: settle; interval: root.mode === "shizuka" ? 2000 : 900; onTriggered: reading.fresh = false }
    // shizuka: open (drawn in full) or folded to a faint kanji.
    readonly property bool unfolded: root.mode !== "shizuka" || r.key === "network" || r.key === "battery"
      || !!r.needsYou || fresh || root.pointed || root.reachKey === r.key
    // suji: the figure in place of the line, on reach.
    readonly property bool reached: readingHover.containsMouse || fresh || root.reachKey === r.key
    readonly property bool lit: readingHover.containsMouse || fresh || root.reachKey === r.key
    readonly property color labelInk: lit ? Ink.ink : Ink.inkMuted

    implicitWidth: root.mode === "cells" ? (root.compact ? cellLine.implicitWidth : cell.implicitWidth)
      : root.mode === "glyphs" ? glyphRow.implicitWidth
      : root.mode === "ink" ? inkRow.implicitWidth + Type.px(18)
      : root.mode === "ma" ? maRow.implicitWidth
      : root.mode === "shizuka" ? quiet.implicitWidth
      : root.mode === "suji" ? sujiRow.implicitWidth
      : root.mode === "inro" ? compartment.width
      : numeral.implicitWidth
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
      opacity: readingHover.containsMouse && root.mode !== "inro" ? 1 : 0
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

    // ---- ink: Shōji's icon and figure; names on reach; the battery an ensō
    Row {
      id: inkRow
      visible: root.mode === "ink"
      anchors.centerIn: parent
      spacing: Type.px(7)
      readonly property var s: reading.r.src || ({})
      readonly property bool reach: readingHover.containsMouse || root.reachKey === reading.r.key
      readonly property color tint: reading.r.needsYou ? Ink.seal : reach ? Ink.ink : Ink.ink2
      readonly property bool linked: reading.r.key === "bluetooth" && !!s.enabled && s.connected > 0
      Parts.Icon {
        visible: reading.r.key !== "battery"
        anchors.verticalCenter: parent.verticalCenter
        name: reading.r.key === "network" ? (inkRow.s.off ? "offline" : "wifi")
          : reading.r.key === "bluetooth" ? (inkRow.s.enabled ? "bluetooth" : "bluetoothOff")
          : reading.r.key === "volume" ? (inkRow.s.muted ? "muted" : "volume")
          : "sun"
        level: inkRow.s.bars > 0 ? Math.max(1, Math.min(3, inkRow.s.bars - (inkRow.s.bars > 3 ? 1 : 0))) : 3
        color: reading.r.key === "bluetooth" && !inkRow.linked && !inkRow.reach && !reading.r.needsYou ? Ink.ink3 : inkRow.tint
        size: Type.px(16)
      }
      Parts.Ring {
        visible: reading.r.key === "battery"
        anchors.verticalCenter: parent.verticalCenter
        skin: root.skin
        value: inkRow.s.percent || 0
        size: Type.px(17)
        alert: reading.r.needsYou
        tint: inkRow.reach ? Ink.ink : Ink.ink2
      }
      FadeText {
        visible: reading.r.key === "volume" || reading.r.key === "brightness" || reading.r.key === "battery"
          || (inkRow.linked && inkRow.s.level >= 0)
        anchors.verticalCenter: parent.verticalCenter
        text: reading.r.key === "bluetooth" ? String(Math.round((inkRow.s.level || 0) * 100)) : reading.r.value
        color: inkRow.tint
        font.family: Type.text; font.pixelSize: Type.px(13)
        font.weight: Font.Medium; font.variableAxes: Type.valueAxes
        font.features: { "tnum": 1 }
      }
      Text {
        visible: inkRow.reach && (reading.r.key === "network" || reading.r.key === "bluetooth")
        anchors.verticalCenter: parent.verticalCenter
        text: inkRow.s.name || ""
        color: Ink.ink3
        font.family: Type.text; font.pixelSize: Type.px(13)
      }
      Parts.Icon {
        visible: reading.r.key === "battery" && !!inkRow.s.charging
        anchors.verticalCenter: parent.verticalCenter
        name: "bolt"; color: Ink.ink2; size: Type.px(14)
      }
    }


    // ---- ma: kanji, figure; a hairline fill under each level
    Item {
      id: maRow
      visible: root.mode === "ma"
      anchors.fill: parent
      implicitWidth: maLine.implicitWidth
      Row {
        id: maLine
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: reading.quantity && !reading.r.link && !root.compact ? -Type.px(2) : 0
        spacing: Type.px(6)
        Text {
          anchors.baseline: maValue.baseline
          text: reading.r.glyph
          color: reading.r.needsYou ? Ink.seal : reading.labelInk
          Behavior on color { enabled: Motion.live; ColorAnimation { duration: 200 } }
          font.family: Type.jp
          font.pixelSize: Type.glossMid
        }
        RollText {
          id: maValue
          figure: reading.r.link ? String(reading.r.brief || "") : String(reading.r.value === undefined ? "" : reading.r.value)
          color: reading.valueInk
          font.family: Type.text
          font.pixelSize: Type.value
          font.weight: Type.valueWeight
          font.variableAxes: Type.valueAxes
          font.features: { "tnum": 1 }
        }
        SignalBars {
          anchors.bottom: maValue.baseline
          visible: reading.r.bars >= 0
          lit: reading.r.bars
        }
      }
      // The level as a hairline under the figure: the ink is the reading,
      // the faint rest its range, so ten ticks become one line.
      Rectangle {
        visible: reading.quantity && !reading.r.link && !root.compact
        x: maLine.x + maValue.x
        anchors.top: maLine.bottom
        anchors.topMargin: Type.px(2)
        width: Math.max(maValue.width, Type.px(18))
        height: 2
        color: Ink.lineSoft
        Rectangle {
          width: Math.max(reading.r.fill > 0 ? 2 : 0, Math.round(parent.width * (reading.r.fill || 0)))
          height: parent.height
          color: reading.r.needsYou ? Ink.seal : Ink.ink
          Behavior on width { enabled: Motion.live; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
      }
    }

    // ---- shizuka: the kanji, and the reading unfolded beside it
    Row {
      id: quiet
      visible: root.mode === "shizuka"
      anchors.verticalCenter: parent.verticalCenter
      spacing: 0
      Text {
        id: quietGlyph
        anchors.verticalCenter: parent.verticalCenter
        text: reading.r.glyph
        // Folded, the kanji waits in the faintest ink; open, it is a label.
        color: reading.r.needsYou ? Ink.seal : !reading.unfolded ? Ink.inkFaint : reading.labelInk
        Behavior on color { enabled: Motion.live; ColorAnimation { duration: 200 } }
        font.family: Type.jp
        font.pixelSize: Type.glossMid
      }
      // What unfolds: clipped, so the reading draws out from under its
      // kanji and is drawn back into it.
      Item {
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        height: quietBody.implicitHeight
        width: reading.unfolded ? quietBody.implicitWidth + Type.px(6) : 0
        Behavior on width { enabled: Motion.live; NumberAnimation { duration: reading.unfolded ? 180 : 240; easing.type: Easing.OutCubic } }
        Row {
          id: quietBody
          x: Type.px(6)
          spacing: Type.px(5)
          opacity: reading.unfolded ? 1 : 0
          Behavior on opacity { enabled: Motion.live; NumberAnimation { duration: 160 } }
          RollText {
            id: quietValue
            figure: reading.r.link ? String(reading.r.brief || "") : String(reading.r.value === undefined ? "" : reading.r.value)
            color: reading.valueInk
            font.family: Type.text
            font.pixelSize: Type.value
            font.weight: Type.valueWeight
            font.variableAxes: Type.valueAxes
            font.features: { "tnum": 1 }
          }
          Text {
            visible: reading.r.unit !== ""
            anchors.baseline: quietValue.baseline
            text: reading.r.unit
            color: Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Type.tag
          }
          SignalBars {
            anchors.bottom: quietValue.baseline
            visible: reading.r.bars >= 0
            lit: reading.r.bars
          }
          // A level that moved shows its ruler while it is open, so you see
          // how far the key took it; network and battery, always open, don't.
          Ticks {
            anchors.verticalCenter: quietValue.verticalCenter
            visible: reading.quantity && reading.r.key !== "battery"
            count: 5
            level: reading.r.level
          }
        }
      }
    }

    // ---- suji: a kanji and a brush line as long as the level
    Row {
      id: sujiRow
      visible: root.mode === "suji"
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(7)
      readonly property int lineWidth: Type.px(30)
      readonly property color tint: reading.r.needsYou ? Ink.seal : Ink.ink
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: reading.r.glyph
        color: reading.r.needsYou ? Ink.seal : reading.reached ? Ink.ink : Ink.inkDim
        Behavior on color { enabled: Motion.live; ColorAnimation { duration: 200 } }
        font.family: Type.jp
        font.pixelSize: Type.px(14)
      }
      // The line, or on reach the figure in its place; the slot is as wide
      // as whichever shows, and eases between the two.
      Item {
        anchors.verticalCenter: parent.verticalCenter
        height: Type.px(16)
        width: reading.reached ? Math.max(sujiRow.lineWidth, sujiFigure.implicitWidth) : sujiRow.lineWidth
        Behavior on width { enabled: Motion.live; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Item {
          id: sujiLine
          anchors.verticalCenter: parent.verticalCenter
          width: sujiRow.lineWidth
          height: 3
          opacity: reading.reached ? 0 : 1
          Behavior on opacity { enabled: Motion.live; NumberAnimation { duration: 140 } }
          // The range: a dotted hairline, Tufte's frame drawn only as far
          // as the data can go.
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
              model: Math.floor(sujiRow.lineWidth / 4)
              Rectangle { width: 2; height: 1; color: Ink.inkFaint }
            }
          }
          // The stroke: heavier at its start, like a brush set down.
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(reading.r.fill > 0 ? 3 : 0, Math.round(sujiRow.lineWidth * (reading.r.fill || 0)))
            height: 3
            radius: 1.5
            color: sujiRow.tint
            Behavior on width { enabled: Motion.live; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          }
        }
        Text {
          id: sujiFigure
          anchors.verticalCenter: parent.verticalCenter
          text: reading.r.link ? String(reading.r.brief || "") : String(reading.r.value === undefined ? "" : reading.r.value) + reading.r.unit
          color: sujiRow.tint
          opacity: reading.reached ? 1 : 0
          Behavior on opacity { enabled: Motion.live; NumberAnimation { duration: 140 } }
          font.family: Type.text
          font.pixelSize: Type.px(13)
          font.weight: Type.valueWeight
          font.variableAxes: Type.valueAxes
          font.features: { "tnum": 1 }
        }
      }
    }

    // ---- inro: one compartment of the case, kanji over value
    Rectangle {
      id: compartment
      visible: root.mode === "inro"
      readonly property bool lit: readingHover.containsMouse || root.reachKey === reading.r.key
      readonly property color tint: lit ? Ink.boneInk : reading.r.needsYou ? Ink.seal : Ink.ink
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(inroHead.implicitWidth, inroValue.implicitWidth, Type.px(14)) + Type.px(18)
      height: root.caseHeight - 2
      color: lit ? Ink.bone : "transparent"
      Behavior on color { enabled: Motion.live; ColorAnimation { duration: 120 } }
      Text {
        id: inroHead
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.compact ? 0 : -Type.px(7)
        visible: !root.compact
        text: reading.r.glyph
        color: compartment.lit ? Ink.boneInk : reading.r.needsYou ? Ink.seal : Ink.inkMuted
        font.family: Type.jp
        font.pixelSize: Type.px(10.5)
      }
      // At 32 px the case is one line: the kanji gives way to the value.
      RollText {
        id: inroValue
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.compact ? 0 : Type.px(6)
        figure: reading.r.link ? String(reading.r.brief || "") : String(reading.r.value === undefined ? "" : reading.r.value)
        color: compartment.tint
        font.family: Type.text
        font.pixelSize: Type.px(12)
        font.weight: Type.valueWeight
        font.variableAxes: Type.valueAxes
        font.features: { "tnum": 1 }
      }
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
