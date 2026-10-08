pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// A slider drawn as a ruler with one needle (never a progress pill): 41
// ticks, every tenth taller, the ticks up to the value inked, and a needle
// at the value, red for the master, ink for everything else. Click or drag
// to set it, scroll to step it.
Item {
  id: root

  // 0..1
  property real value: 0
  property bool red: false
  // Drawn dashed and faint: the channel is muted.
  property bool muted: false
  property real step: 0.05

  // A new value the user asked for (the owner applies it).
  signal moved(real value)

  implicitWidth: Type.px(200)
  implicitHeight: Type.px(26)

  readonly property real v: Math.max(0, Math.min(1, value))

  Repeater {
    model: 41
    Rectangle {
      id: tick
      required property int index
      readonly property bool major: index % 10 === 0
      x: Math.round(index / 40 * (root.width - 1))
      y: root.height - Type.px(4) - height
      width: 1
      height: major ? Type.px(12) : Type.px(6)
      color: index / 40 <= root.v && !root.muted ? Ink.ink : major ? Ink.lineStrong : Ink.line
      opacity: root.muted && index % 2 === 1 ? 0 : 1
    }
  }

  // The needle, capped with a small head like a gauge's pointer, standing
  // on a short base line so it reads as set into the ruler, not laid on it.
  Item {
    id: needle
    x: Math.round(root.v * (root.width - 1)) - Type.px(3)
    y: root.height - height
    width: Type.px(3) * 2 + 1
    height: Type.px(22)
    Behavior on x { enabled: !Motion.still && !drag.pressed; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    readonly property color tone: root.red ? Ink.seal : root.muted ? Ink.inkMuted : Ink.ink
    Rectangle {
      x: Type.px(3) - 1
      width: 3
      height: parent.height
      color: needle.tone
    }
    Rectangle {
      width: parent.width
      height: Type.px(3)
      radius: 1
      color: needle.tone
    }
  }

  MouseArea {
    id: drag
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    function at(x) { return Math.max(0, Math.min(1, x / Math.max(1, root.width - 1))) }
    onPressed: function(mouse) { root.moved(at(mouse.x)) }
    onPositionChanged: function(mouse) { if (pressed) root.moved(at(mouse.x)) }
    onWheel: function(wheel) {
      root.moved(Math.max(0, Math.min(1, root.v + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
    }
  }
}
