import QtQuick
import "../core"

// The seal 印: a stamped square in the theme's red, the one block of colour
// on the bar. `stamp` shows a fixed glyph; `workspace` shows the active
// workspace as a kanji numeral; `none` hides it.
Item {
  id: root

  property string mode: "stamp"
  property string glyph: "鑑"
  property int workspace: 1
  property int size: Type.px(26)

  readonly property var numerals: ["〇", "壱", "弐", "参", "肆", "伍", "陸", "漆", "捌", "玖"]
  readonly property string shown: mode === "workspace"
    ? (workspace >= 0 && workspace < numerals.length ? numerals[workspace] : String(workspace))
    : glyph

  visible: mode !== "none"
  implicitWidth: visible ? size : 0
  implicitHeight: size

  Rectangle {
    id: plate
    anchors.fill: parent
    radius: Math.max(2, Math.round(root.size * 0.11))
    color: Ink.seal
    antialiasing: true

    // The inner rule of a carved seal.
    Rectangle {
      anchors.fill: parent
      anchors.margins: Math.max(2, Math.round(root.size * 0.08))
      radius: Math.max(1, plate.radius - 1)
      color: "transparent"
      border.width: 1
      border.color: Ink.alpha(Ink.paper, 0.5)
    }

    Text {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -Math.round(root.size * 0.02)
      text: root.shown
      color: Ink.paper
      font.family: Type.jpSerif
      font.weight: Font.Medium
      font.pixelSize: Math.round(root.size * 0.58)
      renderType: Text.NativeRendering
    }
  }
}
