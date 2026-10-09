pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Network 網, Prose (文): "On Kumo, Wi-Fi · WPA2 · 5 GHz. Four networks are
// around you; Wi-Fi is on." The network name runs the speed test, the count
// rescans, the state switches Wi-Fi; the networks are an index below.
Item {
  id: root

  property var net: null
  property int maxRows: 7
  signal request(string what, var arg)

  readonly property var current: net ? net.current : { kind: "", label: "…", detail: "" }
  readonly property var networks: net ? net.networks.slice(0, maxRows) : []
  readonly property bool radio: !net || net.radio
  readonly property bool offline: !!(net && net.offline)
  readonly property var words: ["No", "One", "Two", "Three", "Four", "Five", "Six", "Seven"]

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(22)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "network"; jp: "網"; label: "Network · NetworkManager"; compact: true }
    Item { width: 1; height: Type.px(16) }

    ProseText {
      id: line
      text: {
        var s = root.offline ? line.red("Offline") + ". " : "On " + line.word("speed", root.current.label) + (root.current.detail ? ", " + line.em(root.current.detail) : "") + ". "
        if (root.radio) {
          var n = root.networks.length
          s += line.word("rescan", (root.words[n] || n) + (n === 1 ? " network is" : " networks are")) + " around you; "
        }
        s += "Wi-Fi is " + line.word("radio", root.radio ? "on" : "off") + "."
        return s
      }
      onPicked: function(a) {
        if (a === "speed") root.request("speedtest", null)
        else if (a === "rescan") root.request("rescan", null)
        else if (a === "radio") root.request("radio", !root.radio)
      }
    }

    ProseIndex {
      visible: root.radio
      label: "Wi-Fi"
      summary: "click to join"
      Repeater {
        model: root.radio ? root.networks : []
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: modelData.ssid
          note: modelData.signal + "%" + (modelData.note ? " · " + modelData.note : "")
          selected: modelData.current
          interactive: !modelData.current
          onClicked: root.request("connect", { ssid: modelData.ssid, saved: modelData.saved, secure: modelData.secure })
        }
      }
    }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_R) { root.request("rescan", null); event.accepted = true }
  }
}
