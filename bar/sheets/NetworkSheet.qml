pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Net.js" as NetJs
import "../parts"

// Network 網: the connection you are on as the title (red when offline),
// the Wi-Fi around you with the one in use inverted, and at the foot the
// Wi-Fi switch, Omarchy's share card and its speed test. Supports two views:
// the tactile folding fan radar (WifiFan 扇) and the classic row list.
// A click on a network connects to it. R rescans.
Item {
  id: root

  // core/Net.js sheet() shape, or null before the first reading.
  property var net: null
  // Rows shown at most; the rest are further away anyway.
  property int maxRows: 7
  // "fan" (folding fan radar) or "list" (classic rows)
  property string viewMode: "fan"

  // what: connect ({ ssid, saved, secure }) | radio (bool) | rescan |
  // share | speedtest
  signal request(string what, var arg)

  readonly property var current: net ? net.current : { kind: "", label: "…", detail: "" }
  readonly property var networks: net ? net.networks.slice(0, maxRows) : []
  readonly property bool radio: !net || net.radio

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead {
      sheet: "network"
      jp: "網"
      label: "Network · NetworkManager"
      title: root.current.label
      titleColor: root.net && root.net.offline ? Ink.seal : Ink.ink
      blurb: root.current.detail
    }

    GroupHead {
      title: "Wi-Fi"
      summary: root.networks.length + (root.networks.length === 1 ? " network" : " networks")
      actions: root.radio ? [
        { text: root.viewMode === "fan" ? "List 覧" : "Fan 扇", name: "toggleView" },
        { text: "Rescan", name: "rescan" }
      ] : []
      onPicked: function(name) {
        if (name === "toggleView") root.viewMode = (root.viewMode === "fan" ? "list" : "fan")
        else if (name === "rescan") root.request("rescan", null)
      }
    }

    SheetRow {
      visible: !root.radio || root.networks.length === 0
      name: root.radio ? "Looking for networks" : "Wi-Fi is off"
      detail: root.radio ? "" : "Turn it on below to see what is around."
      last: true
    }

    // ── Sensu (Folding fan radar) View ─────────────────────────────────────
    Item {
      visible: root.radio && root.networks.length > 0 && root.viewMode === "fan"
      width: parent.width
      height: fanRadar.implicitHeight + Type.px(14)

      WifiFan {
        id: fanRadar
        anchors.centerIn: parent
        size: Math.min(parent.width - Type.px(16), Type.px(300))
        networks: root.net ? root.net.networks : []
        onPicked: function(ssid, secure, saved) {
          root.request("connect", { ssid: ssid, saved: saved, secure: secure })
        }
      }
    }

    // ── Classic List View ──────────────────────────────────────────────────
    Repeater {
      model: (root.radio && root.viewMode === "list") ? root.networks : []
      SheetRow {
        id: network
        required property var modelData
        required property int index
        lead: true
        selected: modelData.current
        interactive: !modelData.current
        name: modelData.ssid
        detail: modelData.detail
        note: modelData.note
        last: index === root.networks.length - 1
        onClicked: root.request("connect", { ssid: network.modelData.ssid, saved: network.modelData.saved,
                                             secure: network.modelData.secure })

        // Signal as four rising bars, inked up to the strength.
        Row {
          spacing: 2
          Repeater {
            model: 4
            Rectangle {
              id: bar
              required property int index
              anchors.bottom: parent.bottom
              width: 3
              height: 4 + 3 * bar.index
              color: network.modelData.signal > bar.index * 25
                ? (network.selected ? Ink.boneInk : Ink.inkDim)
                : (network.selected ? Ink.alpha(Ink.boneInk, 0.3) : Ink.line)
            }
          }
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom

    SheetButton {
      ghost: true
      text: root.radio ? "Wi-Fi off" : "Wi-Fi on"
      onClicked: root.request("radio", !root.radio)
    }
    SheetButton {
      ghost: true
      visible: root.current.kind === "wifi"
      text: "Share"
      onClicked: root.request("share", null)
    }
    SheetButton {
      plate: true
      text: "Speed test ›"
      onClicked: root.request("speedtest", null)
    }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_R) { root.request("rescan", null); event.accepted = true }
  }
}

