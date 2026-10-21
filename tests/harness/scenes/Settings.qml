import QtQuick
import qs.Commons
import qs.Commons as Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../bar/settings"

// The settings window's page at its design size. render.py passes `params`:
//   { theme, now, ...bar data as in Strips.qml...,
//     settings: { saved, draft, kaze, desk, sumi, busy, page, part, trial, query, monitors, screens, monitor, lastChange, themes, theme, scrollEnd,
//                 width, height, keys } }
// settings.width/height size the window (logical px) instead of its design size.
// saved and draft are style.json documents.
Rectangle {
  id: sheet
  readonly property var p: JSON.parse(params)
  readonly property var s: p.settings || {}
  width: s.width || page.implicitWidth
  height: s.height || page.implicitHeight
  color: Ink.paper

  Component.onCompleted: {
    Commons.Color.foreground = p.theme.foreground
    Commons.Color.background = p.theme.background
    Commons.Color.urgent = p.theme.red
  }

  // settings.scrollEnd: show the foot of the page (Advanced), once laid out.
  Timer {
    interval: 100
    running: !!sheet.s.scrollEnd
    onTriggered: page.scrollToEnd()
  }

  // settings.keys: pressed in turn once laid out, to draw the cursor:
  // "down", "up", "left", "right".
  Timer {
    interval: 250
    running: (sheet.s.keys || []).length > 0
    onTriggered: {
      var moves = { left: [-1, 0], right: [1, 0], up: [0, -1], down: [0, 1] }
      for (var i = 0; i < sheet.s.keys.length; i++) {
        var m = moves[sheet.s.keys[i]]
        if (m) page.keyCursor.move(m[0], m[1])
      }
      page.keyCursor.place()
    }
  }

  SettingsPage {
    id: page
    anchors.fill: parent
    saved: S.normalize(sheet.s.saved || {})
    draft: S.normalize(sheet.s.draft || sheet.s.saved || {})
    page: sheet.s.page || "typesetting"
    part: sheet.s.part || "seal"
    trial: sheet.s.trial || null
    query: sheet.s.query || ""
    lastChange: sheet.s.lastChange || ""
    screens: sheet.s.screens || (sheet.s.monitors || []).map(function(n, i) { return { name: n, x: i * 1920, y: 0, width: i ? 2560 : 1920, height: i ? 1440 : 1080 } })
    overrideMonitor: sheet.s.monitor || ""
    presetView: sheet.s.preset || ""
    // Parts: what the window gets from Bar.own, Extras and the registry.
    visibility: sheet.s.visibility || ({
      own: { indicators: true, keyboard: false, mic: true, tray: true },
      indicators: [
        { key: "recording", glyph: "写", title: "Screen recording" }, { key: "dictation", glyph: "言", title: "Dictation" },
        { key: "reminder", glyph: "予", title: "Reminder" }, { key: "awake", glyph: "目", title: "Stay awake" },
        { key: "night", glyph: "月", title: "Night light" }, { key: "dnd", glyph: "休", title: "Do not disturb" }],
      tray: [{ id: "nm-applet", title: "Network Manager", letter: "N" }, { id: "1password", title: "1Password", letter: "1" }],
      hosted: [{ id: "omarchy.weather", name: "Weather", firstParty: true }, { id: "omarchy.agents", name: "Agents", firstParty: true }]
    })
    themes: sheet.s.themes || []
    theme: sheet.s.theme || ""
    monitors: sheet.s.monitors || []
    machine: Object.assign({ user: "", host: "", kernel: "", uptime: 0, theme: "", omarchy: "", hyprland: "", packages: 0, since: "", machine: "" }, sheet.s.machine || {})
    profile: Object.assign({ name: "", tagline: "", hidden: [] }, sheet.s.profile || {})
    version: "0.1.0"
    profileEditing: !!sheet.s.editing
    undoCount: sheet.s.undo || 0
    kaze: sheet.s.kaze || ({})
    kazeDesk: !!sheet.s.desk
    kazeSumi: !!sheet.s.sumi
    kazeBusy: sheet.s.busy || ""
    sheetFeed: Object.assign({ now: new Date(sheet.p.now || "2026-10-06T21:44:00") }, sheet.s.sheetFeed || {})
    barData: ({
      now: new Date(sheet.p.now || "2026-10-06T21:44:00"),
      spaces: sheet.p.spaces || [],
      activeWindow: sheet.p.window || null,
      home: "/home/ayush",
      media: sheet.p.media || null,
      volume: sheet.p.volume || null,
      network: sheet.p.network || null,
      bluetooth: sheet.p.bluetooth || null,
      battery: sheet.p.battery || null,
      brightness: sheet.p.brightness || null,
      notifications: sheet.p.notifications || [],
      dnd: !!sheet.p.dnd
    })
  }
}
