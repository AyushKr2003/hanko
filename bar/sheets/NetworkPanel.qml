pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Network 繋: the Wi-Fi switch, the network's name as the hero, nearby
// networks below (a click connects). Bluetooth has its own panel.
Column {
  id: root

  property var skin: ({})
  property var net: null
  property int maxRows: 5
  signal request(string sheet, string what, var arg)

  readonly property bool radio: !net || net.radio
  readonly property bool offline: !!(net && net.offline)
  readonly property var networks: net ? net.networks.slice(0, maxRows) : []

  spacing: Type.px(10)

  Item {
    width: parent.width; height: Type.px(22)
    Text { anchors.verticalCenter: parent.verticalCenter; text: "Wi-Fi"; color: Ink.ink2; font.family: Type.text; font.pixelSize: Type.px(12.5); font.weight: Font.Medium; font.variableAxes: Type.valueAxes }
    KataSwitch { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; skin: root.skin; on: root.radio; onToggled: function(on) { root.request("network", "radio", on) } }
  }
  Text {
    width: parent.width; elide: Text.ElideRight
    text: root.net ? root.net.current.label : "…"
    color: root.offline ? Ink.seal : Ink.ink
    font.family: Type.display; font.pixelSize: Type.px(44); font.weight: Font.Normal
    font.variableAxes: Type.axes(Type.px(44), 360)
  }
  Text {
    text: root.net ? root.net.current.detail : ""
    color: Ink.ink3; font.family: Type.text; font.pixelSize: Type.px(12)
  }
  Divider { skin: root.skin; width: parent.width; bleed: Type.px(20) }
  Heading { skin: root.skin; text: "Nearby"; note: "R rescans" }
  KataList {
    width: parent.width
    skin: root.skin
    rows: root.networks.map(function(n) { return { title: n.ssid, detail: n.detail, note: n.current ? "" : n.note, chosen: n.current } })
    onPicked: function(i) { var n = root.networks[i]; if (!n.current) root.request("network", "connect", { ssid: n.ssid, saved: n.saved, secure: n.secure }) }
  }
  Keys.onPressed: function(e) { if (e.key === Qt.Key_R) root.request("network", "rescan", null) }
}
