pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Power 電, Dial (盤): the battery as the gauge (red when low and draining),
// what it lasts and draws beside it, the power profiles as three tiles
// (the active one a bone plate; a click switches) and the battery's
// details as small read-only tiles.
Item {
  id: root

  property var power: null
  signal request(string what, var arg)

  readonly property var details: power ? power.details : []
  readonly property var profiles: power ? power.profiles : []
  readonly property bool hasBattery: !!(power && power.percent >= 0)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(22)

    SheetHead { sheet: "power"; jp: root.power && root.power.charging ? "充" : "電"; label: "Power · UPower"; compact: true }
    Item { width: 1; height: Type.px(16) }

    DialHero {
      interactive: false
      value: root.hasBattery ? root.power.percent / 100 : 1
      red: !!(root.power && root.power.low)
      figure: root.hasBattery ? String(root.power.percent) : "AC"
      unit: root.hasBattery ? "%" : ""
      caption: root.power && root.power.charging ? "charging" : root.hasBattery ? "on battery" : "plugged in"
      title: {
        for (var i = 0; i < root.profiles.length; i++) if (root.profiles[i].active) return root.profiles[i].label
        return "Power"
      }
      lines: [root.power ? root.power.blurb : ""]
    }

    TileSection {
      id: prof
      visible: root.profiles.length > 0
      label: "Profile"
      summary: root.profiles.length + " profiles"
      columns: Math.max(1, Math.min(3, root.profiles.length))
      Repeater {
        model: root.profiles
        Tile {
          required property var modelData
          width: prof.tileWidth
          name: modelData.label
          detail: modelData.detail
          selected: modelData.active
          interactive: !modelData.active
          onClicked: root.request("profile", modelData.name)
        }
      }
    }

    TileSection {
      id: bat
      visible: root.details.length > 0
      label: "Battery"
      summary: root.details.length ? root.details[0].value : ""
      columns: 3
      Repeater {
        model: root.details.slice(1)
        Tile {
          required property var modelData
          width: bat.tileWidth
          implicitHeight: Type.px(52)
          interactive: false
          name: modelData.value
          detail: modelData.name
        }
      }
    }
  }
}
