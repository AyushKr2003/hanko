pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One entry on a page of a crest book (紋帳): the crest, and under it its
// name and a note, as the books caption each mon. The one you bear is
// inked red; a click takes another's colours.
Item {
  id: root

  property alias kind: crest.kind
  property alias level: crest.level
  property alias count: crest.count
  property alias glyph: crest.glyph
  property bool selected: false
  property bool urgent: false
  property bool faint: false
  property bool interactive: true
  property string name: ""
  property string note: ""

  signal clicked()

  implicitHeight: crest.height + Type.px(8) + caption.height

  Crest {
    id: crest
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(Type.px(54), root.width - Type.px(8))
    height: width
    inked: root.selected
    urgent: root.urgent
    faint: root.faint
    turn: hover.containsMouse && root.interactive ? 30 : 0
  }
  Column {
    id: caption
    y: crest.height + Type.px(8)
    width: parent.width
    spacing: Type.px(1)
    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      text: root.name
      color: root.selected ? Ink.ink : Ink.inkDim
      font.family: Type.text
      font.pixelSize: Type.note
      font.weight: root.selected ? Type.valueWeight : Font.Normal
      font.underline: hover.containsMouse && root.interactive
    }
    Text {
      visible: text !== ""
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      text: root.note.toUpperCase()
      color: root.urgent ? Ink.seal : Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
    }
  }
  MouseArea {
    id: hover
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
