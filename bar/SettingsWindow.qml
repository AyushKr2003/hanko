import QtQuick
import Quickshell
import "../core"
import "../services"
import "../core/Extras.js" as X
import "settings"

// Hanko's settings as an ordinary window (a Quickshell FloatingWindow, like
// Omarchy's own dev gallery), so it tiles, floats and takes the keyboard
// like any app. There is no Save: every change prints on the bar and is
// kept at once (Typeset.keep() after each draft edit), and Undo puts the
// last one back (Typeset.history, forgotten when the window closes).
//
// Keys: / searches, Ctrl+Z undoes, Esc clears the search, then closes;
// on Typesetting, Left/Right and 1-0 move through the proof's parts.
FloatingWindow {
  id: win

  required property var bar          // the Bar.qml root

  property string page: "typesetting"
  property string query: ""
  property bool advanced: false


  title: "Hanko settings"
  visible: bar.settingsOpen
  color: Ink.paper
  implicitWidth: Type.px(1600)
  implicitHeight: Type.px(900)
  // The page reflows down to a phone's width; tiled, Hyprland gives the
  // window whatever room it has anyway.
  minimumSize: Qt.size(Type.px(420), Type.px(360))

  // The Profile plate's machine facts, read while the window is open.
  Binding { target: Machine; property: "wanted"; value: win.visible }

  // Closed by the window manager (Super+W, the close button).
  onVisibleChanged: if (!visible && bar.settingsOpen) bar.closeSettings()

  Item {
    id: keys
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)) { Typeset.undo(); event.accepted = true }
      // Typesetting: Left/Right walk the proof's parts, 1-9 and 0 open one.
      else if (win.page === "typesetting" && (event.key === Qt.Key_Left || event.key === Qt.Key_Right) && !(event.modifiers & Qt.ControlModifier)) {
        settings.stepPart(event.key === Qt.Key_Right ? 1 : -1); event.accepted = true
      }
      else if (win.page === "typesetting" && event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !event.modifiers) {
        settings.pickPartAt(event.key === Qt.Key_0 ? 9 : event.key - Qt.Key_1); event.accepted = true
      }
      else if (event.key === Qt.Key_Slash) { win.page = "typesetting"; settings.focusSearch(); event.accepted = true }
      else if (event.key === Qt.Key_Escape) {
        if (win.query !== "") win.query = ""
        else win.bar.closeSettings()
        event.accepted = true
      }
    }

    SettingsPage {
      id: settings
      anchors.fill: parent
      draft: Typeset.live
      saved: Typeset.doc
      undoCount: Typeset.history.length
      page: win.page
      query: win.query
      advanced: win.advanced
      monitors: Quickshell.screens.map(function(s) { return s.name })
      machine: Machine.info
      profile: Dossier.doc
      version: win.bar.version
      picturesDir: (Quickshell.env("XDG_PICTURES_DIR") || Quickshell.env("HOME") + "/Pictures")
      // What the Widgets page lists besides Hanko's own parts.
      visibility: ({
        own: win.bar.own,
        indicators: X.INDICATORS,
        tray: Extras.tray,
        hosted: win.bar.hostedEntries
      })
      barData: ({
        now: win.bar.now,
        spaces: Hypr.spacesFor(win.bar.focusedScreen()),
        activeWindow: Hypr.activeWindow,
        home: Hypr.home,
        media: Media.now,
        timeFormat: win.bar.timeFormat,
        volume: Status.volume,
        network: Status.network,
        bluetooth: Blue.cell,
        battery: Status.battery,
        brightness: Status.brightness,
        notifications: Status.notifications,
        dnd: Status.doNotDisturb,
        indicators: Extras.indicators,
        // The galley lays your bar out as wide as the screen it is on.
        screenWidth: (function() {
          var name = win.bar.focusedScreen(), list = Quickshell.screens
          for (var i = 0; i < list.length; i++) if (list[i].name === name) return list[i].width
          return 0
        })()
      })

      sheetFeed: ({
        now: win.bar.now,
        timeFormat: win.bar.timeFormat,
        zones: Zones.rows(win.bar.now, win.bar.timeFormat === "HH:mm"),
        timeShift: win.bar.timeShift,
        sound: Sound.reading,
        network: Net.reading,
        bluetooth: Blue.reading,
        power: Power.reading,
        display: Display.reading,
        letters: Status.notifications,
        dnd: Status.doNotDisturb
      })
      onSettingPicked: function(key, value) {
        // "…" asks for a glyph of your own, under Advanced.
        if (key === "sealGlyph" && value === "…") { win.advanced = true; return }
        Typeset.draftSet(key, value)
        // A dragged slider is one step of Undo, not one per pixel.
        Typeset.keep(key === "panelOpacity" ? key : "")
      }
      onPresetPicked: function(name) { Typeset.draftPreset(name); Typeset.keep() }
      onResetToPreset: { Typeset.draftReset(); Typeset.keep() }
      onUndo: Typeset.undo()
      onPagePicked: function(key) { win.page = key }
      // A search shows Typesetting, unless you are searching Widgets or Presets.
      onQueryEdited: function(text) { win.query = text; if (text !== "" && win.page !== "widgets" && win.page !== "presets") win.page = "typesetting" }
      onAdvancedToggled: function(on) { win.advanced = on }
      onMonitorCleared: function(name) { Typeset.draftClearMonitor(name); Typeset.keep() }
      onMonitorPicked: function(monitor, key, value) { Typeset.draftMonitor(monitor, key, value); Typeset.keep() }
      onShuffle: { Typeset.draftShuffle(); Typeset.keep() }
      onShowAll: { Typeset.draftShowAll(); Typeset.keep() }
      onProfileTextEdited: function(field, value) { Dossier.setText(field, value) }
      onProfileBlockToggled: function(block) { Dossier.toggle(block) }
      onProfileReset: Dossier.reset()
    }
  }
}
