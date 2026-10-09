pragma ComponentBehavior: Bound
import QtQuick
import "../../../core"
import "../../../bar/sheets"

// Study: Odoshi 縅, armour lacing. The sheet hangs like the sode of a
// great armour: a crown plate (kanmuri-ita) carrying the master, then a
// lame of small scales (kozane) for each choice. A level is how far the
// lame is laced: densely in scarlet silk (kebiki, hi-odoshi) as far as the
// level, sparsely beyond (sugake). The output in use is laced in full and
// cross-stitched along its foot (hishinui), as an armour's last plate is.
Item {
  id: root
  property var sound: null
  signal request(string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var lames: {
    var r = []
    var o = sound ? sound.outputs : []
    for (var i = 0; i < o.length && i < 3; i++) r.push({ name: o[i].label, note: o[i].note, level: o[i].current ? 1 : 0, live: o[i].current, kind: "出" })
    var s = sound ? sound.streams : []
    for (var j = 0; j < s.length && j < 3; j++) r.push({ name: s[j].label, note: s[j].muted ? "muted" : s[j].percent + "%", level: s[j].muted ? 0 : s[j].level, kind: "奏" })
    return r
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(18)

    SheetHead { sheet: "sound"; jp: "音"; label: "Sound · Pipewire"; compact: true }
    Item { width: 1; height: Type.px(16) }

    // The crown plate: the master, its own lame laced under it.
    Rectangle {
      width: parent.width
      height: Type.px(70)
      radius: Type.px(3)
      color: Ink.alpha(Ink.bone, 0.05)
      border.width: 1
      border.color: Ink.lineStrong
      // The plate's printed-leather border (egawa): a fine inner rule.
      Rectangle { anchors.fill: parent; anchors.margins: Type.px(4); color: "transparent"; border.width: 1; border.color: Ink.lineSoft; radius: 2 }
      Text {
        x: Type.px(16)
        anchors.verticalCenter: parent.verticalCenter
        text: "音"
        color: Ink.seal
        font.family: Type.brush
        font.pixelSize: Type.px(34)
      }
      Text {
        x: Type.px(62)
        anchors.verticalCenter: parent.verticalCenter
        text: root.master ? String(root.master.percent) : "—"
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(40)
        font.variableAxes: { "opsz": 72, "wght": 380 }
      }
      Column {
        x: Type.px(124)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(2)
        Text { text: "through Studio Monitors"; color: Ink.ink; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(16); font.weight: Font.Normal; font.variableAxes: Type.axes(Type.px(16), 360) }
        Text { text: "MASTER · LACED TO THE LEVEL"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
      }
    }
    Lame { width: parent.width; level: root.master ? root.master.level : 0; lead: true }
    Item { width: 1; height: Type.px(14) }

    Repeater {
      model: root.lames
      Column {
        id: row
        required property var modelData
        width: column.width
        spacing: Type.px(4)
        Item {
          width: parent.width
          height: Type.px(16)
          Row {
            spacing: Type.px(8)
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.verticalCenter: parent.verticalCenter; text: row.modelData.kind; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(12) }
            Text { anchors.verticalCenter: parent.verticalCenter; text: row.modelData.name; color: row.modelData.live ? Ink.ink : Ink.inkDim; font.family: Type.text; font.pixelSize: Type.px(13) }
          }
          Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: String(row.modelData.note).toUpperCase(); color: row.modelData.live ? Ink.seal : Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
        }
        Lame { width: parent.width; level: row.modelData.level; stitched: !!row.modelData.live; tint: row.modelData.live ? Ink.ink : Ink.seal }
        Item { width: 1; height: Type.px(6) }
      }
    }
  }

  // One lame: a row of small scales, laced as far as its level.
  component Lame: Canvas {
    property real level: 0
    property bool lead: false
    property bool stitched: false
    property color tint: Ink.seal
    height: Type.px(stitched ? 30 : 24)
    onLevelChanged: requestPaint()
    onPaint: {
      var g = getContext("2d"), W = width, H = Type.px(24)
      g.reset()
      var n = Math.max(12, Math.round(W / Type.px(19)))
      var w = W / n, laced = Math.round(Math.max(0, Math.min(1, level)) * n)
      for (var i = 0; i < n; i++) {
        var x = i * w
        // The scale: lacquered, its top rounded off.
        g.fillStyle = Ink.alpha(Ink.bone, 0.07)
        g.strokeStyle = Ink.lineSoft
        g.lineWidth = 1
        g.beginPath()
        g.moveTo(x + 1, H - 0.5)
        g.lineTo(x + 1, 3)
        g.quadraticCurveTo(x + w / 2, -1, x + w - 1, 3)
        g.lineTo(x + w - 1, H - 0.5)
        g.closePath()
        g.fill(); g.stroke()
        if (i < laced) {
          // Kebiki: the cord covers the scale in two close bands.
          var cw = (w - 4) / 2
          g.fillStyle = tint
          g.fillRect(x + 2, 0, cw - 0.5, H * 0.72)
          g.fillRect(x + 2 + cw + 0.5, 0, cw - 0.5, H * 0.72)
          // The twist of the braid: fine ticks across it.
          g.strokeStyle = Ink.alpha(Ink.paper, 0.18)
          for (var t = 3; t < H * 0.72; t += 4) {
            g.beginPath(); g.moveTo(x + 2, t + 1.5); g.lineTo(x + 2 + cw - 0.5, t); g.stroke()
            g.beginPath(); g.moveTo(x + 2 + cw + 0.5, t); g.lineTo(x + w - 2, t + 1.5); g.stroke()
          }
        } else {
          // Sugake: bare scale, its two lacing holes, a pair of cords every third.
          g.fillStyle = Ink.inkFaint
          g.fillRect(x + w / 2 - 2.5, H * 0.3, 1.5, 1.5)
          g.fillRect(x + w / 2 + 1, H * 0.3, 1.5, 1.5)
          if (i % 3 === 0) {
            g.fillStyle = Ink.alpha(tint, 0.35)
            g.fillRect(x + w / 2 - 2, 0, 1, H * 0.72)
            g.fillRect(x + w / 2 + 1, 0, 1, H * 0.72)
          }
        }
      }
      if (stitched) {
        // Hishinui: red cross-knots along the foot.
        g.strokeStyle = Ink.seal
        g.lineWidth = 1.5
        for (var k = 0; k < n; k += 1) {
          var cx = k * w + w / 2, cy = H + 3
          g.beginPath(); g.moveTo(cx - 3, cy - 3); g.lineTo(cx + 3, cy + 3); g.stroke()
          g.beginPath(); g.moveTo(cx + 3, cy - 3); g.lineTo(cx - 3, cy + 3); g.stroke()
        }
      }
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
