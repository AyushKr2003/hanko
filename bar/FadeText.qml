import QtQuick
import "../core"

// A value that fades through to the next one instead of snapping
// (Motion.fade): half the time down to a trace, the new text, half back.
Text {
  id: root
  Behavior on text {
    enabled: Motion.live
    SequentialAnimation {
      NumberAnimation { target: root; property: "opacity"; to: 0.2; duration: Motion.fade / 2; easing.type: Easing.InQuad }
      PropertyAction {}
      NumberAnimation { target: root; property: "opacity"; to: 1; duration: Motion.fade / 2; easing.type: Easing.OutQuad }
    }
  }
}
