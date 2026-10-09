pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Mon.js" as Mon

// Display 明, Mon (紋): the brightness as the sheet's kuyō (scroll on it or
// click a star; never under 1%), then each monitor as a crest, the chosen
// one inked red, one switched off drawn faint. A click chooses. Up/Down
// step the brightness, N toggles night light.
Item {
  id: root

  property var display: null
  signal request(string what, var arg)

  readonly property var monitors: display ? display.monitors.slice(0, 8) : []
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
    Item { width: 1; height: Type.px(18) }

    MonHero {
      kind: root.light ? "kuyo" : "moji"
      glyph: "明"
      level: root.light ? root.light.level : -1
      settable: !!root.light
      figure: root.light ? String(root.light.percent) : "—"
      unit: root.light ? "%" : ""
      title: root.display ? root.display.title : ""
      lines: [root.display ? root.display.blurb : ""]
      onMoved: function(v) { if (root.light) root.request("brightness", Math.max(0.01, v)) }
      SheetButton { text: "Night"; on: root.night; onClicked: root.request("night", !root.night) }
    }

    MonPage {
      id: mons
      jp: "画"
      label: "Monitors"
      summary: root.monitors.length + (root.monitors.length === 1 ? " monitor" : " monitors")
      Repeater {
        model: root.monitors
        CrestCell {
          required property var modelData
          required property int index
          width: mons.cellWidth
          kind: Mon.at(index + 3).kind
          count: Mon.at(index + 3).count
          name: modelData.label.split(" · ")[0]
          note: modelData.focused ? "focused" : modelData.enabled ? "" : "off"
          selected: modelData.current
          faint: !modelData.enabled
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
