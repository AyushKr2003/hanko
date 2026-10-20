pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Densho.js" as Densho
import QtQuick.Shapes

// One section of the handscroll, in ryoku.dev's grammar: a red kanji and
// `02 // SOUND`, a large serif title, a mono caption, and a faint kanji
// watermark low on the right. Its controls go in the default slot.
//
// Densho 伝書 (docs/densho on the design-densho branch) adds three touches:
// `brush` writes the title on with a dry brush as `write` goes 0..1 (the
// head first, the caption behind the stroke, the body last); `poem` sets the
// section's poetic name after its label (order: mokuroku); `fault` draws
// one seal-red seam under the caption while the section is broken
// (faults: seam).
Item {
  id: root

  // core/Scroll.js SECTIONS entry.
  property var info: ({ no: "", jp: "", label: "" })
  // May hold <i>…</i> (the Time title's "the sixth").
  property string title: ""
  property string caption: ""
  property string poem: ""
  property bool brush: false
  property real write: 1
  property bool fault: false

  default property alias content: body.data

  // How far the brush has come: the title is whole at 70%, the caption
  // follows from 45%, the body comes in after the title.
  readonly property real stroke: brush ? Math.max(0, Math.min(1, write / 0.7)) : 1
  readonly property real headInk: brush ? 0.45 + 0.55 * Math.min(1, write * 4) : 1
  readonly property real captionInk: brush ? Math.max(0, Math.min(1, (write - 0.45) * 4)) : 1
  readonly property real bodyInk: brush ? Math.max(0, Math.min(1, (write - 0.62) / 0.3)) : 1

  clip: true

  Text {
    anchors.right: parent.right
    anchors.rightMargin: -Type.px(10)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: -Type.px(40)
    text: root.info.jp
    color: Ink.ink
    opacity: 0.05 * root.bodyInk
    font.family: Type.jpSerif
    font.weight: Font.Light
    font.pixelSize: Type.px(230)
    lineHeight: 1
    lineHeightMode: Text.ProportionalHeight
  }

  Column {
    id: column
    x: Type.px(38)
    y: Type.px(62)
    width: parent.width - 2 * x

    Row {
      spacing: Type.px(10)
      opacity: root.headInk
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.info.jp
        color: Ink.seal
        font.family: Type.jp
        font.pixelSize: Type.glossBig
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.info.no + " // " + root.info.label
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.eyebrow
        font.weight: Type.labelWeight
        font.letterSpacing: Type.trackEyebrow
      }
      Text {
        visible: root.poem !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: "— " + root.poem
        color: Ink.inkFaint
        font.family: Type.display
        font.italic: true
        font.pixelSize: Type.px(15)
        font.variableAxes: Type.axes(Type.px(15))
      }
    }

    Item { width: 1; height: Type.px(12) }

    // The title: whole, or written on by the brush in bands, each band's
    // edge a little ahead or behind (the kasure of a dry brush), with a few
    // dry hairs leading the stroke.
    Item {
      id: titleBox
      width: parent.width
      height: titleText.height

      Title { id: titleText; width: parent.width; visible: root.stroke >= 1 }

      Repeater {
        model: root.stroke > 0 && root.stroke < 1 ? titleBox.bands : 0
        Item {
          id: band
          required property int index
          readonly property real h: Math.ceil(titleText.height / titleBox.bands)
          y: band.index * h
          width: Math.max(0, titleBox.edge + titleBox.ragged[band.index] * titleBox.reach * Math.min(1, root.stroke * 6))
          height: h + 1
          clip: true
          Title { y: -band.y; width: titleBox.width }
        }
      }
      Repeater {
        model: root.stroke > 0 && root.stroke < 1 ? titleBox.hairs : []
        Rectangle {
          id: hair
          required property var modelData
          x: titleBox.edge - hair.modelData.len * titleBox.reach * 0.5
          y: hair.modelData.y * titleText.height
          width: hair.modelData.len * titleBox.reach
          height: hair.modelData.thick
          radius: height / 2
          color: Ink.ink
          opacity: hair.modelData.ink
        }
      }

      readonly property int bands: 14
      // Where the stroke's head is, and how far its broken edge reaches.
      readonly property real edge: root.stroke * (titleText.contentWidth + Type.px(24))
      readonly property real reach: Type.px(26)
      readonly property var ragged: [0.2, -0.6, 0.5, 0.9, -0.2, 0.4, -0.9, 0.1, 0.7, -0.4, 0.3, -0.7, 0.8, -0.1]
      readonly property var hairs: [
        { y: 0.24, len: 1.6, thick: 1, ink: 0.45 }, { y: 0.38, len: 0.9, thick: 1.5, ink: 0.3 },
        { y: 0.52, len: 2.1, thick: 1, ink: 0.35 }, { y: 0.66, len: 1.2, thick: 1, ink: 0.5 },
        { y: 0.8, len: 1.7, thick: 1.5, ink: 0.25 }]
    }

    Item { width: 1; height: Type.px(6) }

    Text {
      id: captionText
      width: parent.width
      opacity: root.captionInk
      elide: Text.ElideRight
      text: root.caption.toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: Type.trackLabel
    }

    Item {
      id: body
      width: parent.width
      height: childrenRect.height
      opacity: root.bodyInk
    }
  }

  // The seam (faults: seam), under the caption: drawn on from the left when
  // the section breaks, lifted off when it mends.
  Item {
    id: seamBox
    x: column.x - Type.px(18)
    y: column.y + captionText.y + captionText.height + Type.px(4)
    width: seam.width * root.seamGrow
    height: seam.height
    clip: true
    visible: root.seamGrow > 0
    opacity: root.captionInk
    Item {
      id: seam
      width: root.width - Type.px(20)
      height: Type.px(26)
      readonly property string path: Densho.seamPath(width, height, Type.px(26))
      Shape {
        anchors.fill: parent
        antialiasing: true
        ShapePath {
          fillColor: "transparent"
          strokeColor: Ink.alpha(Ink.seal, 0.14)
          strokeWidth: Type.px(7)
          joinStyle: ShapePath.RoundJoin
          capStyle: ShapePath.RoundCap
          PathSvg { path: seam.path }
        }
        ShapePath {
          fillColor: "transparent"
          strokeColor: Ink.seal
          strokeWidth: Math.max(1.5, Type.px(2))
          joinStyle: ShapePath.RoundJoin
          capStyle: ShapePath.RoundCap
          PathSvg { path: seam.path }
        }
      }
    }
  }

  // The seam grows over 420 ms when the fault comes and draws back when it
  // goes; with motion still it is simply there or not.
  property real seamGrow: fault ? 1 : 0
  Behavior on seamGrow {
    enabled: Motion.live
    NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.nukiCurve }
  }

  component Title: Text {
    elide: Text.ElideRight
    textFormat: Text.StyledText
    text: root.title
    color: Ink.ink
    font.family: Type.display
    font.pixelSize: Type.hero
    font.weight: Font.Normal
    font.variableAxes: Type.axes(Type.hero)
    font.letterSpacing: -0.8
    lineHeight: 1
    lineHeightMode: Text.ProportionalHeight
  }
}
