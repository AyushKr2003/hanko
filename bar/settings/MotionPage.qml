pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import "../../core/Leaf.js" as LeafJs
import ".."
import "../scroll"

// Settings › Motion 動.
Column {
  id: root

  property var style: ({})
  property var draft: S.normalize({})
  property string query: ""
  property bool compact: false
  // Settings.visibilityCards ctx: own, indicators, tray, hosted.
  property var visibility: ({})

  signal settingPicked(string key, string value)
  signal showAll()

  width: parent ? parent.width : 0

  // ------------------------------------------------ Motion
  Column {
    width: parent.width
    topPadding: Type.px(22)
    spacing: Type.px(18)

    SettingsCard {
      width: parent.width
      card: Settings.MOTION_CARD
      style: root.style
      options: ({})
      onPicked: function(key, value) { root.settingPicked(key, value) }
    }

    Text {
      visible: Motion.system
      width: parent.width
      wrapMode: Text.Wrap
      text: "Omarchy's animations are off, so Hanko is still whatever this says."
      color: Ink.seal
      font.family: Type.text
      font.pixelSize: Type.px(12)
    }

    // The timings, as Scroll's motion sheet gives them.
    Rectangle {
      width: parent.width
      height: timings.implicitHeight + Type.px(16)
      radius: 3
      color: "transparent"
      border.width: 1
      border.color: Ink.line

      Column {
        id: timings
        x: Type.px(14)
        y: Type.px(8)
        width: parent.width - 2 * x
        Repeater {
          model: Settings.MOTION_ROWS
          Item {
            id: timing
            required property var modelData
            required property int index
            readonly property int ms: Motion[modelData[2]]
            width: timings.width
            // A narrow page wraps the line instead of cutting it short.
            height: Math.max(Type.px(36), timingLine.height + Type.px(16))
            Rectangle {
              visible: timing.index > 0
              width: parent.width; height: 1; color: Ink.lineSoft
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Type.px(120)
              text: timing.modelData[0]
              color: Ink.ink
              font.family: Type.text
              font.pixelSize: Type.row
            }
            Text {
              id: timingLine
              anchors.verticalCenter: parent.verticalCenter
              x: Type.px(120)
              width: parent.width - x - Type.px(root.compact ? 70 : 110)
              wrapMode: Text.Wrap
              text: timing.modelData[1]
              color: Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.note
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.right: parent.right
              text: root.style.motion === "still" || Motion.system ? "cut" : timing.ms >= 1000 ? (timing.ms / 1000) + " s" : timing.ms + " ms"
              color: root.style.motion === "still" || Motion.system ? Ink.inkFaint : Ink.inkDim
              font.family: Type.mono
              font.pixelSize: Type.px(10)
              font.letterSpacing: 1
            }
          }
        }
      }
    }
  }

}
