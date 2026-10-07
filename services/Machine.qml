pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Profile.js" as P

// The machine, for the Profile 印影 plate: who, where, kernel, compositor,
// uptime, Omarchy's theme and version (core/Profile.js PROBE, all local
// reads). Read while the settings window is open, once a minute.
Singleton {
  id: root

  property bool wanted: false
  property var info: P.parseMachine("")

  onWantedChanged: if (wanted) probe.running = true

  property Process probe: Process {
    command: ["sh", "-c", P.PROBE]
    stdout: StdioCollector { onStreamFinished: root.info = P.parseMachine(text) }
  }

  property Timer _again: Timer {
    interval: 60000
    repeat: true
    running: root.wanted
    onTriggered: root.probe.running = true
  }
}
