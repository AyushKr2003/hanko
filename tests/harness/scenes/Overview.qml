import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../core/Overview.js" as O
import "../../../bar"
import "../../../bar/settings"
import "../../../bar/overview"

// The workspace overview over a desk with the bar on top. render.py passes
// `params`: { theme, now, spaces (Hypr.spacesFor() rows with `all`),
//   overview: { layout, active, selected, aspect, screen, width, height, rows, columns, fold } }
Rectangle {
  id: sheet
  readonly property var p: JSON.parse(params)
  readonly property var o: p.overview || {}
  readonly property Item bar: classicBar
  width: o.width || 1600
  height: o.height || 900
  color: Ink.paper

  Component.onCompleted: {
    Color.foreground = p.theme.foreground
    Color.background = p.theme.background
    Color.urgent = p.theme.red
  }

  // The desk under it: the sample plate.
  Plate { anchors.fill: parent; cxw: 0.7; cyh: 0.62; rh: 0.5 }

  BarSurface {
    id: classicBar
    width: parent.width
    height: implicitHeight
    style: S.resolve({ preset: "Kamon" })
    now: new Date(sheet.p.now || "2026-10-07T21:44:00")
    spaces: sheet.p.spaces.filter(function(s) { return s.id <= 5 || s.count > 0 }).map(function(s) {
      return Object.assign({}, s, { active: s.id === sheet.o.active })
    })
    activeWindow: sheet.p.window || null
    volume: sheet.p.volume || null
    network: sheet.p.network || null
    battery: sheet.p.battery || null
    notifications: sheet.p.notifications || []
  }

  // overview.layout: dynamic draws Ryoku's instead.
  DynamicView {
    visible: sheet.o.layout === "dynamic"
    anchors.fill: parent
    topInset: sheet.bar.height
    spaces: sheet.p.spaces
    allIds: sheet.p.spaces.map(function(s) { return s.id })
    activeId: sheet.o.active || 1
    aspect: sheet.o.aspect || 0.5625
    animateIn: false
    Component.onCompleted: { seed(); if (sheet.o.selected !== undefined) selected = sheet.o.selected }
  }

  OverviewView {
    visible: sheet.o.layout !== "dynamic"
    anchors.fill: parent
    topInset: sheet.bar.height
    pages: O.pages(sheet.p.spaces, sheet.o.active || 1, sheet.o.rows || O.ROWS, sheet.o.columns || O.COLUMNS, sheet.o.fold !== false)
    columns: sheet.o.columns || O.COLUMNS
    aspect: sheet.o.aspect || 0.5625
    screenName: sheet.o.screen || "DP-1"
    now: new Date(sheet.p.now || "2026-10-07T21:44:00")
  }
}
