import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../bar/settings"

// The settings window's page at its design size. render.py passes `params`:
//   { theme, now, ...bar data as in Strips.qml...,
//     settings: { saved, draft, page, query, advanced, monitors, monitor, scrollEnd } }
// saved and draft are style.json documents.
Rectangle {
  id: sheet
  readonly property var p: JSON.parse(params)
  readonly property var s: p.settings || {}
  width: page.implicitWidth
  height: page.implicitHeight
  color: Ink.paper

  Component.onCompleted: {
    Color.foreground = p.theme.foreground
    Color.background = p.theme.background
    Color.urgent = p.theme.red
  }

  // settings.scrollEnd: show the foot of the page (Advanced), once laid out.
  Timer {
    interval: 100
    running: !!sheet.s.scrollEnd
    onTriggered: page.scrollToEnd()
  }

  SettingsPage {
    id: page
    anchors.fill: parent
    saved: S.normalize(sheet.s.saved || {})
    draft: S.normalize(sheet.s.draft || sheet.s.saved || {})
    page: sheet.s.page || "typesetting"
    query: sheet.s.query || ""
    advanced: !!sheet.s.advanced
    monitors: sheet.s.monitors || []
    machine: Object.assign({ user: "", host: "", kernel: "", uptime: 0, theme: "", omarchy: "", hyprland: "", packages: 0, since: "", machine: "" }, sheet.s.machine || {})
    profile: Object.assign({ name: "", tagline: "", hidden: [] }, sheet.s.profile || {})
    version: "0.1.0"
    profileEditing: !!sheet.s.editing
    overrideMonitor: sheet.s.monitor || ""
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
