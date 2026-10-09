pragma ComponentBehavior: Bound
import QtQuick
import "../../../core"
import "../../../bar/sheets"

// Study: Soroban 算盤, the abacus. Every level is counted out on two rods,
// tens and units: a bead counts when it is pushed to the beam (the heaven
// bead five, each earth bead one). The master's beads are lacquered red.
// Unit dots on the beam part the readings. Click a bead to count to it.
Item {
  id: root
  property var sound: null
  signal request(string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var groups: {
    var r = []
    if (master) r.push({ name: "Master", figure: master.percent, lead: true })
    var s = sound ? sound.streams : []
    for (var i = 0; i < s.length && i < 3; i++) r.push({ name: s[i].label, figure: s[i].muted ? 0 : s[i].percent, muted: s[i].muted })
    return r
  }
  // Rods: two per reading (tens, units), a spare rod between readings.
  readonly property var rods: {
    var r = []
    for (var i = 0; i < groups.length; i++) {
      var f = Math.min(99, Math.round(groups[i].figure))
      if (i > 0) r.push({ spare: true })
      r.push({ digit: Math.floor(f / 10), group: i, lead: !!groups[i].lead, muted: !!groups[i].muted })
      r.push({ digit: f % 10, group: i, lead: !!groups[i].lead, muted: !!groups[i].muted })
    }
    return r
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(16)

    SheetHead { sheet: "sound"; jp: "音"; label: "Sound · Pipewire"; compact: true }
    Item { width: 1; height: Type.px(16) }

    Row {
      spacing: Type.px(10)
      Text {
        text: root.master ? String(root.master.percent) : "—"
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(44)
        font.variableAxes: { "opsz": 72, "wght": 380 }
      }
      Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Type.px(8)
        spacing: Type.px(2)
        Text { text: "through Studio Monitors"; color: Ink.ink; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(16); font.weight: Font.Normal; font.variableAxes: Type.axes(Type.px(16), 360) }
        Text { text: "COUNTED ON THE FIRST TWO RODS"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
      }
    }
    Item { width: 1; height: Type.px(16) }

    // The frame.
    Item {
      id: frame
      readonly property real pitch: Type.px(34)
      readonly property real bw: Type.px(28)
      readonly property real bh: Type.px(12)
      readonly property real pad: Type.px(10)
      readonly property real heaven: pad + bh * 2 + Type.px(4)
      readonly property real beamH: Type.px(5)
      readonly property real earth: bh * 5 + Type.px(6)
      width: root.rods.length * pitch + 2 * pad
      height: heaven + beamH + earth + pad
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.fill: parent
        color: Ink.alpha(Ink.bone, 0.03)
        border.width: Type.px(3)
        border.color: Ink.lineStrong
        radius: 2
      }
      // The rods.
      Repeater {
        model: root.rods
        Rectangle {
          required property int index
          x: frame.pad + index * frame.pitch + frame.pitch / 2
          y: Type.px(3)
          width: 1
          height: frame.height - Type.px(6)
          color: Ink.line
        }
      }
      // The beam, with a unit dot between readings.
      Rectangle {
        x: Type.px(3)
        y: frame.heaven
        width: frame.width - Type.px(6)
        height: frame.beamH
        color: Ink.lineStrong
        Repeater {
          model: root.rods
          Rectangle {
            required property var modelData
            required property int index
            visible: !!modelData.spare
            x: frame.pad - Type.px(3) + index * frame.pitch + frame.pitch / 2 - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Type.px(4); height: width; radius: width / 2
            color: Ink.paper
          }
        }
      }
      // The beads.
      Repeater {
        model: root.rods
        Item {
          id: rod
          required property var modelData
          required property int index
          visible: !modelData.spare
          x: frame.pad + index * frame.pitch + (frame.pitch - frame.bw) / 2
          width: frame.bw
          height: frame.height
          readonly property int d: modelData.digit || 0
          readonly property bool five: d >= 5
          readonly property int ones: d % 5
          readonly property color on: modelData.lead ? Ink.seal : Ink.ink
          // The heaven bead: down on the beam when it counts.
          Bead {
            y: rod.five ? frame.heaven - frame.bh : frame.pad
            counted: rod.five; tint: rod.on
          }
          // The four earth beads: those that count are pushed up.
          Repeater {
            model: 4
            Bead {
              required property int index
              y: index < rod.ones
                ? frame.heaven + frame.beamH + index * frame.bh
                : frame.height - frame.pad - (4 - index) * frame.bh
              counted: index < rod.ones; tint: rod.on
            }
          }
        }
      }
    }

    // The readings under their rods.
    Item {
      width: frame.width
      height: Type.px(40)
      anchors.horizontalCenter: parent.horizontalCenter
      Repeater {
        model: root.groups
        Column {
          required property var modelData
          required property int index
          x: frame.pad + index * 3 * frame.pitch
          width: 2 * frame.pitch
          topPadding: Type.px(8)
          spacing: Type.px(2)
          Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.px(12) }
          Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.muted ? "MUTED" : modelData.figure + "%"; color: modelData.lead ? Ink.seal : Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        }
      }
    }

    Item { width: 1; height: Type.px(10) }
    // Outputs: a single bead each, the playing one counted.
    Row {
      spacing: Type.px(10)
      Text { anchors.verticalCenter: parent.verticalCenter; text: "出"; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(13) }
      Text { anchors.verticalCenter: parent.verticalCenter; text: "OUTPUT"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
    }
    Item { width: 1; height: Type.px(8) }
    Repeater {
      model: root.sound ? root.sound.outputs : []
      Item {
        required property var modelData
        width: column.width
        height: Type.px(26)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(56); height: 1; color: Ink.line }
        Bead {
          x: modelData.current ? Type.px(28) : 0
          anchors.verticalCenter: parent.verticalCenter
          counted: modelData.current; tint: Ink.seal
        }
        Text { x: Type.px(70); anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: modelData.current ? Ink.ink : Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.px(13) }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: modelData.note.toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
      }
    }
  }

  // A soroban bead: two cones base to base, so a flattened hexagon.
  component Bead: Canvas {
    property bool counted: false
    property color tint: Ink.ink
    width: Type.px(28)
    height: Type.px(12)
    onCountedChanged: requestPaint()
    onPaint: {
      var g = getContext("2d"), w = width, h = height
      g.reset()
      g.beginPath()
      g.moveTo(0.5, h / 2)
      g.lineTo(w * 0.3, 0.5)
      g.lineTo(w * 0.7, 0.5)
      g.lineTo(w - 0.5, h / 2)
      g.lineTo(w * 0.7, h - 0.5)
      g.lineTo(w * 0.3, h - 0.5)
      g.closePath()
      if (counted) { g.fillStyle = tint; g.fill() }
      else { g.fillStyle = Ink.alpha(Ink.bone, 0.06); g.fill(); g.strokeStyle = Ink.line; g.lineWidth = 1; g.stroke() }
      // The ridge where the cones meet.
      g.beginPath(); g.moveTo(w * 0.12, h / 2); g.lineTo(w * 0.88, h / 2)
      g.strokeStyle = counted ? Ink.alpha(Ink.paper, 0.35) : Ink.lineSoft
      g.stroke()
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.sound ? root.sound.input : ""
    SheetButton { text: "Mute" }
    SheetButton { ghost: true; text: "Mute mic" }
  }
}
