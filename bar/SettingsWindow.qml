import QtQuick
import Quickshell
import "../core"
import "../services"
import "settings"

// Hanko's settings as an ordinary window (a Quickshell FloatingWindow, like
// Omarchy's own dev gallery), so it tiles, floats and takes the keyboard
// like any app. It edits Typeset's draft: the bar shows every change at
// once, Save writes style.json, and closing the window without saving puts
// the saved style back.
//
// Keys: / searches, Ctrl+S saves, Esc clears the search, then closes.
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

  // Closed by the window manager (Super+W, the close button): like Cancel.
  onVisibleChanged: if (!visible && bar.settingsOpen) bar.closeSettings()

  Item {
    id: keys
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) { Typeset.save(); event.accepted = true }
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
      page: win.page
      query: win.query
      advanced: win.advanced
      monitors: Quickshell.screens.map(function(s) { return s.name })
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
        dnd: Status.doNotDisturb
      })

      onSettingPicked: function(key, value) {
        // "…" asks for a glyph of your own, under Advanced.
        if (key === "sealGlyph" && value === "…") { win.advanced = true; return }
        Typeset.draftSet(key, value)
      }
      onPresetPicked: function(name) { Typeset.draftPreset(name) }
      onResetToPreset: Typeset.draftReset()
      onRevert: Typeset.revert()
      onSave: Typeset.save()
      onPagePicked: function(key) { win.page = key }
      onQueryEdited: function(text) { win.query = text; if (text !== "") win.page = "typesetting" }
      onAdvancedToggled: function(on) { win.advanced = on }
      onMonitorCleared: function(name) { Typeset.draftClearMonitor(name) }
      onMonitorPicked: function(monitor, key, value) { Typeset.draftMonitor(monitor, key, value) }
      onShuffle: Typeset.draftShuffle()
    }
  }
}
