pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Network 網, Mon (紋): the network you are on as the sheet's kuyō (its
// stars lit with the signal; red when offline), then every network around
// you as a kuyō of its own signal, the one you are on inked red. A click
// joins. R rescans.
Item {
  id: root

  property var net: null
  property int maxRows: 8
  signal request(string what, var arg)

  readonly property var current: net ? net.current : { kind: "", label: "…", detail: "" }
  readonly property var networks: net && net.radio ? net.networks.slice(0, maxRows) : []
  readonly property bool radio: !net || net.radio
  readonly property bool offline: !!(net && net.offline)
  readonly property var here: {
    for (var i = 0; i < networks.length; i++) if (networks[i].current) return networks[i]
    return null
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead { sheet: "network"; jp: "網"; label: "Network · NetworkManager"; compact: true }
    Item { width: 1; height: Type.px(18) }

    MonHero {
      kind: root.here ? "kuyo" : "moji"
      glyph: "網"
      level: root.here ? root.here.signal / 100 : -1
      red: root.offline
      figure: root.offline ? "Offline" : root.current.label
      title: root.current.detail
      titleColor: Ink.inkDim
      lines: [root.radio ? "Wi-Fi on" : "Wi-Fi off"]
      SheetButton { text: "Wi-Fi"; on: root.radio; onClicked: root.request("radio", !root.radio) }
    }

    MonPage {
      id: nets
      visible: root.radio
      jp: "波"
      label: "Around you"
      summary: root.networks.length + (root.networks.length === 1 ? " network" : " networks")
      Repeater {
        model: root.networks
        CrestCell {
          required property var modelData
          width: nets.cellWidth
          kind: "kuyo"
          level: modelData.signal / 100
          name: modelData.ssid
          note: modelData.signal + "%" + (modelData.note ? " · " + modelData.note : "")
          selected: modelData.current
          interactive: !modelData.current
          onClicked: root.request("connect", { ssid: modelData.ssid, saved: modelData.saved, secure: modelData.secure })
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    SheetButton { ghost: true; visible: root.radio; text: "Rescan"; onClicked: root.request("rescan", null) }
    SheetButton { ghost: true; visible: root.current.kind === "wifi"; text: "Share"; onClicked: root.request("share", null) }
    SheetButton { plate: true; text: "Speed test ›"; onClicked: root.request("speedtest", null) }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_R) { root.request("rescan", null); event.accepted = true }
  }
}
