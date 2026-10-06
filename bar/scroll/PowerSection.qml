pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// 04 // POWER: the charge in large serif (red when low and draining), how
// long it lasts, and the power profiles, the active one on a plate.
ScrollSection {
  id: root

  // core/Power.js sheet() shape.
  property var power: null

  signal request(string what, var arg)

  readonly property var profiles: power ? power.profiles : []

  title: power && power.percent >= 0
    ? "<font color='" + (power.low ? Ink.seal : Ink.ink) + "'>" + power.percent + "</font>"
      + "<font color='" + Ink.inkMuted + "'><small> %</small></font>"
    : "Plugged in"
  caption: power ? power.blurb : ""

  Column {
    width: parent.width
    topPadding: Type.px(18)

    Repeater {
      model: root.profiles
      ListRow {
        id: profile
        required property var modelData
        required property int index
        position: profile.index
        name: modelData.label
        note: modelData.active ? "Active" : ""
        on: modelData.active
        ruled: profile.index > 0 && !root.profiles[profile.index - 1].active
        interactive: !modelData.active
        onClicked: root.request("profile", profile.modelData.name)
      }
    }
  }
}
