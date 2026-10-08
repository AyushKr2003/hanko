import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// The seal (Kata part `seal`). At rest it is quiet; when something is for
// you (`on`) it is pressed in vermilion, in every design.
//   outline  Margin: a quiet outline
//   deboss   Leaf: a blind impression, no ink
//   carved   Shōji: an ink outline with a carved, uneven edge
Item {
  id: root

  property var skin: ({})
  property string glyph: "鑑"
  property bool on: false
  property int size: Type.px(24)
  readonly property string kind: skin.seal || "outline"
  readonly property bool rough: kind === "carved"
  readonly property real r: (skin.corner === "cut" || kind === "deboss") ? 0 : Math.round(size * 0.22)

  implicitWidth: size
  implicitHeight: size

  // Pressed in when something arrives: down past flat, then lifted away.
  property real press: 1
  onOnChanged: if (on && Motion.live) pressAnim.restart()
  SequentialAnimation {
    id: pressAnim
    NumberAnimation { target: root; property: "press"; from: 1.3; to: 0.94; duration: Motion.ms(250); easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "press"; to: 1; duration: Motion.ms(210); easing.type: Easing.OutCubic }
  }
  scale: press

  // outline and pressed, smooth-edged
  Rectangle {
    visible: !root.rough && root.kind !== "deboss" || (root.on && !root.rough)
    anchors.fill: parent
    anchors.margins: root.on ? 1 : 2
    radius: root.r
    color: root.on ? Ink.seal : "transparent"
    border.width: root.on ? 0 : 1.5
    border.color: Ink.ink3
    antialiasing: true
  }
  // deboss at rest
  Item {
    visible: root.kind === "deboss" && !root.on
    anchors.fill: parent
    Rectangle { anchors.fill: parent; color: Ink.paper2 }
    Rectangle { width: parent.width; height: 1; color: Ink.shadeIn }
    Rectangle { width: 1; height: parent.height; color: Ink.shadeIn }
    Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.cut }
    Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: Ink.cut }
  }
  // carved: the edge wanders, as cut stone does
  InkShape {
    visible: root.rough
    x: 1.5; y: 1.5
    width: root.size - 3; height: root.size - 3
    path: Brush.rough(root.size - 3, root.size - 3, root.r * 0.6, root.glyph.charCodeAt(0) % 97 + 3, root.size / 30)
    fill: root.on ? Ink.seal : "transparent"
    stroke: root.on ? "transparent" : Ink.ink2
    strokeWidth: root.on ? 0 : 1.5
  }
  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: root.on ? Ink.paper : root.kind === "deboss" ? Ink.ink4 : root.rough ? Ink.ink2 : Ink.ink3
    font.family: Type.jpSerif
    font.weight: Font.DemiBold
    font.pixelSize: Math.round(root.size * 0.54)
  }
}
