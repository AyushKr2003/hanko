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
  // Every network seen lately (core/Net.js remember()), so the list holds
  // when NetworkManager prunes its cache down to the one you're on.
  property var _seen: ({})

  function _take(text) {
    var kept = NetJs.remember(_seen, NetJs.parseWifi(text), Date.now())
    _seen = kept.seen
    wifi = kept.rows
  }

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
  // A full scan: nmcli waits for it (5 to 8 s) and prints what it found,
  // so the list fills as soon as the scan lands, not at the next poll.
  function rescan() { if (!fresh.running) fresh.running = true }

  // The poll below reads NetworkManager's cache (--rescan no), which it
  // barely refreshes while connected and prunes as access points age out.
  // So scan on opening and every half minute while open, and remember
  // what was seen (_take).
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
        root._take(parts[2] || "")
      }
    }
  }

  property Process fresh: Process {
    command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,FREQ,SSID", "device", "wifi", "list", "--rescan", "yes"]
    stdout: StdioCollector {
      onStreamFinished: if (String(text || "").trim() !== "") root._take(text)
    }
  }
}
