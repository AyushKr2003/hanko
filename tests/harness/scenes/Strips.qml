import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Style.js" as S
import "../../../bar"

// A sheet of labelled bars, one per strip. render.py passes `params`:
//   { theme: { foreground, background, red }, width, now, title,
//     strips: [ { label, doc } ] }   doc is a style.json document.
Rectangle {
  id: sheet

  readonly property var p: JSON.parse(params)
  width: p.width || 1600
  height: column.implicitHeight + 72
  color: Ink.paper

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
      model: sheet.p.strips

      Column {
        required property var modelData
        width: column.width
        spacing: 8

        Text {
          text: modelData.label
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: 10
          font.letterSpacing: 1.6
        }

        Rectangle {
          width: parent.width
          height: bar.height + 2
          color: "transparent"
          border.color: Ink.lineSoft

          BarSurface {
            id: bar
            x: 1; y: 1
            width: parent.width - 2
            height: implicitHeight
            style: S.resolve(modelData.doc || {})
            now: new Date(sheet.p.now || "2026-10-06T21:44:00")
            spaces: modelData.spaces || sheet.p.spaces || []
            activeWindow: modelData.window !== undefined ? modelData.window : (sheet.p.window || null)
            home: "/home/ayush"
            media: modelData.media !== undefined ? modelData.media : (sheet.p.media || null)
            timeFormat: modelData.timeFormat || "HH:mm"
          }
        }
      }
    }
  }
}
