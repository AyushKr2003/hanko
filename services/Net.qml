pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Net.js" as NetJs

// The Network sheet's data: Wi-Fi switched on or not, the saved networks
// and the networks around you, read from nmcli every few seconds while the
// sheet is open. The connection itself is the bar's own reading
// (Status.network, from omarchy-network-status).
Singleton {
  id: root

  // Set by Bar.qml while the Network sheet is open.
  property bool wanted: false

  property bool radio: true
  property var saved: []
  property var wifi: []

  // core/Net.js sheet() shape, or null while the sheet is closed.
  readonly property var reading: wanted ? NetJs.sheet(Status.network, wifi, saved, radio) : null

  function refresh() { if (!scan.running) scan.running = true }

  // A saved network comes up by name; an open one connects directly; one
  // that needs a password opens nmtui in a terminal to ask for it.
  function connect(ssid, saved, secure) {
    var how = NetJs.connectHow({ saved: saved, secure: secure })
    if (how === "up") Status.run(["nmcli", "connection", "up", "id", ssid])
    else if (how === "open") Status.run(["nmcli", "device", "wifi", "connect", ssid])
    else Quickshell.execDetached(["xdg-terminal-exec", "nmtui-connect", ssid])
    again.restart()
  }
  function disconnect(ssid) { Status.run(["nmcli", "connection", "down", "id", ssid]); again.restart() }
  function setRadio(on) { Status.run(["nmcli", "radio", "wifi", on ? "on" : "off"]); again.restart() }
  function rescan() { Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]); again.restart() }

  // The list below is NetworkManager's cache (--rescan no), which it
  // barely refreshes while connected and prunes as access points age out:
  // left alone it shrinks to the network you're on. So scan on opening
  // and every half minute while open.
  onWantedChanged: if (wanted) rescan()
  property Timer _scan: Timer {
    interval: 30000
    repeat: true
    running: root.wanted
    onTriggered: root.rescan()
  }

  property Timer _poll: Timer {
    interval: 5000
    repeat: true
    running: root.wanted
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
  // After an action, look again once NetworkManager has had a moment.
  property Timer again: Timer { interval: 1500; onTriggered: root.refresh() }

  property Process scan: Process {
    command: ["sh", "-c", "nmcli radio wifi; echo '%%'; nmcli -t -f NAME,TYPE connection show; echo '%%';"
      + " nmcli -t -f IN-USE,SIGNAL,SECURITY,FREQ,SSID device wifi list --rescan no"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = String(text || "").split("%%\n")
        root.radio = String(parts[0] || "").trim() !== "disabled"
        root.saved = NetJs.parseSaved(parts[1] || "")
        root.wifi = NetJs.parseWifi(parts[2] || "")
      }
    }
  }
}
