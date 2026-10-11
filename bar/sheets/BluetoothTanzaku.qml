pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Blue.js" as BlueJs

// Bluetooth 藍, Tanzaku (短冊): the connected device on the first slip (its
// charge as the wash, red when low), then a slip for every device, hung as
// far as its charge (at rest when it doesn't say); connected ones inked and
// sealed. A click connects, disconnects or pairs. P switches Bluetooth.
Item {
  id: root

  property var blue: null
  signal request(string what, var arg)

  readonly property bool powered: !!(blue && blue.enabled)
  readonly property var all: blue && powered ? blue.connected.concat(blue.known).concat(blue.found).slice(0, 6) : []
  readonly property var first: blue && powered && blue.connected.length ? blue.connected[0] : null

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(18)

    SheetHead { sheet: "bluetooth"; jp: "藍"; label: "Bluetooth · BlueZ"; compact: true }
    Item { width: 1; height: Type.px(18) }

    TanzakuRail {
      LeadStrip {
        mark: "藍"
        figure: root.first && root.first.level >= 0 ? String(root.first.level) : root.powered ? "—" : "off"
        unit: root.first && root.first.level >= 0 ? "%" : ""
        caption: root.first ? root.first.name : root.blue ? root.blue.title : "Bluetooth"
        level: root.first && root.first.level >= 0 ? root.first.level / 100 : -1
        red: !!(root.first && root.first.level >= 0 && root.first.level / 100 <= BlueJs.LOW)
      }
      Repeater {
        model: root.all
        Tanzaku {
          required property var modelData
          name: modelData.name
          foot: modelData.level >= 0 ? modelData.level + "%" : (modelData.paired ? "·" : "new")
          level: modelData.level >= 0 ? modelData.level / 100 : -1
          urgent: modelData.level >= 0 && modelData.level / 100 <= BlueJs.LOW
          selected: modelData.connected
          onClicked: root.request("device", { address: modelData.address, action: BlueJs.action(modelData) })
        }
      }
    }
    TanzakuFoot {
      text: !root.blue || !root.blue.present ? "No adapter" : !root.powered ? "Bluetooth is off"
          : root.blue.scanning ? "Looking for devices · click a slip to connect" : "Each slip hangs as far as its charge"
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    SheetButton {
      visible: !!(root.blue && root.blue.present)
      text: "Bluetooth"
      on: root.powered
      onClicked: root.request("power", !root.powered)
    }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_P) { root.request("power", !root.powered); event.accepted = true }
  }
}
