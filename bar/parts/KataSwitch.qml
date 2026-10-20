import QtQuick
import "../../core"

// On or off: a square on Shōji's cut corners, framed on the washi. The knob
// slides on the skin's tempo.
Item {
  id: root

  property var skin: ({})
  property bool on: false
  signal toggled(bool on)

  // Te 手 (core/Cursor.js): Enter or Space flips it.
  readonly property bool keyStop: true
  function keyPress() { root.toggled(!root.on) }

  implicitWidth: Type.px(34)
  implicitHeight: Type.px(20)

  Rectangle {
    anchors.fill: parent
    color: root.on ? Ink.ink : "transparent"
    border.width: root.on ? 0 : 1
    border.color: Ink.ink4
  }
  Rectangle {
    readonly property real pad: Type.px(3)
    x: root.on ? root.width - width - pad : pad
    y: pad
    width: root.height - 2 * pad; height: width
    color: root.on ? Ink.paper : Ink.ink2
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(root.skin.open || 200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] } }
  }
  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled(!root.on) }
}
