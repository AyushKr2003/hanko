pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../core/Sheets.js" as Sheets
import "../core/Inkan.js" as Inkan
import "../core/Spaces.js" as SpacesJs
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
  // The bar drawn on this screen (BarSurface), for anchorFor().
  required property var surface

  readonly property string screenName: screen ? screen.name : ""
  readonly property bool open: bar.sheet !== "" && bar.sheetScreen === screenName
  // Inkan 印 (form: inkan): no strip; sheets print from the seal in its
  // corner (bar/SealWindow.qml), away from the edge it shares.
  readonly property bool inkan: barWindow.inkan
  readonly property var sealWin: barWindow.seal
  readonly property string corner: Inkan.cornerOf(barWindow.shown.inkanAt)
  readonly property bool sealTop: corner.indexOf("top") === 0
  readonly property int screenW: barWindow.screen ? barWindow.screen.width : width
  readonly property int screenH: barWindow.screen ? barWindow.screen.height : height
  readonly property var sealRect: Inkan.place(corner, screenW, screenH, sealWin.size, sealWin.margin)
  readonly property bool atBottom: inkan ? !sealTop : bar.position === "bottom"
  // The bar's strip on this screen: its height plus the inset gap.
  readonly property int strip: inkan ? 0 : barWindow.barHeight + barWindow.gap
  property bool primed: false
  // The sheet on show; kept through the un-print after it closes.
  property string shownSheet: ""
  // Where the open sheet sits: Sheets.place() in screen coordinates.
  property var placed: ({ x: 0, tearX: 0, tearWidth: 0 })
  // Shōji's skin, for a sheet in the Shōji hand.
  readonly property var skin: barWindow.skin || ({})
  readonly property var view: classicView
  readonly property var feed: ({
    now: win.bar.now,
    timeFormat: win.bar.timeFormat,
    zones: Zones.rows(win.bar.now, win.bar.timeFormat === "HH:mm"),
    timeShift: win.bar.timeShift,
    // Koyomi 暦: the almanac or the week, the picked day, the sky.
    calendar: Typeset.current.calendar,
    timePick: win.bar.timePick,
    sky: Sky.forecast,
    sound: Sound.reading,
    network: Net.reading,
    bluetooth: Blue.reading,
    power: Power.reading,
    display: Display.reading,
    letters: Status.notifications,
    dnd: Status.doNotDisturb,
    // No. 00's own (Inkan): a row per sheet, the pages, the window, the song.
    all: win.bar.sheet === "all" ? {
      glyph: barWindow.shown.sealGlyph,
      rows: Inkan.rows({ volume: Status.volume, network: Status.network, bluetooth: Blue.cell,
                         battery: Status.battery, brightness: Status.brightness,
                         notifications: Status.notifications, dnd: Status.doNotDisturb }),
      spaces: Hypr.spacesFor(win.screenName),
      window: Hypr.activeWindow,
      home: Hypr.home,
      media: Media.now
    } : ({})
  })
  function cycle(delta) { bar.cycleSheet(delta) }

  function place() {
    if (!open) return
    if (inkan) {
      var at = Inkan.sheetPlace(win.corner, win.screenW, win.screenH, win.sealRect, view.width, view.height,
                                Type.px(Inkan.SHEET_GAP), Sheets.SCREEN_MARGIN)
      placed = { x: at.x, y: at.y, tearX: 0, tearWidth: 0 }
      classicView.side = win.corner.indexOf("left") > 0 ? -1 : 1
      return
    }
    var info = Sheets.byKey(shownSheet)
    var a = null
    for (var i = 0; info && !a && i < info.anchors.length; i++) a = surface.anchorFor(info.anchors[i])
    var gap = barWindow.gap
    // Measured from the bar, which is always mapped: this window has no
    // width yet on the frame it maps, which pinned every sheet left.
    var screenW = barWindow.width + 2 * gap
    var cellX = a ? a.x + gap : screenW - gap - 200
    placed = Sheets.place(shownSheet, cellX, a ? a.width : 100, view.width, screenW)
    classicView.side = cellX + (a ? a.width : 100) / 2 < screenW / 2 ? -1 : 1
  }
  onWidthChanged: Qt.callLater(place)
  Connections {
    target: win.barWindow
    function onWidthChanged() { Qt.callLater(win.place) }
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

  // Everything but the bar strip (under Inkan, the seal) takes clicks, so
  // a click there reaches the bar, or lifts the sheet off the seal.
  mask: Region {
    x: 0
    y: 0
    width: win.width
    height: win.height
    Region {
      intersection: Intersection.Subtract
      x: win.inkan ? win.sealRect.x : 0
      y: win.inkan ? win.sealRect.y : win.atBottom ? win.height - win.strip : 0
      width: win.inkan ? win.sealRect.width : win.width
      height: win.inkan ? win.sealRect.height : win.strip
    }
  }

  // Under Inkan a sheet prints once the seal has pressed (the stamp's
  // 140 ms), and lifts off when it closes: rising 6 px away from the seal
  // as it fades (the sheath, 240 ms), instead of un-printing.
  property bool printed: false
  property real lift: 0
  Timer { id: printAfter; interval: Motion.ms(Motion.stamp); onTriggered: win.printed = win.open }
  NumberAnimation {
    id: lifting
    target: win
    property: "lift"
    from: 0
    to: 1
    duration: Motion.ms(Motion.noto)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.notoCurve
  }

  onOpenChanged: {
    primed = false
    if (open) {
      lifting.stop()
      lift = 0
      if (inkan && !printed) printAfter.restart()
      else printed = true
      shownSheet = bar.sheet
      Qt.callLater(place)
      prime.restart()
    } else {
      printAfter.stop()
      if (inkan && !Motion.still) lifting.restart()
      else printed = false
      closing.restart()
    }
  }
  Connections {
    target: win.bar
    function onSheetChanged() {
      if (!win.open) return
      win.shownSheet = win.bar.sheet
      Qt.callLater(win.place)
      Qt.callLater(win.view.focusContents)
    }
  }

  Timer {
    id: prime
    interval: 75
    onTriggered: {
      if (!win.open) return
      win.primed = true
      win.view.focusContents()
    }
  }

  // Long enough for the sheath (Motion.noto, 240 ms), un-print or lift-off.
  Timer {
    id: closing
    interval: Motion.noto
    onTriggered: win.printed = false
  }

  // A click anywhere off the sheet closes it.
  MouseArea {
    anchors.fill: parent
    enabled: win.open
    acceptedButtons: Qt.AllButtons
    onPressed: win.bar.closeSheet()
  }

  SheetView {
    id: classicView
    paperOpacity: win.barWindow.shown.panelOpacity > 0 ? win.barWindow.shown.panelOpacity / 100 : 1
    styles: win.barWindow.shown.sheetStyles || ({})
    skin: win.skin
    onWidthChanged: Qt.callLater(win.place)
    onHeightChanged: if (win.inkan) Qt.callLater(win.place)
    // A Shōji sheet hangs on its rail a little below the bar and slides
    // along it to the next cell; the other hands print flush and jump.
    readonly property int railGap: rail ? (win.skin.gap || 0) : 0
    x: win.placed.x
    Behavior on x {
      enabled: classicView.rail && !!win.skin.travels && win.open && !Motion.still
      NumberAnimation { duration: win.skin.open || 360; easing.type: Easing.BezierSpline; easing.bezierCurve: win.skin.openCurve || [0.16, 1, 0.3, 1, 1, 1] }
    }
    opacity: 1 - win.lift
    y: win.inkan ? win.placed.y + (win.atBottom ? -1 : 1) * Type.px(6) * win.lift : win.atBottom ? win.height - win.strip - height - railGap : win.strip + railGap
    sheet: win.shownSheet
    // Under Inkan: printed after the press, and still printed while it lifts.
    open: win.inkan ? win.printed : win.open
    atBottom: win.atBottom
    tearX: win.placed.tearX
    tearWidth: win.placed.tearWidth
    feed: win.feed

    onRequest: function(sheet, what, arg) { win.bar.sheetRequest(sheet, what, arg) }
    onCloseRequested: win.bar.closeSheet()
    onCycle: function(delta) { win.cycle(delta) }

    // Swallow clicks on the paper so they don't reach the closer behind.
    MouseArea {
      z: -1
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }
  }

  // A sheet opened from No. 00 carries the way back: a crumb on the side
  // away from the seal, and Backspace.
  Text {
    id: crumb
    readonly property bool shown: win.open && win.bar.sheetFrom === "all" && win.bar.sheet !== "all"
    visible: shown
    x: classicView.x
    y: win.atBottom ? classicView.y - height - Type.px(16) : classicView.y + classicView.height + Type.px(16)
    text: "‹ NO. 00"
    color: crumbHit.containsMouse ? Ink.ink : Ink.inkDim
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.weight: Type.labelWeight
    font.letterSpacing: Type.trackTag
    MouseArea {
      id: crumbHit
      anchors.fill: parent
      anchors.margins: -Type.px(6)
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: win.bar.backSheet()
    }
  }
  Shortcut {
    sequence: "Backspace"
    enabled: crumb.shown
    onActivated: win.bar.backSheet()
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
