import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "core"
import "core/Iai.js" as Iai
import "core/Sweep.js" as Sweep

// Kaze 風, the desk (docs/kaze): the parts of Hanko's look that belong to
// the whole desk rather than the bar, so they run whichever bar is in use.
// An Omarchy service plugin (services start with the shell and reload when
// their files change); it draws only while something is happening, and has
// no surface at all at rest.
//
//   Ha 刃, the focus sweep: when focus moves to a window, light runs once
//   round its edge (core/Sweep.js) while Hyprland inks the edge up from
//   faint (style.lua's border speed), so the light passes and leaves ink.
//
//   A window that needs you: Hyprland has no urgent border colour, so the
//   desk frames an urgent window in seal red, breathing (never colour
//   alone), until you go to it.
Item {
  id: root

  // Host injection (Omarchy's plugin contract); unused.
  property var shell
  property var manifest
  property string omarchyPath

  // ── Motion: Iai, and still when style.json says so ──
  readonly property string styleFile: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/hanko/style.json"
  property bool styleStill: false
  readonly property bool still: styleStill
  FileView {
    path: root.styleFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.styleStill = /"motion"\s*:\s*"still"/.test(text())
    onLoadFailed: root.styleStill = false
  }

  // Hyprland's own border width; its frame sits that far outside a window.
  property int border: 1
  Process {
    running: true
    command: ["hyprctl", "-j", "getoption", "general:border_size"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.border = Math.max(0, JSON.parse(text).int | 0) } catch (e) {}
      }
    }
  }

  // ── The sweep ─────────────────────────────────────────────────────────
  // The rect (global, logical px) being swept, and how far round it is.
  property var sweepRect: null
  property real progress: 0
  property string lastAddress: ""
  property bool primed: false   // no sweep for the focus Hanko finds at start
  // Windows that just opened slide in on the draw; the sweep waits for them.
  property var opened: ({})

  // The light travels on the shake-off curve, easing in and out: on the
  // draw's curve it would cover nine tenths of the edge in the first
  // tenth of a second and then crawl.
  readonly property var travelCurve: Iai.qml("chiburi")

  SequentialAnimation {
    id: sweep
    PauseAnimation { id: sweepDelay; duration: Sweep.HOLD }
    NumberAnimation {
      target: root
      property: "progress"
      from: 0
      to: 1
      duration: Sweep.MS
      easing.type: Easing.BezierSpline
      easing.bezierCurve: root.travelCurve
    }
    ScriptAction { script: { root.sweepRect = null; root.progress = 0 } }
  }

  // Set by the `sweep` IPC call: run once on the focused window even
  // though focus didn't move, and even with motion still (a preview, as
  // Settings › Motion plays a row on hover, and a way to test it).
  property bool replay: false

  function sweepTo(w) {
    if (!w || !w.address || !w.at || !w.size) return
    var preview = root.replay
    var same = w.address === root.lastAddress && !preview
    root.replay = false
    root.lastAddress = w.address
    if (!root.primed) { root.primed = true; return }
    // A preview runs even with motion still: it was asked for.
    if (same || (root.still && !preview) || (w.fullscreen | 0) > 0) return
    sweep.stop()
    root.progress = 0
    var fresh = root.opened[w.address] && Date.now() - root.opened[w.address] < 400
    sweepDelay.duration = Sweep.HOLD + (fresh ? Iai.total("nuki") : 0)
    root.sweepRect = Sweep.frame(w.at, w.size, root.border)
    sweep.start()
  }

  Process {
    id: active
    command: ["hyprctl", "-j", "activewindow"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.sweepTo(JSON.parse(text)) } catch (e) {}
      }
    }
  }

  // ── Windows that need you ─────────────────────────────────────────────
  // address → true, from Hyprland's `urgent` event, until focused or closed.
  property var urgentSet: ({})
  // [{ x, y, width, height }] of the urgent windows on a shown workspace.
  property var urgentRects: []

  Process {
    id: clients
    command: ["sh", "-c", "hyprctl -j clients; echo '%%'; hyprctl -j monitors"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = String(text || "").split("%%\n")
        try {
          var list = JSON.parse(parts[0]), mons = JSON.parse(parts[1] || "[]")
          var shown = {}
          for (var m = 0; m < mons.length; m++) {
            if (mons[m].activeWorkspace) shown[mons[m].activeWorkspace.id] = true
            if (mons[m].specialWorkspace && mons[m].specialWorkspace.id) shown[mons[m].specialWorkspace.id] = true
          }
          var out = []
          for (var i = 0; i < list.length; i++) {
            var c = list[i]
            if (root.urgentSet[c.address] && c.workspace && shown[c.workspace.id])
              out.push(Sweep.frame(c.at, c.size, root.border))
          }
          root.urgentRects = out
        } catch (e) { root.urgentRects = [] }
      }
    }
  }
  function refreshUrgent() {
    if (Object.keys(root.urgentSet).length === 0) { root.urgentRects = []; return }
    if (!clients.running) clients.running = true
  }
  function setUrgent(address, on) {
    if (!address) return
    var next = Object.assign({}, root.urgentSet)
    if (on) next[address] = true
    else if (next[address]) delete next[address]
    else return
    root.urgentSet = next
    root.refreshUrgent()
  }

  // Hyprland's raw events: activewindowv2>>ADDRESS, urgent>>ADDRESS,
  // openwindow>>ADDRESS,…, closewindow>>ADDRESS (without the 0x).
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var n = event.name, data = String(event.data || "")
      var address = "0x" + data.split(",")[0]
      if (n === "activewindowv2") {
        root.setUrgent(address, false)
        if (data !== "" && data !== ",") { if (!active.running) active.running = true }
      } else if (n === "urgent") {
        root.setUrgent(address, true)
        Oto.play("urgent")
      } else if (n === "workspacev2") {
        Oto.play("workspace")
      } else if (n === "openwindow") {
        var o = Object.assign({}, root.opened); o[address] = Date.now(); root.opened = o
      } else if (n === "closewindow") {
        root.setUrgent(address, false)
        var c = Object.assign({}, root.opened); delete c[address]; root.opened = c
      } else if (["workspace", "workspacev2", "movewindow", "movewindowv2", "changefloatingmode", "fullscreen", "activespecial"].indexOf(n) >= 0) {
        root.refreshUrgent()
      }
    }
  }

  // Urgent frames don't follow a drag or resize on their own (no event):
  // a slow look while one is up keeps them where their windows are.
  Timer {
    interval: 1000
    repeat: true
    running: root.urgentRects.length > 0
    onTriggered: root.refreshUrgent()
  }

  // ── Drawing: one input-transparent overlay per screen ─────────────────
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData

      readonly property var area: ({ x: modelData.x, y: modelData.y, width: modelData.width, height: modelData.height })
      readonly property var local: Sweep.onScreen(root.sweepRect, area)
      readonly property var urgentHere: root.urgentRects.map(function(r) { return Sweep.onScreen(r, win.area) }).filter(function(r) { return !!r })

      // No surface unless there is something to draw.
      visible: (local !== null && root.progress > 0) || urgentHere.length > 0
      color: "transparent"
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "hanko-desk"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      // Clicks go straight through to the windows underneath.
      mask: Region {}

      Canvas {
        id: light
        anchors.fill: parent
        visible: win.local !== null
        renderStrategy: Canvas.Cooperative
        property real t: root.progress
        // Light on a blade is brighter than the blade: the edge's own ink
        // (the theme's foreground) lifted halfway to white.
        readonly property color glint: Qt.tint(Ink.bone, Qt.rgba(1, 1, 1, 0.55))
        onTChanged: requestPaint()
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var r = win.local
          if (!r) return
          var pieces = Sweep.lit(r, t)
          ctx.lineCap = "butt"
          ctx.lineWidth = 2
          for (var i = 0; i < pieces.length; i++) {
            var s = pieces[i]
            ctx.strokeStyle = Qt.rgba(glint.r, glint.g, glint.b, s.alpha)
            ctx.beginPath()
            ctx.moveTo(s.a.x, s.a.y)
            ctx.lineTo(s.b.x, s.b.y)
            ctx.stroke()
          }
        }
      }

      // Seal red round each window that needs you, breathing 1 ↔ 0.5 over
      // 1.1 s each way (as the bar's red readings do).
      Repeater {
        model: win.urgentHere
        Rectangle {
          required property var modelData
          x: modelData.x - 0.5
          y: modelData.y - 0.5
          width: modelData.width + 1
          height: modelData.height + 1
          color: "transparent"
          border.width: 2
          border.color: Ink.seal
          SequentialAnimation on opacity {
            running: !root.still
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.5; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.5; to: 1; duration: 1100; easing.type: Easing.InOutSine }
          }
        }
      }
    }
  }

  // omarchy-shell hankodesk sweep: light round the focused window now.
  // omarchy-shell hankodesk state: what the desk is drawing, for doctor.
  // On a reload Omarchy makes the new desk before the old one is gone, and
  // a target has one handler: register a moment later, once it is free.
  IpcHandler {
    id: ipc
    enabled: false
    target: "hankodesk"
    function sweep(): string {
      root.primed = true
      root.replay = true
      if (!active.running) active.running = true
      return "ok"
    }
    function state(): string {
      return JSON.stringify({ still: root.still, border: root.border, sweeping: root.sweepRect !== null, urgent: Object.keys(root.urgentSet).length, screens: Quickshell.screens.length })
    }
  }

  Timer { interval: 500; running: true; onTriggered: ipc.enabled = true }

  Component.onCompleted: active.running = true
}
