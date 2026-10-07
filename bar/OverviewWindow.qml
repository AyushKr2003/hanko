pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../core"
import "../core/Overview.js" as O
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

  screen: barWindow.screen
  visible: open || closing.running
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "hanko-overview"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: win.open && win.focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
      view.reveal = 1
      grabLater.restart()
      if (focusedHere) keys.forceActiveFocus()
    } else {
      grab.active = false
      view.reveal = 0
      closing.restart()
    }
  }

  // Leave first, then act: closing hands the keyboard back to the window
  // that had it, which would undo a focus dispatched while still open.
  property var pending: null
  function closeThen(fn) {
    pending = fn
    bar.closeOverview()
    later.restart()
  }
  Timer {
    id: later
    interval: 90
    onTriggered: { var fn = win.pending; win.pending = null; if (fn) fn() }
  }

  OverviewView {
    id: view
    anchors.fill: parent
    topInset: win.atBottom ? 0 : win.strip
    bottomInset: win.atBottom ? win.strip : 0
    pages: O.pages(Hypr.workspaces, win.activeId, O.ROWS, O.COLUMNS, true)
    columns: O.COLUMNS
    aspect: Hypr.aspectFor(win.screenName)
    screenName: win.screenName
    now: win.bar.now
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

  // A window's live picture, while the overview is open.
  Component {
    id: snapshotComponent
    ScreencopyView {
      property string address: ""
      captureSource: win.open && address !== "" ? Hypr.toplevelFor(address) : null
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
}
