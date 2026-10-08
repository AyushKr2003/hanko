import QtQuick
import "../../core"

// Concave corners where a fold-out panel (Margin) meets the bar, carrying
// the bar's hairline round them, so bar and panel read as one sheet. Put it
// over the panel's top edge, as wide as the panel.
Item {
  id: root

  property real r: Type.px(14)
  height: r

  InkShape {
    x: -root.r; width: root.r; height: root.r
    path: "M 0 0 L " + root.r + " 0 L " + root.r + " " + root.r + " A " + root.r + " " + root.r + " 0 0 0 0 0 Z"
    fill: Ink.paper
  }
  InkShape {
    x: -root.r; width: root.r; height: root.r
    path: "M " + root.r + " " + root.r + " A " + root.r + " " + root.r + " 0 0 0 0 0"
    stroke: Ink.kLine; strokeWidth: 1; fill: "transparent"
  }
  InkShape {
    x: root.width; width: root.r; height: root.r
    path: "M " + root.r + " 0 L 0 0 L 0 " + root.r + " A " + root.r + " " + root.r + " 0 0 1 " + root.r + " 0 Z"
    fill: Ink.paper
  }
  InkShape {
    x: root.width; width: root.r; height: root.r
    path: "M 0 " + root.r + " A " + root.r + " " + root.r + " 0 0 1 " + root.r + " 0"
    stroke: Ink.kLine; strokeWidth: 1; fill: "transparent"
  }
}
