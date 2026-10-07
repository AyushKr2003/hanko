pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// 03 // NETWORK: the network you're on as the title, then the networks
// around you, the joined one on a plate, each with its signal.
ScrollSection {
  id: root

  // core/Net.js sheet() shape.
  property var net: null

  signal request(string what, var arg)

  readonly property var networks: net && net.radio ? net.networks.slice(0, 5) : []

  title: net ? net.current.label : "…"
  caption: net ? net.current.detail : ""

  Column {
    width: parent.width
    topPadding: Type.px(18)

    ListRow {
      visible: root.networks.length === 0
      name: root.net && !root.net.radio ? "Wi-Fi is off" : "Looking for networks"
      note: root.net && !root.net.radio ? "Off" : ""
      interactive: !!(root.net && !root.net.radio)
      onClicked: root.request("radio", true)
    }

    Repeater {
      model: root.networks
      ListRow {
        id: wifi
        required property var modelData
        required property int index
        position: wifi.index
        name: modelData.ssid
        note: modelData.current ? "Joined" : modelData.saved ? "Saved" : modelData.secure ? "WPA" : "Open"
        on: modelData.current
        ruled: wifi.index > 0 && !root.networks[wifi.index - 1].current
        interactive: !modelData.current
        onClicked: root.request("connect", { ssid: wifi.modelData.ssid, saved: wifi.modelData.saved, secure: wifi.modelData.secure })
        trailing: Component {
          SignalBars {
            lit: Math.max(1, Math.min(4, Math.ceil(wifi.modelData.signal / 25)))
            ink: wifi.on ? Ink.boneInk : Ink.inkMuted
          }
        }
      }
    }
  }
}
