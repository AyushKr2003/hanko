import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../core/Overview.js" as O
import "../../../core/Kata.js" as K
import "../../../core/Skin.js" as Sk
import "../../../bar"
import "../../../bar/settings"
import "../../../bar/overview"

// The workspace overview over a desk with the bar on top. render.py passes
// `params`: { theme, now, spaces (Hypr.spacesFor() rows with `all`),
//   overview: { layout, active, selected, aspect, screen, width, height, rows, columns, fold },
//   design: a Kata style doc ({ design: "shoji" }) to print the bar and pages in that design }
// overview.layout "framed" prints Shōji's framed pages under the Hanko bar.
Rectangle {
  id: sheet
  readonly property var p: JSON.parse(params)
  readonly property var o: p.overview || {}
  readonly property var kata: K.resolve(p.design || {})
  readonly property var skin: kata.classic && o.layout !== "framed" ? ({}) : Sk.skin(kata)
  readonly property Item bar: kata.classic ? classicBar : kataBar
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

  KataBar {
    id: kataBar
    visible: !sheet.kata.classic
    width: parent.width
    skin: sheet.skin
    style: S.resolve(sheet.p.design || {})
    now: new Date(sheet.p.now || "2026-10-07T21:44:00")
    spaces: classicBar.spaces
    activeWindow: sheet.p.window || null
    volume: sheet.p.volume || null
    network: sheet.p.network || null
    battery: sheet.p.battery || null
    notifications: sheet.p.notifications || []
  }

  BarSurface {
    id: classicBar
    visible: sheet.kata.classic
    width: parent.width
    height: implicitHeight
    style: S.resolve({ preset: "Hanko" })
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
    skin: sheet.skin
    pages: O.pages(sheet.p.spaces, sheet.o.active || 1, sheet.o.rows || O.ROWS, sheet.o.columns || O.COLUMNS, sheet.o.fold !== false)
    columns: sheet.o.columns || O.COLUMNS
    aspect: sheet.o.aspect || 0.5625
    screenName: sheet.o.screen || "DP-1"
    now: new Date(sheet.p.now || "2026-10-07T21:44:00")
  }
}
