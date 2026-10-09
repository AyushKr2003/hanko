import QtQuick
import "../../core"

// The Prose sheets' sentence (文): the sheet's state written out in Fraunces,
// the words you can change underlined; tapping one does what it says. After
// "mad libs" forms, where fields complete a sentence: the state reads at a
// glance as language, and the controls sit inside it. Build `text` with
// word(action, label) for a tappable word and em(text) for an italic one.
Text {
  id: root

  signal picked(string action)

  function word(action, label) {
    return "<a href=\"" + action + "\">" + label + "</a>"
  }
  function em(t) { return "<i>" + t + "</i>" }
  function red(t) { return "<font color=\"" + Ink.seal + "\">" + t + "</font>" }

  width: parent ? parent.width : 0
  wrapMode: Text.Wrap
  textFormat: Text.StyledText
  color: Ink.inkDim
  linkColor: Ink.ink
  lineHeight: 1.22
  font.family: Type.display
  font.pixelSize: Type.px(24)
  font.weight: Font.Normal
  font.variableAxes: Type.axes(Type.px(24), 380)
  onLinkActivated: function(link) { root.picked(link) }

  HoverHandler { cursorShape: root.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor }
}
