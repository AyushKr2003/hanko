pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../core/Spaces.js" as Spaces
import "../core/Title.js" as Title

// Hyprland, reduced to the plain data the left zone draws and the few
// actions it takes. Window geometry only lives in each toplevel's
// lastIpcObject, which Quickshell refreshes on request, so the relevant
// Hyprland events trigger a refresh.
Singleton {
  id: root

  // Bumped after every refresh so bindings that read lastIpcObject re-run.
  property int revision: 0

  readonly property string home: Quickshell.env("HOME")

  // Raw workspaces with their windows, geometry normalized per monitor.
  readonly property var workspaces: {
    void root.revision
    var tops = Hyprland.toplevels.values
    var byWs = {}
    for (var i = 0; i < tops.length; i++) {
      var d = tops[i].lastIpcObject
      if (!d || !d.workspace) continue
      var id = d.workspace.id
      if (!byWs[id]) byWs[id] = []
      byWs[id].push({ at: d.at, size: d.size, floating: !!d.floating, focus: d.focusHistoryID === undefined ? 1e9 : d.focusHistoryID,
                      name: Title.appName(d.class || ""), address: d.address || "", title: d.title || "",
                      fullscreen: (d.fullscreen || 0) > 0 })
    }
    var out = []
    var wss = Hyprland.workspaces.values
    for (var j = 0; j < wss.length; j++) {
      var ws = wss[j]
      var wins = byWs[ws.id] || []
      // The workspace's most recently focused window is the filled one.
      var best = -1
      for (var k = 0; k < wins.length; k++)
        if (!wins[k].floating && (best < 0 || wins[k].focus < wins[best].focus)) best = k
      for (var m = 0; m < wins.length; m++) wins[m].focused = m === best
      var mon = ws.monitor ? ws.monitor.lastIpcObject : null
      out.push({
        id: ws.id,
        name: ws.name,
        urgent: !!ws.urgent,
        count: wins.length,
        windows: Spaces.layoutOf(wins, Spaces.usableArea(mon)),
        // Every window, floating ones too, for the overview.
        all: Spaces.layoutOf(wins, Spaces.usableArea(mon), true)
      })
    }
    return out
  }

  // Count floating windows too, so a workspace of only floats is occupied.
  function spacesFor(screenName) {
    var mon = monitorNamed(screenName)
    var active = mon && mon.activeWorkspace ? mon.activeWorkspace.id : (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)
    var list = Spaces.list(root.workspaces.map(function(w) {
      return { id: w.id, name: w.name, urgent: w.urgent, windows: w.windows, count: w.count, all: w.all }
    }), active)
    var counts = {}
    for (var i = 0; i < root.workspaces.length; i++) counts[root.workspaces[i].id] = root.workspaces[i].count
    for (var j = 0; j < list.length; j++) list[j].count = counts[list[j].id] || 0
    return list
  }

  function activeIdFor(screenName) {
    var mon = monitorNamed(screenName)
    return mon && mon.activeWorkspace ? mon.activeWorkspace.id : 1
  }

  function monitorNamed(name) {
    var ms = Hyprland.monitors.values
    for (var i = 0; i < ms.length; i++) if (ms[i].name === name) return ms[i]
    return Hyprland.focusedMonitor
  }

  // The focused window, or null on an empty workspace: Hyprland keeps
  // reporting the last window after you move to an empty one.
  readonly property var activeWindow: {
    void root.revision
    var t = Hyprland.activeToplevel
    var ws = Hyprland.focusedWorkspace
    if (!t || !ws || ws.toplevels.values.length === 0) return null
    var d = t.lastIpcObject || {}
    return { cls: d.class || (t.wayland ? t.wayland.appId : ""), title: t.title || d.title || "" }
  }

  // ---------------------------------------------------------- actions
  // Dispatchers are Lua source in current Hyprland, so values are quoted.
  function luaStr(s) {
    return '"' + String(s).replace(/[\\"\x00-\x1f\x7f]/g, function(c) {
      var n = String(c.charCodeAt(0))
      while (n.length < 3) n = "0" + n
      return "\\" + n
    }) + '"'
  }

  function focusWorkspace(id) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + luaStr(id) + " })") }
  function stepWorkspace(delta) { focusWorkspace(delta > 0 ? "r+1" : "r-1") }
  function focusWindow(address) {
    if (/^0x[0-9a-fA-F]+$/.test(String(address)))
      Hyprland.dispatch("hl.dsp.focus({ window = " + luaStr("address:" + address) + " })")
  }

  // Read windows and workspaces again now (the overview opening).
  function refresh() { refreshTimer.restart() }

  // The overview's actions. A window moves without following it.
  function moveWindow(address, workspace) {
    if (/^0x[0-9a-fA-F]+$/.test(String(address)) && Number(workspace) > 0)
      Hyprland.dispatch("hl.dsp.window.move({ window = " + luaStr("address:" + address) + ", workspace = " + luaStr(String(workspace)) + ", follow = false })")
  }
  function closeWindow(address) {
    if (/^0x[0-9a-fA-F]+$/.test(String(address)))
      Hyprland.dispatch("hl.dsp.window.close({ window = " + luaStr("address:" + address) + " })")
  }
  // The Wayland toplevel behind a Hyprland window, for the overview's live
  // snapshot (ScreencopyView). Matched through the HyprlandToplevel attached
  // to each of ToplevelManager's toplevels, as omarchy-overview does; null
  // when there is none.
  function toplevelFor(address) {
    var want = String(address || "").replace(/^0x/, "").toLowerCase()
    if (!want) return null
    var tops = ToplevelManager.toplevels.values
    for (var i = 0; i < tops.length; i++) {
      var h = tops[i].HyprlandToplevel
      if (h && String(h.address || "").replace(/^0x/, "").toLowerCase() === want) return tops[i]
    }
    return null
  }
  // The monitor's height / width, for the overview's pages.
  function aspectFor(screenName) {
    var m = monitorNamed(screenName)
    var d = m ? m.lastIpcObject : null
    var a = Spaces.usableArea(d)
    return a ? a.height / a.width : 0.5625
  }

  function openMenu() { Quickshell.execDetached(["omarchy-shell", "shell", "toggle", "omarchy.menu", "{\"menu\":\"root\"}"]) }
  function openTerminal() { Quickshell.execDetached(["xdg-terminal-exec"]) }

  // ---------------------------------------------------------- refresh
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var n = event.name
      if (n.endsWith("v2")) return
      if (["openwindow", "closewindow", "movewindow", "windowtitle", "changefloatingmode", "fullscreen", "activewindow", "urgent"].indexOf(n) >= 0)
        refreshTimer.restart()
      else if (["workspace", "focusedmon", "moveworkspace", "createworkspace", "destroyworkspace", "monitoradded", "monitorremoved"].indexOf(n) >= 0) {
        Hyprland.refreshMonitors()
        refreshTimer.restart()
      }
    }
  }

  // Window resizes send no event of their own; a slow tick keeps the
  // layout glyphs honest after a drag.
  Timer {
    id: refreshTimer
    interval: 60
    onTriggered: {
      Hyprland.refreshToplevels()
      Hyprland.refreshWorkspaces()
      root.revision++
      settleTimer.restart()
    }
  }
  // The refresh answers asynchronously; read again once it has landed.
  Timer {
    id: settleTimer
    interval: 150
    onTriggered: root.revision++
  }
  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: refreshTimer.restart()
  }

  Component.onCompleted: {
    Hyprland.refreshMonitors()
    refreshTimer.restart()
  }
}
