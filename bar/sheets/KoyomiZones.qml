pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Elsewhen on the almanac (Koyomi 暦): the other cities as a grid of small
// cells, up to five across, so any number of them takes a known height
// (a row of cells for each five) instead of a line each. A cell is the
// city (cut short if it must be), its time and how far it is from yours.
// `hand` sets the type: "ledger" (serif time, as the Ledger's Elsewhen),
// "mono" (the tracked mono of the craft hands and Tanzaku) or "shoji"
// (Shōji's tones). `rows`, when set, keeps to that many rows: the cities
// past it are counted in the last cell.
Item {
  id: root

  property var zones: []
  property string hand: "ledger"
  property int rows: 0
  readonly property int across: Math.max(1, Math.min(5, zones.length))
  readonly property int fit: rows > 0 ? Math.min(zones.length, rows * across) : zones.length
  // The cells shown: when some don't fit, the last one says how many more.
  readonly property var cells: {
    if (fit >= zones.length) return zones
    var out = zones.slice(0, fit - 1)
    out.push({ more: zones.length - fit + 1 })
    return out
  }
  readonly property real cellW: width / across
  readonly property real cellH: Type.px(40)

  implicitHeight: zones.length ? Math.ceil(cells.length / across) * cellH : 0
  height: implicitHeight
  visible: zones.length > 0

  readonly property color nameInk: hand === "shoji" ? Ink.ink2 : Ink.inkDim
  readonly property color timeInk: Ink.ink
  readonly property color noteInk: hand === "shoji" ? Ink.ink3 : Ink.inkMuted

  Repeater {
    model: root.cells
    Item {
      id: cell
      required property var modelData
      required property int index
      readonly property var zone: modelData
      x: (index % root.across) * root.cellW
      y: Math.floor(index / root.across) * root.cellH
      width: root.cellW
      height: root.cellH
      // Hairlines between the cells of a row.
      Rectangle { visible: cell.index % root.across > 0; y: Type.px(6); width: 1; height: root.cellH - Type.px(12); color: Ink.lineSoft }
      Column {
        x: cell.index % root.across > 0 ? Type.px(10) : 0
        anchors.verticalCenter: parent.verticalCenter
        width: root.cellW - x - Type.px(6)
        spacing: Type.px(1)
        Text {
          width: parent.width
          elide: Text.ElideRight
          text: cell.zone.more ? "+" + cell.zone.more + " more" : (root.hand === "mono" ? String(cell.zone.label || "").toUpperCase() : cell.zone.label || "")
          color: root.nameInk
          font.family: root.hand === "mono" ? Type.mono : Type.text
          font.pixelSize: root.hand === "mono" ? Type.tag : Type.px(11.5)
          font.letterSpacing: root.hand === "mono" ? Type.trackTag : 0
        }
        Row {
          visible: !cell.zone.more
          width: parent.width
          spacing: Type.px(6)
          Text {
            id: clockText
            text: cell.zone.time || "—"
            color: cell.zone.ready === false ? Ink.inkFaint : root.timeInk
            font.family: root.hand === "mono" ? Type.mono : Type.display
            font.pixelSize: root.hand === "mono" ? Type.px(13) : Type.px(17)
            font.weight: Font.Normal
            font.variableAxes: root.hand === "mono" ? ({}) : Type.axes(Type.px(17), 400)
            font.features: { "tnum": 1 }
          }
          Text {
            anchors.baseline: clockText.baseline
            width: Math.max(0, parent.width - clockText.width - Type.px(6))
            elide: Text.ElideRight
            text: cell.zone.rel || ""
            color: root.noteInk
            font.family: Type.mono
            font.pixelSize: Type.tag
          }
        }
      }
    }
  }
}
