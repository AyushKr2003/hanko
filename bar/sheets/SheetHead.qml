pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// The head of a sheet: an eyebrow (a dash, the kanji, the mono label and a
// rule to the edge), the serif title and a one-line blurb.
//   ── 音 SOUND · PIPEWIRE ─────────────
//   Sound
//   Where it plays, how loud, and who is talking.
Column {
  id: root

  property string jp: ""
  property string label: ""
  property string title: ""
  property string blurb: ""
  // Red only when the title is something that needs you (offline, low).
  property color titleColor: Ink.ink

  width: parent ? parent.width : 0
  spacing: 0

  Row {
    width: root.width
    height: Type.px(12)
    spacing: Type.px(8)

    Rectangle {
      id: dash
      anchors.verticalCenter: parent.verticalCenter
      width: Type.px(18)
      height: 1
      color: Ink.inkMuted
    }
    Text {
      id: jpText
      anchors.verticalCenter: parent.verticalCenter
      text: root.jp
      color: Ink.ink
      font.family: Type.jp
      font.pixelSize: Type.px(11)
    }
    Text {
      id: labelText
      anchors.verticalCenter: parent.verticalCenter
      text: root.label.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.px(9.5)
      font.letterSpacing: Type.px(2.2)
    }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, root.width - dash.width - jpText.width - labelText.width - 3 * parent.spacing)
      height: 1
      color: Ink.lineSoft
    }
  }

  Item { width: 1; height: Type.px(14) }

  Text {
    text: root.title
    color: root.titleColor
    font.family: Type.display
    font.pixelSize: Type.px(38)
    font.weight: Font.Normal
    font.variableAxes: { "opsz": 96, "wght": 400 }
    font.letterSpacing: -0.4
    lineHeight: 1
    lineHeightMode: Text.ProportionalHeight
  }

  Item { width: 1; height: Type.px(8) }

  Text {
    width: root.width
    visible: text !== ""
    text: root.blurb
    color: Ink.inkMuted
    wrapMode: Text.Wrap
    font.family: Type.text
    font.pixelSize: Type.px(13)
  }
}
