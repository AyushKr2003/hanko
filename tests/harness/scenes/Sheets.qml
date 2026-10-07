import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../core/Sheets.js" as Sheets
import "../../../bar"
import "../../../bar/sheets"
import "../../../bar/scroll"

// Desks: a bar with one sheet open under the cell it drops from, as
// bar/SheetWindow.qml places it, or with the handscroll unrolled under it.
// render.py passes `params`:
//   { theme, width, now, title, ...bar data as in Strips.qml...,
//     desks: [ { label, doc, sheet, cell, feed, height, scroll, current } ] }
// `feed` is the sheet's plain data (SheetView.feed); `cell` overrides the
// bar cell the sheet hangs from. With `scroll: true` the desk shows the
// scroll at section `current` instead of a sheet.
Rectangle {
  id: sheet

  readonly property var p: JSON.parse(params)
  width: p.width || 1600
  height: column.implicitHeight + 72
  color: Ink.paper

  function pick(desk, key) {
    if (desk[key] !== undefined) return desk[key]
    return p[key] !== undefined ? p[key] : null
  }

  Component.onCompleted: {
    Color.foreground = p.theme.foreground
    Color.background = p.theme.background
    Color.urgent = p.theme.red
  }

  Column {
    id: column
    x: 40
    y: 36
    width: sheet.width - 80
    spacing: 22

    Text {
      text: sheet.p.title || ""
      visible: text !== ""
      color: Ink.ink
      font.family: Type.display
      font.pixelSize: 30
      font.variableAxes: { "opsz": 72, "wght": 400 }
    }

    Repeater {
      model: sheet.p.desks

      Column {
        id: deskColumn
        required property var modelData
        width: column.width
        spacing: 8

        Text {
          text: deskColumn.modelData.label
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: 10
          font.letterSpacing: 1.6
        }

        Rectangle {
          id: desk
          readonly property var style: S.resolve(deskColumn.modelData.doc || {})
          readonly property bool atBottom: style.position === "bottom"
          readonly property date now: new Date(deskColumn.modelData.now || sheet.p.now || "2026-10-06T21:44:00")
          readonly property string key: deskColumn.modelData.sheet || ""
          readonly property bool scroll: !!deskColumn.modelData.scroll
          readonly property string cell: deskColumn.modelData.cell || (scroll ? "" : Sheets.byKey(key).anchors[0])
          property var placed: ({ x: 0, tearX: 0, tearWidth: 0 })

          width: parent.width
          height: deskColumn.modelData.height || 620
          color: "transparent"
          border.color: Ink.lineSoft
          clip: true

          function place() {
            var a = bar.anchorFor(cell) || { x: bar.width - 200, width: 100 }
            placed = Sheets.place(key, a.x, a.width, view.width, bar.width)
          }
          Component.onCompleted: if (!scroll) Qt.callLater(place)

          BarSurface {
            id: bar
            x: 1
            y: desk.atBottom ? desk.height - height - 1 : 1
            width: parent.width - 2
            height: implicitHeight
            style: desk.style
            now: desk.now
            spaces: deskColumn.modelData.spaces || sheet.p.spaces || []
            activeWindow: sheet.pick(deskColumn.modelData, "window")
            home: "/home/ayush"
            media: sheet.pick(deskColumn.modelData, "media")
            timeFormat: deskColumn.modelData.timeFormat || "HH:mm"
            volume: sheet.pick(deskColumn.modelData, "volume")
            network: sheet.pick(deskColumn.modelData, "network")
            battery: sheet.pick(deskColumn.modelData, "battery")
            brightness: sheet.pick(deskColumn.modelData, "brightness")
            bluetooth: sheet.pick(deskColumn.modelData, "bluetooth")
            notifications: sheet.pick(deskColumn.modelData, "notifications") || []
            dnd: !!sheet.pick(deskColumn.modelData, "dnd")
          }

          ScrollView {
            visible: desk.scroll
            x: bar.x + Math.round(bar.width * 0.069)
            width: bar.width - 2 * Math.round(bar.width * 0.069)
            height: implicitHeight
            y: desk.atBottom ? bar.y - height : bar.y + bar.height
            atBottom: desk.atBottom
            divider: desk.style.interlude
            endleaf: desk.style.endleaf
            sides: desk.style.sides
            guides: desk.style.guides
            current: deskColumn.modelData.current || 0
            ink: deskColumn.modelData.ink !== undefined ? deskColumn.modelData.ink : 1
            reveal: deskColumn.modelData.reveal !== undefined ? deskColumn.modelData.reveal : 1
            feed: {
              var f = Object.assign({}, deskColumn.modelData.feed || {})
              f.now = desk.now
              if (!f.spaces) f.spaces = deskColumn.modelData.spaces || sheet.p.spaces || []
              return f
            }
          }

          SheetView {
            id: view
            visible: !desk.scroll
            x: bar.x + desk.placed.x
            y: desk.atBottom ? bar.y - height : bar.y + bar.height
            sheet: desk.scroll ? "" : desk.key
            atBottom: desk.atBottom
            tearX: desk.placed.tearX
            tearWidth: desk.placed.tearWidth
            animate: false
            feed: {
              var f = Object.assign({}, deskColumn.modelData.feed || {})
              f.now = desk.now
              return f
            }
          }
        }
      }
    }
  }
}
