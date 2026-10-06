pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Display 明, the LUM cell's sheet: the brightness of the chosen monitor as
// a large number on a ruler (backlight on a laptop panel, DDC on an
// external one), every monitor with its mode and scale (the chosen one
// inverted; a click chooses another), and night light at the foot.
// Up/Down step the brightness, N toggles night light.
Item {
  id: root

  // core/Display.js sheet() shape, or null before the first reading.
  property var display: null

  // what: brightness (0..1) | monitor (name) | night (bool) | edit
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

    SheetHead {
      jp: "明"
      label: "Display · Hyprland"
      title: root.display ? root.display.title : "Display"
      blurb: root.display ? root.display.blurb : ""
    }

    GroupHead { title: "Brightness"; summary: "Scroll on bar · ±5" }

    Item {
      width: parent.width
      height: Type.px(12) + Type.px(40) + Type.px(6)

      Row {
        x: Type.px(2)
        y: Type.px(12)
        width: parent.width - Type.px(4)
        spacing: Type.px(16)

        Text {
          id: big
          width: Type.px(66)
          anchors.verticalCenter: parent.verticalCenter
          text: root.light ? String(root.light.percent) : "—"
          color: root.light ? Ink.ink : Ink.inkFaint
          font.family: Type.display
          font.pixelSize: Type.px(40)
          font.weight: Font.Normal
          font.variableAxes: { "opsz": 72, "wght": 400 }
        }
        Ruler {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - big.width - nightButton.width - 2 * parent.spacing
          value: root.light ? root.light.level : 0
          muted: !root.light
          onMoved: function(v) { if (root.light) root.request("brightness", v) }
        }
        SheetButton {
          id: nightButton
          anchors.verticalCenter: parent.verticalCenter
          text: "Night"
          on: root.night
          onClicked: root.request("night", !root.night)
        }
      }
    }

    GroupHead {
      title: "Monitors"
      summary: root.monitors.length + (root.monitors.length === 1 ? " monitor" : " monitors")
    }

    SheetRow {
      visible: root.monitors.length === 0
      name: "No monitors"
      detail: "Hyprland reports none."
      last: true
    }

    Repeater {
      model: root.monitors
      SheetRow {
        id: monitor
        required property var modelData
        required property int index
        lead: true
        selected: modelData.current
        interactive: !modelData.current && modelData.enabled
        name: modelData.label
        detail: modelData.detail
        note: modelData.focused ? "Focused" : modelData.enabled ? "" : "Off"
        last: index === root.monitors.length - 1
        onClicked: root.request("monitor", monitor.modelData.name)
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.night ? "Night light · on" : "Night light · off"

    SheetButton {
      plate: true
      text: "Monitors ›"
      onClicked: root.request("edit", null)
    }
  }

  Keys.onUpPressed: if (root.light) root.request("brightness", Math.min(1, root.light.level + 0.05))
  Keys.onDownPressed: if (root.light) root.request("brightness", Math.max(0.01, root.light.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_N) { root.request("night", !root.night); event.accepted = true }
  }
}
