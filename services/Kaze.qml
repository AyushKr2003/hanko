pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Settings.js" as Settings

// Kaze 風 for the settings page: the switches in ~/.config/hanko/kaze.json
// (read by the desk's plugins; written at once, with its own Undo), whether
// the desk is on (the marked line in looknfeel.lua that `hanko desk` adds)
// and whether Sumi is on (its shader in the state folder). The desk and
// Sumi are switched by the `hanko` CLI, as from a terminal.
Singleton {
  id: root

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string cli: String(Qt.resolvedUrl("../scripts/hanko")).replace(/^file:\/\//, "")

  // Read while the settings window is open.
  property bool wanted: false

  property var doc: ({})
  // Set from the files as they load (a file deleted since keeps its old
  // text in the view, so a failed load says off).
  property bool desk: false
  property bool sumi: false
  // A switch the CLI is turning ("desk" | "sumi" | ""), so the page can say so.
  property string busy: ""

  // Undo: the documents before each change, with when it was made.
  property var history: []
  readonly property real lastAt: history.length ? history[history.length - 1].at : 0
  readonly property string lastChange: history.length ? Settings.kazeChange(history[history.length - 1].doc, doc) : ""

  function set(key, value) {
    var next = Settings.kazeWith(doc, key, value)
    if (JSON.stringify(next) === JSON.stringify(doc)) return
    var h = history.slice()
    h.push({ doc: doc, at: Date.now() })
    if (h.length > 50) h.shift()
    history = h
    _commit(next)
  }
  function undo() {
    if (!history.length) return false
    var h = history.slice()
    var previous = h.pop()
    history = h
    _commit(previous.doc)
    return true
  }
  function forget() { history = [] }

  // `hanko desk on|off` restarts the shell when its plugins change (this
  // window closes with it), so it runs detached and outlives the shell.
  function setDesk(on) {
    busy = "desk"
    Quickshell.execDetached(["sh", "-c", "\"$0\" desk " + (on ? "on" : "off") + " >/dev/null 2>&1", cli])
    _settle.restart()
  }
  function setSumi(on) {
    busy = "sumi"
    _sumiRun.command = [cli, "sumi", on ? "on" : "off"]
    _sumiRun.running = true
  }

  function _commit(next) {
    doc = next
    _mkdir.running = true
  }

  onWantedChanged: if (wanted) { _file.reload(); _look.reload(); _sumi.reload() }

  property Process _mkdir: Process {
    command: ["mkdir", "-p", root.configHome + "/hanko"]
    onExited: root._file.setText(JSON.stringify(root.doc) + "\n")
  }
  property Process _sumiRun: Process {
    onExited: { root.busy = ""; root._sumi.reload() }
  }
  property Timer _settle: Timer {
    interval: 4000
    onTriggered: { root.busy = ""; root._look.reload() }
  }
  // A file that doesn't exist yet can't be watched; look again now and then.
  property Timer _poll: Timer {
    interval: 3000
    repeat: true
    running: root.wanted
    onTriggered: { root._look.reload(); root._sumi.reload() }
  }

  property FileView _file: FileView {
    path: root.configHome + "/hanko/kaze.json"
    watchChanges: true
    printErrors: false
    atomicWrites: true
    onFileChanged: reload()
    onLoaded: {
      var parsed = {}
      try { parsed = JSON.parse(text() || "{}") } catch (e) { console.warn("hanko: kaze.json is not valid JSON") }
      if (!parsed || typeof parsed !== "object") parsed = {}
      if (JSON.stringify(parsed) !== JSON.stringify(root.doc)) root.doc = parsed
    }
  }
  property FileView _look: FileView {
    path: root.configHome + "/hypr/looknfeel.lua"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.desk = /-- hanko desk$/m.test(text())
    onLoadFailed: root.desk = false
  }
  property FileView _sumi: FileView {
    path: root.stateHome + "/hanko/sumi/sumi.glsl"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.sumi = text().length > 0
    onLoadFailed: root.sumi = false
  }
}
