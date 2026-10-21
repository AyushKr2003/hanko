pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Display 明, Shōji's: the chosen monitor's brightness as a hero figure you
// scroll, the slider part under it (never below 1%), night light on the
// switch part, then the monitors, the chosen one under the selection part
// (a click chooses which monitor the slider drives; one switched off can't
// be chosen). + and - step the brightness, N toggles night light.
// Requests as DisplaySheet's: brightness (0.01..1) | monitor | night | edit.
Column {
  id: root

  property var skin: ({})
  property var display: null
  signal request(string sheet, string what, var arg)

  readonly property var light: display ? display.brightness : null
  readonly property var monitors: display ? display.monitors.slice(0, 5) : []
  readonly property bool night: !!(display && display.night)
  function setLight(v) { root.request("display", "brightness", Math.max(0.01, Math.min(1, v))) }

  spacing: Type.px(10)

  Item {
    width: parent.width; height: hero.height
    Figure {
      id: hero
      skin: root.skin
      value: root.light ? String(root.light.percent) : "—"
      unit: root.light ? "%" : ""
      MouseArea {
        anchors.fill: parent
        enabled: root.light !== null
        onWheel: function(w) { if (root.light) root.setLight(root.light.level + (w.angleDelta.y > 0 ? 0.02 : -0.02)) }
      }
    }
    Column {
      anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: Type.px(10)
      spacing: Type.px(2)
      Text {
        anchors.right: parent.right
        text: root.display ? root.display.title : ""
        color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5)
        font.weight: Font.Medium; font.variableAxes: Type.valueAxes
      }
      Text {
        anchors.right: parent.right
        text: root.light ? "Scroll the figure or drag below" : "No brightness control here"
        color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12)
      }
    }
  }
  KataSlider {
    visible: root.light !== null
    width: parent.width
    skin: root.skin; seed: 7
    value: root.light ? root.light.percent : 0
    onMoved: function(v) { root.setLight(v / 100) }
  }
  Divider { skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Item {
    width: parent.width; height: Type.px(26)
    Text { anchors.verticalCenter: parent.verticalCenter; text: "Night light"; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
    KataSwitch { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; skin: root.skin; on: root.night; onToggled: function(on) { root.request("display", "night", on) } }
  }
  Divider { skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Item {
    width: parent.width
    height: heading.height
    Heading { id: heading; skin: root.skin; text: "Monitors"; note: "" }
    Text {
      anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: Type.px(6)
      text: "Arrange ›"
      readonly property bool keyStop: true
      function keyPress() { root.request("display", "edit", null) }
      color: arrange.containsMouse ? Ink.ink : Ink.ink3
      font.family: Type.text; font.pixelSize: Type.px(12)
      MouseArea { id: arrange; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.request("display", "edit", null) }
    }
  }
  KataList {
    width: parent.width
    skin: root.skin
    rows: root.monitors.map(function(m) {
      return { title: m.label, detail: m.detail, note: !m.enabled ? "Off" : m.focused ? "Focused" : "", chosen: m.current }
    })
    onPicked: function(i) { var m = root.monitors[i]; if (m.enabled && !m.current) root.request("display", "monitor", m.name) }
  }
  Keys.onPressed: function(e) { if (e.key === Qt.Key_N) { root.request("display", "night", !root.night); e.accepted = true } }
}
