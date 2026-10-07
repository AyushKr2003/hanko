pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Blue.js" as BlueJs

// 04 // BLUETOOTH: what is connected as the title, then your devices,
// connected ones on a plate, known and nearby ones below; a click
// connects, disconnects or pairs. Off, a single row turns it on.
ScrollSection {
  id: root

  // core/Blue.js sheet() shape.
  property var blue: null

  signal request(string what, var arg)

  readonly property bool powered: !!(blue && blue.enabled)
  readonly property var devices: blue && powered ? blue.connected.concat(blue.known, blue.found).slice(0, 5) : []

  title: blue ? blue.title : "Bluetooth"
  caption: blue ? blue.blurb : ""

  Column {
    width: parent.width
    topPadding: Type.px(18)

    ListRow {
      visible: !!(root.blue && root.blue.present && !root.powered)
      name: "Bluetooth is off"
      note: "Turn on"
      interactive: true
      onClicked: root.request("power", true)
    }

    Repeater {
      model: root.devices
      ListRow {
        id: device
        required property var modelData
        required property int index
        position: device.index
        name: modelData.name
        note: modelData.note || (modelData.detail ? modelData.detail.split(" · ")[0] : "New")
        on: modelData.connected
        ruled: device.index > 0 && !root.devices[device.index - 1].connected
        interactive: true
        onClicked: root.request("device", { address: device.modelData.address, action: BlueJs.action(device.modelData) })
      }
    }
  }
}
