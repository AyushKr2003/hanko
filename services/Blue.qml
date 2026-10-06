pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../core/Blue.js" as BlueJs

// Bluetooth 藍 for the bar's BT cell, its sheet and its scroll section.
// BlueZ devices are copied into plain objects before anything draws them
// (core/Blue.js), and every action goes through Omarchy's scripts, as its
// own Bluetooth panel does: omarchy-bluetooth-power (which persists across
// reboots, unlike flipping BlueZ's Powered) and omarchy-bluetooth-device.
Singleton {
  id: root

  // Set by Bar.qml while the Bluetooth sheet or the scroll is open: the
  // adapter scans for new devices only then.
  property bool wanted: false

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool present: adapter !== null && adapter !== undefined
  readonly property bool powered: present && adapter.enabled === true
  readonly property bool scanning: present && adapter.discovering === true

  readonly property var devices: {
    var values = Bluetooth.devices ? Bluetooth.devices.values : []
    var out = []
    for (var i = 0; i < values.length; i++) {
      var d = values[i]
      if (!d) continue
      out.push({ address: String(d.address || ""), name: String(d.deviceName || d.name || ""),
                 icon: String(d.icon || ""), connected: !!d.connected,
                 paired: !!(d.paired || d.bonded || d.trusted), pairing: !!d.pairing,
                 battery: d.batteryAvailable ? Number(d.battery) : -1 })
    }
    return out
  }

  // The bar cell (core/Status.js shape) and the panel (core/Blue.js sheet()).
  readonly property var cell: BlueJs.cell(present, powered, devices)
  readonly property var reading: wanted ? BlueJs.sheet(present, powered, scanning, devices) : null

  // Scan while the panel is open, stop when it closes.
  onWantedChanged: setScan(wanted)
  onPoweredChanged: if (wanted) setScan(true)
  function setScan(on) {
    if (present && powered && adapter.discovering !== on) adapter.discovering = on
  }

  function setPower(on) { Quickshell.execDetached(["omarchy-bluetooth-power", on ? "on" : "off"]) }
  function device(address, action) {
    if (!/^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(String(address))) return
    if (["pair", "connect", "disconnect", "forget"].indexOf(action) < 0) return
    Quickshell.execDetached(["omarchy-bluetooth-device", action, address])
  }
}
