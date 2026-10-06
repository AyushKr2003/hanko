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
// right-click toggles do not disturb.
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
        font.pixelSize: Type.px(8)
        font.letterSpacing: 1.6
      }
      Text {
        text: root.dnd ? "静" : "報"
        color: Ink.inkFaint
        font.family: Type.jp
        font.pixelSize: Type.px(8.5)
      }
    }
    Row {
      spacing: Type.px(6)
      Text {
        id: countNum
        text: root.countText
        color: root.count > 0 ? Ink.ink : Ink.inkFaint
        font.family: Type.mono
        font.pixelSize: Type.px(12)
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
      font.pixelSize: Type.px(8)
      font.letterSpacing: 1.6
    }
    Text {
      id: countNum2
      anchors.verticalCenter: parent.verticalCenter
      text: root.countText
      color: root.count > 0 ? Ink.ink : Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(12)
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
      Behavior on spacing { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

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
      font.pixelSize: Type.px(9.5)
      font.letterSpacing: 1.2
    }
  }

  // A seal of the app's initial. Urgent ones are solid; silenced ones lose
  // their red.
  component Stamp: Rectangle {
    id: stamp
    property var n: ({})
    readonly property color sealInk: root.dnd ? Ink.inkMuted : Ink.seal
    readonly property bool solid: !!n.urgent && !root.dnd
    width: Type.px(18)
    height: width
    radius: 2
    rotation: root.fanned ? 0 : n.tilt || 0
    Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    antialiasing: true
    color: solid ? sealInk : Ink.paper
    border.width: 1.5
    border.color: sealInk

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
