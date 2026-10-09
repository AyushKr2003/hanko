pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Status.js" as StatusJs

// Notifications 報 (docs/COMPONENTS.md):
//   count   INBOX 03 with one red dot
//   stamps  each notification a small stamped seal of its app's initial,
//           slightly askew, newest on top; hover fans them out
// Do not disturb keeps the count but drops the red: the label reads QUIET 静
// and the stamps are inked, not sealed. Click replays the recent ones;
// right-click toggles do not disturb. A new stamp is pressed down
// oversized and tilted, then settles (Motion.stamp, the only overshoot).
Item {
  id: root

  property string mode: "stamps"
  // core/Status.js notifications(): newest first.
  property var notifications: []
  property bool dnd: false
  property int barHeight: 40

  signal action(string how)

  readonly property bool compact: barHeight <= Type.px(32)
  readonly property int count: notifications.length
  readonly property string countText: StatusJs.count2(count)
  readonly property var shown: notifications.slice(0, 3)
  readonly property bool fanned: hover.hovered

  // Notifications already on the bar: only one that arrives after the
  // first reading is pressed down (Motion.stamp). Updated after the
  // stamps are built, so a new one still finds itself missing here.
  property var known: ({})
  property bool primed: false
  function keyOf(n) { return n.timestamp + "|" + n.app + "|" + n.summary }
  onNotificationsChanged: Qt.callLater(remember)
  Component.onCompleted: Qt.callLater(remember)
  function remember() {
    var k = {}
    for (var i = 0; i < notifications.length; i++) k[keyOf(notifications[i])] = true
    known = k
    primed = true
  }

  implicitWidth: mode === "count" ? (compact ? countLine.implicitWidth : countCell.implicitWidth) : stampRow.implicitWidth
  implicitHeight: barHeight

  HoverHandler { id: hover }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.action(mouse.button === Qt.RightButton ? "right" : mouse.button === Qt.MiddleButton ? "middle" : "click")
    }
  }

  // ------------------------------------------------------------ count
  Column {
    id: countCell
    visible: root.mode === "count" && !root.compact
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -1
    spacing: 1

    Row {
      spacing: Type.px(6)
      Text {
        text: root.dnd ? "QUIET" : "INBOX"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackLabel
      }
      Text {
        text: root.dnd ? "休" : "文"
        color: Ink.inkMuted
        font.family: Type.jp
        font.pixelSize: Type.gloss
      }
    }
    Row {
      spacing: Type.px(6)
      Text {
        id: countNum
        text: root.countText
        color: root.count > 0 ? Ink.ink : Ink.inkFaint
        font.family: Type.mono
        font.pixelSize: Type.figure
        font.letterSpacing: 0.8
      }
      Dot { anchors.verticalCenter: countNum.verticalCenter }
    }
  }

  Row {
    id: countLine
    visible: root.mode === "count" && root.compact
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(7)
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.dnd ? "QUIET" : "INBOX"
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.weight: Type.labelWeight
      font.letterSpacing: Type.trackLabel
    }
    Text {
      id: countNum2
      anchors.verticalCenter: parent.verticalCenter
      text: root.countText
      color: root.count > 0 ? Ink.ink : Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.figure
    }
    Dot { anchors.verticalCenter: countNum2.verticalCenter }
  }

  // One red dot when something waits; a hollow ring while silenced.
  component Dot: Rectangle {
    visible: root.count > 0
    width: Type.px(5)
    height: width
    radius: width / 2
    color: root.dnd ? "transparent" : Ink.seal
    border.width: root.dnd ? 1 : 0
    border.color: Ink.inkMuted
  }

  // ------------------------------------------------------------ stamps
  Row {
    id: stampRow
    visible: root.mode === "stamps"
    anchors.verticalCenter: parent.verticalCenter
    spacing: Type.px(8)

    Row {
      id: pile
      anchors.verticalCenter: parent.verticalCenter
      visible: root.count > 0
      spacing: root.fanned ? Type.px(4) : -Type.px(4)
      Behavior on spacing { enabled: !Motion.still; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }

      Repeater {
        model: root.shown
        Stamp {
          required property var modelData
          required property int index
          n: modelData
          z: root.shown.length - index
        }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.countText
      color: root.count > 0 ? Ink.inkMuted : Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.label
      font.weight: Type.labelWeight
      font.letterSpacing: Type.trackLabel
    }
  }

  // A seal of the app's initial. Urgent ones are solid; silenced ones lose
  // their red.
  component Stamp: Rectangle {
    id: stamp
    property var n: ({})
    // 0 = held above the bar, oversized and tilted; 1 = pressed and settled.
    property real press: 1
    readonly property color sealInk: root.dnd ? Ink.inkMuted : Ink.seal
    readonly property bool solid: !!n.urgent && !root.dnd
    width: Type.px(18)
    height: width
    radius: 2
    rotation: root.fanned ? 0 : n.tilt || 0
    Behavior on rotation { enabled: !Motion.still; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
    antialiasing: true
    color: solid ? sealInk : Ink.paper
    border.width: 1.5
    border.color: sealInk
    transform: [
      Scale {
        origin.x: stamp.width / 2; origin.y: stamp.height / 2
        xScale: 1 + 0.45 * (1 - stamp.press); yScale: xScale
      },
      Rotation { origin.x: stamp.width / 2; origin.y: stamp.height / 2; angle: -12 * (1 - stamp.press) }
    ]
    opacity: Math.min(1, 0.4 + stamp.press)

    NumberAnimation {
      id: pressing
      target: stamp
      property: "press"
      from: 0
      to: 1
      duration: Motion.stamp
      easing.type: Easing.BezierSpline
      easing.bezierCurve: Motion.stampCurve
    }
    Component.onCompleted: if (root.primed && Motion.live && !root.known[root.keyOf(n)]) pressing.start()

    Text {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -0.5
      readonly property bool latin: /^[A-Z0-9]$/.test(stamp.n.glyph || "")
      text: stamp.n.glyph || ""
      color: stamp.solid ? Ink.paper : stamp.sealInk
      font.family: latin ? Type.display : Type.jpSerif
      font.pixelSize: Type.px(latin ? 12 : 11)
      font.variableAxes: { "opsz": 14, "wght": 500 }
    }
  }
}
