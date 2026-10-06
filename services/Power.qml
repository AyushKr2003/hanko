pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../core/Power.js" as PowerJs

// The Power sheet's data: the battery's detail and the power profiles, from
// the same scripts Omarchy's power panel runs, read while the sheet is open.
// The percentage and brightness are the bar's own readings (Status).
Singleton {
  id: root

  // Set by Bar.qml while the Power sheet is open.
  property bool wanted: false

  property var battery: ({})
  property var profiles: []

  // core/Power.js sheet() shape, or null while the sheet is closed.
  readonly property var reading: wanted ? PowerJs.sheet(battery, profiles, Status.battery, Status.brightness) : null

  function refresh() { if (!read.running) read.running = true }

  // Omarchy remembers a profile per power source, so say which one.
  function setProfile(name) {
    Status.run(["omarchy-powerprofiles-set", UPower.onBattery ? "battery" : "ac", name])
    again.restart()
  }
  function setBrightness(v) {
    Status.run(["omarchy-brightness-display", Math.max(1, Math.round(v * 100)) + "%"])
  }

  property Timer _poll: Timer {
    interval: 5000
    repeat: true
    running: root.wanted
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
  property Timer again: Timer { interval: 600; onTriggered: root.refresh() }

  property Process read: Process {
    command: ["sh", "-c", "omarchy-battery-status --shell 2>/dev/null; echo '%%'; omarchy-powerprofiles-list --active-state 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = String(text || "").split("%%\n")
        root.battery = PowerJs.keyValues(parts[0] || "")
        root.profiles = PowerJs.profiles(parts[1] || "")
      }
    }
  }
}
