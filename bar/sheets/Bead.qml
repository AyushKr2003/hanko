import QtQuick
import "../../core"

// One soroban bead (Soroban 算盤): two cones base to base, so a flattened
// hexagon, its ridge where the cones meet (on a wire across the sheet,
// `across`, the hexagon stands on end). Counted, it is filled in its tint;
// not counted, an outline. SorobanHand and SorobanKoyomi count with it.
Canvas {
  property bool counted: false
  property bool across: false
  property color tint: Ink.ink
  width: Type.px(28)
  height: Type.px(12)
  onCountedChanged: requestPaint()
  onTintChanged: requestPaint()
  onPaint: {
    var g = getContext("2d"), w = width, h = height
    g.reset()
    g.beginPath()
    if (across) {
      g.moveTo(w / 2, 0.5); g.lineTo(w - 0.5, h * 0.3); g.lineTo(w - 0.5, h * 0.7)
      g.lineTo(w / 2, h - 0.5); g.lineTo(0.5, h * 0.7); g.lineTo(0.5, h * 0.3)
    } else {
      g.moveTo(0.5, h / 2); g.lineTo(w * 0.3, 0.5); g.lineTo(w * 0.7, 0.5)
      g.lineTo(w - 0.5, h / 2); g.lineTo(w * 0.7, h - 0.5); g.lineTo(w * 0.3, h - 0.5)
    }
    g.closePath()
    if (counted) { g.fillStyle = tint; g.fill() }
    else { g.fillStyle = Ink.alpha(Ink.bone, 0.06); g.fill(); g.strokeStyle = Ink.line; g.lineWidth = 1; g.stroke() }
    // The ridge where the cones meet.
    g.beginPath()
    if (across) { g.moveTo(w / 2, h * 0.12); g.lineTo(w / 2, h * 0.88) }
    else { g.moveTo(w * 0.12, h / 2); g.lineTo(w * 0.88, h / 2) }
    g.strokeStyle = counted ? Ink.alpha(Ink.paper, 0.35) : Ink.lineSoft
    g.stroke()
  }
}
