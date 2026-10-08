pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../parts"

// Rows with one chosen (a device, a network, a profile): the selection part
// sits behind the chosen row and slides when it changes; on Leaf's ink
// plate the chosen row's text turns paper.
//   rows: [{ title, detail, note, chosen, mark (bool: unread) }]
Item {
  id: root

  property var skin: ({})
  property var rows: []
  property int rowHeight: Type.px(46)
  signal picked(int index)

  readonly property int chosen: {
    for (var i = 0; i < rows.length; i++) if (rows[i].chosen) return i
    return -1
  }

  implicitHeight: rows.length * rowHeight

  Selection {
    id: sel
    visible: root.chosen >= 0
    skin: root.skin
    x: -Type.px(10); width: root.width + Type.px(20); height: root.rowHeight
    y: Math.max(0, root.chosen) * root.rowHeight
  }

  Repeater {
    model: root.rows
    Item {
      id: row
      required property var modelData
      required property int index
      readonly property bool on: index === root.chosen
      readonly property color strong: on && sel.inverts ? Ink.paper : Ink.ink
      readonly property color quiet: on && sel.inverts ? Ink.alpha(Ink.paper, 0.75) : Ink.ink3
      y: index * root.rowHeight
      width: root.width; height: root.rowHeight

      Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - note.implicitWidth - Type.px(12)
        spacing: Type.px(2)
        Text {
          width: parent.width
          elide: Text.ElideRight
          text: row.modelData.title || ""
          color: row.on ? row.strong : Ink.ink2
          font.family: Type.text; font.pixelSize: Type.px(13.5)
          font.weight: row.on ? Font.Medium : Font.Normal
          font.variableAxes: row.on ? Type.valueAxes : ({ "wght": 420 })
        }
        Text {
          visible: !!row.modelData.detail
          width: parent.width
          elide: Text.ElideRight
          text: row.modelData.detail || ""
          color: row.quiet
          font.family: Type.text; font.pixelSize: Type.px(12)
        }
      }
      Text {
        id: note
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.note || ""
        color: row.quiet
        font.family: Type.text; font.pixelSize: Type.px(12)
      }
      UnreadMark { visible: !!row.modelData.mark; anchors.fill: parent; skin: root.skin }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(row.index) }
    }
  }
}
