pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Display 明, Prose (文): "Built-in, at 70% brightness, 2880×1800 · 120 Hz.
// Night light is off." Night light's state toggles it and a ruler under the
// sentence sets the brightness; the monitors are an index below.
Item {
  id: root

  property var display: null
  signal request(string what, var arg)

  readonly property var monitors: display ? display.monitors : []
  readonly property var light: display ? display.brightness : null
  readonly property bool night: !!(display && display.night)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(22)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "display"; jp: "明"; label: "Display · Hyprland"; compact: true }
    Item { width: 1; height: Type.px(16) }

    ProseText {
      id: line
      text: {
        if (!root.display) return "Asking Hyprland…"
        var s = line.word("edit", root.display.title)
        s += root.light ? ", at " + root.light.percent + "% brightness" : ", its brightness out of reach"
        s += root.display.blurb ? ", " + line.em(root.display.blurb) + ". " : ". "
        s += "Night light is " + line.word("night", root.night ? "on" : "off") + "."
        return s
      }
      onPicked: function(a) {
        if (a === "night") root.request("night", !root.night)
        else if (a === "edit") root.request("edit", null)
      }
    }

    Item { visible: !!root.light; width: 1; height: Type.px(14) }
    Ruler {
      visible: !!root.light
      width: parent.width
      value: root.light ? root.light.level : 0
      onMoved: function(v) { if (root.light) root.request("brightness", Math.max(0.01, v)) }
    }

    ProseIndex {
      label: "Monitors"
      summary: root.monitors.length + (root.monitors.length === 1 ? " monitor" : " monitors")
      Repeater {
        model: root.monitors
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: modelData.label
          note: modelData.focused ? "Focused" : modelData.enabled ? "" : "Off"
          selected: modelData.current
          interactive: !modelData.current && modelData.enabled
          onClicked: root.request("monitor", modelData.name)
        }
      }
    }
  }

  Keys.onUpPressed: if (root.light) root.request("brightness", Math.min(1, root.light.level + 0.05))
  Keys.onDownPressed: if (root.light) root.request("brightness", Math.max(0.01, root.light.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_N) { root.request("night", !root.night); event.accepted = true }
  }
}
