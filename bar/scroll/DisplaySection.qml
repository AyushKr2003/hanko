pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// 06 // DISPLAY: the chosen monitor's brightness in large serif with a
// fader beside the monitors (the chosen one on a plate), and night light
// as a fader-bank switch.
ScrollSection {
  id: root

  // core/Display.js sheet() shape.
  property var display: null

  signal request(string what, var arg)

  readonly property var monitors: display ? display.monitors.slice(0, 4) : []
  readonly property var light: display ? display.brightness : null

  title: light
    ? light.percent + "<font color='" + Ink.inkMuted + "'><small> %</small></font>"
    : (display ? display.title : "Display")
  caption: display ? display.title + (display.blurb ? " · " + display.blurb : "") : ""

  Row {
    width: parent.width
    topPadding: Type.px(22)
    spacing: Type.px(34)

    Row {
      id: bank
      spacing: Type.px(26)
      Fader {
        name: "Light"
        value: root.light ? root.light.level : 0
        muted: !root.light
        onMoved: function(v) { if (root.light) root.request("brightness", Math.max(0.01, v)) }
      }
      // Night light as a two-stop fader: down is day, up is night.
      Fader {
        name: "Night"
        value: root.display && root.display.night ? 1 : 0
        valueText: root.display && root.display.night ? "on" : "off"
        onMoved: function(v) { root.request("night", v >= 0.5) }
      }
    }

    Column {
      anchors.bottom: bank.bottom
      anchors.bottomMargin: Type.px(26)
      width: Math.max(Type.px(200), parent.width - bank.width - parent.spacing)
      Repeater {
        model: root.monitors
        ListRow {
          id: mon
          required property var modelData
          required property int index
          position: mon.index
          name: modelData.internal ? "Built-in" : modelData.name
          note: modelData.enabled ? modelData.detail.split(" · ")[0] : "Off"
          on: modelData.current
          ruled: mon.index > 0 && !root.monitors[mon.index - 1].current
          interactive: !modelData.current && modelData.enabled
          onClicked: root.request("monitor", mon.modelData.name)
        }
      }
    }
  }
}
