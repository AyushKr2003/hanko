pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Brush.js" as Brush

// A button that asks you to hold it instead of asking "are you sure?"
// (Kata part `hold`). While you hold (600 ms) the seal's red comes in, and
// drains if you let go:
//   soak    Leaf (and Margin): the red soaks across the button like ink in paper
//   stroke  Shōji: a brush stroke is drawn under the label, left to right
// With `hold` off it is a plain button that fires on a click.
Item {
  id: root

  property var skin: ({})
  property string label: ""
  property bool hold: true
  // Harness: show the press part-way.
  property real progress: 0
  signal fired()

  readonly property string kind: skin.hold || "soak"
  property real soak: progress
  readonly property color tone: hold ? Ink.seal : Ink.ink2

  implicitWidth: Type.px(90)
  implicitHeight: Type.px(56)

  NumberAnimation on soak { id: fill; running: false; to: 1; duration: Motion.ms(600) }
  NumberAnimation on soak { id: drain; running: false; to: 0; duration: Motion.ms(200) }
  onSoakChanged: if (soak >= 1 && area.pressed) { fill.stop(); soak = 0; root.fired() }

  Rectangle {
    anchors.fill: parent
    radius: root.skin.radiusChip || 0
    color: "transparent"
    border.width: 1; border.color: root.hold ? Ink.alpha(Ink.seal, 0.45) : Ink.kLine
    clip: true
    Rectangle {
      visible: root.kind === "soak"
      width: parent.width * root.soak; height: parent.height
      color: Ink.alpha(Ink.seal, 0.2)
    }
  }
  // stroke: the brush drawn as far as the hold has come
  Item {
    visible: root.kind === "stroke" && root.soak > 0
    x: Type.px(12); y: parent.height - Type.px(15)
    width: (parent.width - Type.px(24)) * root.soak; height: Type.px(7)
    clip: true
    InkShape {
      width: root.width - Type.px(24); height: Type.px(7)
      path: Brush.stroke(width, height, 7)
      fill: Ink.alpha(Ink.seal, 0.75)
    }
  }
  Text {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: root.kind === "stroke" ? -Type.px(3) : 0
    text: root.label
    color: root.tone
    font.family: Type.text; font.pixelSize: Type.px(12.5)
  }
  MouseArea {
    id: area
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onPressed: if (root.hold) { drain.stop(); fill.start() }
    onReleased: if (root.hold) { fill.stop(); drain.start() }
    onClicked: if (!root.hold) root.fired()
  }
}
