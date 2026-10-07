import QtQuick
import "../../core"

// One editorial line: a name (and a mono byline) on the left, a value on
// the right, a hairline leader between them. `spec` sets the name as a
// small tracked label and the value in mono (a dossier's small print);
// `credit` sets the name large. A row with a url inverts under the
// pointer and opens it.
Item {
  id: root
  property string kind: "spec"
  property string name: ""
  property string by: ""
  property string value: ""
  property string url: ""
  readonly property bool linked: url !== ""
  readonly property bool inverted: linked && hover.hovered
  readonly property bool spec: kind === "spec"

  implicitHeight: spec ? Type.px(26) : Type.px(40)

  HoverHandler { id: hover; enabled: root.linked; cursorShape: Qt.PointingHandCursor }
  TapHandler { enabled: root.linked; onTapped: Qt.openUrlExternally(root.url) }

  Rectangle {
    anchors.fill: parent
    radius: 3
    color: root.inverted ? Ink.bone : "transparent"
  }
  Text {
    id: nameText
    x: root.spec ? 0 : Type.px(12)
    anchors.verticalCenter: parent.verticalCenter
    text: root.name
    color: root.inverted ? Ink.boneInk : root.spec ? Ink.inkMuted : Ink.ink
    font.family: root.spec ? Type.mono : Type.text
    font.pixelSize: root.spec ? Type.tag : Type.row
    font.weight: root.spec ? Font.Normal : Font.Medium
    font.letterSpacing: root.spec ? Type.trackLabel : 0
    font.capitalization: root.spec ? Font.AllUppercase : Font.MixedCase
  }
  Text {
    id: byText
    visible: root.by !== ""
    anchors.left: nameText.right
    anchors.leftMargin: Type.px(8)
    anchors.baseline: nameText.baseline
    text: root.by
    color: root.inverted ? Ink.boneInk : Ink.inkMuted
    opacity: root.inverted ? 0.7 : 1
    font.family: Type.mono
    font.pixelSize: Type.tag
  }
  Text {
    id: valueText
    anchors.right: parent.right
    anchors.rightMargin: root.spec ? 0 : Type.px(12)
    anchors.verticalCenter: parent.verticalCenter
    // Never runs over the name.
    width: Math.max(0, Math.min(implicitWidth, root.width - (byText.visible ? byText.x + byText.width : nameText.x + nameText.width) - Type.px(36)))
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
    text: root.value
    color: root.inverted ? Ink.boneInk : root.spec ? Ink.ink : Ink.inkMuted
    opacity: root.inverted && !root.spec ? 0.75 : 1
    font.family: root.spec ? Type.mono : Type.text
    font.pixelSize: root.spec ? Type.note : Type.note
  }
  Rectangle {
    anchors.left: byText.visible ? byText.right : nameText.right
    anchors.leftMargin: Type.px(12)
    anchors.right: valueText.left
    anchors.rightMargin: Type.px(12)
    anchors.verticalCenter: parent.verticalCenter
    height: 1
    color: root.inverted ? Ink.alpha(Ink.boneInk, 0.25) : Ink.lineSoft
  }
}
