import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "core"
import "core/Iai.js" as Iai
import "core/Sweep.js" as Sweep
import "core/Kaisei.js" as Kaisei
import "core/Taiji.js" as Taiji

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
//
//   Taiji 対峙, the cut: when a password goes to be checked, hanko.lock's
//   view leaves a note; the desk lays the lock's own picture (core/
//   Standoff.qml) under the lock, and the moment the session unlocks, cuts
//   it along the diagonal and peels each half away from it like a page
//   turned in a book (core/Taiji.js holds the timeline, assets/shaders/
//   curl.vert bends the paper).
//
//   Kaisei 回生: when the shell comes back from a crash (a fresh quickshell
//   core dump, core/Kaisei.js), a small tab says so at the top right for a
//   few seconds.
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

  // ── The cut's halves ──────────────────────────────────────────────────
  // One side of the cut, peeled off like a page turned in a book: the
  // sheet rolls round a soft curl that runs out from the cut, one end
  // leading, and lies back over itself face down (assets/shaders/curl.vert
  // bends a fine mesh of the picture; curl.frag lights it). Taiji.cutCurl
  // says where the curl is.
  component CutHalf: ShaderEffect {
    id: half
    required property real roll
    // +1 below the cut, -1 above
    property real side: 1
    readonly property var curl: Taiji.cutCurl(roll, width, height)
    // flat under the lock while armed, gone once rolled off
    visible: roll < 1
    // the lock's picture
    property variant source
    property vector2d screen: Qt.vector2d(width, height)
    property real fold: curl.fold
    property real radius: curl.radius
    property real tilt: curl.tilt
    // near enough that a lifting sheet swells toward you, as paper does
    property real eye: Math.sqrt(width * width + height * height) * 1.1
    property color back: Ink.paper2
    // the curl runs across the cut's width and along its depth, fine
    // enough that the roll's outline has no facets (a few px a cell)
    mesh: GridMesh { resolution: Qt.size(128, 320) }
    vertexShader: Qt.resolvedUrl("assets/shaders/curl.vert.qsb")
    fragmentShader: Qt.resolvedUrl("assets/shaders/curl.frag.qsb")
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
      visible: (local !== null && root.progress > 0) || urgentHere.length > 0 || (root.kaisei > 0 && win.isFocusedScreen) || root.cutPhase !== ""
      readonly property bool isFocusedScreen: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
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

      // The cut: the lock's picture, once, as a texture; over it two halves
      // either side of the diagonal from the bottom left to the top right,
      // each peeling off (CutHalf, above).
      Item {
        id: cutLayer
        anchors.fill: parent
        visible: root.cutPhase !== ""
        readonly property real hyp: Math.sqrt(width * width + height * height)
        readonly property real deg: -Math.atan2(height, width) * 180 / Math.PI
        // drawn through a multisampled layer, so the roll's outline and the
        // cut's edge come out smooth instead of in steps (a mesh's edges
        // get no antialiasing of their own); laid while armed, so the
        // first frame of the cut doesn't wait for it
        layer.enabled: root.cutPhase !== ""
        layer.samples: 4

        Standoff {
          id: cutPicture
          width: cutLayer.width; height: cutLayer.height
          // drawn only through the halves; sampled smoothly, with
          // mipmaps for where the roll squeezes it, never pixel by pixel
          layer.enabled: true
          layer.smooth: true
          layer.mipmap: true
          opacity: 0
          backgroundPath: root.cutNote.backgroundPath || ""
          backgroundVersion: root.cutNote.backgroundVersion || 0
          loadBackground: root.cutPhase !== ""
          authenticating: root.cutPhase === "armed"
          ticking: root.cutPhase !== "cutting"
          fingerprint: !!root.cutNote.fingerprint
        }
        // the desk beside each roll, shaded where the paper lifts off it
        ShaderEffect {
          anchors.fill: parent
          visible: root.cutRollAbove > 0 && root.cutRollBelow < 1
          readonly property var above: Taiji.cutCurl(root.cutRollAbove, width, height)
          readonly property var below: Taiji.cutCurl(root.cutRollBelow, width, height)
          property vector2d screen: Qt.vector2d(width, height)
          property real tilt: above.tilt
          property real start: above.start
          property real foldA: above.fold
          property real radiusA: above.radius
          property real foldB: below.fold
          property real radiusB: below.radius
          fragmentShader: Qt.resolvedUrl("assets/shaders/curlshade.frag.qsb")
        }
        CutHalf {
          anchors.fill: parent
          side: -1
          roll: root.cutRollAbove
          source: cutPicture
        }
        CutHalf {
          anchors.fill: parent
          side: 1
          roll: root.cutRollBelow
          source: cutPicture
        }
        // The cut itself: a hairline from corner to corner, lit at once in
        // a faint glow of its own, fading as the halves lift.
        Item {
          visible: root.cutFlash > 0
          opacity: root.cutFlash
          x: 0; y: cutLayer.height
          width: cutLayer.hyp; height: 0
          transformOrigin: Item.TopLeft
          rotation: cutLayer.deg
          Rectangle { y: -4; width: parent.width; height: 10; antialiasing: true; color: Ink.bone; opacity: 0.18 }
          Rectangle { y: 0; width: parent.width; height: 2; antialiasing: true; color: Qt.tint(Ink.bone, Qt.rgba(1, 1, 1, 0.55)) }
        }
      }

      // 回生: a small paper tab under the top right corner.
      Rectangle {
        visible: root.kaisei > 0 && win.isFocusedScreen
        anchors.right: parent.right
        anchors.rightMargin: 24
        y: 52
        width: kaiseiRow.implicitWidth + 36
        height: 52
        clip: true
        color: Ink.paper
        border.width: 1
        border.color: Ink.lineStrong
        opacity: root.kaisei
        transform: Translate { x: (1 - root.kaisei) * 30 }
        Row {
          id: kaiseiRow
          anchors.centerIn: parent
          spacing: 14
          Text { anchors.verticalCenter: parent.verticalCenter; text: "回生"; color: Ink.ink; font.family: "Noto Serif CJK JP"; font.pixelSize: 22; font.letterSpacing: 2 }
          Text { anchors.verticalCenter: parent.verticalCenter; text: "BACK · AFTER A CRASH"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: 11; font.letterSpacing: 2.2 }
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
    function kaisei(): string { root.showKaisei(); return "ok" }
    // A preview of the unlock cut, without a lock: lay the picture, then cut.
    function cut(): string {
      root.armCut({ at: Date.now(), backgroundPath: Quickshell.env("HOME") + "/.local/state/omarchy/current/background", fingerprint: false })
      root.cutPreviewing = true
      lockPoll.stop()
      cutPreview.restart()
      return "ok"
    }
    function state(): string {
      return JSON.stringify({ still: root.still, border: root.border, sweeping: root.sweepRect !== null, urgent: Object.keys(root.urgentSet).length, screens: Quickshell.screens.length })
    }
  }

  Timer { interval: 500; running: true; onTriggered: ipc.enabled = true }

  // ── Taiji: the cut on unlock ──────────────────────────────────────────
  readonly property string cutPath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/hanko/cut.json"
  // "" nothing; "armed" laid under the lock, waiting; "cutting" parting.
  property string cutPhase: ""
  property var cutNote: ({})
  // how far into the cut (ms, 0 to Taiji.CUT_MS); the hairline and how far
  // each half has rolled off (0 flat to 1 gone) follow from it
  property real cutMs: 0
  readonly property real cutFlash: cutPhase === "cutting" ? Taiji.cutFlash(cutMs) : 0
  readonly property real cutRollAbove: Taiji.cutRoll(0, cutMs)
  readonly property real cutRollBelow: Taiji.cutRoll(1, cutMs)
  // The note must exist before it can be watched.
  Process {
    running: true
    command: ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\"; [ -f \"$1\" ] || echo '{}' > \"$1\"", "sh", root.cutPath]
    onExited: cutFile.reload()
  }
  FileView {
    id: cutFile
    path: root.cutPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var n = {}
      try { n = JSON.parse(text() || "{}") } catch (e) {}
      if (n.at && Date.now() - n.at < 10000) root.armCut(n)
      else if (root.cutPhase === "armed") root.disarmCut()
    }
  }
  function armCut(n) {
    root.cutNote = n
    cutAnim.stop()
    root.cutMs = 0
    root.cutPhase = "armed"
    cutTimeout.restart()
    lockPoll.restart()
  }
  function disarmCut() {
    lockPoll.stop(); cutTimeout.stop(); cutAnim.stop()
    root.cutPhase = ""
  }
  Timer { id: cutTimeout; interval: 12000; onTriggered: root.disarmCut() }
  Timer { id: cutPreview; interval: 700; onTriggered: root.cut() }
  // While armed: ask the lock, often, whether it has let go.
  Timer {
    id: lockPoll
    interval: 80
    repeat: true
    onTriggered: if (!lockAsk.running) lockAsk.running = true
  }
  Process {
    id: lockAsk
    command: ["omarchy-shell", "lock", "isLocked"]
    stdout: StdioCollector {
      onStreamFinished: if (root.cutPhase === "armed" && String(text).trim() === "false") root.cut()
    }
  }
  // A preview (the IPC call) runs even with motion still: it was asked for.
  property bool cutPreviewing: false
  function cut() {
    lockPoll.stop(); cutTimeout.stop()
    root.cutPhase = "cutting"
    var preview = root.cutPreviewing
    root.cutPreviewing = false
    if (root.still && !preview) { root.disarmCut(); return }
    cutAnim.restart()
  }
  SequentialAnimation {
    id: cutAnim
    // one even clock; Taiji.js shapes the hairline and each fold from it
    NumberAnimation { target: root; property: "cutMs"; from: 0; to: Taiji.CUT_MS; duration: Taiji.CUT_MS; easing.type: Easing.Linear }
    ScriptAction { script: { root.cutPhase = ""; cutFile.setText("{}") } }
  }

  // ── Kaisei 回生: back after a crash ───────────────────────────────────
  property real kaisei: 0
  Process {
    id: crashLook
    command: ["coredumpctl", "--no-pager", "list", "/usr/bin/quickshell", "--since=-120s", "--json=short"]
    stdout: StdioCollector {
      onStreamFinished: if (Kaisei.crashedRecently(text, Date.now())) root.showKaisei()
    }
  }
  function showKaisei() { kaiseiAnim.restart() }
  SequentialAnimation {
    id: kaiseiAnim
    PauseAnimation { duration: 800 }
    NumberAnimation { target: root; property: "kaisei"; to: 1; duration: root.still ? 0 : Iai.BEATS.nuki.ms; easing.type: Easing.BezierSpline; easing.bezierCurve: Iai.qml("nuki") }
    PauseAnimation { duration: 4000 }
    NumberAnimation { target: root; property: "kaisei"; to: 0; duration: root.still ? 0 : Iai.BEATS.noto.ms; easing.type: Easing.BezierSpline; easing.bezierCurve: Iai.qml("noto") }
  }

  Component.onCompleted: { active.running = true; crashLook.running = true }
}
