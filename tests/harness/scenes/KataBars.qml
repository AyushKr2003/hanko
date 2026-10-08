pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Kata.js" as K
import "../../../core/Skin.js" as Sk
import "../../../core/Style.js" as S
import "../../../bar"

// Kata bars (K4): one strip per style document, over a strip of desk so
// washi has something behind it. Data as in Strips.qml (sheet-level, a
// strip's own value wins); `hover` points at a cell.
Rectangle {
  id: sheet

  readonly property var p: JSON.parse(params)
  function pick(strip, key) {
    if (strip[key] !== undefined) return strip[key]
    return p[key] !== undefined ? p[key] : null
  }
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
    width: sheet.width - 80
    spacing: 22

    Text {
      text: sheet.p.title || ""
      color: Ink.ink
      font.family: Type.display; font.pixelSize: 30; font.weight: Font.Normal
      font.variableAxes: Type.axes(30, 360, 0)
    }

    Repeater {
      model: sheet.p.strips
      Column {
        id: strip
        required property var modelData
        readonly property var kata: K.resolve(modelData.doc || {})
        width: column.width
        spacing: 8
        Text {
          text: strip.modelData.label || K.describe(strip.kata)
          color: Ink.ink3
          font.family: Type.text; font.pixelSize: 13
        }
        Rectangle {
          width: parent.width
          height: bar.height + 30
          clip: true
          color: Ink.sunk
          border.color: Ink.kLine
          // a desk behind the bar: soft bands, so translucent paper shows something
          Repeater {
            model: 9
            Rectangle {
              required property int index
              x: index * parent.width / 9; y: 0; width: parent.width / 18; height: parent.height
              color: Ink.alpha(Ink.ink, 0.04)
            }
          }
          KataBar {
            id: bar
            x: 1; y: 1
            width: parent.width - 2
            skin: Sk.skin(strip.kata)
            style: S.resolve(strip.modelData.doc || {})
            now: new Date(strip.modelData.now || sheet.p.now || "2026-10-08T21:44:00")
            spaces: sheet.pick(strip.modelData, "spaces") || []
            activeWindow: sheet.pick(strip.modelData, "window")
            home: "/home/ayush"
            media: sheet.pick(strip.modelData, "media")
            volume: sheet.pick(strip.modelData, "volume")
            network: sheet.pick(strip.modelData, "network")
            battery: sheet.pick(strip.modelData, "battery")
            notifications: sheet.pick(strip.modelData, "notifications") || []
            dnd: !!sheet.pick(strip.modelData, "dnd")
            hoverCell: strip.modelData.hover || ""
          }
        }
      }
    }
  }
}
