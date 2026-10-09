pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Network 網, Dial (盤): the signal of the network you are on as the gauge,
// its name beside it (red when offline) with the Wi-Fi switch and the
// speed test, then the networks around you as tiles, each with its signal
// along its foot. A click connects. R rescans.
Item {
  id: root

  property var net: null
  property int maxRows: 6
  signal request(string what, var arg)

  readonly property var current: net ? net.current : { kind: "", label: "…", detail: "" }
  readonly property var networks: net ? net.networks.slice(0, maxRows) : []
  readonly property bool radio: !net || net.radio
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
    Item { width: 1; height: Type.px(16) }

    DialHero {
      interactive: false
      value: root.here ? root.here.signal / 100 : root.current.kind === "wired" ? 1 : -1
      red: !!(root.net && root.net.offline)
      figure: root.here ? String(root.here.signal) : root.current.kind === "wired" ? "LAN" : "—"
      unit: root.here ? "%" : ""
      caption: root.here ? "signal" : root.net && root.net.offline ? "offline" : root.current.kind
      title: root.current.label
      titleColor: root.net && root.net.offline ? Ink.seal : Ink.ink
      lines: [root.current.detail]
      SheetButton { text: root.radio ? "Wi-Fi on" : "Wi-Fi off"; on: root.radio; onClicked: root.request("radio", !root.radio) }
      SheetButton { plate: true; text: "Speed test ›"; onClicked: root.request("speedtest", null) }
    }

    TileSection {
      id: list
      label: "Wi-Fi"
      summary: !root.radio ? "off" : root.networks.length + (root.networks.length === 1 ? " network" : " networks")
      Repeater {
        model: root.radio ? root.networks : []
        Tile {
          required property var modelData
          width: list.tileWidth
          name: modelData.ssid
          detail: modelData.detail
          note: modelData.note
          level: modelData.signal / 100
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
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_R) { root.request("rescan", null); event.accepted = true }
  }
}
