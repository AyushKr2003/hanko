pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Commons as Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../core/Inkan.js" as Inkan
import "../../../core/Sheets.js" as Sheets
import "../../../core/Spaces.js" as SpacesJs
import "../../../bar"
import "../../../bar/sheets"

// Inkan 印 (form: inkan; docs/shell-concepts/inkan): the seal's states in a
// grid, then desks with the seal at its real size in a corner and, when a
// desk says `hover`, its reading beside it. render.py passes `params`:
//   { theme, width, now, title, states: [ { label, doc, data, size } ],
//     desks: [ { label, doc, data, hover, pressed, height, sheet, from, feed } ] }
// `data` is what bar/SealWindow.qml feeds: { battery, network, volume,
// notifications, dnd, workspace, bluetooth, brightness } in the services'
// shapes. A desk with `sheet` prints it from the seal as SheetWindow does:
// "all" is No. 00 (its spaces, window and media from the params' `spaces`,
// `window` and `media`); any other with `from: "all"` shows the crumb back.
Rectangle {
  id: page

  readonly property var p: JSON.parse(params)
  readonly property date now: new Date(p.now || "2026-10-06T21:44:00")
  width: p.width || 1600
  height: column.implicitHeight + 72
  color: Ink.paper

  Component.onCompleted: {
    Commons.Color.foreground = p.theme.foreground
    Commons.Color.background = p.theme.background
    Commons.Color.urgent = p.theme.red
    Motion.forceStill = true
  }

  function carvingOf(item) {
    return Inkan.carving(S.resolve(item.doc || {}), item.data || {})
  }

  Column {
    id: column
    x: 40
    y: 36
    width: page.width - 80
    spacing: 22

    Text {
      text: page.p.title || ""
      visible: text !== ""
      color: Ink.ink
      font.family: Type.display
      font.pixelSize: 30
      font.variableAxes: { "opsz": 72, "wght": 400 }
    }

    Grid {
      id: grid
      visible: (page.p.states || []).length > 0
      columns: 6
      width: parent.width
      readonly property real cellW: width / columns

      Repeater {
        model: page.p.states || []

        Rectangle {
          id: tile
          required property var modelData
          width: grid.cellW
          height: 150
          color: "transparent"
          border.color: Ink.lineSoft

          InkanSeal {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 26
            size: tile.modelData.size || 72
            carving: page.carvingOf(tile.modelData)
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 116
            text: String(tile.modelData.label).toUpperCase()
            color: Ink.ink
            font.family: Type.mono
            font.pixelSize: 10
            font.letterSpacing: 1.8
          }
        }
      }
    }

    Repeater {
      model: page.p.desks || []

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
          readonly property string corner: style.inkanAt
          readonly property var spot: Inkan.place(corner, width, height, seal.size, Type.px(Inkan.MARGIN))
          width: deskColumn.modelData.width || parent.width
          height: deskColumn.modelData.height || 150
          color: "transparent"
          border.color: Ink.lineSoft
          clip: true

          InkanSeal {
            id: seal
            x: desk.spot.x
            y: desk.spot.y
            carving: page.carvingOf(deskColumn.modelData)
            hovered: !!deskColumn.modelData.hover
            pressed: !!deskColumn.modelData.pressed
            bloom: deskColumn.modelData.pressed ? 1 : 0
          }

          // A sheet printed from the seal, placed as SheetWindow places it.
          property var at: ({ x: 0, y: 0 })
          function placeSheet() {
            at = Inkan.sheetPlace(corner, width, height, Inkan.place(corner, width, height, seal.size, Type.px(Inkan.MARGIN)),
                                  view.width, view.height, Type.px(Inkan.SHEET_GAP), Sheets.SCREEN_MARGIN)
          }
          SheetView {
            id: view
            readonly property var d: deskColumn.modelData.data || {}
            visible: !!deskColumn.modelData.sheet
            x: desk.at.x
            y: desk.at.y
            sheet: deskColumn.modelData.sheet || ""
            atBottom: desk.corner.indexOf("bottom") === 0
            animate: false
            styles: desk.style.sheetStyles || ({})
            onHeightChanged: Qt.callLater(desk.placeSheet)
            onWidthChanged: Qt.callLater(desk.placeSheet)
            feed: {
              var f = Object.assign({}, deskColumn.modelData.feed || {})
              f.now = page.now
              f.timeFormat = "HH:mm"
              f.letters = view.d.notifications || []
              f.dnd = !!view.d.dnd
              f.all = {
                glyph: desk.style.sealGlyph,
                rows: Inkan.rows(view.d),
                spaces: SpacesJs.list(page.p.spaces || [], view.d.workspace || 1, 4),
                window: page.p.window || null,
                home: "/home/ayush",
                media: page.p.media || null
              }
              return f
            }
          }
          Text {
            visible: deskColumn.modelData.from === "all"
            x: view.x
            y: view.atBottom ? view.y - height - Type.px(16) : view.y + view.height + Type.px(16)
            text: "‹ NO. 00"
            color: Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.tag
            font.weight: Type.labelWeight
            font.letterSpacing: Type.trackTag
          }

          InkanReading {
            visible: !!deskColumn.modelData.hover
            parts: Inkan.reading(deskColumn.modelData.data || {}, Qt.formatTime(page.now, "HH:mm"))
            y: seal.y + (seal.height - height) / 2
            x: desk.corner.indexOf("left") >= 0 ? seal.x + seal.width + Type.px(14) : seal.x - Type.px(14) - width
          }
        }
      }
    }
  }
}
