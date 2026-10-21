pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../core/Status.js" as StatusJs

// How things are: sound, network, battery, brightness and notifications,
// reduced to the plain shapes core/Status.js describes. Every reading goes
// through the same tools Omarchy's own bar and keys use, so Hanko shows what
// Omarchy would and its scroll steps raise the same OSD.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string notifDir: home + "/.local/state/omarchy/notifications"

  // Set by Bar.qml from shell.firstPartyServiceFor("omarchy.notifications").
  property var notificationsProxy: null

  // ---------------------------------------------------------- sound
  // Like Omarchy's audio panel: a DSP sink (a speaker tuning, EasyEffects)
  // fronts the physical sink where loudness lives, so read that one.
  readonly property var sink: Pipewire.defaultAudioSink
  property string volumeSinkName: ""
  readonly property var volumeSink: {
    if (volumeSinkName === "" || !sink || volumeSinkName === String(sink.name)) return sink
    var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.isSink && !n.isStream && String(n.name) === volumeSinkName && n.audio) return n
    }
    return sink
  }
  onSinkChanged: if (!sinkProc.running) sinkProc.running = true

  PwObjectTracker { objects: [root.sink, root.volumeSink] }

  readonly property var volume: volumeSink && volumeSink.audio
    ? StatusJs.volume(volumeSink.audio.volume, volumeSink.audio.muted, true) : null

  Process {
    id: sinkProc
    command: ["omarchy-audio-output-sink"]
    stdout: StdioCollector {
      onStreamFinished: root.volumeSinkName = String(text || "").trim()
    }
  }

  // ---------------------------------------------------------- battery
  readonly property var device: UPower.displayDevice
  readonly property var battery: device && device.isPresent && device.isLaptopBattery
    ? StatusJs.battery(Number(device.percentage || 0) * 100, !UPower.onBattery, true) : null

  // ---------------------------------------------------------- network
  property var network: null

  Process {
    id: netProc
    command: ["omarchy-network-status"]
    stdout: StdioCollector {
      onStreamFinished: root.network = String(text || "").trim() === "" ? null : StatusJs.network(text)
    }
  }

  // ---------------------------------------------------------- brightness
  // Laptops only: a panel with a backlight. External monitors are left to
  // Omarchy's keys and OSD.
  property var brightness: null

  Process {
    id: lightProc
    command: ["sh", "-c", "ls /sys/class/backlight/* >/dev/null 2>&1 && brightnessctl -m -c backlight 2>/dev/null | head -n 1"]
    stdout: StdioCollector {
      onStreamFinished: root.brightness = StatusJs.brightness(text)
    }
  }

  // ---------------------------------------------------------- notifications
  // Omarchy keeps every live toast and the last ten it showed as one-line
  // JSON files; Hanko reads those rather than running a second server.
  property var notifications: []
  readonly property bool doNotDisturb: notificationsProxy ? notificationsProxy.doNotDisturb === true : dndFallback
  property bool dndFallback: false

  Process {
    id: notifProc
    // A loop, not one awk: with no live toast the first glob stays literal
    // and gawk stops dead on it, before it ever reaches the history.
    command: ["sh", "-c", "for f in \"$1\"/*.json \"$1\"/history/*.json; do [ -f \"$f\" ] && cat \"$f\" && echo; done; true", "--", root.notifDir]
    stdout: StdioCollector {
      onStreamFinished: root.notifications = StatusJs.without(StatusJs.notifications(text), root.putAway)
    }
  }

  // One letter put away for good: off the screen if it is still a toast
  // (Omarchy's `dismiss` moves it into the history), then its history file
  // and images deleted. It leaves the inbox at once; `putAway` keeps it out
  // while the files go.
  property var putAway: ({})
  function putAwayLetter(letter) {
    if (!letter || !letter.stem) return
    var gone = Object.assign({}, putAway)
    gone[letter.stem] = true
    putAway = gone
    notifications = StatusJs.without(notifications, gone)
    run(["sh", "-c",
      "dir=$1 stem=$2\n" +
      "if [ -f \"$dir/$stem.json\" ]; then\n" +
      "  [ -n \"$3\" ] && omarchy-shell notifications dismiss \"$3\" >/dev/null 2>&1\n" +
      "  i=0; while [ -f \"$dir/$stem.json\" ] && [ $i -lt 30 ]; do sleep 0.1; i=$((i+1)); done\n" +
      "  rm -f \"$dir/$stem.json\"\n" +
      "fi\n" +
      "rm -f \"$dir/history/$stem.json\" \"$dir/images/$stem\"-*", "--",
      root.notifDir, String(letter.stem), String(letter.summary || "")])
  }

  // Without the proxy (an older Omarchy), DND comes from the settings file.
  FileView {
    path: root.home + "/.local/state/omarchy/notifications.json"
    watchChanges: root.notificationsProxy === null
    onFileChanged: reload()
    onLoaded: {
      try { root.dndFallback = JSON.parse(text()).dnd === true } catch (e) { root.dndFallback = false }
    }
  }

  // ---------------------------------------------------------- polling
  function refresh() {
    if (!netProc.running) netProc.running = true
    if (!lightProc.running) lightProc.running = true
    if (!notifProc.running) notifProc.running = true
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // A change Hanko made itself shows at once rather than on the next poll.
  Timer { id: soon; interval: 250; onTriggered: root.refresh() }

  // ---------------------------------------------------------- actions
  function run(argv) { Quickshell.execDetached(argv); soon.restart() }
  function toggle(panel) { run(["omarchy-shell", "shell", "toggle", panel, "{}"]) }

  // name: volume | network | battery | brightness | notif
  // how:  click | middle | right | up | down
  function act(name, how) {
    if (name === "volume") {
      if (how === "up") run(["omarchy-audio-output-volume", "+5"])
      else if (how === "down") run(["omarchy-audio-output-volume", "-5"])
      else if (how === "middle" || how === "right") run(["omarchy-audio-output-volume", "mute-toggle"])
      else toggle("omarchy.audio")
    } else if (name === "brightness") {
      if (how === "up") run(["omarchy-brightness-display", "+5%"])
      else if (how === "down") run(["omarchy-brightness-display", "5%-"])
      else toggle("omarchy.power")
    } else if (name === "bluetooth") {
      // The middle or right button switches Bluetooth on or off.
      if (how === "middle" || how === "right") Blue.setPower(!Blue.powered)
    } else if (name === "network") {
      toggle("omarchy.network")
    } else if (name === "battery") {
      toggle("omarchy.power")
    } else if (name === "notif") {
      if (how === "right" || how === "middle") {
        if (notificationsProxy) notificationsProxy.setDoNotDisturb(!doNotDisturb)
        else run(["omarchy-toggle-notification-silencing"])
      } else {
        run(["omarchy-shell", "notifications", "showHistory"])
      }
    }
  }
}
