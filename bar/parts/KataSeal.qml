import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// The seal (Kata part `seal`): Shōji's carved seal, an ink outline whose
// edge wanders as cut stone does. At rest it is quiet; when something is
// for you (`on`) it is pressed in vermilion.
Item {
  id: root

  property var skin: ({})
  property string glyph: "鑑"
  property bool on: false
  property int size: Type.px(24)

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

  InkShape {
    x: 1.5; y: 1.5
    width: root.size - 3; height: root.size - 3
    path: Brush.rough(root.size - 3, root.size - 3, 0, root.glyph.charCodeAt(0) % 97 + 3, root.size / 30)
    fill: root.on ? Ink.seal : "transparent"
    stroke: root.on ? "transparent" : Ink.ink2
    strokeWidth: root.on ? 0 : 1.5
  }
  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: root.on ? Ink.paper : Ink.ink2
    font.family: Type.jpSerif
    font.weight: Font.DemiBold
    font.pixelSize: Math.round(root.size * 0.54)
  }
}
