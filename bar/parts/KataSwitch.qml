import QtQuick
import "../../core"

// On or off: a pill on soft corners (Margin), a square on cut ones (Leaf,
// Shōji). The knob slides on the skin's tempo.
Item {
  id: root

  property var skin: ({})
  property bool on: false
  signal toggled(bool on)

  readonly property bool soft: skin.corner !== "cut"
  implicitWidth: Type.px(34)
  implicitHeight: Type.px(20)

  Rectangle {
    anchors.fill: parent
    radius: root.soft ? height / 2 : 0
    color: root.on ? Ink.ink : (root.skin.surface === "washi" ? "transparent" : Ink.ink4)
    border.width: root.skin.surface === "washi" && !root.on ? 1 : 0
    border.color: Ink.ink4
  }
  Rectangle {
    readonly property real pad: Type.px(3)
    x: root.on ? root.width - width - pad : pad
    y: pad
    width: root.height - 2 * pad; height: width
    radius: root.soft ? width / 2 : 0
    color: root.on ? Ink.paper : Ink.ink2
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.ms(root.skin.open || 200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] } }
  }
  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled(!root.on) }
}
