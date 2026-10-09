pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Sheets.js" as Sheets

// The head of a sheet: an eyebrow (a dash, the kanji, the mono label, a
// rule to the edge and the sheet's folio), the serif title over its kanji
// set large and faint like a watermark in the paper, and a one-line
// standfirst in serif italic.
//   ── 音 SOUND · PIPEWIRE ──────── Nº 02
//   Sound                              音
//   Where it plays, how loud, and who is talking.
Column {
  id: root

  // Which sheet this heads (Sheets.js key): gives the folio number.
  property string sheet: ""
  property string jp: ""
  property string label: ""
  property string title: ""
  property string blurb: ""
  // Red only when the title is something that needs you (offline, low).
  property color titleColor: Ink.ink
  // The eyebrow alone: Dial and Prose sheets make their own hero.
  property bool compact: false

  readonly property var info: Sheets.byKey(sheet)
  readonly property string folio: info ? info.no : ""

  width: parent ? parent.width : 0
  spacing: 0

  Item {
    width: root.width
    height: Type.px(12)

    Row {
      id: lead
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(8)

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(18)
        height: 1
        color: Ink.inkMuted
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.jp
        color: Ink.ink
        font.family: Type.jp
        font.pixelSize: Type.glossMid
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label.toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.eyebrow
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackEyebrow
      }
    }
    Rectangle {
      x: lead.width + Type.px(8)
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, (folioText.visible ? folioText.x - Type.px(8) : root.width) - x)
      height: 1
      color: Ink.lineSoft
    }
    // The folio: which page of the bar this is, as a book numbers its leaves.
    Text {
      id: folioText
      visible: root.folio !== ""
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "No. " + root.folio
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }

  Item { visible: !root.compact; width: 1; height: Type.px(14) }

  Item {
    visible: !root.compact
    width: root.width
    height: titleText.height

    // The sheet's kanji pressed into the paper behind the title: set large,
    // nearly the paper's own colour, clipped by nothing so it reads as a mark
    // in the sheet rather than a picture on it.
    Text {
      anchors.right: parent.right
      anchors.rightMargin: -Type.px(4)
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: Type.px(6)
      text: root.jp
      color: Ink.ink
      opacity: Ink.light ? 0.07 : 0.055
      font.family: Type.jpSerif
      font.pixelSize: Type.px(84)
      font.weight: Font.Black
    }
    Text {
      id: titleText
      width: parent.width - Type.px(72)
      elide: Text.ElideRight
      text: root.title
      color: root.titleColor
      font.family: Type.display
      font.pixelSize: Type.title
      font.weight: Font.Normal
      font.variableAxes: Type.axes(Type.title)
      font.letterSpacing: -0.6
      lineHeight: 1
      lineHeightMode: Text.ProportionalHeight
    }
  }

  Item { visible: !root.compact; width: 1; height: Type.px(8) }

  // The standfirst: Fraunces italic, as a magazine sets the line under a head.
  Text {
    width: root.width - Type.px(40)
    visible: text !== "" && !root.compact
    text: root.blurb
    color: Ink.inkDim
    wrapMode: Text.Wrap
    font.family: Type.display
    font.italic: true
    font.pixelSize: Type.px(15)
    font.weight: Font.Normal
    font.variableAxes: Type.axes(Type.px(15), 360)
    lineHeight: 1.15
  }
}
