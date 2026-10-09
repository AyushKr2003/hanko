pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Power 電, Tanzaku (短冊): the battery on the first slip (its charge as the
// wash, red when low and draining), a slip for each power profile (the one
// running inked and sealed; a click switches) and, parted from them, the
// battery's details as quiet slips with their figures at the foot.
Item {
  id: root

  property var power: null
  signal request(string what, var arg)

  readonly property var details: power ? power.details.slice(1, 3) : []
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

    TanzakuRail {
      LeadStrip {
        mark: root.power && root.power.charging ? "充" : "電"
        figure: root.hasBattery ? String(root.power.percent) : "AC"
        unit: root.hasBattery ? "%" : ""
        caption: root.power ? root.power.blurb : ""
        level: root.hasBattery ? root.power.percent / 100 : -1
        red: !!(root.power && root.power.low)
      }
      Repeater {
        model: root.profiles
        Tanzaku {
          required property var modelData
          name: modelData.label
          selected: modelData.active
          interactive: !modelData.active
          onClicked: root.request("profile", modelData.name)
        }
      }
      Item { width: Type.px(4); height: 1; visible: root.details.length > 0 }
      Repeater {
        model: root.details
        Tanzaku {
          required property var modelData
          name: modelData.name
          foot: modelData.value
          interactive: false
        }
      }
    }
    TanzakuFoot { text: root.profiles.length ? "Click a profile to run it" : "" }
  }
}
