pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Blue.js" as BlueJs

// Bluetooth 藍, Dial (盤): the connected device's charge as the gauge, its
// name beside it with the power switch, then every device as a tile:
// connected (a click disconnects), paired (connects), nearby (pairs).
// P switches Bluetooth.
Item {
  id: root

  property var blue: null
  signal request(string what, var arg)

  readonly property bool powered: !!(blue && blue.enabled)
  readonly property var connected: blue && powered ? blue.connected : []
  readonly property var others: blue && powered ? blue.known.concat(blue.found).slice(0, 6) : []
  readonly property var first: connected.length ? connected[0] : null

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead { sheet: "bluetooth"; jp: "藍"; label: "Bluetooth · BlueZ"; compact: true }
    Item { width: 1; height: Type.px(16) }

    DialHero {
      interactive: false
      value: root.first && root.first.level >= 0 ? root.first.level / 100 : -1
      red: !!(root.first && root.first.level >= 0 && root.first.level / 100 <= BlueJs.LOW)
      figure: root.first && root.first.level >= 0 ? String(root.first.level) : root.powered ? "—" : "Off"
      unit: root.first && root.first.level >= 0 ? "%" : ""
      caption: root.first ? "charge" : root.powered ? "no device" : "bluetooth"
      title: root.blue ? root.blue.title : "Bluetooth"
      titleColor: root.powered ? Ink.ink : Ink.inkMuted
      lines: [root.blue ? root.blue.blurb : ""]
      SheetButton {
        visible: !!(root.blue && root.blue.present)
        text: root.powered ? "Bluetooth on" : "Bluetooth off"
        on: root.powered
        onClicked: root.request("power", !root.powered)
      }
    }

    TileSection {
      id: devices
      visible: root.powered
      label: "Devices"
      summary: root.blue && root.blue.scanning ? "looking…" : (root.connected.length + root.others.length) + " in reach"
      Repeater {
        model: root.connected.concat(root.others)
        Tile {
          required property var modelData
          width: devices.tileWidth
          name: modelData.name
          detail: modelData.detail
          note: modelData.note
          level: modelData.level >= 0 ? modelData.level / 100 : -1
          urgent: modelData.level >= 0 && modelData.level / 100 <= BlueJs.LOW
          selected: modelData.connected
          onClicked: root.request("device", { address: modelData.address, action: BlueJs.action(modelData) })
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.blue && !root.blue.present ? "No adapter" : root.powered ? "Click a device to connect or pair" : "Bluetooth is off"
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_P) { root.request("power", !root.powered); event.accepted = true }
  }
}
