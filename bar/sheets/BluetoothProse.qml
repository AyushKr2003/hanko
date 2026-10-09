pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Blue.js" as BlueJs

// Bluetooth 藍, Prose (文): "Bluetooth is on. WH-1000XM5 is connected, 80%
// charged. Two more are paired." The state switches it, a device's name
// does the obvious thing (disconnects a connected one); every device is in
// the index below. P switches Bluetooth.
Item {
  id: root

  property var blue: null
  signal request(string what, var arg)

  readonly property bool powered: !!(blue && blue.enabled)
  readonly property var connected: blue && powered ? blue.connected : []
  readonly property var all: blue && powered ? blue.connected.concat(blue.known).concat(blue.found).slice(0, 7) : []
  readonly property var words: ["No", "One", "Two", "Three", "Four", "Five", "Six", "Seven"]

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(22)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "bluetooth"; jp: "藍"; label: "Bluetooth · BlueZ"; compact: true }
    Item { width: 1; height: Type.px(16) }

    ProseText {
      id: line
      text: {
        if (!root.blue || !root.blue.present) return "This machine has no Bluetooth adapter."
        var s = "Bluetooth is " + line.word("power", root.powered ? "on" : "off") + ". "
        if (!root.powered) return s + "Turn it on to see your devices."
        if (root.connected.length) {
          var d = root.connected[0]
          var low = d.level >= 0 && d.level / 100 <= BlueJs.LOW
          s += line.word("dev0", d.name) + " is connected" + (d.level >= 0 ? ", " + (low ? line.red(d.level + "%") : d.level + "%") + " charged" : "") + ". "
          if (root.connected.length > 1) s += (root.words[root.connected.length - 1] || "More") + " more with it. "
        } else s += "Nothing is connected. "
        var known = root.blue.known.length
        if (known) s += line.em((root.words[known] || known) + (known === 1 ? " other is" : " others are")) + " paired."
        else if (root.blue.scanning) s += "Looking for devices…"
        return s
      }
      onPicked: function(a) {
        if (a === "power") root.request("power", !root.powered)
        else if (a === "dev0" && root.connected.length)
          root.request("device", { address: root.connected[0].address, action: BlueJs.action(root.connected[0]) })
      }
    }

    ProseIndex {
      visible: root.powered
      label: "Devices"
      summary: root.blue && root.blue.scanning ? "looking…" : "click to connect"
      Repeater {
        model: root.all
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: modelData.name
          note: (modelData.level >= 0 ? modelData.level + "% · " : "") + (modelData.note || "Nearby")
          selected: modelData.connected
          onClicked: root.request("device", { address: modelData.address, action: BlueJs.action(modelData) })
        }
      }
    }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_P) { root.request("power", !root.powered); event.accepted = true }
  }
}
