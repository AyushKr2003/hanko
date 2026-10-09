pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Power 電: the battery as the ring part (an ensō that closes as it
// fills, the figure inside it), how long it lasts, the display's
// brightness, the power profile and the session's actions.
Column {
  id: root

  property var skin: ({})
  property var power: null
  property var display: null
  signal request(string sheet, string what, var arg)

  readonly property bool low: !!(power && power.low && !power.charging)
  readonly property var light: display ? display.brightness : null

  spacing: Type.px(10)

  Row {
    width: parent.width
    spacing: Type.px(18)
    visible: root.power !== null
    // the charge as an ensō, the figure inside it
    Item {
      width: Type.px(112)
      height: Type.px(112)
      Ring {
        anchors.fill: parent
        skin: root.skin; size: Type.px(112); value: root.power ? root.power.percent : 0; alert: root.low
      }
      Text {
        anchors.centerIn: parent
        text: root.power ? String(root.power.percent) : ""
        color: root.low ? Ink.seal : Ink.ink
        font.family: Type.display; font.pixelSize: Type.px(38); font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(38), 340)
      }
    }
    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(6)
      width: parent.width - x
      Text {
        text: root.power ? (root.power.charging ? "Charging" : "On battery") : ""
        color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12.5)
      }
      Text {
        width: parent.width; wrapMode: Text.WordWrap
        text: root.power ? root.power.blurb : ""
        color: Ink.ink
        font.family: Type.display; font.pixelSize: Type.px(20); font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(20), 380)
      }
    }
  }
  Text {
    visible: root.power === null
    text: "No battery"
    color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(13)
  }
  Divider { visible: root.light !== null; skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Heading { visible: root.light !== null; skin: root.skin; text: "Brightness"; note: root.light ? String(root.light.percent) : "" }
  KataSlider {
    visible: root.light !== null
    width: parent.width
    skin: root.skin; seed: 7
    value: root.light ? root.light.percent : 0
    onMoved: function(v) { root.request("display", "brightness", v / 100) }
  }
  Divider { visible: root.power !== null; skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Heading { visible: root.power !== null; skin: root.skin; text: "Power mode" }
  Choice {
    visible: root.power !== null && root.power.profiles.length > 0
    width: parent.width
    skin: root.skin
    options: root.power ? root.power.profiles.map(function(p) { return { key: p.name, label: p.label } }) : []
    current: {
      var ps = root.power ? root.power.profiles : []
      for (var i = 0; i < ps.length; i++) if (ps[i].active) return ps[i].name
      return ""
    }
    onPicked: function(key) { root.request("power", "profile", key) }
  }
  Divider { skin: root.skin; width: parent.width; bleed: Type.px(20) }
  SessionRow {
    width: parent.width
    skin: root.skin
    onAct: function(key) { root.request("leaf", "session", key) }
  }
}
