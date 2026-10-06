import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../core/Sheets.js" as Sheets
import "../services"

// One layer-shell bar per screen. It reserves its own height and, when the
// bar is hidden, parks just past the screen edge instead of unmapping, the
// same trick Omarchy's bar uses so showing it again is only a margin change.
PanelWindow {
  id: win

  required property var bar          // the Bar.qml root
  property var style: Typeset.styleFor(screen ? screen.name : "")

  // What the bar actually draws: Hanko's style, Omarchy's position, and
  // Omarchy's transparency toggle turning solid paper into glass.
  readonly property var shown: {
    var s = Object.assign({}, win.style)
    s.position = win.bar.position
    if (win.bar.transparent && s.surface === "solid") s.surface = "glass"
    return s
  }

  readonly property int barHeight: Type.px(style.height)
  readonly property bool atBottom: bar.position === "bottom"
  // Inset floats 8 px off the screen's edges. Hyprland adds the margin on
  // the anchored edge to the exclusive zone, so windows stay 8 px clear of
  // the frame too.
  readonly property int gap: shown.surface === "inset" ? 8 : 0

  color: "transparent"
  implicitHeight: barHeight
  exclusionMode: bar.barHidden ? ExclusionMode.Ignore : ExclusionMode.Auto

  WlrLayershell.namespace: "hanko-bar"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: !win.atBottom
    bottom: win.atBottom
    left: true
    right: true
  }

  margins {
    top: win.atBottom ? 0 : (win.bar.barHidden ? -win.barHeight - win.gap : win.gap)
    bottom: !win.atBottom ? 0 : (win.bar.barHidden ? -win.barHeight - win.gap : win.gap)
    left: win.gap
    right: win.gap
  }

  readonly property string screenName: screen ? screen.name : ""
  readonly property alias surface: surface

  Component.onCompleted: bar.registerWindow(screenName, win)
  Component.onDestruction: bar.unregisterWindow(screenName, win)

  // A click on a cell with a sheet opens (or closes) that sheet; anything
  // else goes to the service as before.
  function cellClicked(cell, how, fallback) {
    var key = Sheets.forCell(cell)
    if (how === "click" && bar.sheetReady(key)) bar.toggleSheet(key, screenName)
    else fallback()
  }

  BarSurface {
    id: surface
    anchors.fill: parent
    style: win.shown
    now: win.bar.now
    spaces: Hypr.spacesFor(win.screen ? win.screen.name : "")
    activeWindow: Hypr.activeWindow
    home: Hypr.home
    media: Media.now
    timeFormat: win.bar.timeFormat
    volume: Status.volume
    network: Status.network
    battery: Status.battery
    brightness: Status.brightness
    notifications: Status.notifications
    dnd: Status.doNotDisturb

    onSealClicked: function(button) {
      if (button === Qt.RightButton) Hypr.openTerminal()
      else Hypr.openMenu()
    }
    onWorkspaceActivated: function(id) { Hypr.focusWorkspace(id) }
    onWorkspaceStepped: function(delta) { Hypr.stepWorkspace(delta) }
    onMediaAction: function(name) { Media.act(name) }
    onStatusAction: function(name, how) { win.cellClicked(name, how, function() { Status.act(name, how) }) }
    onInboxAction: function(how) { win.cellClicked("notif", how, function() { Status.act("notif", how) }) }
    onClockClicked: win.cellClicked("clock", "click", function() {})
    // The rod unrolls the scroll; Phase 7 gives it somewhere to go.
    onEdgePulled: win.bar.edgePulled(win.screen ? win.screen.name : "")
  }

  SheetWindow {
    bar: win.bar
    barWindow: win
    surface: surface
  }
}
