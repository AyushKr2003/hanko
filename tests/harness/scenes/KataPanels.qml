pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Kata.js" as K
import "../../../core/Skin.js" as Sk
import "../../../bar/sheets"

// Kata panels (K5): one row per panel, one column per style document, each
// panel hanging from a strip of bar line as SheetWindow hangs it.
//   { theme, width, now, title, feed, panels: ["time", ...], docs: [ { label, doc } ] }
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
    Motion.forceStill = true
  }

  Column {
    id: column
    x: 40; y: 36
    spacing: 22

    Text {
      text: sheet.p.title || ""
      color: Ink.ink
      font.family: Type.display; font.pixelSize: 30; font.weight: Font.Normal
      font.variableAxes: Type.axes(30, 360, 0)
    }

    Repeater {
      model: sheet.p.panels
      Row {
        id: row
        required property string modelData
        spacing: 24
        Repeater {
          model: sheet.p.docs
          Column {
            id: cell
            required property var modelData
            readonly property var kata: K.resolve(modelData.doc || {})
            readonly property var skin: Sk.skin(kata, (modelData.doc || {}).panelOpacity || 0)
            spacing: 8
            Text {
              text: (cell.modelData.label || K.describe(cell.kata)) + " · " + row.modelData
              color: Ink.ink3
              font.family: Type.text; font.pixelSize: 13
            }
            Rectangle {
              width: panel.width + 48
              height: panel.height + 70
              color: Ink.sunk
              border.color: Ink.kLine
              clip: true
              Repeater {
                model: 7
                Rectangle {
                  required property int index
                  x: index * parent.width / 7; y: 0; width: parent.width / 14; height: parent.height
                  color: Ink.alpha(Ink.ink, 0.04)
                }
              }
              // the bar's line the panel hangs from
              Rectangle { width: parent.width; height: 14; color: Ink.paper }
              Rectangle { y: 14; width: parent.width; height: 1; color: Ink.kLine }
              ShojiPanel {
                id: panel
                x: 24
                y: 15 + (cell.skin.gap || 0)
                skin: cell.skin
                sheet: row.modelData
                open: true
                side: 1
                feed: {
                  var f = JSON.parse(JSON.stringify(sheet.p.feed))
                  f.now = new Date(sheet.p.now || "2026-10-08T21:44:00")
                  return f
                }
              }
            }
          }
        }
      }
    }
  }
}
