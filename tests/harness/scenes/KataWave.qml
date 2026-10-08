pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import "../../../core"
import "../../../core/Kata.js" as K
import "../../../core/Skin.js" as Sk
import "../../../bar/parts"

// Kata's second wave (K6): the notify part (three letters, the second one
// part-way swiped or torn) and the hold part (part-way held), one column per
// style document, on that design's surface.
//   { theme, width, now, title, letters, docs: [ { label, doc } ] }
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

    Row {
      spacing: 28
      Repeater {
        model: sheet.p.docs
        Column {
          id: cell
          required property var modelData
          readonly property var kata: K.resolve(modelData.doc || {})
          readonly property var skin: Sk.skin(kata)
          spacing: 8
          Text {
            text: cell.modelData.label || K.describe(cell.kata)
            color: Ink.ink3
            font.family: Type.text; font.pixelSize: 13
          }
          Rectangle {
            width: 440; height: inner.implicitHeight + 64
            color: Ink.sunk
            border.color: Ink.kLine
            Surface { x: 16; y: 16; width: parent.width - 32; height: parent.height - 32; skin: cell.skin }
            Column {
              id: inner
              x: 36; y: 32
              width: parent.width - 72
              spacing: 10
              Repeater {
                model: sheet.p.letters
                Letter {
                  required property var modelData
                  required property int index
                  width: inner.width
                  skin: cell.skin
                  letter: modelData
                  now: new Date(sheet.p.now)
                  first: index === 0
                  pull: index === 1 ? (cell.skin.notify === "cards" ? 70 : cell.skin.notify === "tickets" ? 16 : 0) : 0
                }
              }
              Item { width: 1; height: 6 }
              Row {
                spacing: 8
                Hold { width: (inner.width - 24) / 4; skin: cell.skin; label: "Lock"; hold: false }
                Hold { width: (inner.width - 24) / 4; skin: cell.skin; label: "Sleep"; hold: false }
                Hold { width: (inner.width - 24) / 4; skin: cell.skin; label: "Restart"; progress: 0.6 }
                Hold { width: (inner.width - 24) / 4; skin: cell.skin; label: "Shut down" }
              }
            }
          }
        }
      }
    }
  }
}
