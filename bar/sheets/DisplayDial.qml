pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Display 明, Dial (盤): the chosen monitor's brightness as a gauge you turn,
// its name and mode beside it with Night, and every monitor as a tile (a
// click chooses it). Up/Down step the brightness, N toggles night light.
Item {
  id: root

  property var display: null
  signal request(string what, var arg)

  readonly property var monitors: display ? display.monitors : []
  readonly property var light: display ? display.brightness : null
  readonly property bool night: !!(display && display.night)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead { sheet: "display"; jp: "明"; label: "Display · Hyprland"; compact: true }
    Item { width: 1; height: Type.px(16) }

    DialHero {
      interactive: !!root.light
      value: root.light ? root.light.level : -1
      figure: root.light ? String(root.light.percent) : "—"
      unit: root.light ? "%" : ""
      caption: root.light ? "brightness" : "no control"
      title: root.display ? root.display.title : "Display"
      lines: [root.display ? root.display.blurb : ""]
      onMoved: function(v) { if (root.light) root.request("brightness", Math.max(0.01, v)) }
      SheetButton { text: "Night"; on: root.night; onClicked: root.request("night", !root.night) }
    }

    TileSection {
      id: mons
      label: "Monitors"
      summary: root.monitors.length + (root.monitors.length === 1 ? " monitor" : " monitors")
      Repeater {
        model: root.monitors
        Tile {
          required property var modelData
          width: mons.tileWidth
          name: modelData.label
          detail: modelData.detail
          note: modelData.focused ? "Focused" : modelData.enabled ? "" : "Off"
          selected: modelData.current
          interactive: !modelData.current && modelData.enabled
          onClicked: root.request("monitor", modelData.name)
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: "Night light · " + (root.night ? "on" : "off")
    SheetButton { plate: true; text: "Monitors ›"; onClicked: root.request("edit", null) }
  }

  Keys.onUpPressed: if (root.light) root.request("brightness", Math.min(1, root.light.level + 0.05))
  Keys.onDownPressed: if (root.light) root.request("brightness", Math.max(0.01, root.light.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_N) { root.request("night", !root.night); event.accepted = true }
  }
}
