import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons
import qs.Ui
import "core/InkMath.js" as InkMath
import "core/Print.js" as Print

// Sumizuri 墨摺 (docs/kaze, mockup 03): Omarchy's background, printed in the
// theme's paper and ink. This is Omarchy's own Background.qml (MIT, from
// shell/plugins/background), kept as it is (switching, transitions, the
// theme reveal, double-clicks), with one step added: every picture it is
// asked to show goes through bin/hanko-print first (cached in
// ~/.cache/hanko/prints), and the sky keeps the hour above it. The manifest
// says clonedFrom omarchy.background, so Omarchy's own calls reach it.
// `"wallpaper": "original"` in ~/.config/hanko/kaze.json shows the pictures
// as they are.
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

  Component.onCompleted: refreshBackground()

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
