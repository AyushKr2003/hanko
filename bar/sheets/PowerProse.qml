pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Power 電, Prose (文): "91%, on battery: 5h 10m left, drawing 8.4 W.
// Running Balanced, fast when it matters, quiet otherwise." The profile's
// name steps to the next profile; the battery's details are an index.
Item {
  id: root

  property var power: null
  signal request(string what, var arg)

  readonly property var details: power ? power.details : []
  readonly property var profiles: power ? power.profiles : []
  readonly property int active: {
    for (var i = 0; i < profiles.length; i++) if (profiles[i].active) return i
    return -1
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(22)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "power"; jp: root.power && root.power.charging ? "充" : "電"; label: "Power · UPower"; compact: true }
    Item { width: 1; height: Type.px(16) }

    ProseText {
      id: line
      text: {
        if (!root.power) return "Reading the battery…"
        var pct = root.power.percent >= 0 ? root.power.percent + "%" : ""
        var s = pct ? (root.power.low ? line.red(pct) : pct) + ", " + (root.power.charging ? "charging" : "on battery")
                    : "Plugged in"
        s += root.power.blurb ? ": " + line.em(root.power.blurb) + ". " : ". "
        if (root.active >= 0) {
          var p = root.profiles[root.active]
          s += "Running " + line.word("next", p.label) + (p.detail ? ", " + p.detail.charAt(0).toLowerCase() + p.detail.slice(1) : "") + "."
        }
        return s
      }
      onPicked: function(a) {
        if (a === "next" && root.profiles.length)
          root.request("profile", root.profiles[(root.active + 1) % root.profiles.length].name)
      }
    }

    ProseIndex {
      visible: root.profiles.length > 0
      label: "Profiles"
      summary: "click to switch"
      Repeater {
        model: root.profiles
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: modelData.label
          note: modelData.active ? "In use" : ""
          selected: modelData.active
          interactive: !modelData.active
          onClicked: root.request("profile", modelData.name)
        }
      }
    }

    ProseIndex {
      visible: root.details.length > 0
      label: "Battery"
      summary: root.details.length ? root.details[0].value : ""
      Repeater {
        model: root.details.slice(1)
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: modelData.name
          note: modelData.value
          interactive: false
        }
      }
    }
  }
}
