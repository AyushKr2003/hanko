pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../core/Sound.js" as SoundJs

// The Sound sheet's data: the master (the same resolved sink the bar shows,
// see Status.volumeSink), the outputs, the apps playing and the input. Only
// gathered while the sheet is open. Nodes are copied into plain objects
// before anything is drawn (core/Sound.js), and every action looks its node
// up again by id and name, as Omarchy's audio panel does: Pipewire deletes
// nodes at will and reuses ids.
Singleton {
  id: root

  // Set by Bar.qml while the Sound sheet is open.
  property bool wanted: false

  readonly property var nodes: wanted && Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var sinks: nodes.filter(function(n) { return n && n.isSink && !n.isStream })
  readonly property var playback: nodes.filter(function(n) { return n && n.isStream && root.isPlayback(n) })
  readonly property var source: Pipewire.defaultAudioSource

  // Bound nodes report their properties and volume.
  PwObjectTracker { objects: root.wanted ? root.sinks.concat(root.playback, root.source ? [root.source] : []) : [] }

  // name -> false for sinks Omarchy reports unplugged or fronted by a tuning.
  property var available: ({})

  // Playback streams accept audio from apps and publish as sinks; reading
  // the media class only as a fallback (Quickshell versions differ).
  function isPlayback(n) {
    if (n.isSink === true) return true
    var t = String(n.type || "")
    return t.indexOf("Output") >= 0
  }

  readonly property var propKeys: ["node.nick", "node.description", "node.name", "device.profile.description",
    "device.bus", "device.product.name", "api.bluez5.codec", "audio.rate", "application.name", "media.name"]

  function plain(n) {
    if (!n) return null
    var props = {}
    if (n.ready && n.properties) for (var i = 0; i < propKeys.length; i++) {
      var v = n.properties[propKeys[i]]
      if (v !== undefined && v !== null) props[propKeys[i]] = v
    }
    return { id: n.id, name: String(n.name || ""), description: String(n.description || ""),
             nickname: String(n.nickname || ""), props: props,
             volume: n.audio ? n.audio.volume : 0, muted: n.audio ? n.audio.muted : false }
  }

  // core/Sound.js sheet() shape, or null while the sheet is closed.
  readonly property var reading: wanted
    ? SoundJs.sheet(plain(Status.volumeSink), plain(Status.sink), sinks.map(plain), playback.map(plain), plain(source), available)
    : null

  function find(id, name) {
    var all = Pipewire.nodes ? Pipewire.nodes.values : []
    for (var i = 0; i < all.length; i++)
      if (all[i] && all[i].id === id && String(all[i].name) === String(name)) return all[i]
    return null
  }

  function setMaster(v) {
    var s = Status.volumeSink
    if (s && s.audio) s.audio.volume = Math.max(0, Math.min(1, v))
  }
  function toggleMute() { Quickshell.execDetached(["omarchy-audio-output-volume", "mute-toggle"]) }
  function setOutput(id, name) {
    var n = find(id, name)
    if (!n) return
    Pipewire.preferredDefaultAudioSink = n
    Quickshell.execDetached(["omarchy-audio-output-set-default", String(id), String(name)])
  }
  function nextOutput() { Quickshell.execDetached(["omarchy-audio-output-switch"]) }
  function setStream(id, name, v) {
    var n = find(id, name)
    if (n && n.audio) n.audio.volume = Math.max(0, Math.min(1, v))
  }
  function toggleStream(id, name) {
    var n = find(id, name)
    if (n && n.audio) n.audio.muted = !n.audio.muted
  }
  function setInput(v) {
    if (root.source && root.source.audio) root.source.audio.volume = Math.max(0, Math.min(1, v))
  }
  function toggleInput() { Quickshell.execDetached(["omarchy-audio-input-mute"]) }

  // Availability changes when things are plugged in; check while open.
  property Timer _availability: Timer {
    interval: 5000
    repeat: true
    running: root.wanted
    triggeredOnStart: true
    onTriggered: if (!root._availProc.running) root._availProc.running = true
  }
  property Process _availProc: Process {
    command: ["omarchy-audio-sink-availability"]
    stdout: StdioCollector {
      onStreamFinished: {
        var next = {}
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var f = lines[i].trim().split("\t")
          if (f.length >= 2) next[f[0]] = f[1] !== "0"
        }
        root.available = next
      }
    }
  }
}
