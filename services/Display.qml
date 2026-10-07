pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../core/Display.js" as DisplayJs

// The Display panel's data: every monitor Hyprland knows and the
// brightness of the one the panel speaks for, read every few seconds while
// the panel is open, as Omarchy's own Display panel reads them. Night light
// is Omarchy's nightlight service (Extras.nightProxy).
Singleton {
  id: root

  // Set by Bar.qml while the Display sheet or the scroll is open.
  property bool wanted: false

  property var monitors: []
  // The monitor picked in the panel ("" = the focused one).
  property string picked: ""
  property int percent: -1

  readonly property string target: DisplayJs.target(monitors, picked)
  // core/Display.js sheet() shape, or null while closed.
  readonly property var reading: wanted
    ? DisplayJs.sheet(monitors, picked, percent, !!(Extras.nightProxy && Extras.nightProxy.enabled)) : null

  function refresh() { if (!monitorsProc.running) monitorsProc.running = true }
  function readBrightness() {
    if (!target || brightnessProc.running) return
    brightnessProc.command = ["omarchy-brightness-display", "--monitor", target]
    brightnessProc.running = true
  }
  onTargetChanged: { percent = -1; readBrightness() }

  // A drag sends many values; only the last one in each 120 ms goes out.
  property int _queued: -1
  function setBrightness(v) {
    _queued = Math.max(1, Math.min(100, Math.round(v * 100)))
    percent = _queued
    if (!_send.running) _send.start()
  }
  property Timer _send: Timer {
    interval: 120
    onTriggered: {
      if (root._queued < 0 || !root.target) return
      Quickshell.execDetached(["omarchy-brightness-display", "--no-osd", "--monitor", root.target, root._queued + "%"])
      root._queued = -1
    }
  }
  function pick(name) { picked = String(name || "") }
  function setNight(on) { if (Extras.nightProxy) Extras.nightProxy.setNightlight(!!on) }
  function editMonitors() {
    Quickshell.execDetached(["omarchy-launch-editor", Quickshell.env("HOME") + "/.config/hypr/monitors.lua"])
  }

  property Timer _poll: Timer {
    interval: 5000
    repeat: true
    running: root.wanted
    triggeredOnStart: true
    onTriggered: { root.refresh(); root.readBrightness() }
  }
  property Connections _events: Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (root.wanted && ["monitoradded", "monitorremoved", "focusedmon"].indexOf(event.name) >= 0) root.refresh()
    }
  }

  property Process monitorsProc: Process {
    command: ["hyprctl", "monitors", "all", "-j"]
    stdout: StdioCollector { onStreamFinished: root.monitors = DisplayJs.monitors(text) }
  }
  property Process brightnessProc: Process {
    stdout: StdioCollector { onStreamFinished: root.percent = DisplayJs.brightness(text) }
  }
}
