pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Power 電: the battery's charge as the title (red when low and draining),
// how long it lasts and what it draws, its detail, the power profiles with
// the active one inverted, and the screen's brightness on laptops.
// Up/Down step the brightness.
Item {
  id: root

  // core/Power.js sheet() shape, or null before the first reading.
  property var power: null

  // what: profile (name) | brightness (0..1)
  signal request(string what, var arg)

  readonly property var details: power ? power.details : []
  readonly property var profiles: power ? power.profiles : []
  readonly property var light: power ? power.brightness : null

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

    GroupHead {
      visible: !!root.light
      title: "Brightness"
      summary: "Scroll on bar · ±5"
    }

    SheetRow {
      id: lightRow
      visible: !!root.light
      name: "Screen"
      nameWidth: Type.px(90)
      note: root.light ? String(root.light.percent) : ""
      last: true

      Ruler {
        width: lightRow.width - Type.px(90) - Type.px(12) - Type.px(20) - Type.px(10) - Type.px(46)
        height: Type.px(22)
        value: root.light ? root.light.level : 0
        onMoved: function(v) { root.request("brightness", v) }
      }
    }
  }

  Keys.onUpPressed: if (root.light) root.request("brightness", Math.min(1, root.light.level + 0.05))
  Keys.onDownPressed: if (root.light) root.request("brightness", Math.max(0.01, root.light.level - 0.05))
}
