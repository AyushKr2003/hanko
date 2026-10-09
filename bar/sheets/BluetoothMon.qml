pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Blue.js" as BlueJs

// Bluetooth 藍, Mon (紋): the connected device's charge as the sheet's kuyō,
// then every device in reach as a crest, a kuyō of its charge where it
// says one, its own mon where it doesn't; connected ones inked red. A click
// connects, disconnects or pairs. P switches Bluetooth.
Item {
  id: root

  property var blue: null
  signal request(string what, var arg)

  readonly property bool powered: !!(blue && blue.enabled)
  readonly property var all: blue && powered ? blue.connected.concat(blue.known).concat(blue.found).slice(0, 8) : []
  readonly property var first: blue && powered && blue.connected.length ? blue.connected[0] : null

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead { sheet: "bluetooth"; jp: "藍"; label: "Bluetooth · BlueZ"; compact: true }
    Item { width: 1; height: Type.px(18) }

    MonHero {
      kind: root.first && root.first.level >= 0 ? "kuyo" : "moji"
      glyph: "藍"
      level: root.first && root.first.level >= 0 ? root.first.level / 100 : -1
      red: !!(root.first && root.first.level >= 0 && root.first.level / 100 <= BlueJs.LOW)
      figure: root.first && root.first.level >= 0 ? String(root.first.level) : root.powered ? "On" : "Off"
      unit: root.first && root.first.level >= 0 ? "%" : ""
      title: root.first ? root.first.name : root.blue ? root.blue.blurb : ""
      lines: root.blue && root.blue.scanning ? ["Looking for devices…"] : []
      SheetButton {
        visible: !!(root.blue && root.blue.present)
        text: "Bluetooth"
        on: root.powered
        onClicked: root.request("power", !root.powered)
      }
    }

    MonPage {
      id: devs
      visible: root.powered && root.all.length > 0
      jp: "器"
      label: "In reach"
      summary: root.all.length + (root.all.length === 1 ? " device" : " devices")
      Repeater {
        model: root.all
        CrestCell {
          required property var modelData
          required property int index
          width: devs.cellWidth
          kind: modelData.level >= 0 ? "kuyo" : "wa"
          level: modelData.level >= 0 ? modelData.level / 100 : -1
          urgent: modelData.level >= 0 && modelData.level / 100 <= BlueJs.LOW && !modelData.connected
          name: modelData.name
          note: (modelData.level >= 0 ? modelData.level + "% · " : "") + (modelData.note || "nearby")
          selected: modelData.connected
          onClicked: root.request("device", { address: modelData.address, action: BlueJs.action(modelData) })
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.blue && !root.blue.present ? "No adapter" : root.powered ? "Click a crest to connect" : "Bluetooth is off"
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_P) { root.request("power", !root.powered); event.accepted = true }
  }
}
