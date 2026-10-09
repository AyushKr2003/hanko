pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Network 網, Tanzaku (短冊): the network you are on on the first slip (its
// signal as the wash; red when offline), then a slip for each network
// around you, hung as far as its signal; the one in use inked and sealed.
// A click joins. R rescans.
Item {
  id: root

  property var net: null
  property int maxRows: 6
  signal request(string what, var arg)

  readonly property var current: net ? net.current : { kind: "", label: "…", detail: "" }
  readonly property var networks: net && net.radio ? net.networks.slice(0, maxRows) : []
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
    bottomPadding: Type.px(18)

    SheetHead { sheet: "network"; jp: "網"; label: "Network · NetworkManager"; compact: true }
    Item { width: 1; height: Type.px(18) }

    TanzakuRail {
      LeadStrip {
        mark: "網"
        figure: root.here ? String(root.here.signal) : root.net && root.net.offline ? "off" : "—"
        unit: root.here ? "%" : ""
        caption: root.net && root.net.offline ? "offline" : root.current.label
        level: root.here ? root.here.signal / 100 : -1
        red: !!(root.net && root.net.offline)
        muted: !!(root.net && root.net.offline)
      }
      Repeater {
        model: root.networks
        Tanzaku {
          required property var modelData
          name: modelData.ssid
          foot: modelData.signal + "%"
          level: modelData.signal / 100
          selected: modelData.current
          interactive: !modelData.current
          onClicked: root.request("connect", { ssid: modelData.ssid, saved: modelData.saved, secure: modelData.secure })
        }
      }
    }
    TanzakuFoot { text: root.radio ? "Each slip hangs as far as its signal · click to join" : "Wi-Fi is off" }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    SheetButton { text: "Wi-Fi"; on: root.radio; onClicked: root.request("radio", !root.radio) }
    SheetButton { ghost: true; visible: root.radio; text: "Rescan"; onClicked: root.request("rescan", null) }
    SheetButton { plate: true; text: "Speed test ›"; onClicked: root.request("speedtest", null) }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_R) { root.request("rescan", null); event.accepted = true }
  }
}
