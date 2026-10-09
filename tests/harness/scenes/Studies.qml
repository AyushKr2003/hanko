import QtQuick
import qs.Commons
import "../../../core"
import "../../../bar/sheets"
import "../studies"

// Sheet-hand studies: the same Sound sheet drawn in several candidate hands,
// side by side on paper, to choose one before building all seven sheets.
// params: { theme, width, title, sound, studies: [ { key, jp, name, line } ] }
Rectangle {
  id: sheet
  readonly property var p: JSON.parse(params)
  width: p.width || 2000
  height: column.implicitHeight + 80
  color: Ink.paper

  Component.onCompleted: {
    Color.foreground = p.theme.foreground
    Color.background = p.theme.background
    Color.urgent = p.theme.red
  }

  Column {
    id: column
    x: 40; y: 36
    spacing: 28
    Text { text: sheet.p.title || ""; color: Ink.ink; font.family: Type.display; font.pixelSize: 30; font.variableAxes: { "opsz": 72, "wght": 400 } }
    Flow {
      width: sheet.width - 80
      spacing: 36
      Repeater {
        model: sheet.p.studies
        Column {
          id: study
          required property var modelData
          width: 430
          spacing: 12
          Row {
            spacing: 10
            Text { text: study.modelData.jp; color: Ink.seal; font.family: Type.brush; font.pixelSize: 26 }
            Text { anchors.baseline: parent.children[0].baseline; text: study.modelData.name; color: Ink.ink; font.family: Type.display; font.pixelSize: 24 }
          }
          Text { width: parent.width; wrapMode: Text.Wrap; text: study.modelData.line; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: 12; lineHeight: 1.25 }
          Item { width: 1; height: 4 }
          SheetCard {
            width: 430
            Loader {
              width: 430
              sourceComponent: ({ shogi: shogi, soroban: soroban, odoshi: odoshi, kasumi: kasumi })[study.modelData.key]
            }
          }
        }
      }
    }
  }
  Component { id: shogi; ShogiSound { sound: sheet.p.sound } }
  Component { id: soroban; SorobanSound { sound: sheet.p.sound } }
  Component { id: odoshi; OdoshiSound { sound: sheet.p.sound } }
  Component { id: kasumi; KasumiSound { sound: sheet.p.sound } }
}
