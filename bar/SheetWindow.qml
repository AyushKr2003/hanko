pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../core/Sheets.js" as Sheets
import "../services"
import "sheets"

// The layer a sheet is printed on, one per screen, next to its BarWindow.
// Built the way Omarchy's own KeyboardPanel is: a full-screen layer-shell
// surface (so a click anywhere else closes the sheet) whose input mask
// leaves the bar strip to the bar, so clicking another cell switches
// sheets in one click. Keyboard focus is primed Exclusive for a moment,
// then OnDemand: Hyprland only hands an already-mapped OnDemand surface
// the keyboard when it is primed, and Exclusive would swallow clicks on
// other screens.
PanelWindow {
  id: win

  required property var bar          // the Bar.qml root
  required property var barWindow    // this screen's BarWindow
  required property BarSurface surface

  readonly property string screenName: screen ? screen.name : ""
  readonly property bool open: bar.sheet !== "" && bar.sheetScreen === screenName
  readonly property bool atBottom: bar.position === "bottom"
  // The bar's strip on this screen: its height plus the inset gap.
  readonly property int strip: barWindow.barHeight + barWindow.gap
  property bool primed: false
  // The sheet on show; kept through the un-print after it closes.
  property string shownSheet: ""
  // Where the open sheet sits: Sheets.place() in screen coordinates.
  property var placed: ({ x: 0, tearX: 0, tearWidth: 0 })

  function place() {
    if (!open) return
    var info = Sheets.byKey(shownSheet)
    var a = surface.anchorFor(info ? info.anchors[0] : "") || surface.anchorFor(info ? info.anchors[1] || "" : "")
    var gap = barWindow.gap
    var cellX = a ? a.x + gap : width - gap - 200
    placed = Sheets.place(shownSheet, cellX, a ? a.width : 100, view.width, width)
  }

  screen: barWindow.screen
  // Stays mapped while the sheet un-prints, then unmaps.
  visible: open || closing.running
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "hanko-sheet"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: win.open ? (win.primed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // Everything but the bar strip takes clicks.
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

  onOpenChanged: {
    primed = false
    if (open) {
      closing.stop()
      shownSheet = bar.sheet
      Qt.callLater(place)
      prime.restart()
    } else {
      closing.restart()
    }
  }
  Connections {
    target: win.bar
    function onSheetChanged() {
      if (!win.open) return
      win.shownSheet = win.bar.sheet
      Qt.callLater(win.place)
      Qt.callLater(view.focusContents)
    }
  }

  Timer {
    id: prime
    interval: 75
    onTriggered: {
      if (!win.open) return
      win.primed = true
      view.focusContents()
    }
  }

  // Long enough for the 180 ms un-print.
  Timer {
    id: closing
    interval: 220
  }

  // A click anywhere off the sheet closes it.
  MouseArea {
    anchors.fill: parent
    enabled: win.open
    acceptedButtons: Qt.AllButtons
    onPressed: win.bar.closeSheet()
  }

  SheetView {
    id: view
    x: win.placed.x
    y: win.atBottom ? win.height - win.strip - height : win.strip
    sheet: win.shownSheet
    open: win.open
    atBottom: win.atBottom
    tearX: win.placed.tearX
    tearWidth: win.placed.tearWidth
    feed: ({
      now: win.bar.now,
      zones: Zones.rows(win.bar.now, win.bar.timeFormat === "HH:mm"),
      timeShift: win.bar.timeShift,
      sound: Sound.reading,
      network: Net.reading,
      power: Power.reading,
      letters: Status.notifications,
      dnd: Status.doNotDisturb
    })

    onRequest: function(sheet, what, arg) { win.bar.sheetRequest(sheet, what, arg) }
    onCloseRequested: win.bar.closeSheet()
    onCycle: function(delta) { win.bar.cycleSheet(delta) }

    // Swallow clicks on the paper so they don't reach the closer behind.
    MouseArea {
      z: -1
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }
  }

  // Other screens get a clear twin while the sheet is open, so a click on
  // any monitor closes it (pointer input is hit-tested per output).
  Variants {
    model: win.open ? Quickshell.screens : []

    delegate: Component {
      PanelWindow {
        id: twin
        required property var modelData
        screen: twin.modelData
        visible: twin.modelData.name !== win.screenName
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "hanko-sheet-dismiss"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onPressed: win.bar.closeSheet()
        }
      }
    }
  }
}
