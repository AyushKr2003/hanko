import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons
import qs.Ui
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "core/InkMath.js" as InkMath
import "core/Print.js" as Print
import "core/Wind.js" as Wind
import "core/Weather.js" as Weather
import "core/Iai.js" as Iai
import "core"

// Sumizuri 墨摺 (docs/kaze, mockup 03): Omarchy's background, printed in the
// theme's paper and ink. This is Omarchy's own Background.qml (MIT, from
// shell/plugins/background), kept as it is (switching, transitions, the
// theme reveal, double-clicks), with one step added: every picture it is
// asked to show goes through bin/hanko-print first (cached in
// ~/.cache/hanko/prints), and the sky keeps the hour above it. The manifest
// says clonedFrom omarchy.background, so Omarchy's own calls reach it.
// `"wallpaper": "original"` in ~/.config/hanko/kaze.json shows the pictures
// as they are.
//
// Kaze 風, the living layer (mockup 04): grass along the foot of the print,
// in the faintest ink, leaning with the real wind (Open-Meteo for the place in
// Omarchy's weather settings) and gusting toward a window that needs you.
// It is drawn once per change: a lean every 15 minutes, a slow sway on
// windy days, 30 fps only through a gust; none of it under a fullscreen
// window, with motion still, or on battery below 30%.
Item {
  id: root

  // ── Sumizuri: the print step ──────────────────────────────────────────
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
  readonly property string printDir: cacheHome + "/hanko/prints"
  readonly property string printer: String(Qt.resolvedUrl("bin/hanko-print")).replace(/^file:\/\//, "")
  property var kaze: ({})
  readonly property string mode: Print.wallpaperMode(kaze)
  // The picture asked for, before printing (currentBackground is the print).
  property string sourcePath: ""

  FileView {
    path: root.configHome + "/hanko/kaze.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { try { root.kaze = JSON.parse(text() || "{}") } catch (e) { root.kaze = {} } }
    onLoadFailed: root.kaze = {}
  }
  onModeChanged: root.reprint()

  // The paper and ink for a theme's foreground and background.
  function inksFor(fg, bg) {
    var light = InkMath.isLight(bg)
    return { paper: bg, ink: Print.inkFor(InkMath.ramp(fg, bg), light), light: light }
  }
  // foreground and background out of a colors.toml.
  function themeColors(toml) {
    var out = {}
    var re = /^\s*(foreground|background)\s*=\s*"(#[0-9a-fA-F]{6})"/gm
    var m
    while ((m = re.exec(String(toml || ""))) !== null) out[m[1]] = m[2]
    return out
  }

  // One print at a time; a newer request replaces one still waiting. If the
  // print isn't ready within `patience` (it takes a few seconds the first
  // time), the original goes up now and the print follows when it lands.
  readonly property int patience: 400
  property var request: null
  property var queued: null
  function printed(path, fg, bg, done) {
    path = String(path || "").trim()
    if (!path || root.mode === "original") { done(path); return }
    var inks = root.inksFor(String(fg), String(bg))
    var req = { path: path, inks: inks, done: done, answered: false }
    if (printProc.running) { root.queued = req; return }
    root.start(req)
  }
  function start(req) {
    root.request = req
    printProc.command = [root.printer, "--cache", root.printDir, req.path, req.inks.paper, req.inks.ink].concat(req.inks.light ? ["light"] : [])
    printProc.running = true
    patienceTimer.restart()
  }
  function answer(req, result) {
    if (!req) return
    if (!req.answered) { req.answered = true; req.done(result); return }
    // Late: the original went up; bring the print in if it's still the one.
    if (result !== req.path && root.sourcePath === req.path) root.setBackground(result, false)
  }
  Timer {
    id: patienceTimer
    interval: root.patience
    onTriggered: if (root.request && !root.request.answered) root.answer(root.request, root.request.path)
  }
  Process {
    id: printProc
    stdout: StdioCollector {
      onStreamFinished: {
        var req = root.request
        var out = String(text || "").trim()
        root.answer(req, out !== "" ? out : (req ? req.path : ""))
      }
    }
    onExited: function(code) {
      if (code !== 0 && root.request && !root.request.answered) root.answer(root.request, root.request.path)
      if (root.queued) { var next = root.queued; root.queued = null; root.start(next) }
    }
  }

  // Show the picture at `path`, printed in the current theme's inks.
  function show(path, instant) {
    root.sourcePath = String(path || "").trim()
    root.printed(root.sourcePath, Color.foreground, Color.background, function(p) { root.setBackground(p, instant) })
  }
  function reprint() {
    if (root.sourcePath) root.show(root.sourcePath, false)
  }
  // A theme switch that didn't come through themeTransition still re-inks.
  Connections {
    target: Color
    function onForegroundChanged() { reprintTimer.restart() }
    function onBackgroundChanged() { reprintTimer.restart() }
  }
  Timer { id: reprintTimer; interval: 150; onTriggered: root.reprint() }

  // ── Kaze: the wind ────────────────────────────────────────────────────
  readonly property var wind: Wind.settings(kaze)
  readonly property string styleFile: root.configHome + "/hanko/style.json"
  property bool still: false
  FileView {
    path: root.styleFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.still = /"motion"\s*:\s*"still"/.test(text())
    onLoadFailed: root.still = false
  }

  // The place, as Omarchy's weather panel has it; found from the IP address
  // (wttr.in) when it has a name but no coordinates.
  property var place: ({ latitude: null, longitude: null })
  FileView {
    path: root.stateHome + "/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.placeFrom(Weather.location(text()))
    onLoadFailed: root.placeFrom(Weather.location(""))
  }
  function placeFrom(loc) {
    if (loc.latitude !== null) { root.place = loc; root.fetchWind() }
    else if (!areaProc.running) areaProc.running = true
  }
  Process {
    id: areaProc
    command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/?format=j1"]
    stdout: StdioCollector {
      onStreamFinished: {
        var a = Weather.area(text)
        if (a) { root.place = a; root.fetchWind() }
      }
    }
  }
  property real windLean: 0
  function fetchWind() {
    if (root.wind.wind !== "weather" || root.place.latitude === null || windProc.running) return
    windProc.command = ["curl", "-fsS", "--max-time", "8", Weather.url(root.place.latitude, root.place.longitude)]
    windProc.running = true
  }
  Process {
    id: windProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var cur = JSON.parse(text).current
          root.windLean = Wind.lean(cur.wind_speed_10m, cur.wind_direction_10m)
        } catch (e) {}
      }
    }
  }
  Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.fetchWind() }
  // Sumi 墨 (`hanko sumi on`): the wind blows harder, as Kurosawa Mode's did.
  property bool sumi: false
  FileView {
    path: root.stateHome + "/hanko/sumi/sumi.glsl"
    watchChanges: true
    printErrors: false
    onLoaded: root.sumi = true
    onLoadFailed: root.sumi = false
  }
  // A virtual wind (Settings › Kaze) stands in for the weather's.
  readonly property real lean: (root.wind.wind === "calm" ? 0
    : root.wind.wind === "virtual" ? Wind.virtualLean(root.wind) : root.windLean) * (root.sumi ? 1.3 : 1)

  // Monitors whose shown workspace has a fullscreen window: the grass rests there.
  property var fullscreenOn: ({})
  Process {
    id: fsProc
    command: ["sh", "-c", "hyprctl -j monitors; echo '%%'; hyprctl -j workspaces"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parts = String(text || "").split("%%\n")
          var mons = JSON.parse(parts[0]), wss = JSON.parse(parts[1])
          var full = {}, byId = {}
          for (var i = 0; i < wss.length; i++) byId[wss[i].id] = wss[i]
          for (var j = 0; j < mons.length; j++) {
            var w = mons[j].activeWorkspace && byId[mons[j].activeWorkspace.id]
            if (w && w.hasfullscreen) full[mons[j].name] = true
          }
          root.fullscreenOn = full
        } catch (e) {}
      }
    }
  }
  function lookFullscreen() { if (!fsProc.running) fsProc.running = true }

  // A gust toward a share of the width (0..1) on one screen, or every screen.
  property real gustTarget: 0.5
  property string gustScreen: ""
  property real gustProgress: 0
  NumberAnimation {
    id: gustAnim
    target: root
    property: "gustProgress"
    from: 0
    to: 1
    duration: Wind.GUST_MS
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Iai.qml("chiburi")
    onFinished: { root.gustProgress = 0; root.previewing = false }
  }
  // A preview (the IPC call) runs even with motion still: it was asked for.
  property bool previewing: false
  function gust(share, screenName, preview) {
    if (root.wind.grass !== "grass") return
    if (!preview && (!root.wind.gusts || root.still)) return
    root.previewing = !!preview
    root.gustTarget = Math.max(0, Math.min(1, Number(share)))
    root.gustScreen = String(screenName || "")
    gustAnim.restart()
  }

  // Hyprland: a window that needs you gets a gust toward it.
  Process {
    id: urgentProc
    property string address: ""
    command: ["sh", "-c", "hyprctl -j clients; echo '%%'; hyprctl -j monitors"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parts = String(text || "").split("%%\n")
          var list = JSON.parse(parts[0]), mons = JSON.parse(parts[1])
          var c = null
          for (var i = 0; i < list.length; i++) if (list[i].address === urgentProc.address) c = list[i]
          if (!c) return
          for (var j = 0; j < mons.length; j++) {
            var m = mons[j]
            if (m.id !== c.monitor) continue
            var cx = c.at[0] + c.size[0] / 2 - m.x
            root.gust(cx / (m.width / (m.scale || 1)), m.name)
          }
        } catch (e) {}
      }
    }
  }
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var n = event.name
      if (n === "urgent") {
        urgentProc.address = "0x" + String(event.data || "")
        if (!urgentProc.running) urgentProc.running = true
      } else if (["fullscreen", "workspace", "workspacev2", "focusedmon", "activewindowv2", "closewindow", "openwindow"].indexOf(n) >= 0) {
        root.lookFullscreen()
      }
    }
  }

  // omarchy-shell hankowind gust 0.9   (a share of the width; any screen)
  // omarchy-shell hankowind state
  IpcHandler {
    id: windIpc
    enabled: false
    target: "hankowind"
    function gust(share: string): string { root.gust(parseFloat(share), "", true); return "ok" }
    // `hanko sumi on|off` says so here (a file watch can't see a file that
    // doesn't exist yet).
    function setSumi(on: string): string { root.sumi = on === "true" || on === "on"; return "ok" }
    function state(): string {
      return JSON.stringify({ lean: root.lean, sumi: root.sumi, grass: root.wind.grass, gusts: root.wind.gusts, still: root.still,
        place: root.place.name || "", fullscreen: Object.keys(root.fullscreenOn) })
    }
  }
  Timer { interval: 500; running: true; onTriggered: windIpc.enabled = true }

  // The sway: a slow nudge on windy days, twice a second.
  property real swayTick: 0
  Timer {
    interval: 500
    repeat: true
    running: Math.abs(root.lean) >= 0.15 && Wind.mayMove(root.still, false, UPower.onBattery, UPower.displayDevice ? UPower.displayDevice.percentage : 1)
    onTriggered: root.swayTick += 0.5
  }

  // ── The sky keeps the hour ──
  property real hour: 12
  function tick() { var d = new Date(); root.hour = d.getHours() + d.getMinutes() / 60 }
  Timer { interval: 15 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.tick() }
  readonly property var sky: Print.skyAt(root.hour)
  readonly property bool lightTheme: InkMath.isLight(String(Color.background))

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentBackgroundLink: stateHome + "/omarchy/current/background"

  property string currentBackground: ""
  property string displayedBackground: ""
  property string incomingBackground: ""
  property string oldBackground: ""
  property bool finishingTransition: false
  property int backgroundVersion: 0
  property int revealStartedVersion: -1
  property int pendingThemeVersion: -1
  property string pendingColorsRaw: ""
  property string pendingShellRaw: ""
  property real revealProgress: 1

  function imageUrl(path) {
    return Util.fileUrl(path)
  }

  function refreshBackground() {
    if (!readlinkProc.running) readlinkProc.running = true
  }

  function setBackground(path, instant) {
    transitionBackground("", path, path, instant, false)
  }

  function transitionBackground(fromPath, path, finalPath, instant, force) {
    path = String(path || "").trim()
    finalPath = String(finalPath || path).trim()
    fromPath = String(fromPath || "").trim()
    if (!path || (!force && finalPath === currentBackground)) return
    currentBackground = finalPath
    backgroundVersion += 1
    revealStartedVersion = -1

    revealAnimation.stop()
    finishingTransition = false

    if (instant || !displayedBackground) {
      oldBackground = ""
      incomingBackground = ""
      displayedBackground = path
      revealProgress = 1
      return
    }

    oldBackground = fromPath || displayedBackground
    incomingBackground = path
    revealProgress = 0
  }

  function setPendingTheme(colorsB64, shellB64) {
    pendingColorsRaw = Util.decodeBase64(colorsB64)
    pendingShellRaw = Util.decodeBase64(shellB64)
    pendingThemeVersion = backgroundVersion
    pendingThemeFallbackTimer.restart()
  }

  function applyPendingTheme() {
    // Background polling can advance backgroundVersion while a theme switch is
    // pending; the latest theme payload should still apply.
    if (pendingThemeVersion < 0) return
    pendingThemeFallbackTimer.stop()
    Color.loadColors(pendingColorsRaw)
    // Color.loadShell also refreshes Style so the type scale flips with the
    // background reveal instead of waiting for a separate reload path.
    Color.loadShell(pendingShellRaw)
    Style.scheduleRefresh()
    pendingThemeVersion = -1
    pendingColorsRaw = ""
    pendingShellRaw = ""
  }

  function transitionBackgroundWithTheme(fromPath, path, finalPath, colorsB64, shellB64) {
    transitionBackground(fromPath, path, finalPath, false, true)
    setPendingTheme(colorsB64, shellB64)
    if (!incomingBackground || revealProgress >= 1) applyPendingTheme()
  }

  function startReveal(panel) {
    if (!incomingBackground) return
    panel.maskReady = true
    if (revealStartedVersion === backgroundVersion) return
    revealStartedVersion = backgroundVersion
    applyPendingTheme()
    revealAnimation.restart()
  }

  function openSelector() {
    if (!bgSwitchProc.running) bgSwitchProc.running = true
  }

  function openThemeSwitcher() {
    if (!themeSwitchProc.running) themeSwitchProc.running = true
  }

  Process {
    id: bgSwitchProc
    command: ["bash", "-c", "background=$(omarchy-theme-bg-switcher); [[ -n $background ]] && omarchy-theme-bg-set \"$background\""]
    onExited: root.refreshBackground()
  }

  Process {
    id: themeSwitchProc
    command: ["bash", "-c", "theme=$(omarchy-theme-switcher); [[ -n $theme ]] && omarchy-theme-set \"$theme\" >/dev/null 2>&1 &"]
    onExited: root.refreshBackground()
  }

  Process {
    id: readlinkProc
    command: ["readlink", "-f", root.currentBackgroundLink]
    stdout: StdioCollector {
      onStreamFinished: root.show(String(text || "").trim(), false)
    }
  }

  IpcHandler {
    target: "background"

    function refresh(): void {
      root.refreshBackground()
    }

    function set(path: string): void {
      root.show(path, false)
    }

    function setInstant(path: string): void {
      root.show(path, true)
    }

    // Omarchy names the pictures; the desk shows their prints, so the
    // transition starts from what is on screen now.
    function transition(fromPath: string, path: string): void {
      root.sourcePath = String(path || "").trim()
      root.printed(path, Color.foreground, Color.background, function(p) {
        root.transitionBackground(root.displayedBackground || fromPath, p, p, false, false)
      })
    }

    // A theme switch: print the new picture in the new theme's inks.
    function themeTransition(fromPath: string, path: string, finalPath: string, colorsB64: string, shellB64: string): void {
      var c = root.themeColors(Util.decodeBase64(colorsB64))
      root.sourcePath = String(finalPath || path || "").trim()
      root.printed(root.sourcePath, c.foreground || Color.foreground, c.background || Color.background, function(p) {
        root.transitionBackgroundWithTheme(root.displayedBackground || fromPath, p, p, colorsB64, shellB64)
      })
    }
  }

  Timer {
    id: pendingThemeFallbackTimer
    interval: 300
    repeat: false
    onTriggered: root.applyPendingTheme()
  }

  NumberAnimation {
    id: revealAnimation
    target: root
    property: "revealProgress"
    from: 0
    to: 1
    duration: 420
    easing.type: Easing.InOutCubic
    onFinished: {
      if (root.incomingBackground) {
        root.displayedBackground = root.currentBackground || root.incomingBackground
        root.finishingTransition = true
      }
      root.revealProgress = 1
    }
  }

  Component.onCompleted: { refreshBackground(); lookFullscreen() }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      screen: modelData
      visible: !remapGuard.remapping
      anchors { top: true; bottom: true; left: true; right: true }

      ScreenMoveRemap {
        id: remapGuard
        window: panel
      }
      color: "transparent"
      // Keep render updates enabled. The background layer has been observed to
      // lose its committed buffer while parked with updatesEnabled=false,
      // leaving a black desktop until omarchy-shell is restarted. The wallpaper
      // itself is static, so this favors correctness over a small render-loop
      // optimization.
      updatesEnabled: true

      property bool maskReady: false

      function maybeStartReveal() {
        if (!root.incomingBackground || root.revealProgress !== 0 || maskReady) return
        if (incomingFrame.status !== Image.Ready) return
        Qt.callLater(function() {
          if (!root.incomingBackground || root.revealProgress !== 0 || maskReady) return
          if (incomingFrame.status !== Image.Ready) return
          root.startReveal(panel)
        })
      }

      WlrLayershell.namespace: "omarchy-background"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Image {
        id: base
        anchors.fill: parent
        source: root.imageUrl(root.displayedBackground)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        onStatusChanged: {
          if (status === Image.Ready && root.finishingTransition) {
            root.incomingBackground = ""
            root.oldBackground = ""
            root.finishingTransition = false
          }
        }
      }

      Image {
        id: oldFrame
        anchors.fill: parent
        source: root.imageUrl(root.oldBackground)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        visible: root.oldBackground !== "" && root.revealProgress < 1
        onStatusChanged: panel.maybeStartReveal()
      }

      Item {
        id: incomingLayer
        anchors.fill: parent
        visible: root.incomingBackground !== "" && incomingFrame.status === Image.Ready && (root.revealProgress >= 1 || panel.maskReady)
        layer.enabled: root.incomingBackground !== "" && root.revealProgress < 1
        layer.smooth: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: revealMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.02
        }

        Image {
          id: incomingFrame
          anchors.fill: parent
          source: root.imageUrl(root.incomingBackground)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: false
          smooth: true
          mipmap: true
          onStatusChanged: panel.maybeStartReveal()
        }
      }

      Item {
        id: revealMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        readonly property real slant: -0.18
        readonly property real centerTop: width / 2 - slant * height / 2
        readonly property real centerBottom: width / 2 + slant * height / 2
        readonly property real reach: width / 2 + Math.abs(slant) * height / 2 + 4
        readonly property real spread: reach * root.revealProgress

        Shape {
          anchors.fill: parent
          antialiasing: true
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            startX: revealMask.centerTop - revealMask.spread; startY: 0
            PathLine { x: revealMask.centerTop + revealMask.spread; y: 0 }
            PathLine { x: revealMask.centerBottom + revealMask.spread; y: revealMask.height }
            PathLine { x: revealMask.centerBottom - revealMask.spread; y: revealMask.height }
            PathLine { x: revealMask.centerTop - revealMask.spread; y: 0 }
          }
        }
      }

      // The sky: the top 40% lifts toward the lighter of paper and ink by day
      // and settles toward the darker at night (core/Print.js skyAt).
      Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: parent.height * 0.4
        visible: root.mode === "print" && (root.sky.lift > 0 || root.sky.shade > 0)
        gradient: Gradient {
          GradientStop {
            position: 0
            color: root.sky.lift > 0
              ? Qt.rgba(root.lightTheme ? Color.background.r : Color.foreground.r, root.lightTheme ? Color.background.g : Color.foreground.g, root.lightTheme ? Color.background.b : Color.foreground.b, root.sky.lift)
              : Qt.rgba(0, 0, 0, root.sky.shade)
          }
          GradientStop { position: 1; color: "transparent" }
        }
      }

      // The ground: the print fades into paper along the foot, so the grass reads.
      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Math.round(parent.height * 0.24)
        visible: grass.visible
        gradient: Gradient {
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 0.7; color: Color.background }
        }
      }

      // The grass. Drawn when the lean, the sway or a gust changes; it rests
      // (no sway, no gust) under a fullscreen window and on low battery.
      Canvas {
        id: grass
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Math.round(parent.height * 170 / 1080)
        visible: root.wind.grass === "grass"
        renderStrategy: Canvas.Cooperative
        readonly property bool moves: Wind.mayMove(root.still, !!root.fullscreenOn[panel.modelData.name],
          UPower.onBattery, UPower.displayDevice ? UPower.displayDevice.percentage : 1)
        readonly property var blades: Wind.field(width, height, 11)
        readonly property real sway: moves ? Wind.swayAt(root.lean, root.swayTick) : 0
        readonly property var gustNow: (moves || root.previewing) && (root.gustScreen === "" || root.gustScreen === panel.modelData.name)
          ? Wind.gustAt(root.gustProgress, root.gustTarget) : null
        // The faintest ink: the grass is the quietest thing on the desk.
        readonly property color ink: Ink.inkFaint
        onBladesChanged: requestPaint()
        onSwayChanged: requestPaint()
        onGustNowChanged: requestPaint()
        onInkChanged: requestPaint()
        Connections { target: root; function onLeanChanged() { grass.requestPaint() } }
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var c = grass.ink
          for (var i = 0; i < blades.length; i++) {
            var g = Wind.blade(blades[i], height, width, root.lean, sway, gustNow)
            ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, g.alpha * 0.85)
            ctx.beginPath()
            ctx.moveTo(g.root[0] - g.w, g.root[1])
            ctx.quadraticCurveTo(g.ctrl[0] - g.w * 0.45, g.ctrl[1], g.tip[0], g.tip[1])
            ctx.quadraticCurveTo(g.ctrl[0] + g.w * 0.35, g.ctrl[1], g.root[0] + g.w, g.root[1])
            ctx.closePath()
            ctx.fill()
            if (g.plume.length) {
              ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, g.alpha * 0.63)
              ctx.lineWidth = 1
              ctx.beginPath()
              for (var k = 0; k < g.plume.length; k++) { var p = g.plume[k]; ctx.moveTo(p[0], p[1]); ctx.lineTo(p[2], p[3]) }
              ctx.stroke()
            }
          }
        }
      }

      Connections {
        target: root
        function onIncomingBackgroundChanged() {
          panel.maskReady = false
          panel.maybeStartReveal()
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onDoubleClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) root.openThemeSwitcher()
          else root.openSelector()
          mouse.accepted = true
        }
      }
    }
  }
}
