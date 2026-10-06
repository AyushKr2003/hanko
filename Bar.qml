pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "core"
import "core/Sheets.js" as Sheets
import "bar"
import "services"

// Hanko · entry point of the `hanko.bar` plugin (manifest.json, kind "bar").
// omarchy-shell loads this file in place of its own bar and injects the
// properties below. The host reads back barHidden, barSize, position and
// fontFamily; see docs/ROADMAP.md for the whole contract.
Item {
  id: root

  // Injected by the host.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var barWidgetRegistry: null
  property var pluginRegistry: null
  property var barConfig: ({})
  property var shell: null
  property var manifest: null

  readonly property string version: manifest && manifest.version ? manifest.version : "0.1.0"

  // Mirrors `omarchy toggle bar` (the bar-off flag file).
  property bool barHidden: false

  // Hanko's own position when set (`hanko style set position bottom`);
  // otherwise Omarchy's bar.position, as long as it is an edge Hanko draws.
  readonly property string position: {
    if (Typeset.ownsPosition) return Typeset.current.position
    var p = barConfig ? String(barConfig.position || "") : ""
    return p === "bottom" ? "bottom" : "top"
  }
  readonly property bool vertical: false
  readonly property int barSize: barHidden ? 0 : Type.px(Typeset.current.height)
  readonly property string fontFamily: Type.mono

  property alias now: clock.date

  // Omarchy's bar transparency (`omarchy-shell shell toggleBarTransparency`,
  // stored as bar.transparent in shell.json). Hanko shows it as glass: a
  // solid surface turns to glass; glass and inset stay as they are.
  property bool transparent: false
  onBarConfigChanged: transparent = !!(barConfig && barConfig.transparent === true)

  // The rod was pulled on a screen (edge: rod | rodrule). Phase 7 unrolls
  // the scroll from here.
  signal edgePulled(string screenName)

  // Called by the host. Like Omarchy's own bar it writes bar.transparent to
  // shell.json through the host, so the choice survives a restart and the
  // new barConfig comes back to us; without that API it flips for this
  // session only. Either way style.json is left alone.
  function toggleTransparency() {
    var next = !transparent
    var written = shell && typeof shell.mutateShellConfig === "function"
      && shell.mutateShellConfig(function(config) {
        if (!config.bar || typeof config.bar !== "object" || Array.isArray(config.bar)) config.bar = {}
        config.bar.transparent = next
      })
    if (!written) transparent = next
  }

  // 12- or 24-hour, from Omarchy's own clock (the `format` on omarchy.clock
  // in shell.json). Only the hour style carries over: Hanko lays out the
  // date itself.
  readonly property string timeFormat: {
    var f = omarchyClockFormat
    return /h/.test(f.replace(/HH?/g, "")) || /ap/i.test(f) ? "h:mm AP" : "HH:mm"
  }
  readonly property string omarchyClockFormat: {
    var layout = barConfig && barConfig.layout ? barConfig.layout : {}
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var list = Array.isArray(layout[sections[s]]) ? layout[sections[s]] : []
      for (var i = 0; i < list.length; i++)
        if (list[i] && list[i].id === "omarchy.clock" && list[i].format) return String(list[i].format)
    }
    return "HH:mm"
  }

  // ------------------------------------------------------------- sheets
  //
  // One sheet open at a time, across every screen. panels: scroll falls
  // back to sheets until the handscroll lands (Phase 7).
  property string sheet: ""
  property string sheetScreen: ""
  // Weeks the Time sheet's ribbon is moved from today.
  property int timeShift: 0
  // The sheets built so far.
  readonly property var sheetsReady: ["time"]

  function sheetReady(key) { return !!key && sheetsReady.indexOf(key) >= 0 }

  function focusedScreen() {
    var m = Hyprland.focusedMonitor
    if (m && m.name) return m.name
    return Quickshell.screens.length ? Quickshell.screens[0].name : ""
  }

  function openSheet(key, screenName) {
    if (!sheetReady(key) || barHidden) return false
    if (key !== sheet) timeShift = 0
    sheetScreen = screenName || focusedScreen()
    sheet = key
    return true
  }
  function closeSheet() { sheet = "" }
  function toggleSheet(key, screenName) {
    if (sheet === key && sheetScreen === screenName) closeSheet()
    else openSheet(key, screenName)
  }
  function cycleSheet(delta) {
    if (sheet) openSheet(Sheets.step(sheet, delta, sheetsReady), sheetScreen)
  }
  // Something a sheet asked for: pages, values, devices.
  function sheetRequest(key, what, arg) {
    if (key === "time" && what === "shift") timeShift = Number(arg) || 0
  }

  onBarHiddenChanged: if (barHidden) closeSheet()

  Binding { target: Zones; property: "barConfig"; value: root.barConfig }
  Binding { target: Zones; property: "wanted"; value: root.sheet === "time" }

  // BarWindows by screen name, for the host's per-screen questions.
  property var windows: ({})
  function registerWindow(name, w) {
    var next = Object.assign({}, windows)
    next[name] = w
    windows = next
  }
  function unregisterWindow(name, w) {
    if (windows[name] !== w) return
    var next = Object.assign({}, windows)
    delete next[name]
    windows = next
  }

  // ------------------------------------------------- host: bar widgets
  //
  // Omarchy's audio, clock, network and power panels are kind bar-widget,
  // so with Hanko as the bar `omarchy-shell shell toggle omarchy.audio`
  // (and SUPER+CTRL+A, W, P, ALT+D, ALT+E) land here. Hanko answers with
  // its own sheets. The host asks isBarWidgetOpen first: summon opens,
  // never toggles.
  function summonBarWidget(id) {
    var key = Sheets.forOmarchyId(id)
    return sheetReady(key) && openSheet(key, focusedScreen())
  }
  function hideBarWidget(id) {
    var key = Sheets.forOmarchyId(id)
    if (!sheetReady(key)) return false
    if (sheet === key) closeSheet()
    return true
  }
  function isBarWidgetOpen(id) {
    var key = Sheets.forOmarchyId(id)
    return key !== "" && sheet === key
  }
  // `togglePanelAt right N` (SUPER+CTRL+1..9): the Nth Omarchy panel among
  // Hanko's right-zone cells, on the focused screen.
  function panelWidgetIdAt(section, index) {
    if (barHidden || String(section) !== "right") return ""
    var w = windows[focusedScreen()]
    return w ? Sheets.panelAt(w.surface.rightCells, index) : ""
  }

  // Omarchy's choice of media player, when the host offers it.
  Binding {
    target: Media
    property: "proxy"
    value: root.shell && typeof root.shell.firstPartyServiceFor === "function" ? root.shell.firstPartyServiceFor("omarchy.media") : null
  }

  Binding {
    target: Status
    property: "notificationsProxy"
    value: root.shell && typeof root.shell.firstPartyServiceFor === "function" ? root.shell.firstPartyServiceFor("omarchy.notifications") : null
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      BarWindow {
        required property var modelData
        screen: modelData
        bar: root
      }
    }
  }

  // ------------------------------------------------------------- hiding
  //
  // `omarchy toggle bar` writes ~/.local/state/omarchy/toggles/bar-off, then
  // calls `omarchy.bar syncHidden`. The directory is watched because a
  // FileView cannot watch a file that does not exist yet.
  readonly property string togglesDir: Quickshell.env("HOME") + "/.local/state/omarchy/toggles"

  Process {
    id: hiddenProbe
    running: true
    command: ["bash", "-c", "[[ -f \"$1/bar-off\" ]] && echo yes || echo no", "_", root.togglesDir]
    stdout: SplitParser {
      onRead: function(line) { root.barHidden = String(line).trim() === "yes" }
    }
  }

  FileView {
    path: root.togglesDir
    watchChanges: true
    printErrors: false
    onFileChanged: hiddenProbe.running = true
  }

  IpcHandler {
    target: "omarchy.bar"
    function syncHidden(): void { hiddenProbe.running = true }
  }

  // ------------------------------------------------------------- hanko IPC
  //
  // omarchy-shell hanko <fn> ...  (scripts/hanko wraps these)
  IpcHandler {
    target: "hanko"

    function version(): string { return root.version }
    function styleGet(): string { return JSON.stringify(Typeset.current) }
    function styleDoc(): string { return Typeset.serialized() }
    function styleSet(key: string, value: string): string { return Typeset.set(key, value) ? "ok" : "invalid" }
    function stylePreset(name: string): string { return Typeset.applyPreset(name) ? "ok" : "unknown" }
    function styleReset(): string { Typeset.reset(); return "ok" }
    function styleShuffle(): string { Typeset.shuffle(); return "ok" }
    function warnings(): string { return Typeset.warnings.join("\n") }
    function sheet(name: string): string {
      if (root.sheet === name) { root.closeSheet(); return "closed" }
      return root.openSheet(name, root.focusedScreen()) ? "open" : "unknown"
    }
    function sheetClose(): string { root.closeSheet(); return "ok" }
  }
}
