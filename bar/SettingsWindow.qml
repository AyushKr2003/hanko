import QtQuick
import Quickshell
import "../core"
import "../services"
import "../core/Extras.js" as X
import "../core/Settings.js" as Settings
import "../core/Style.js" as S
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
  Binding { target: Kaze; property: "wanted"; value: win.visible }

  // Kaze's changes have their own history; on its page Undo walks back
  // whichever was made last.
  readonly property bool kazeLast: page === "kaze" && Kaze.history.length > 0
    && (!Typeset.history.length || Kaze.lastAt >= Typeset._lastAt)
  function undo() { if (kazeLast) Kaze.undo(); else Typeset.undo() }

  // Colour 色 lists Omarchy's themes: read them when the page opens.
  onPageChanged: if (page === "colour") Themes.loadThemes()

  // Closed by the window manager (Super+W, the close button).
  onVisibleChanged: {
    if (!visible) Kaze.forget()
    if (!visible && bar.settingsOpen) bar.closeSettings()
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true

    // Omarchy's panel keys (bar/parts/KeyCursor.qml): the arrows or h j k l
    // move one cursor over the rail and the page, Enter or Space press,
    // + and - set a level, Tab goes to the next page. Typesetting keeps
    // [ and ] for its parts and 1-0 to open one. A text field in use keeps
    // its letters; Up and Down leave it.
    Keys.onPressed: function(event) {
      var t = event.text
      var K = event.key
      var cursor = settings.keyCursor
      if (K === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)) win.undo()
      else if (win.page === "typesetting" && (t === "[" || t === "]")) settings.stepPart(t === "]" ? 1 : -1)
      else if (win.page === "typesetting" && K >= Qt.Key_0 && K <= Qt.Key_9 && !event.modifiers) {
        settings.pickPartAt(K === Qt.Key_0 ? 9 : K - Qt.Key_1)
      }
      else if (K === Qt.Key_Slash) { win.page = "typesetting"; settings.focusSearch() }
      else if (K === Qt.Key_Escape) {
        if (win.query !== "") win.query = ""
        else win.bar.closeSettings()
      }
      else if (K === Qt.Key_Tab || K === Qt.Key_Backtab) settings.stepPage(K === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1)
      else if (K === Qt.Key_Down || t === "j") { keys.forceActiveFocus(); cursor.move(0, 1) }
      else if (K === Qt.Key_Up || t === "k") { keys.forceActiveFocus(); cursor.move(0, -1) }
      else if (K === Qt.Key_Right || t === "l") cursor.move(1, 0)
      else if (K === Qt.Key_Left || t === "h") cursor.move(-1, 0)
      else if (K === Qt.Key_Return || K === Qt.Key_Enter || K === Qt.Key_Space) cursor.activate()
      else if (t === "+" || t === "=") cursor.step(1)
      else if (t === "-" || t === "_") cursor.step(-1)
      else return
      event.accepted = true
    }

    SettingsPage {
      id: settings
      anchors.fill: parent
      draft: Typeset.live
      saved: Typeset.doc
      undoCount: Typeset.history.length + (win.page === "kaze" ? Kaze.history.length : 0)
      page: win.page
      query: win.query
      themes: Themes.themes
      theme: Themes.theme
      onThemePicked: function(slug) { Themes.setTheme(slug) }
      onCopyText: function(text) { Quickshell.execDetached(["wl-copy", text]) }
      kaze: Kaze.doc
      kazeDesk: Kaze.desk
      kazeSumi: Kaze.sumi
      kazeTools: ({ cursor: Kaze.cursor, tools: Kaze.tools, theme: Kaze.theme, boot: Kaze.boot })
      kazeCursorSize: Kaze.cursorSize
      kazeBusy: Kaze.busy
      onKazePicked: function(key, value) { Kaze.set(key, value) }
      onDeskPicked: function(on) { Kaze.setDesk(on) }
      onSumiPicked: function(on) { Kaze.setSumi(on) }
      onToolPicked: function(key, on) { Kaze.setTool(key, on) }
      onWindSpeedPicked: function(speed) { Kaze.set("windSpeed", speed, "windSpeed") }
      onCursorSizePicked: function(size) { Kaze.setCursorSize(size) }
      lastChange: win.kazeLast ? Kaze.lastChange : Typeset.history.length ? Settings.describeChange(Typeset.history[Typeset.history.length - 1], Typeset.doc, S.resolve) : ""
      screens: Quickshell.screens.map(function(s) { return { name: s.name, x: s.x, y: s.y, width: s.width, height: s.height } })
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
        Typeset.draftSet(key, value)
        // A dragged slider is one step of Undo, not one per pixel.
        Typeset.keep(key === "panelOpacity" ? key : "")
      }
      onPresetPicked: function(name) { Typeset.draftPreset(name); Typeset.keep() }
      onResetToPreset: { Typeset.draftReset(); Typeset.keep() }
      onUndo: win.undo()
      onPagePicked: function(key) { win.page = key }
      // A search shows Typesetting, unless you are searching Widgets or Presets.
      onQueryEdited: function(text) { win.query = text; if (text !== "" && win.page !== "parts" && win.page !== "presets") win.page = "typesetting" }
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
