pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Blue.js" as BlueJs

// Bluetooth 藍: what is connected as the title, then your devices in three
// groups: connected (inverted; a click disconnects), known (a click
// connects) and nearby, found while the sheet is open (a click pairs).
// The foot switches Bluetooth on and off. P does too.
Item {
  id: root

  // core/Blue.js sheet() shape, or null before the first reading.
  property var blue: null
  property int maxKnown: 4
  property int maxFound: 4

  // what: power (bool) | device ({ address, action })
  signal request(string what, var arg)

  readonly property bool powered: !!(blue && blue.enabled)
  readonly property var connected: blue && powered ? blue.connected : []
  readonly property var known: blue && powered ? blue.known.slice(0, maxKnown) : []
  readonly property var found: blue && powered ? blue.found.slice(0, maxFound) : []

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead {
      sheet: "bluetooth"
      jp: "藍"
      label: "Bluetooth · BlueZ"
      title: root.blue ? root.blue.title : "Bluetooth"
      titleColor: root.powered ? Ink.ink : Ink.inkMuted
      blurb: root.blue ? root.blue.blurb : ""
    }

    // ------------------------------------------------ connected
    GroupHead {
      visible: root.powered
      title: "Connected"
      summary: root.connected.length + (root.connected.length === 1 ? " device" : " devices")
    }
    SheetRow {
      visible: root.powered && root.connected.length === 0
      name: "Nothing connected"
      last: true
    }
    Repeater {
      model: root.connected
      DeviceRow { selected: true }
    }

    // ------------------------------------------------ known
    GroupHead {
      visible: root.powered && root.known.length > 0
      title: "Known"
      summary: root.blue ? root.blue.known.length + " paired" : ""
    }
    Repeater {
      model: root.known
      DeviceRow {}
    }

    // ------------------------------------------------ nearby
    GroupHead {
      visible: root.powered
      title: "Nearby"
      summary: root.blue && root.blue.scanning ? "Looking…" : root.found.length + " found"
    }
    SheetRow {
      visible: root.powered && root.found.length === 0
      name: root.blue && root.blue.scanning ? "Looking for devices" : "None found"
      detail: "Put a device in pairing mode to see it here."
      last: true
    }
    Repeater {
      model: root.found
      DeviceRow {}
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.blue && !root.blue.present ? "No adapter" : ""

    SheetButton {
      visible: !!(root.blue && root.blue.present)
      plate: !root.powered
      ghost: root.powered
      text: root.powered ? "Bluetooth off" : "Bluetooth on"
      onClicked: root.request("power", !root.powered)
    }
  }

  // One device: its name, what it is and its battery; a click does the
  // obvious thing (core/Blue.js action()).
  component DeviceRow: SheetRow {
    id: device
    required property var modelData
    lead: true
    interactive: true
    name: modelData.name
    detail: modelData.detail
    note: modelData.note
    onClicked: root.request("device", { address: device.modelData.address, action: BlueJs.action(device.modelData) })
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_P) { root.request("power", !root.powered); event.accepted = true }
  }
}
