pragma ComponentBehavior: Bound
import QtQuick
import "../../../core"
import "../../../bar/sheets"

// Study: Kasumi 霞, the mist bands of a picture scroll. In Yamato-e and on
// gold screens, long flat bands of stylised mist (suyari-gasumi) part one
// scene from the next. Here every choice is such a band of gold leaf,
// drawn as far across the sheet as its level, drifting in from alternate
// sides as mist does in an emaki. The output in use is gilded whole and
// carries a small red seal; a muted band is only its outline.
Item {
  id: root
  property var sound: null
  signal request(string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var bands: {
    var r = []
    var o = sound ? sound.outputs : []
    for (var i = 0; i < o.length && i < 3; i++) r.push({ name: o[i].label, note: o[i].note, level: o[i].current ? 1 : 0.34, gilt: o[i].current, sealed: o[i].current })
    var s = sound ? sound.streams : []
    for (var j = 0; j < s.length && j < 3; j++) r.push({ name: s[j].label, note: s[j].muted ? "muted" : s[j].percent + "%", level: s[j].level, gilt: !s[j].muted })
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
    Item { width: 1; height: Type.px(10) }

    // The scene: the master, with its kanji set large like a title slip.
    Item {
      width: parent.width
      height: Type.px(96)
      Text {
        anchors.right: parent.right
        anchors.rightMargin: Type.px(6)
        y: Type.px(4)
        text: "音"
        color: Ink.alpha(Ink.bone, 0.9)
        font.family: Type.brush
        font.pixelSize: Type.px(64)
      }
      Column {
        y: Type.px(10)
        spacing: Type.px(2)
        Row {
          spacing: Type.px(4)
          Text { text: root.master ? String(root.master.percent) : "—"; color: Ink.ink; font.family: Type.display; font.pixelSize: Type.px(44); font.variableAxes: { "opsz": 72, "wght": 380 } }
          Text { y: Type.px(8); text: "%"; color: Ink.inkMuted; font.family: Type.display; font.pixelSize: Type.px(16) }
        }
        Text { text: "through Studio Monitors"; color: Ink.ink; font.family: Type.display; font.italic: true; font.pixelSize: Type.px(16); font.weight: Font.Normal; font.variableAxes: Type.axes(Type.px(16), 360) }
      }
    }
    Band { width: parent.width; level: root.master ? root.master.level : 0; gilt: true; lead: true; name: "Master"; note: root.master ? root.master.percent + "%" : "" }
    Item { width: 1; height: Type.px(14) }

    Repeater {
      model: root.bands
      Band {
        required property var modelData
        required property int index
        width: column.width
        fromRight: index % 2 === 0
        level: modelData.level
        gilt: modelData.gilt
        sealed: !!modelData.sealed
        name: modelData.name
        note: modelData.note
      }
    }
  }

  // One band of mist: a long flat cloud with stepped, rounded ends.
  component Band: Item {
    id: band
    property real level: 0
    property bool gilt: true
    property bool lead: false
    property bool sealed: false
    property bool fromRight: false
    property string name: ""
    property string note: ""
    readonly property real len: Math.max(Type.px(70), width * Math.max(0, Math.min(1, level)))
    height: Type.px(lead ? 40 : 34)

    Canvas {
      id: mist
      x: band.fromRight ? band.width - width : 0
      width: band.len
      height: band.height - Type.px(4)
      onWidthChanged: requestPaint()
      onPaint: {
        var g = getContext("2d"), L = width, H = height
        g.reset()
        function cap(x0, y0, x1, h) {
          var r = h / 2
          g.moveTo(x0 + r, y0)
          g.lineTo(x1 - r, y0)
          g.arc(x1 - r, y0 + r, r, -Math.PI / 2, Math.PI / 2, false)
          g.lineTo(x0 + r, y0 + h)
          g.arc(x0 + r, y0 + r, r, Math.PI / 2, Math.PI * 1.5, false)
        }
        g.beginPath()
        var h = H * 0.52
        // The body, and a lip above and below, set in from the ends.
        cap(0, H * 0.24, L, h)
        g.closePath()
        g.moveTo(0, 0)
        cap(band.fromRight ? L * 0.16 : L * 0.08, 0, band.fromRight ? L * 0.92 : L * 0.78, H * 0.46)
        g.closePath()
        cap(band.fromRight ? L * 0.04 : L * 0.22, H * 0.54, band.fromRight ? L * 0.7 : L * 0.96, H * 0.46)
        g.closePath()
        if (band.gilt) {
          g.fillStyle = band.lead ? Ink.alpha(Ink.bone, 0.90) : Ink.alpha(Ink.bone, 0.62)
          g.fill()
          // Leaf squares: the faint seams of gold leaf laid edge to edge.
          g.save(); g.clip()
          g.strokeStyle = Ink.alpha(Ink.boneInk, 0.07); g.lineWidth = 1
          for (var x = Type.px(22); x < L; x += Type.px(22)) { g.beginPath(); g.moveTo(x, 0); g.lineTo(x, H); g.stroke() }
          g.restore()
        } else {
          g.setLineDash([3, 3]); g.strokeStyle = Ink.lineStrong; g.lineWidth = 1; g.stroke()
        }
      }
    }
    Text {
      x: band.fromRight ? mist.x + Type.px(18) : Type.px(18)
      anchors.verticalCenter: mist.verticalCenter
      text: band.name
      color: band.gilt ? Ink.boneInk : Ink.inkMuted
      font.family: Type.display
      font.italic: true
      font.pixelSize: Type.px(band.lead ? 17 : 15)
      font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(band.lead ? 17 : 15), 380)
    }
    Text {
      x: band.fromRight ? mist.x - width - Type.px(10) : mist.x + mist.width + Type.px(10)
      visible: band.len < band.width - Type.px(60)
      anchors.verticalCenter: mist.verticalCenter
      text: String(band.note).toUpperCase()
      color: band.lead || band.sealed ? Ink.seal : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
    // A band across the whole sheet keeps its note inside its far end.
    Text {
      visible: band.len >= band.width - Type.px(60)
      x: mist.x + mist.width - width - Type.px(band.sealed || band.lead ? 40 : 18)
      anchors.verticalCenter: mist.verticalCenter
      text: String(band.note).toUpperCase()
      color: Ink.alpha(Ink.boneInk, 0.7)
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
    // The seal pressed on the band in use.
    Rectangle {
      visible: band.sealed || band.lead
      x: band.fromRight ? mist.x + mist.width - width - Type.px(16) : mist.x + mist.width - width - Type.px(16)
      anchors.verticalCenter: mist.verticalCenter
      width: Type.px(14); height: width; radius: 1
      color: Ink.seal
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
