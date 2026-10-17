pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../core"
import "../core/Overview.js" as O
import "../core/Mission.js" as M
import "../services"
import "overview"

// The layer the workspace overview 一覧 is laid on, one per screen next to
// its BarWindow, all open together (Bar.overviewOpen). Its working
// principle follows AyushKr2003/omarchy-overview: a full-screen Overlay
// layer, the keyboard on the focused monitor only, a Hyprland focus grab
// that closes it when you click away, arrows that switch the real
// workspace while it stays open, live ScreencopyView snapshots of each
// window found through ToplevelManager's HyprlandToplevel addresses, and
// window moves that don't follow the window. What it looks like is
// OverviewView's.
PanelWindow {
  id: win

  required property var bar          // the Bar.qml root
  required property var barWindow    // this screen's BarWindow

  readonly property string screenName: screen ? screen.name : ""
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
  readonly property bool focusedHere: !!Hyprland.focusedMonitor && !!monitor && Hyprland.focusedMonitor.name === monitor.name
  readonly property bool open: bar.overviewOpen
  readonly property bool atBottom: bar.position === "bottom"
  readonly property int strip: barWindow.barHeight + barWindow.gap
  readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
  // Which overview (style.json `overview`): grid, Hanko's pages; dynamic,
  // Ryoku's (bar/overview/DynamicView.qml).
  readonly property bool dynamic: Typeset.current.overview === "dynamic"
  // mission, omarchy-overview's mission control (bar/overview/MissionView.qml).
  readonly property bool mission: Typeset.current.overview === "mission"
  // The mission overview's search, typed on this screen.
  property string query: ""
  property int resultIndex: 0
  readonly property var results: mission && query.trim() !== "" ? Finder.find(query) : []
  // This screen's workspaces, for the dynamic overview.
  readonly property var screenSpaces: Hypr.workspaces.filter(function(w) { return w.id > 0 && (!w.monitor || w.monitor === win.screenName) })

  screen: barWindow.screen
  visible: open || closing.running
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "hanko-overview"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: !win.focusedHere ? WlrKeyboardFocus.None
    : win.handing ? WlrKeyboardFocus.OnDemand
    : win.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // The bar strip stays the bar's: its cells still work under an open
  // overview.
  mask: Region {
    x: 0
    y: 0
    width: win.width
    height: win.height
    Region {
      intersection: Intersection.Subtract
      x: 0
      y: win.atBottom ? win.height - win.strip : 0
      width: win.width
      height: win.strip
    }
  }

  // Click away (another app, another layer): closed. Only the focused
  // monitor's window holds the grab, so a second screen can't close it.
  HyprlandFocusGrab {
    id: grab
    windows: [win]
    active: false
    onCleared: if (win.open && win.focusedHere) win.bar.closeOverview()
  }
  // The grab lands a moment after the layer maps, as omarchy-overview's does.
  Timer {
    id: grabLater
    interval: 120
    onTriggered: grab.active = win.open && win.focusedHere
  }
  onFocusedHereChanged: if (open) grab.active = focusedHere

  Timer { id: closing; interval: Motion.ms(Motion.rollUp) }

  onOpenChanged: {
    if (open) {
      closing.stop()
      handOver.stop()
      letGo.stop()
      handing = false
      view.reveal = 1
      ryoku.reveal = 1
      ryoku.seed()
      query = ""
      resultIndex = 0
      spread.reveal = 1
      spread.seed()
      grabLater.restart()
      if (focusedHere) keys.forceActiveFocus()
    } else {
      grab.active = false
      view.reveal = 0
      ryoku.reveal = 0
      spread.reveal = 0
      spread.endDrag()
      closing.restart()
      // Letting go of the keyboard hands it back to the window that had it,
      // and Hyprland follows that window to the workspace the overview
      // opened on, then the arrows' one again: a flash. So hand it over
      // first: on demand (Hyprland ignores a focus while it's exclusive),
      // focus the live workspace's last window, then let go.
      if (focusedHere) {
        here = activeId
        handing = true
        handOver.restart()
      }
    }
  }

  // The keyboard's handover on closing (above).
  property bool handing: false
  property int here: 0
  Timer {
    id: handOver
    interval: 30
    onTriggered: {
      var address = Hypr.lastWindowOn(win.here)
      if (address) Hypr.focusWindow(address)
      letGo.restart()
    }
  }
  Timer {
    id: letGo
    interval: 40
    onTriggered: {
      win.handing = false
      // An empty workspace has no window to take the keyboard, so Hyprland
      // may still go back: come back here (unless closeThen has somewhere
      // else to go).
      if (!win.pending) {
        var id = win.here
        win.pending = function() { if (win.activeId !== id) Hypr.focusWorkspace(id) }
      }
      later.restart()
    }
  }

  // Leave first, then act: closing hands the keyboard back to the window
  // that had it, which would undo a focus dispatched while still open.
  property var pending: null
  function closeThen(fn) {
    pending = fn
    bar.closeOverview()
    if (!handing) later.restart()   // else letGo starts it
  }
  Timer {
    id: later
    interval: 90
    onTriggered: { var fn = win.pending; win.pending = null; if (fn) fn() }
  }

  OverviewView {
    id: view
    visible: !win.dynamic && !win.mission
    anchors.fill: parent
    topInset: win.atBottom ? 0 : win.strip
    bottomInset: win.atBottom ? win.strip : 0
    pages: O.pages(Hypr.workspaces, win.activeId, O.ROWS, O.COLUMNS, true)
    columns: O.COLUMNS
    aspect: Hypr.aspectFor(win.screenName)
    screenName: win.screenName
    now: win.bar.now
    timeFormat: win.bar.timeFormat
    reveal: 0
    snapshot: win.open ? snapshotComponent : null

    Behavior on reveal {
      NumberAnimation {
        duration: win.open ? Motion.ms(Motion.unroll) : Motion.ms(Motion.rollUp)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.unrollCurve
      }
    }

    onPagePicked: function(id) { win.closeThen(function() { Hypr.focusWorkspace(id) }) }
    onWindowPicked: function(address) { win.closeThen(function() { Hypr.focusWindow(address) }) }
    onWindowClosed: function(address) { Hypr.closeWindow(address) }
    onWindowMoved: function(address, id) { Hypr.moveWindow(address, id) }
    onDismissed: win.bar.closeOverview()

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: function(event) {
        if (event.angleDelta.y !== 0) Hypr.focusWorkspace(O.wheel(win.activeId, event.angleDelta.y > 0 ? -1 : 1, O.ROWS, O.COLUMNS))
      }
    }
  }

  DynamicView {
    id: ryoku
    visible: win.dynamic
    anchors.fill: parent
    topInset: win.atBottom ? 0 : win.strip
    bottomInset: win.atBottom ? win.strip : 0
    spaces: win.screenSpaces
    allIds: Hypr.workspaces.filter(function(w) { return w.id > 0 }).map(function(w) { return w.id })
    activeId: win.activeId
    aspect: Hypr.aspectFor(win.screenName)
    glyph: Typeset.current.sealGlyph || "鑑"
    wallpaper: "file://" + Quickshell.env("HOME") + "/.local/state/omarchy/current/background"
    snapshot: win.open && win.dynamic ? snapshotComponent : null
    iconFor: function(cls) {
      var c = String(cls || "")
      if (!c) return ""
      var entry = DesktopEntries.heuristicLookup(c)
      return Quickshell.iconPath(entry && entry.icon ? entry.icon : c.toLowerCase(), true)
    }
    reveal: 0
    Behavior on reveal { NumberAnimation { duration: Motion.ms(240); easing.type: Easing.OutCubic } }

    onGoTo: function(id) { win.closeThen(function() { Hypr.focusWorkspace(id) }) }
    onWindowFocused: function(address) { win.closeThen(function() { Hypr.focusWindow(address) }) }
    onWindowClosed: function(address) { Hypr.closeWindow(address) }
    onWindowMoved: function(address, id) { Hypr.moveWindow(address, id) }
    onDismissed: win.bar.closeOverview()
  }

  MissionView {
    id: spread
    visible: win.mission
    anchors.fill: parent
    topInset: win.atBottom ? 0 : win.strip
    bottomInset: win.atBottom ? win.strip : 0
    spaces: win.screenSpaces
    allIds: Hypr.workspaces.filter(function(w) { return w.id > 0 }).map(function(w) { return w.id })
    activeId: win.activeId
    aspect: Hypr.aspectFor(win.screenName)
    screenName: win.screenName
    wallpaper: "file://" + Quickshell.env("HOME") + "/.local/state/omarchy/current/background"
    // Kept through the close, so the windows zoom home with their pictures.
    snapshot: win.visible && win.mission ? snapshotComponent : null
    query: win.query
    results: win.results
    resultIndex: win.resultIndex
    reveal: 0
    Behavior on reveal { NumberAnimation { duration: Motion.ms(280); easing.type: Easing.OutCubic } }

    onWorkspacePicked: function(id, go) {
      if (go) win.closeThen(function() { Hypr.focusWorkspace(id) })
      else Hypr.focusWorkspace(id)
    }
    onWindowPicked: function(address) { win.closeThen(function() { Hypr.focusWindow(address) }) }
    onWindowClosed: function(address) { Hypr.closeWindow(address) }
    onWindowMoved: function(address, id) { Hypr.moveWindow(address, id) }
    onWindowsSwapped: function(a, b) { Hypr.swapWindows(a, b, win.spaceOfWindow(a), win.spaceOfWindow(b)) }
    onResultPicked: function(r) { win.runResult(r) }
    onResultHovered: function(i) { win.resultIndex = i }
    onDismissed: win.bar.closeOverview()

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      enabled: !spread.searching
      property real held: 0
      onWheel: function(event) {
        held += event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x
        if (Math.abs(held) < 120) return
        var id = M.stepId(spread.keys, win.activeId, held > 0 ? -1 : 1)
        held = 0
        if (id > 0) Hypr.focusWorkspace(id)
      }
    }
  }

  function spaceOfWindow(address) {
    var all = Hypr.workspaces
    for (var i = 0; i < all.length; i++) {
      var list = all[i].all || []
      for (var j = 0; j < list.length; j++) if (list[j].address === address) return all[i].id
    }
    return -1
  }
  // A result: a window is focused once the overview has let go; the rest
  // run after it closes.
  function runResult(r) {
    if (!r) return
    if (r.kind === "window") win.closeThen(function() { Hypr.focusWindow(r.address) })
    else win.closeThen(function() { Finder.run(r) })
  }

  // A window's live picture, while the overview is up.
  Component {
    id: snapshotComponent
    ScreencopyView {
      property string address: ""
      captureSource: win.visible && address !== "" ? Hypr.toplevelFor(address) : null
      live: true
    }
  }

  // Keys: arrows and hjkl switch the workspace, digits jump inside the
  // group, Enter and Esc are done.
  Item {
    id: keys
    anchors.fill: parent
    focus: win.open && win.focusedHere
    Keys.onPressed: function(event) {
      if (win.dynamic) { win.dynamicKey(event); return }
      if (win.mission) { win.missionKey(event); return }
      var k = event.key, dir = ""
      if (k === Qt.Key_Escape || k === Qt.Key_Return || k === Qt.Key_Enter) { win.bar.closeOverview(); event.accepted = true; return }
      if (k === Qt.Key_Left || k === Qt.Key_H) dir = "left"
      else if (k === Qt.Key_Right || k === Qt.Key_L) dir = "right"
      else if (k === Qt.Key_Up || k === Qt.Key_K) dir = "up"
      else if (k === Qt.Key_Down || k === Qt.Key_J) dir = "down"
      if (dir) { Hypr.focusWorkspace(O.step(win.activeId, dir, O.ROWS, O.COLUMNS)); event.accepted = true; return }
      if (k >= Qt.Key_0 && k <= Qt.Key_9) {
        var id = O.jump(win.activeId, k - Qt.Key_0, O.ROWS, O.COLUMNS)
        if (id > 0) Hypr.focusWorkspace(id)
        event.accepted = true
      }
    }
  }

  // omarchy-overview's keys for the mission overview. With a query: the
  // results (arrows, Tab, Page keys, Enter runs, Esc clears, Backspace and
  // Ctrl+Backspace, Ctrl+U). Without: arrows choose (along the strip they
  // switch), Tab hops between the strip and the windows, Page Up/Down and
  // Ctrl+arrows switch, Super+digit goes to a space, Enter goes, Delete or
  // Ctrl+W closes the chosen window, Esc is done; any other text searches.
  function missionKey(event) {
    var k = event.key, mods = event.modifiers
    var ctrl = (mods & Qt.ControlModifier) !== 0, meta = (mods & Qt.MetaModifier) !== 0
    var shift = (mods & Qt.ShiftModifier) !== 0
    var printable = !(mods & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && event.text.length > 0
      && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127
    event.accepted = true
    if (query.length > 0) {
      var n = results.length
      if (k === Qt.Key_Escape) { query = ""; resultIndex = 0 }
      else if (k === Qt.Key_Up || k === Qt.Key_Backtab || (k === Qt.Key_Tab && shift)) resultIndex = Math.max(0, resultIndex - 1)
      else if (k === Qt.Key_Down || k === Qt.Key_Tab) resultIndex = Math.min(Math.max(0, n - 1), resultIndex + 1)
      else if (k === Qt.Key_PageDown) resultIndex = Math.min(Math.max(0, n - 1), resultIndex + 6)
      else if (k === Qt.Key_PageUp) resultIndex = Math.max(0, resultIndex - 6)
      else if (k === Qt.Key_Return || k === Qt.Key_Enter) runResult(results[Math.min(resultIndex, n - 1)])
      else if (k === Qt.Key_Backspace) { query = ctrl ? query.replace(/\S*\s*$/, "") : query.slice(0, -1); resultIndex = 0 }
      else if (k === Qt.Key_U && ctrl) { query = ""; resultIndex = 0 }
      else if (printable) { query += event.text; resultIndex = 0 }
      else event.accepted = false
      return
    }
    if (k === Qt.Key_Escape) win.bar.closeOverview()
    else if (meta && k >= Qt.Key_0 && k <= Qt.Key_9) Hypr.focusWorkspace(k === Qt.Key_0 ? 10 : k - Qt.Key_0)
    else if (k === Qt.Key_PageUp || k === Qt.Key_PageDown || ((ctrl || meta) && (k === Qt.Key_Left || k === Qt.Key_Right))) {
      var id = M.stepId(spread.keys, win.activeId, k === Qt.Key_PageUp || k === Qt.Key_Left ? -1 : 1)
      if (id > 0) Hypr.focusWorkspace(id)
    }
    else if (k === Qt.Key_Left) spread.navigate("left")
    else if (k === Qt.Key_Right) spread.navigate("right")
    else if (k === Qt.Key_Up) spread.navigate("up")
    else if (k === Qt.Key_Down) spread.navigate("down")
    else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) spread.hop()
    else if (k === Qt.Key_Return || k === Qt.Key_Enter) spread.activate()
    else if (k === Qt.Key_Delete || (k === Qt.Key_W && ctrl)) { var a = spread.selectedAddress(); if (a) Hypr.closeWindow(a) }
    else if (printable && event.text !== " ") { query = event.text; resultIndex = 0 }
    else event.accepted = false
  }

  // Ryoku's keys for the dynamic overview: Tab and the arrows move the
  // selection (nothing switches yet), Alt+Tab steps desktops, Enter goes,
  // Esc dismisses.
  function dynamicKey(event) {
    var k = event.key
    var alt = (event.modifiers & Qt.AltModifier) !== 0
    var shift = (event.modifiers & Qt.ShiftModifier) !== 0
    if (k === Qt.Key_Escape) win.bar.closeOverview()
    else if (alt && (k === Qt.Key_Tab || k === Qt.Key_Right || k === Qt.Key_Backtab || k === Qt.Key_Left))
      ryoku.cycleDesk(shift || k === Qt.Key_Backtab || k === Qt.Key_Left ? -1 : 1)
    else if (k === Qt.Key_Tab || k === Qt.Key_Right || k === Qt.Key_Down) ryoku.cycle(shift ? -1 : 1)
    else if (k === Qt.Key_Backtab || k === Qt.Key_Left || k === Qt.Key_Up) ryoku.cycle(-1)
    else if (k === Qt.Key_Return || k === Qt.Key_Enter) ryoku.activateSelected()
    else return
    event.accepted = true
  }
}
