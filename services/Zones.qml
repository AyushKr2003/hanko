pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Time.js" as T

// Elsewhen's cities for the Time sheet. The list comes from Omarchy's bar
// layout (the omarchy.elsewhen entry's `zones`), or Elsewhen's own seed
// cities when unset; each zone's offset comes from one `date` probe, since
// QML has no time zone database. Probed when the Time sheet opens and every
// half hour while it stays open (offsets change at DST).
Singleton {
  id: root

  // Set by Bar.qml.
  property var barConfig: ({})
  property bool wanted: false

  readonly property var zones: T.zonesFromBarConfig(barConfig)
  property var probe: ({})
  // Minutes east of UTC here, refreshed with each probe.
  property int localOffset: -new Date().getTimezoneOffset()

  // core/Time.js zoneRow() shapes at `now`.
  function rows(now, hour24) {
    return T.zoneRows(zones, probe, now, localOffset, hour24)
  }

  function refresh() {
    localOffset = -new Date().getTimezoneOffset()
    if (zones.length === 0 || probeProc.running) return
    probeProc.command = T.probeCommand(zones.map(function(z) { return z.id }))
    probeProc.running = true
  }

  onWantedChanged: if (wanted) refresh()
  onZonesChanged: if (wanted) refresh()

  property Timer _again: Timer {
    interval: 30 * 60 * 1000
    repeat: true
    running: root.wanted
    onTriggered: root.refresh()
  }

  property Process probeProc: Process {
    stdout: StdioCollector {
      onStreamFinished: root.probe = T.parseProbe(text)
    }
  }
}
