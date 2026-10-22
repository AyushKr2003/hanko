pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Settings.js" as Settings
import "../core/Paths.js" as Paths

// Kaze 風 for the settings page: the switches in ~/.config/hanko/kaze.json
// (read by the desk's plugins; written at once, with its own Undo), whether
// the desk is on (the flag `hanko desk on` leaves in the state folder)
// and whether Sumi is on (its shader in the state folder), and the four
// tools beside the desk: the brush cursor (its flag in the state folder),
// btop and Neovim in the theme's inks (what `hanko tools on` leaves), the
// Hanko theme (Omarchy's current theme name) and the boot screen (Plymouth's
// theme in /etc/plymouth/plymouthd.conf). The desk, Sumi and the tools are
// switched by the `hanko` CLI, as from a terminal.
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
  // The brush cursor's size in pixels, from its flag (`hanko cursor size`).
  property int cursorSize: 22
  readonly property bool tools: _btopBefore.on || _nvimSpec.on
  property bool theme: false
  // Omarchy's current theme, by its folder name.
  property string themeName: ""
  property bool boot: false
  // Settings › Boot: what the installed screen was drawn for (boot-drawn.json:
  // theme, glyph, name, press, at), the last switch's error ("" when it
  // went), and the page's preview: the theme drawn into the state folder by
  // scripts/hanko-boot at 1080 px, its version going up with each drawing.
  property var bootDrawn: ({})
  property string bootError: ""
  readonly property string bootPreviewDir: stateHome + "/hanko/boot-preview"
  property int bootPreviewVersion: 0
  // The folder the page draws from ("" before the first drawing).
  readonly property string bootPreview: bootPreviewVersion > 0 ? bootPreviewDir + "/v" + bootPreviewVersion : ""
  property bool bootPreviewBusy: false
  // A switch the CLI is turning ("desk" | "sumi" | "cursor" | "tools" |
  // "theme" | "boot" | ""), so the page can say so.
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

  // The brush cursor, the tools, the Hanko theme and the boot screen: `hanko
  // cursor|tools|theme|boot on|off`. A theme switch takes a few seconds
  // (Omarchy restyles every app); the boot screen asks for your password
  // (pkexec) and rebuilds the initramfs, a minute. Their words go to the
  // state folder's tools.log (boot.log for the boot screen).
  function setTool(key, on) {
    if (["cursor", "tools", "theme", "boot"].indexOf(key) < 0) return
    busy = key
    _runTool(key, on ? "on" : "off")
  }
  // Settings › Boot's Redraw: `hanko boot refresh` (the screen drawn again
  // for the theme, the seal and the choices as they are now).
  function bootRefresh() { busy = "boot"; _runTool("boot", "refresh") }
  function _runTool(key, word) {
    var log = key === "boot" ? "boot.log" : "tools.log"
    if (key === "boot") bootError = ""
    _toolRun.key = key
    _toolRun.command = ["sh", "-c", "mkdir -p \"$1\" && \"$0\" " + key + " " + word + " >\"$1/" + log + "\" 2>&1",
      cli, stateHome + "/hanko"]
    _toolRun.running = true
  }
  // Draw the page's preview (a second or two); a request while one draws
  // waits for it.
  function buildBootPreview() {
    if (_previewRun.running) { _previewRun.again = true; return }
    bootPreviewBusy = true
    // Each drawing in a folder of its own (v1, v2…): an Image keeps what it
    // loaded from a path, so a new path is how the page sees the new one.
    var n = bootPreviewVersion + 1
    _previewRun.next = n
    _previewRun.command = ["sh", "-c", "mkdir -p \"$1\" && HANKO_BOOT_HEIGHT=1080 \"$0\" build \"$1/v$2\" >/dev/null 2>&1 && find \"$1\" -mindepth 1 -maxdepth 1 ! -name \"v$2\" -exec rm -rf {} +",
      Paths.local(Qt.resolvedUrl("../scripts/hanko-boot")), bootPreviewDir, String(n)]
    _previewRun.running = true
  }

  // The cursor's size: shown at once, handed to `hanko cursor size` once the
  // drag rests, so a drag is one run of the CLI, not twenty.
  function setCursorSize(px) {
    cursorSize = Math.max(16, Math.min(48, Math.round(px)))
    _sizeRest.restart()
  }
  property Timer _sizeRest: Timer {
    interval: 250
    onTriggered: {
      root._sizeRun.command = [root.cli, "cursor", "size", String(root.cursorSize)]
      root._sizeRun.running = true
    }
  }
  property Process _sizeRun: Process {
    onExited: root._cursor.reload()
  }

  function _commit(next) {
    doc = next
    _mkdir.running = true
  }

  function _reloadTools() { _cursor.reload(); _btopBefore.reload(); _nvimSpec.reload(); _themeName.reload(); _plymouth.reload(); _bootDrawn.reload() }
  onWantedChanged: if (wanted) { _file.reload(); _look.reload(); _sumi.reload(); _reloadTools() }

  property Process _mkdir: Process {
    command: ["mkdir", "-p", root.configHome + "/hanko"]
    onExited: root._file.setText(JSON.stringify(root.doc) + "\n")
  }
  property Process _toolRun: Process {
    property string key: ""
    onExited: function(code) {
      root.busy = ""
      root._reloadTools()
      if (key === "boot" && code !== 0) { root._bootLog.armed = true; root._bootLog.reload() }
    }
  }
  property Process _previewRun: Process {
    property bool again: false
    property int next: 0
    onExited: function(code) {
      root.bootPreviewBusy = false
      if (code === 0) root.bootPreviewVersion = next
      if (again) { again = false; root.buildBootPreview() }
    }
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
    onLoaded: {
      root.cursor = text().length > 0
      var n = parseInt(text(), 10)
      if (n > 0 && !root._sizeRest.running && !root._sizeRun.running) root.cursorSize = n
    }
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
    onLoaded: { root.themeName = text().trim(); root.theme = root.themeName === "hanko" }
    onLoadFailed: root.theme = false
  }
  // Plymouth's theme: the boot screen is Hanko's while it says hanko.
  property FileView _plymouth: FileView {
    path: "/etc/plymouth/plymouthd.conf"
    printErrors: false
    onLoaded: root.boot = /^\s*Theme\s*=\s*hanko\s*$/m.test(text())
    onLoadFailed: root.boot = false
  }
  property FileView _bootDrawn: FileView {
    path: root.stateHome + "/hanko/boot-drawn.json"
    printErrors: false
    onLoaded: { try { root.bootDrawn = JSON.parse(text() || "{}") || {} } catch (e) { root.bootDrawn = {} } }
    onLoadFailed: root.bootDrawn = ({})
  }
  // The last words of a switch that failed (the CLI says why on its last
  // line). A FileView reads its file as soon as it is made, so it only
  // speaks once a switch has failed (`armed`).
  property FileView _bootLog: FileView {
    property bool armed: false
    path: root.stateHome + "/hanko/boot.log"
    printErrors: false
    onLoaded: {
      if (!armed) return
      armed = false
      var lines = text().split("\n").filter(function(l) { return l.trim().length > 0 })
      root.bootError = lines.length ? lines[lines.length - 1].replace(/^hanko: /, "") : "It didn't take."
    }
    onLoadFailed: { if (armed) { armed = false; root.bootError = "It didn't take." } }
  }
}
