pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Display 明, Tanzaku (短冊): the chosen monitor's brightness on the first
// slip (pull it to set; never below 1%), then a slip for each monitor (the
// chosen one inked and sealed, one switched off dashed). A click chooses.
// + and - step the brightness, N toggles night light.
Item {
  id: root

  property var display: null
  signal request(string what, var arg)

  readonly property var monitors: display ? display.monitors.slice(0, 5) : []
  readonly property var light: display ? display.brightness : null
  readonly property bool night: !!(display && display.night)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(18)

    SheetHead { sheet: "display"; jp: "明"; label: "Display · Hyprland"; compact: true }
    Item { width: 1; height: Type.px(18) }

    TanzakuRail {
      LeadStrip {
        mark: "明"
        figure: root.light ? String(root.light.percent) : "—"
        unit: root.light ? "%" : ""
        caption: root.display ? root.display.title : ""
        level: root.light ? root.light.level : -1
        settable: !!root.light
        onMoved: function(v) { if (root.light) root.request("brightness", Math.max(0.01, v)) }
      }
      Repeater {
        model: root.monitors
        Tanzaku {
          required property var modelData
          name: modelData.label
          foot: modelData.focused ? "◉" : modelData.enabled ? "" : "off"
          selected: modelData.current
          dashed: !modelData.enabled
          interactive: !modelData.current && modelData.enabled
          onClicked: root.request("monitor", modelData.name)
        }
      }
    }
    TanzakuFoot { text: root.light ? "Pull the first slip to set · click a monitor to choose it" : "Click a monitor to choose it" }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    SheetButton { text: "Night"; on: root.night; onClicked: root.request("night", !root.night) }
    SheetButton { plate: true; text: "Monitors ›"; onClicked: root.request("edit", null) }
  }
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_N) { root.request("night", !root.night); event.accepted = true }
  }
}
