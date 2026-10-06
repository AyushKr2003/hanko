import QtQuick
import "../../core"

// One section of the handscroll, in ryoku.dev's grammar: a red kanji and
// `02 // SOUND`, a large serif title, a mono caption, and a faint kanji
// watermark low on the right. Its controls go in the default slot.
Item {
  id: root

  // core/Scroll.js SECTIONS entry.
  property var info: ({ no: "", jp: "", label: "" })
  // May hold <i>…</i> (the Time title's "the sixth").
  property string title: ""
  property string caption: ""

  default property alias content: body.data

  clip: true

  Text {
    anchors.right: parent.right
    anchors.rightMargin: -Type.px(10)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: -Type.px(40)
    text: root.info.jp
    color: Ink.ink
    opacity: 0.05
    font.family: Type.jpSerif
    font.weight: Font.Light
    font.pixelSize: Type.px(230)
    lineHeight: 1
    lineHeightMode: Text.ProportionalHeight
  }

  Column {
    x: Type.px(38)
    y: Type.px(62)
    width: parent.width - 2 * x

    Row {
      spacing: Type.px(10)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.info.jp
        color: Ink.seal
        font.family: Type.jp
        font.pixelSize: Type.px(13)
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.info.no + " // " + root.info.label
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.px(10)
        font.letterSpacing: Type.px(2.4)
      }
    }

    Item { width: 1; height: Type.px(12) }

    Text {
      width: parent.width
      elide: Text.ElideRight
      textFormat: Text.StyledText
      text: root.title
      color: Ink.ink
      font.family: Type.display
      font.pixelSize: Type.px(46)
      font.weight: Font.Normal
      font.variableAxes: { "opsz": 120, "wght": 400 }
      font.letterSpacing: -0.8
      lineHeight: 1
      lineHeightMode: Text.ProportionalHeight
    }

    Item { width: 1; height: Type.px(6) }

    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.caption.toUpperCase()
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.px(9)
      font.letterSpacing: Type.px(1.8)
    }

    Item {
      id: body
      width: parent.width
      height: childrenRect.height
    }
  }
}
