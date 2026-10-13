pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../core/Inkan.js" as Inkan
import "../../../bar"

// Inkan 印 (form: inkan; docs/shell-concepts/inkan): the seal's states in a
// grid, then desks with the seal at its real size in a corner and, when a
// desk says `hover`, its reading beside it. render.py passes `params`:
//   { theme, width, now, title, states: [ { label, doc, data, size } ],
//     desks: [ { label, doc, data, hover, pressed, height } ] }
// `data` is what bar/SealWindow.qml feeds: { battery, network, volume,
// notifications, dnd, workspace } in the services' shapes.
Rectangle {
  id: sheet

  readonly property var p: JSON.parse(params)
  readonly property date now: new Date(p.now || "2026-10-06T21:44:00")
  width: p.width || 1600
  height: column.implicitHeight + 72
  color: Ink.paper

  Component.onCompleted: {
    Color.foreground = p.theme.foreground
    Color.background = p.theme.background
    Color.urgent = p.theme.red
    Motion.forceStill = true
  }

  function carvingOf(item) {
    return Inkan.carving(S.resolve(item.doc || {}), item.data || {})
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

    Grid {
      id: grid
      visible: (sheet.p.states || []).length > 0
      columns: 6
      width: parent.width
      readonly property real cellW: width / columns

      Repeater {
        model: sheet.p.states || []

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
            carving: sheet.carvingOf(tile.modelData)
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
      model: sheet.p.desks || []

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
            carving: sheet.carvingOf(deskColumn.modelData)
            hovered: !!deskColumn.modelData.hover
            pressed: !!deskColumn.modelData.pressed
            bloom: deskColumn.modelData.pressed ? 1 : 0
          }

          InkanReading {
            visible: !!deskColumn.modelData.hover
            parts: Inkan.reading(deskColumn.modelData.data || {}, Qt.formatTime(sheet.now, "HH:mm"))
            y: seal.y + (seal.height - height) / 2
            x: desk.corner.indexOf("left") >= 0 ? seal.x + seal.width + Type.px(14) : seal.x - Type.px(14) - width
          }
        }
      }
    }
  }
}
