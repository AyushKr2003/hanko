import QtQuick
import qs.Commons
import qs.Commons as Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../core/Sheets.js" as Sheets
import "../../../core/Skin.js" as Sk
import "../../../bar"
import "../../../bar/sheets"

// Desks: a bar with one sheet open under the cell it drops from, as
// bar/SheetWindow.qml places it. render.py passes `params`:
//   { theme, width, now, title, ...bar data as in Strips.qml...,
//     desks: [ { label, doc, sheet, cell, feed, height, keys } ] }
// `feed` is the sheet's plain data (SheetView.feed); `cell` overrides the
// bar cell the sheet hangs from; `keys` are pressed in turn once it is laid
// out, to draw the cursor (core/Cursor.js): "down", "up", "left", "right",
// "enter", "+" or "-"; `open` is an inbox letter opened (its stem).
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
    Commons.Color.foreground = p.theme.foreground
    Commons.Color.background = p.theme.background
    Commons.Color.urgent = p.theme.red
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
          readonly property string cell: deskColumn.modelData.cell || Sheets.byKey(key).anchors[0]
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
          Component.onCompleted: Qt.callLater(place)

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

          SheetView {
            id: view
            paperOpacity: desk.style.panelOpacity > 0 ? desk.style.panelOpacity / 100 : 1
            styles: desk.style.sheetStyles || ({})
            // As SheetWindow: Shōji's skin, and a Shōji sheet hangs on its rail.
            skin: Sk.fromStyle(desk.style)
            x: bar.x + desk.placed.x
            y: desk.atBottom ? bar.y - height - (rail ? skin.gap : 0) : bar.y + bar.height + (rail ? skin.gap : 0)
            sheet: desk.key
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
          // An inbox letter opened to read in full ("open": its stem), once
          // the sheet is set (a new sheet folds any open letter).
          Timer {
            interval: 60
            running: !!deskColumn.modelData.open
            onTriggered: view.openLetter = deskColumn.modelData.open
          }
          Timer {
            interval: 120
            running: (deskColumn.modelData.keys || []).length > 0
            onTriggered: {
              var moves = { down: [0, 1], up: [0, -1], left: [-1, 0], right: [1, 0] }
              var keys = deskColumn.modelData.keys
              for (var i = 0; i < keys.length; i++) {
                var k = keys[i]
                if (moves[k]) view.keyMove(moves[k][0], moves[k][1])
                else if (k === "enter") view.keyActivate()
                else if (k === "+" || k === "-") view.stepLevel(k === "+" ? 1 : -1)
              }
              view.placeCursor()
            }
          }
        }
      }
    }
  }
}
