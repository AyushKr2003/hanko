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
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")

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
  // Omarchy keeps the toasts on screen and the recent history on disk; Hanko
  // reads those rather than running a second server. Stable keeps one JSON
  // file per notification (*.json, history/*.json); rc, edge and dev keep
  // live.json and history.json beside quiet.json (core/Status.js reads both).
  property var notifications: []
  readonly property bool doNotDisturb: notificationsProxy ? notificationsProxy.doNotDisturb === true : dndFallback

  Process {
    id: notifProc
    // A loop, not one awk: with no live toast the first glob stays literal
    // and gawk stops dead on it, before it ever reaches the history.
    command: ["sh", "-c",
      "echo '#live'\n" +
      "for f in \"$1\"/*.json; do\n" +
      "  case $f in */history.json|*/quiet.json) continue ;; esac\n" +
      "  [ -f \"$f\" ] && cat \"$f\" && echo\n" +
      "done\n" +
      "echo '#history'\n" +
      "for f in \"$1\"/history.json \"$1\"/history/*.json; do [ -f \"$f\" ] && cat \"$f\" && echo; done\n" +
      "true", "--", root.notifDir]
    stdout: StdioCollector {
      onStreamFinished: {
        var all = StatusJs.notifications(text)
        root.notifications = StatusJs.without(all, root.putAway)
        if (root.putAwayLoaded) root.keepPutAway(StatusJs.stillHeld(root.putAway, all))
      }
    }
  }

  // One letter put away for good. It leaves the inbox at once, and `putAway`
  // (the stems, kept in Hanko's state folder) keeps it out until Omarchy has
  // forgotten it too, across restarts.
  //   stable  off the screen if it is still a toast (`dismiss` moves its file
  //           into the history), then its history file and images deleted;
  //   deck    the history is one file the daemon rewrites from memory, so it
  //           is forgotten through the daemon's `forgetKeys` where it has one
  //           (a patched clone); Omarchy's own only takes a toast off the
  //           screen by summary, and the letter stays put away here.
  property var putAway: ({})
  property bool putAwayLoaded: false
  function putAwayLetter(letter) {
    if (!letter || !letter.stem) return
    var gone = Object.assign({}, putAway)
    gone[letter.stem] = true
    keepPutAway(gone)
    notifications = StatusJs.without(notifications, gone)
    if (letter.key) {
      run(["sh", "-c",
        "omarchy-shell notifications forgetKeys \"$1\" >/dev/null 2>&1 && exit 0\n" +
        "[ \"$2\" = true ] && [ -n \"$3\" ] && omarchy-shell notifications dismiss \"$3\" >/dev/null 2>&1\n" +
        "true", "--", String(letter.key), letter.live ? "true" : "false", String(letter.summary || "")])
      return
    }
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

  function keepPutAway(gone) {
    var text = JSON.stringify(Object.keys(gone).sort())
    if (text === JSON.stringify(Object.keys(putAway).sort()) && putAwayFile.written === text) return
    putAway = gone
    putAwayFile.written = text
    if (!putAwayMkdir.running) putAwayMkdir.running = true
  }

  // The state folder may not exist yet; written once it does.
  Process {
    id: putAwayMkdir
    command: ["mkdir", "-p", root.stateHome + "/hanko"]
    onExited: putAwayFile.setText(putAwayFile.written + "\n")
  }

  FileView {
    id: putAwayFile
    property string written: ""
    path: root.stateHome + "/hanko/put-away.json"
    atomicWrites: true
    printErrors: false
    onLoaded: {
      var gone = {}
      try {
        var keys = JSON.parse(text())
        for (var i = 0; i < keys.length; i++) gone[String(keys[i])] = true
      } catch (e) {}
      root.putAway = Object.assign(gone, root.putAway)
      written = text().trim()
      root.putAwayLoaded = true
    }
    onLoadFailed: root.putAwayLoaded = true
  }

  // Without the proxy (an older Omarchy), DND comes from the daemon's own
  // file: quiet.json on the deck, which an empty one hasn't written yet, so
  // the old notifications.json holds until it does (as the daemon reads it).
  property var quietDnd: null
  property bool legacyDnd: false
  readonly property bool dndFallback: quietDnd !== null ? quietDnd : legacyDnd

  FileView {
    path: root.notifDir + "/quiet.json"
    watchChanges: root.notificationsProxy === null
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.quietDnd = String(text()).trim() === "" ? null : JSON.parse(text()).dnd === true } catch (e) { root.quietDnd = null }
    }
    onLoadFailed: root.quietDnd = null
  }

  FileView {
    path: root.home + "/.local/state/omarchy/notifications.json"
    watchChanges: root.notificationsProxy === null
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.legacyDnd = JSON.parse(text()).dnd === true } catch (e) { root.legacyDnd = false }
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
