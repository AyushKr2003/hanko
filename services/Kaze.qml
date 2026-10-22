pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Settings.js" as Settings
import "../core/Paths.js" as Paths

// Kaze 風 for the settings page: the switches in ~/.config/hanko/kaze.json
// (read by the desk's plugins; written at once, with its own Undo), whether
// the desk is on (the flag `hanko desk on` leaves in the state folder)
// and whether Sumi is on (its shader in the state folder), and the three
// tools beside the desk: the brush cursor (its flag in the state folder),
// btop and Neovim in the theme's inks (what `hanko tools on` leaves), and the
// Hanko theme (Omarchy's current theme name). The desk, Sumi and the tools
// are switched by the `hanko` CLI, as from a terminal.
Singleton {
  id: root

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string cli: Paths.local(Qt.resolvedUrl("../scripts/hanko"))

  // Read while the settings window is open.
  property bool wanted: false

  property var doc: ({})
  // Set from the files as they load (a file deleted since keeps its old
  // text in the view, so a failed load says off).
  property bool desk: false
  property bool sumi: false
  property bool cursor: false
  readonly property bool tools: _btopBefore.on || _nvimSpec.on
  property bool theme: false
  // A switch the CLI is turning ("desk" | "sumi" | "cursor" | "tools" |
  // "theme" | ""), so the page can say so.
  property string busy: ""

  // Undo: the documents before each change, with when it was made.
  property var history: []
  readonly property real lastAt: history.length ? history[history.length - 1].at : 0
  readonly property string lastChange: history.length ? Settings.kazeChange(history[history.length - 1].doc, doc) : ""

  // `tag` names a continuous edit (the wind's speed being dragged): repeats
  // within 1.5 s are one step of Undo, as Typeset.keep() does.
  property string _lastTag: ""
  property real _lastAt: 0
  function set(key, value, tag) {
    var next = Settings.kazeWith(doc, key, value)
    if (JSON.stringify(next) === JSON.stringify(doc)) return
    var now = Date.now()
    var merge = !!tag && tag === _lastTag && now - _lastAt < 1500 && history.length > 0
    _lastTag = tag || ""
    _lastAt = now
    if (merge) { _commit(next); return }
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

  // `hanko desk on` restarts the shell when its plugins change (this window
  // closes with it), so it runs detached and outlives the shell. What it
  // says goes to the state folder's desk.log, to read when it didn't take.
  function setDesk(on) {
    busy = "desk"
    Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && \"$0\" desk " + (on ? "on" : "off") + " >\"$1/desk.log\" 2>&1",
      cli, stateHome + "/hanko"])
    _settle.restart()
  }
  function setSumi(on) {
    busy = "sumi"
    _sumiRun.command = [cli, "sumi", on ? "on" : "off"]
    _sumiRun.running = true
  }

  // The brush cursor, the tools and the Hanko theme: `hanko cursor|tools|theme
  // on|off`. A theme switch takes a few seconds (Omarchy restyles every app);
  // its words go to the state folder's tools.log.
  function setTool(key, on) {
    if (["cursor", "tools", "theme"].indexOf(key) < 0) return
    busy = key
    _toolRun.command = ["sh", "-c", "mkdir -p \"$1\" && \"$0\" " + key + " " + (on ? "on" : "off") + " >\"$1/tools.log\" 2>&1",
      cli, stateHome + "/hanko"]
    _toolRun.running = true
  }

  function _commit(next) {
    doc = next
    _mkdir.running = true
  }

  function _reloadTools() { _cursor.reload(); _btopBefore.reload(); _nvimSpec.reload(); _themeName.reload() }
  onWantedChanged: if (wanted) { _file.reload(); _look.reload(); _sumi.reload(); _reloadTools() }

  property Process _mkdir: Process {
    command: ["mkdir", "-p", root.configHome + "/hanko"]
    onExited: root._file.setText(JSON.stringify(root.doc) + "\n")
  }
  property Process _toolRun: Process {
    onExited: { root.busy = ""; root._reloadTools() }
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
    onTriggered: { root._look.reload(); root._sumi.reload(); root._reloadTools() }
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
    path: root.stateHome + "/hanko/desk"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.desk = text().length > 0
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
  property FileView _cursor: FileView {
    path: root.stateHome + "/hanko/cursor"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.cursor = text().length > 0
    onLoadFailed: root.cursor = false
  }
  // `hanko tools on` keeps btop's old theme here and writes Neovim's spec;
  // either one means on, as the CLI's tools_on says.
  property FileView _btopBefore: FileView {
    property bool on: false
    path: root.stateHome + "/hanko/tools/btop-before"
    printErrors: false
    onLoaded: on = true
    onLoadFailed: on = false
  }
  property FileView _nvimSpec: FileView {
    property bool on: false
    path: root.configHome + "/nvim/lua/plugins/zz-hanko-kaze.lua"
    printErrors: false
    onLoaded: on = true
    onLoadFailed: on = false
  }
  property FileView _themeName: FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.theme = text().trim() === "hanko"
    onLoadFailed: root.theme = false
  }
}
