pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Settings.js" as Settings

// One card of the Typesetting page: `// LEFT · WHERE YOU ARE`, then a row per
// setting with its name, a line on what it does, and a segmented control.
Rectangle {
  id: root

  // core/Settings.js CARDS entry.
  property var card: ({ title: "", rows: [] })
  // The resolved draft style and the option lists (Style.js OPTIONS).
  property var style: ({})
  property var options: ({})
  property string query: ""

  signal picked(string key, string value)

  readonly property var rows: card.rows.filter(function(r) { return Settings.matches(r, root.query, root.options) })

  visible: rows.length > 0
  implicitHeight: column.implicitHeight + Type.px(12) + Type.px(4)
  radius: 3
  color: "transparent"
  border.width: 1
  border.color: Ink.line

  Column {
    id: column
    x: Type.px(14)
    y: Type.px(12)
    width: parent.width - 2 * x

    Item {
      width: parent.width
      height: head.height + Type.px(8)
      Row {
        id: head
        spacing: Type.px(8)
        Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(2) }
        Text { text: root.card.title.toUpperCase(); color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.px(10); font.letterSpacing: Type.px(2) }
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: head.verticalCenter
        text: (root.rows.length + (root.rows.length === 1 ? " row" : " rows")).toUpperCase()
        color: Ink.inkFaint
        font.family: Type.mono
        font.pixelSize: Type.px(9)
        font.letterSpacing: Type.px(2)
      }
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.line }
    }

    Repeater {
      model: root.rows
      Item {
        id: row
        required property var modelData
        required property int index
        width: column.width
        height: Math.max(Type.px(44), texts.height + Type.px(12), seg.height + Type.px(12))

        Rectangle {
          visible: row.index < root.rows.length - 1
          anchors.bottom: parent.bottom
          width: parent.width
          height: 1
          color: Ink.lineSoft
        }
        Column {
          id: texts
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - seg.width - Type.px(10)
          Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.modelData.name
            color: Ink.ink
            font.family: Type.text
            font.pixelSize: Type.px(13.5)
          }
          Text {
            visible: text !== ""
            width: parent.width
            wrapMode: Text.Wrap
            text: row.modelData.detail
            color: Ink.inkMuted
            font.family: Type.text
            font.pixelSize: Type.px(11)
          }
        }
        Segmented {
          id: seg
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          options: Settings.optionsFor(row.modelData.key, root.options)
          selected: Settings.selected(row.modelData.key, root.style, root.style.sealGlyph)
          onPicked: function(value) { root.picked(row.modelData.key, value) }
        }
      }
    }
  }
}
