pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Lock, Suspend, Restart, Shut down. The two that end your session ask you
// to hold them instead of asking "are you sure?": the seal's red soaks into
// the button while you hold (600 ms) and drains if you let go.
Row {
  id: root

  property var skin: ({})
  signal act(string key)

  readonly property var actions: [
    { key: "lock", name: "Lock", hold: false },
    { key: "suspend", name: "Sleep", hold: false },
    { key: "reboot", name: "Restart", hold: true },
    { key: "shutdown", name: "Shut down", hold: true }
  ]
  spacing: root.skin.surface === "washi" ? 0 : Type.px(8)
  height: Type.px(56)

  Repeater {
    model: root.actions
    Item {
      id: btn
      required property var modelData
      width: (root.width - root.spacing * 3) / 4; height: root.height
      property real soak: 0
      NumberAnimation on soak { id: fill; running: false; to: 1; duration: Motion.ms(600) }
      NumberAnimation on soak { id: drain; running: false; to: 0; duration: Motion.ms(200) }
      onSoakChanged: if (soak >= 1 && area.pressed) { soak = 0; root.act(btn.modelData.key) }
      Rectangle {
        anchors.fill: parent
        radius: root.skin.radiusChip || 0
        color: "transparent"
        border.width: 1; border.color: btn.modelData.hold ? Ink.alpha(Ink.seal, 0.45) : Ink.kLine
        clip: true
        Rectangle { width: parent.width * btn.soak; height: parent.height; color: Ink.alpha(Ink.seal, 0.2) }
      }
      Text {
        anchors.centerIn: parent
        text: btn.modelData.name
        color: btn.modelData.hold ? Ink.seal : Ink.ink2
        font.family: Type.text; font.pixelSize: Type.px(12.5)
      }
      MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: if (btn.modelData.hold) { drain.stop(); fill.start() }
        onReleased: if (btn.modelData.hold) { fill.stop(); drain.start() }
        onClicked: if (!btn.modelData.hold) root.act(btn.modelData.key)
      }
    }
  }
}
