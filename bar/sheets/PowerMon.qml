pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Mon.js" as Mon

// Power 電, Mon (紋): the battery as the sheet's kuyō (red when low and
// draining), the power profiles as three crests, the one running inked red
// (a click switches), and the battery's details as quiet crests with their
// figures.
Item {
  id: root

  property var power: null
  signal request(string what, var arg)

  readonly property var details: power ? power.details.slice(1) : []
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
    Item { width: 1; height: Type.px(18) }

    MonHero {
      kind: root.hasBattery ? "kuyo" : "moji"
      glyph: "電"
      level: root.hasBattery ? root.power.percent / 100 : -1
      red: !!(root.power && root.power.low)
      figure: root.hasBattery ? String(root.power.percent) : "AC"
      unit: root.hasBattery ? "%" : ""
      title: root.power && root.power.charging ? "charging" : root.hasBattery ? "on battery" : "plugged in"
      lines: [root.power ? root.power.blurb : ""]
    }

    MonPage {
      id: prof
      visible: root.profiles.length > 0
      jp: "構"
      label: "Profile"
      summary: root.profiles.length + " profiles"
      columns: Math.max(3, root.profiles.length)
      Repeater {
        model: root.profiles
        CrestCell {
          required property var modelData
          required property int index
          width: prof.cellWidth
          kind: Mon.at(index + 3).kind
          count: Mon.at(index + 3).count
          name: modelData.label
          selected: modelData.active
          interactive: !modelData.active
          onClicked: root.request("profile", modelData.name)
        }
      }
    }

    MonPage {
      id: bat
      visible: root.details.length > 0
      jp: "記"
      label: "Battery"
      summary: root.power && root.power.details.length ? root.power.details[0].value : ""
      columns: Math.max(3, root.details.length)
      Repeater {
        model: root.details
        CrestCell {
          required property var modelData
          required property int index
          width: bat.cellWidth
          kind: Mon.at(index).kind
          count: Mon.at(index).count
          faint: true
          interactive: false
          name: modelData.value
          note: modelData.name
        }
      }
    }
  }
}
