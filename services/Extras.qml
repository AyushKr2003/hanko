pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import "../core/Extras.js" as X

// What Hanko's own marks show (bar/Marks.qml): the indicators Omarchy's
// bar shows, the keyboard layout, the microphone and the tray, read the
// same way Omarchy's widgets read them, and only while the bar layout asks
// for them (Bar.qml sets the want* flags from core/Hosted.js own()).
Singleton {
  id: root

  property bool wantIndicators: false
  property bool wantKeyboard: false
  property bool wantMic: false
  property bool wantTray: false

  // Omarchy's idle and night light services (Bar.qml, from the host).
  property var idleProxy: null
  property var nightProxy: null

  // ---------------------------------------------------------- indicators
  property bool recording: false
  property string dictation: "idle"
  property int reminders: 0
  // Do not disturb, the bar's own reading (Bar.qml, from Status).
  property bool dnd: false
  readonly property var indicatorState: ({
    recording: recording, dictation: dictation, reminders: reminders,
    awake: !!(idleProxy && idleProxy.stayAwake), night: !!(nightProxy && nightProxy.enabled), dnd: dnd
  })
  // Every indicator, those that are off marked so (the bar shows them as
  // faint outlines to switch on).
  readonly property var indicators: wantIndicators ? X.indicators(indicatorState, true) : []

  property Timer _recordingPoll: Timer {
    interval: 2000
    repeat: true
    running: root.wantIndicators
    triggeredOnStart: true
    onTriggered: if (!root._recordingProc.running) root._recordingProc.running = true
  }
  property Process _recordingProc: Process {
    command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]
    onExited: function(code) { root.recording = code === 0 }
  }
  // Voxtype streams one status line per change while it runs.
  property Process _dictationProc: Process {
    running: root.wantIndicators
    command: ["bash", "-c", "command -v omarchy-voxtype-status >/dev/null && exec omarchy-voxtype-status"]
    stdout: SplitParser {
      onRead: function(line) {
        var d = X.moduleJson(line)
        root.dictation = String(d.alt || d.class || "idle")
      }
    }
  }
  property Timer _reminderPoll: Timer {
    interval: 60000
    repeat: true
    running: root.wantIndicators
    triggeredOnStart: true
    onTriggered: if (!root._reminderProc.running) root._reminderProc.running = true
  }
  property Process _reminderProc: Process {
    command: ["bash", "-c", "command -v omarchy-reminder >/dev/null && omarchy-reminder show --json"]
    stdout: StdioCollector {
      onStreamFinished: root.reminders = Number(X.moduleJson(text).count || 0)
    }
  }

  // A click switches the indicator, as on Omarchy's bar: a recording
  // stops (or the capture menu opens to start one), a reminder lists or
  // asks for one, the rest toggle.
  function indicatorAction(key, how) {
    if (key === "recording") Quickshell.execDetached(recording ? ["omarchy-capture-screenrecording", "--stop-recording"]
                                                               : ["omarchy-menu", "toggle", "trigger.capture.screenrecord"])
    else if (key === "dictation") Quickshell.execDetached(["omarchy-voxtype-config"])
    else if (key === "reminder") Quickshell.execDetached(reminders > 0 && how !== "right" ? ["omarchy-reminder", "show"] : ["omarchy-reminder", "-i"])
    else if (key === "awake") {
      if (idleProxy) idleProxy.setIdleEnabled(!!idleProxy.stayAwake)
      else Quickshell.execDetached(["omarchy-toggle-idle"])
    }
    else if (key === "night" && nightProxy) nightProxy.setNightlight(!nightProxy.enabled)
    else if (key === "dnd") Status.act("notif", "right")
    _reminderPoll.restart()
    _recordingPoll.restart()
  }

  // ---------------------------------------------------------- keyboard
  property var keyboard: null
  property Process _keyboardProc: Process {
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector { onStreamFinished: root.keyboard = X.keyboard(text) }
  }
  function readKeyboard() { if (wantKeyboard && !_keyboardProc.running) _keyboardProc.running = true }
  onWantKeyboardChanged: readKeyboard()
  property Connections _layoutEvents: Connections {
    target: Hyprland
    function onRawEvent(event) { if (event.name === "activelayout") root.readKeyboard() }
  }
  function keyboardAction(how) {
    Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", how === "right" ? "prev" : "next"])
  }

  // ---------------------------------------------------------- microphone
  readonly property var source: wantMic ? Pipewire.defaultAudioSource : null
  property PwObjectTracker _micTracker: PwObjectTracker { objects: root.source ? [root.source] : [] }
  readonly property var mic: source && source.audio
    ? { muted: !!source.audio.muted, percent: Math.round((source.audio.volume || 0) * 100) } : null
  function micAction(how) {
    if (how === "up" || how === "down") {
      if (source && source.audio) source.audio.volume = Math.max(0, Math.min(1, source.audio.volume + (how === "up" ? 0.05 : -0.05)))
    } else {
      Quickshell.execDetached(["omarchy-audio-input-mute"])
    }
  }

  // ---------------------------------------------------------- tray
  readonly property var trayItems: wantTray && SystemTray.items ? SystemTray.items.values : []
  readonly property var tray: X.tray(trayItems)
  // Ayatana items (Steam): no Activate, so a click opens the menu. Read
  // again each time the tray changes (core/Extras.js menuOnlyIds).
  property var menuOnly: []
  onTrayItemsChanged: if (wantTray) _menuOnlyRead.restart()
  property Timer _menuOnlyRead: Timer {
    interval: 300
    onTriggered: if (root._menuOnlyProc.running) restart(); else root._menuOnlyProc.running = true
  }
  property Process _menuOnlyProc: Process {
    command: ["busctl", "--user", "get-property", "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
              "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems"]
    stdout: StdioCollector { onStreamFinished: root.menuOnly = X.menuOnlyIds(text) }
  }
  // showMenu(item, cell) draws an item's menu in Hanko (bar/TrayMenuWindow):
  // item.display() asks for a platform menu, which Quickshell only draws in
  // QApplication mode and omarchy-shell doesn't start in, so it did nothing.
  // display() stays for an item that has no DBus menu to read.
  function trayAction(id, how, cell, showMenu) {
    var item = null
    for (var i = 0; i < trayItems.length; i++) if (String(trayItems[i].id || i) === id) { item = trayItems[i]; break }
    if (!item) return
    if (how === "up" || how === "down") { item.scroll(how === "up" ? 120 : -120, false); return }
    if (how === "middle") { item.secondaryActivate(); return }
    if (how === "right" || item.onlyMenu || menuOnly.indexOf(X.pathId(item.id)) >= 0) {
      if (item.hasMenu && item.menu && showMenu) { showMenu(item, cell); return }
      var win = cell && cell.QsWindow ? cell.QsWindow.window : null
      if (!win) return
      var p = cell.mapToItem(win.contentItem, 0, cell.height)
      item.display(win, Math.round(p.x), Math.round(p.y))
      return
    }
    item.activate()
  }
}
