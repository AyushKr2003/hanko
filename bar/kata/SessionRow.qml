pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Lock, Suspend, Restart, Shut down. The two that end your session ask you
// to hold them instead of asking "are you sure?" (the hold part: Shōji's
// brush stroke). The four sit side by side as one row of doors.
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
  spacing: 0
  height: Type.px(56)

  Repeater {
    model: root.actions
    Hold {
      required property var modelData
      width: (root.width - root.spacing * 3) / 4; height: root.height
      skin: root.skin
      label: modelData.name
      hold: modelData.hold
      onFired: root.act(modelData.key)
    }
  }
}
