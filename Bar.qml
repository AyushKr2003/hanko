pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "core"
import "core/Sheets.js" as Sheets
import "core/Scroll.js" as Scroll
import "core/Hosted.js" as Hosted
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
  // Under Inkan (form: inkan) there is no strip: Omarchy is told 0, so its
  // OSD and toasts sit as they would with no bar.
  readonly property int barSize: barHidden || Typeset.current.form === "inkan" ? 0 : Type.px(Typeset.current.height)
  readonly property string fontFamily: Type.mono

  property alias now: clock.date

  // Omarchy's bar transparency (`omarchy-shell shell toggleBarTransparency`,
  // stored as bar.transparent in shell.json). Hanko shows it as glass: a
  // solid surface turns to glass; glass and washi stay as they are.
  property bool transparent: false
  onBarConfigChanged: transparent = !!(barConfig && barConfig.transparent === true)

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

  // 12- or 24-hour: the `hours` setting, or on auto Omarchy's own clock (the
  // `format` on omarchy.clock in shell.json). Only the hour style carries
  // over: Hanko lays out the date itself.
  readonly property string timeFormat: {
    var h = Typeset.current.hours
    if (h === "24h") return "HH:mm"
    if (h === "12h") return "h:mm AP"
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
  // The sheets that can open (all = No. 00, Inkan's sheet of every sheet).
  readonly property var sheetsReady: ["all", "time", "sound", "network", "bluetooth", "power", "display", "inbox"]
  // "all" while the open sheet was opened from No. 00, so it can go back.
  property string sheetFrom: ""

  function sheetReady(key) { return !!key && sheetsReady.indexOf(key) >= 0 }

  function focusedScreen() {
    var m = Hyprland.focusedMonitor
    if (m && m.name) return m.name
    return Quickshell.screens.length ? Quickshell.screens[0].name : ""
  }

  function openSheet(key, screenName, from) {
    if (!sheetReady(key) || barHidden) return false
    closeScroll()
    closeOverview()
    closeHostedPopout()
    if (key !== sheet) timeShift = 0
    sheetScreen = screenName || focusedScreen()
    sheetFrom = key === "all" ? "" : from || ""
    sheet = key
    return true
  }
  function closeSheet() { sheet = ""; sheetFrom = "" }
  // Backspace or the crumb on a sheet opened from No. 00.
  function backSheet() { if (sheet && sheetFrom === "all") openSheet("all", sheetScreen) }
  function toggleSheet(key, screenName) {
    if (sheet === key && sheetScreen === screenName) closeSheet()
    else openSheet(key, screenName)
  }
  // Tab walks the sheets; No. 00 is among them only under Inkan.
  function cycleSheet(delta) {
    if (!sheet) return
    var ready = inkanOn(sheetScreen) ? sheetsReady : sheetsReady.filter(function(k) { return k !== "all" })
    openSheet(Sheets.step(sheet, delta, ready), sheetScreen, sheetFrom)
  }
  // Something a sheet asked for: pages, values, devices.
  function sheetRequest(key, what, arg) {
    if (key === "all") {
      if (what === "open") openSheet(String(arg), sheetScreen, "all")
      else if (what === "workspace") { closeSheet(); Hypr.focusWorkspace(Number(arg)) }
      else if (what === "media") Media.act(String(arg))
      else if (what === "menu") { closeSheet(); Hypr.openMenu() }
      else if (what === "settings") { closeSheet(); openSettings() }
    } else if (key === "time" && what === "shift") timeShift = Number(arg) || 0
    else if (key === "sound") {
      if (what === "master") Sound.setMaster(Number(arg))
      else if (what === "mute") Sound.toggleMute()
      else if (what === "output") Sound.setOutput(arg.id, arg.name)
      else if (what === "nextOutput") Sound.nextOutput()
      else if (what === "stream") Sound.setStream(arg.id, arg.name, Number(arg.value))
      else if (what === "streamMute") Sound.toggleStream(arg.id, arg.name)
      else if (what === "inputMute") Sound.toggleInput()
      else if (what === "input") Sound.setInput(Number(arg))
    } else if (key === "network") {
      if (what === "connect") Net.connect(arg.ssid, arg.saved, arg.secure)
      else if (what === "radio") Net.setRadio(!!arg)
      else if (what === "rescan") Net.rescan()
      // Omarchy's speed test and Wi-Fi share card are panels of their own.
      else if (what === "speedtest" || what === "share") {
        closeSheet()
        if (shell && typeof shell.summon === "function")
          shell.summon(what === "speedtest" ? "omarchy.speedtest" : "omarchy.wifiqr", "{}")
      }
    } else if (key === "power") {
      if (what === "profile") Power.setProfile(String(arg))
    } else if (key === "bluetooth") {
      if (what === "power") Blue.setPower(!!arg)
      else if (what === "device") Blue.device(String(arg.address), String(arg.action))
    } else if (key === "display") {
      if (what === "brightness") Display.setBrightness(Number(arg))
      else if (what === "monitor") Display.pick(String(arg))
      else if (what === "night") Display.setNight(!!arg)
      else if (what === "edit") { closeSheet(); closeScroll(); Display.editMonitors() }
    } else if (key === "spaces") {
      if (what === "window") Hypr.focusWindow(String(arg))
      else if (what === "workspace") Hypr.focusWorkspace(Number(arg))
      closeScroll()
    } else if (key === "inbox") {
      if (what === "dnd") Status.act("notif", "right")
      else if (what === "replay") { closeSheet(); Status.act("notif", "click") }
      // `clear` forgets the history, `dismissAll` the toasts still on screen.
      else if (what === "clear") {
        Status.run(["sh", "-c", "omarchy-shell notifications clear; omarchy-shell notifications dismissAll"])
      }
    } else if (key === "leaf") leafRequest(what, arg)
  }

  // The end leaf after Inbox on the scroll (bar/scroll/EndLeaf.qml).
  function leafRequest(what, arg) {
    if (what === "session") { closeScroll(); Leaf.sessionAct(String(arg)) }
    else if (what === "theme") Leaf.setTheme(String(arg))
    else if (what === "themes") { closeScroll(); Leaf.openThemes() }
    else if (what === "focus") Leaf.focusAct(String(arg))
    else if (what === "note") Leaf.toggleNote(Number(arg))
    else if (what === "notes") { closeScroll(); Leaf.editNotes() }
    else if (what === "clip") Leaf.copyClip(Number(arg))
    else if (what === "tool") {
      var key = String(arg)
      if (key === "awake") {
        // Omarchy's idle service: stay awake is idle switched off.
        var idle = Extras.idleProxy
        if (idle && typeof idle.setIdleEnabled === "function") idle.setIdleEnabled(!!idle.stayAwake)
        else Quickshell.execDetached(["omarchy-toggle-idle"])
      } else if (key === "night") Display.setNight(!(Extras.nightProxy && Extras.nightProxy.enabled))
      else if (key === "silence") Status.act("notif", "right")
      else { closeScroll(); Leaf.runTool(key) }
    }
  }

  // ------------------------------------------------------------- hosted
  //
  // Widgets from Omarchy's bar layout that Hanko neither is nor draws its
  // own way (weather, Bluetooth, monitors, third-party), created from the
  // host's widget registry with a facade (bar/HostBar.qml).
  readonly property var hostedEntries: {
    var reg = barWidgetRegistry
    if (!reg) return []
    void reg.revision
    var widgets = reg.widgets || {}
    var list = Hosted.hosted(barConfig, function(id) { return !!widgets[id] },
      function(id) { return !!(widgets[id] && widgets[id].metadata && widgets[id].metadata.allowMultiple) })
    return list.map(function(e) {
      var w = widgets[e.id]
      var m = w.metadata || {}
      return { id: e.id, key: e.key, settings: e.settings, component: w.component,
               pluginId: m.pluginId || e.id,
               // For the Widgets page: what to call it and whose it is.
               name: String(m.displayName || ""), description: String(m.description || ""),
               firstParty: m.firstParty === true || e.id.indexOf("omarchy.") === 0 }
    })
  }
  readonly property var own: Hosted.own(barConfig)
  Binding { target: Extras; property: "wantIndicators"; value: root.own.indicators }
  Binding { target: Extras; property: "wantKeyboard"; value: root.own.keyboard }
  Binding { target: Extras; property: "wantMic"; value: root.own.mic }
  Binding { target: Extras; property: "wantTray"; value: root.own.tray }
  Binding { target: Extras; property: "dnd"; value: Status.doNotDisturb }
  Binding {
    target: Extras
    property: "idleProxy"
    value: root.shell && typeof root.shell.firstPartyServiceFor === "function" ? root.shell.firstPartyServiceFor("omarchy.idle") : null
  }
  Binding {
    target: Extras
    property: "nightProxy"
    value: root.shell && typeof root.shell.firstPartyServiceFor === "function" ? root.shell.firstPartyServiceFor("omarchy.nightlight") : null
  }

  // One popout at a time across Hanko's sheets, its scroll and hosted
  // widgets' panels.
  property var hostedPopout: null
  function requestHostedPopout(owner) {
    if (hostedPopout && hostedPopout !== owner) closeHostedPopout()
    closeSheet()
    closeScroll()
    hostedPopout = owner
  }
  function releaseHostedPopout(owner) { if (hostedPopout === owner) hostedPopout = null }
  function closeHostedPopout() {
    var p = hostedPopout
    hostedPopout = null
    try { if (p && typeof p.close === "function") p.close() } catch (e) {}
  }

  // Live hosted widget items by entry key (one per screen).
  property var hostedItems: ({})
  function registerHosted(key, item) {
    var next = Object.assign({}, hostedItems)
    next[key] = (next[key] || []).filter(function(i) { return i !== item }).concat([item])
    hostedItems = next
  }
  function unregisterHosted(key, item) {
    if (!hostedItems[key]) return
    var next = Object.assign({}, hostedItems)
    next[key] = next[key].filter(function(i) { return i !== item })
    hostedItems = next
  }
  function hostedWidgets(id) {
    var out = []
    for (var k in hostedItems) if (k === id || k.indexOf(id + "#") === 0) out = out.concat(hostedItems[k])
    return out
  }
  // The hosted widget on the focused screen (or any), for the host's panel
  // calls.
  function hostedItemFor(id) {
    var items = hostedWidgets(id)
    var screen = focusedScreen()
    for (var i = 0; i < items.length; i++) {
      var w = items[i] && items[i].QsWindow ? items[i].QsWindow.window : null
      if (w && w.screen && w.screen.name === screen) return items[i]
    }
    return items.length ? items[0] : null
  }
  function run(command) { if (command) Quickshell.execDetached(["sh", "-c", String(command)]) }

  // ------------------------------------------------------------- settings
  //
  // The settings window keeps every change as it is made (no Save); its
  // undo history is forgotten when it closes.
  property bool settingsOpen: false
  function openSettings() { settingsOpen = true }
  function closeSettings() {
    Typeset.revert()
    Typeset.forget()
    settingsOpen = false
  }

  SettingsWindow { bar: root }

  // ------------------------------------------------------------- overview
  //
  // The workspace overview 一覧 (bar/OverviewWindow.qml): every screen lays
  // out its workspaces at once; the focused one takes the keyboard. Right-
  // click on the workspaces, or `omarchy-shell hanko overview`.
  property bool overviewOpen: false
  function openOverview() {
    closeSheet()
    closeScroll()
    closeHostedPopout()
    Hypr.refresh()
    overviewOpen = true
  }
  function closeOverview() { overviewOpen = false }
  function toggleOverview() { if (overviewOpen) closeOverview(); else openOverview() }

  // ------------------------------------------------------------- scroll
  //
  // The handscroll (panels: scroll): open on one screen at a time, panned
  // to one section. It stays where you left it between unrolls.
  property bool scrollOpen: false
  property string scrollScreen: ""
  property int scrollSection: 0

  function panelsFor(screenName) {
    return Typeset.styleFor(screenName || focusedScreen()).panels
  }
  // Unroll at a section key ("" keeps the last one).
  function openScroll(key, screenName) {
    if (barHidden) return false
    closeSheet()
    closeHostedPopout()
    closeOverview()
    var i = Scroll.indexOf(key)
    if (i >= 0) scrollSection = i
    scrollScreen = screenName || focusedScreen()
    scrollOpen = true
    return true
  }
  function closeScroll() { scrollOpen = false }
  // Open at a section, pan to it if open elsewhere, roll up if it's showing.
  function toggleScroll(key, screenName) {
    var i = Scroll.indexOf(key)
    if (scrollOpen && scrollScreen === screenName && (i < 0 || i === scrollSection)) closeScroll()
    else openScroll(key, screenName)
  }
  function scrollTo(index) {
    scrollSection = Math.max(0, Math.min(Scroll.SECTIONS.length - 1, index))
  }
  function stepScroll(delta) { scrollTo(scrollSection + delta) }
  readonly property string scrollKey: Scroll.SECTIONS[scrollSection].key

  // A panel for one of Omarchy's ids, as this screen's style wants it.
  function openPanel(key, screenName) {
    if (!key) return false
    if (panelsFor(screenName) === "scroll") return openScroll(key, screenName)
    return openSheet(key, screenName)
  }
  function panelOpen(key) {
    return key !== "" && (sheet === key || (scrollOpen && scrollKey === key))
  }
  function closePanel(key) {
    if (sheet === key) closeSheet()
    if (scrollOpen && scrollKey === key) closeScroll()
  }

  onBarHiddenChanged: if (barHidden) { closeSheet(); closeScroll() }

  // ------------------------------------------------------------- inkan
  //
  // Inkan 印 (form: inkan, bar/SealWindow.qml): a press on the seal, or
  // `omarchy-shell hanko press`, prints No. 00 from it (every sheet on
  // one), or unrolls the scroll under panels: scroll; again, it lifts off.
  function inkanOn(screenName) { return Typeset.styleFor(screenName || focusedScreen()).form === "inkan" }
  // Whether something printed from the seal is out on this screen.
  function inkanPrinted(screenName) {
    return (sheet !== "" && sheetScreen === screenName) || (scrollOpen && scrollScreen === screenName)
  }
  // A seal dragged to another corner: kept for that monitor, or for the
  // whole style when there is only the one screen.
  function moveSeal(screenName, corner) {
    if (Quickshell.screens.length > 1) Typeset.setFor(screenName, "inkanAt", corner)
    else Typeset.set("inkanAt", corner)
  }
  function pressSeal(screenName) {
    var name = screenName || focusedScreen()
    if (inkanPrinted(name)) { closeSheet(); closeScroll(); return "closed" }
    if (panelsFor(name) === "scroll") return openScroll("", name) ? "open" : "hidden"
    return openSheet("all", name) ? "open" : "hidden"
  }

  Binding { target: Zones; property: "barConfig"; value: root.barConfig }
  // Data for a sheet is gathered while it is open; the scroll shows every
  // section at once, so all of it while the scroll is out.
  Binding { target: Zones; property: "wanted"; value: root.sheet === "time" || root.scrollOpen }
  Binding { target: Sound; property: "wanted"; value: root.sheet === "sound" || root.scrollOpen }
  Binding { target: Net; property: "wanted"; value: root.sheet === "network" || root.scrollOpen }
  Binding { target: Power; property: "wanted"; value: root.sheet === "power" || root.scrollOpen }
  Binding { target: Display; property: "wanted"; value: root.sheet === "display" || root.scrollOpen }
  Binding { target: Weather; property: "wanted"; value: root.scrollOpen }
  Binding { target: Leaf; property: "wanted"; value: root.scrollOpen }
  Binding { target: Leaf; property: "kind"; value: Typeset.styleFor(root.scrollScreen || root.focusedScreen()).endleaf || "koyomi" }
  Binding { target: Weather; property: "barConfig"; value: root.barConfig }
  Binding { target: Blue; property: "wanted"; value: root.sheet === "bluetooth" || root.scrollOpen }

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
  // its own sheets, or the scroll at that section under panels: scroll.
  // The host asks isBarWidgetOpen first: summon opens, never toggles.
  // A hosted widget answers for its own id through its open()/close().
  function summonBarWidget(id) {
    var key = Sheets.forOmarchyId(id)
    if (sheetReady(key)) return openPanel(key, focusedScreen())
    var w = hostedItemFor(String(id))
    if (w && typeof w.open === "function") { w.open(); return true }
    return false
  }
  function hideBarWidget(id) {
    var key = Sheets.forOmarchyId(id)
    if (sheetReady(key)) { closePanel(key); return true }
    var items = hostedWidgets(String(id))
    for (var i = 0; i < items.length; i++) if (typeof items[i].close === "function") items[i].close()
    return items.length > 0
  }
  function isBarWidgetOpen(id) {
    var key = Sheets.forOmarchyId(id)
    if (key) return panelOpen(key)
    var items = hostedWidgets(String(id))
    for (var i = 0; i < items.length; i++) if (items[i].opened === true) return true
    return false
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
  // Riding 騎 (docs/kaze, mockup 11): while Sumi is on, the bar recedes to
  // its rule (the paper and every zone fade); the pointer on it brings them
  // back. `hanko sumi` says so over IPC; at start the state folder says so.
  property bool riding: false
  FileView {
    path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/hanko/sumi/sumi.glsl"
    printErrors: false
    onLoaded: root.riding = true
    onLoadFailed: root.riding = false
  }

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
    // Unroll or roll up the handscroll on the focused screen, whatever
    // `panels` says (bind it to a key: see the README).
    function settings(): string {
      if (root.settingsOpen) { root.closeSettings(); return "closed" }
      root.openSettings()
      return "open"
    }
    // Hide or show one part of the bar (the Widgets page's parts:
    // seal, volume, tray, indicator:night, hosted:omarchy.weather, ...).
    function hide(part: string): string { return Typeset.set("show:" + part, "hidden") ? "ok" : "invalid" }
    function show(part: string): string { return Typeset.set("show:" + part, "shown") ? "ok" : "invalid" }
    // One setting for one monitor (style.json `monitors`).
    function styleSetFor(monitor: string, key: string, value: string): string {
      return Typeset.setFor(monitor, key, value) ? "ok" : "invalid"
    }
    function overview(): string {
      root.toggleOverview()
      return root.overviewOpen ? "open" : "closed"
    }
    function scroll(): string {
      if (root.scrollOpen) { root.closeScroll(); return "closed" }
      return root.openScroll("", root.focusedScreen()) ? "open" : "hidden"
    }
    // A press on the seal (Inkan), for a keybinding: prints No. 00, or
    // lifts it off.
    function press(): string { return root.pressSeal(root.focusedScreen()) }
    // Kaze's riding mode (`hanko sumi on|off`): the bar recedes to its rule.
    function riding(on: string): string { root.riding = on === "true" || on === "on"; return "ok" }
    function scrollTo(name: string): string {
      return Scroll.indexOf(name) >= 0 && root.openScroll(name, root.focusedScreen()) ? "open" : "unknown"
    }
  }
}
