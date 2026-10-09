import QtQuick
import "../core"
import "parts" as Parts

// The seal 鑑: a stamped square in the theme's red, the one block of colour
// on the bar. `stamp` shows a fixed glyph; `workspace` shows the active
// workspace as a kanji numeral; `carved` is Shōji's (the KataSeal part): an
// ink outline at rest, pressed red when letters wait for you, with their
// count beside it (`count`, under notif: seal); `none` hides it.
Item {
  id: root

  property string mode: "stamp"
  property string glyph: "鑑"
  property int workspace: 1
  property int size: Type.px(26)
  // carved: Shōji's skin, and the letters it carries (notif: seal).
  property var skin: ({})
  property bool count: false
  property int letters: 0
  property bool dnd: false
  readonly property bool carved: mode === "carved"
  readonly property bool pressed: carved && count && letters > 0 && !dnd

  readonly property var numerals: ["〇", "壱", "弐", "参", "肆", "伍", "陸", "漆", "捌", "玖"]
  readonly property string shown: mode === "workspace"
    ? (workspace >= 0 && workspace < numerals.length ? numerals[workspace] : String(workspace))
    : glyph

  visible: mode !== "none"
  implicitWidth: !visible ? 0 : carved ? carvedRow.implicitWidth + Type.px(8) : size
  implicitHeight: size

  Row {
    id: carvedRow
    visible: root.carved
    anchors.centerIn: parent
    spacing: Type.px(6)
    Parts.KataSeal {
      anchors.verticalCenter: parent.verticalCenter
      skin: root.skin
      glyph: root.glyph
      on: root.pressed
      size: Math.round(root.size * 0.92)
    }
    Text {
      visible: root.pressed
      anchors.verticalCenter: parent.verticalCenter
      text: String(root.letters)
      color: Ink.seal
      font.family: Type.display; font.pixelSize: Type.px(16); font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.px(16), 400)
    }
  }

  Rectangle {
    id: plate
    visible: !root.carved
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
