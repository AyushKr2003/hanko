import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../core/Sheets.js" as Sheets
import "../core/Scroll.js" as Scroll
import "../core/Skin.js" as Skin
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
  // Float inset floats 8 px off the screen's edges. Hyprland adds the margin on
  // the anchored edge to the exclusive zone, so windows stay 8 px clear of
  // the frame too.
  readonly property int gap: shown.float === "inset" ? 8 : 0

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
  // Shōji's skin (core/Skin.js) for this screen's style: the Shōji sheet
  // hand and the framed overview wear it, as the bar's Shōji values do.
  readonly property var skin: Skin.fromStyle(shown)
  readonly property Item surface: classicSurface

  Component.onCompleted: bar.registerWindow(screenName, win)
  Component.onDestruction: bar.unregisterWindow(screenName, win)

  // panels: scroll unrolls the handscroll; panels: sheets drops sheets.
  readonly property bool scrolls: shown.panels === "scroll"

  // A click on a cell with a panel opens (or closes) it at that cell's
  // sheet or section; anything else goes to the service as before.
  function cellClicked(cell, how, fallback) {
    if (how !== "click") { fallback(); return }
    if (scrolls && Scroll.forCell(cell)) bar.toggleScroll(Scroll.forCell(cell), screenName)
    else if (bar.sheetReady(Sheets.forCell(cell))) bar.toggleSheet(Sheets.forCell(cell), screenName)
    else fallback()
  }

  // A pull on the rod: the scroll unrolls (at the section under the
  // pointer, else where it was); with sheets, the sheet of the cell under
  // the pointer drops, or Time.
  function rodPulled(x) {
    var cell = surface.cellAt(x)
    if (scrolls) bar.openScroll(Scroll.forCell(cell) || "", screenName)
    else bar.openSheet(Sheets.forCell(cell) || "time", screenName)
  }

  BarSurface {
    id: classicSurface
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
    bluetooth: Blue.cell
    notifications: Status.notifications
    dnd: Status.doNotDisturb
    hosted: win.bar.hostedEntries
    host: win.bar
    indicators: Extras.indicators
    keyboard: Extras.keyboard
    mic: Extras.mic
    tray: Extras.tray
    onIndicatorAction: function(key, how) { Extras.indicatorAction(key, how) }
    onKeyboardAction: function(how) { Extras.keyboardAction(how) }
    // Middle-click on the mic opens Sound, where the input is.
    onMicAction: function(how) { if (how === "middle") win.bar.openPanel("sound", win.screenName); else Extras.micAction(how) }
    onTrayAction: function(id, how, cell) { Extras.trayAction(id, how, cell) }

    onSealClicked: function(button) {
      if (button === Qt.RightButton) Hypr.openTerminal()
      else Hypr.openMenu()
    }
    onWorkspaceActivated: function(id) { Hypr.focusWorkspace(id) }
    onWorkspaceStepped: function(delta) { Hypr.stepWorkspace(delta) }
    onOverviewRequested: win.bar.toggleOverview()
    onMediaAction: function(name) { Media.act(name) }
    onStatusAction: function(name, how) { win.cellClicked(name, how, function() { Status.act(name, how) }) }
    onInboxAction: function(how) { win.cellClicked("notif", how, function() { Status.act("notif", how) }) }
    onClockClicked: win.cellClicked("clock", "click", function() {})
    // The rod unrolls the scroll, or drops the sheet under the pull.
    onEdgePulled: function(x) { win.rodPulled(x) }
  }

  ScrollWindow {
    bar: win.bar
    barWindow: win
  }

  OverviewWindow {
    bar: win.bar
    barWindow: win
  }

  SheetWindow {
    bar: win.bar
    barWindow: win
    surface: win.surface
  }
}
