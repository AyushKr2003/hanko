pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Power 電: the battery's charge as the title (red when low and draining),
// how long it lasts and what it draws, its detail, and the power profiles
// with the active one inverted. Brightness has its own panel (Display 明).
Item {
  id: root

  // core/Power.js sheet() shape, or null before the first reading.
  property var power: null

  // what: profile (name)
  signal request(string what, var arg)

  readonly property var details: power ? power.details : []
  readonly property var profiles: power ? power.profiles : []

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(22)

    SheetHead {
      jp: root.power && root.power.charging ? "充" : "電"
      label: "Power · UPower"
      title: root.power && root.power.percent >= 0 ? root.power.percent + "%" : "Plugged in"
      titleColor: root.power && root.power.low ? Ink.seal : Ink.ink
      blurb: root.power ? root.power.blurb : ""
    }

    GroupHead {
      visible: root.details.length > 0
      title: "Battery"
      summary: root.details.length ? root.details[0].value : ""
    }

    Repeater {
      model: root.details.slice(1)
      SheetRow {
        id: detailRow
        required property var modelData
        required property int index
        minHeight: Type.px(36)
        name: modelData.name
        note: modelData.value
        upperNote: false
        last: index === root.details.length - 2
      }
    }

    GroupHead {
      visible: root.profiles.length > 0
      title: "Profile"
      summary: root.profiles.length + " profiles"
    }

    Repeater {
      model: root.profiles
      SheetRow {
        id: profile
        required property var modelData
        required property int index
        lead: true
        selected: modelData.active
        interactive: !modelData.active
        name: modelData.label
        detail: modelData.detail
        last: index === root.profiles.length - 1
        onClicked: root.request("profile", profile.modelData.name)
      }
    }
  }
}
