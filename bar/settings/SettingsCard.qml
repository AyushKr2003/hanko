pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Settings.js" as Settings
import "../../core/Style.js" as S

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
        Text { text: "//"; color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
        Text { text: root.card.title.toUpperCase(); color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.eyebrow; font.letterSpacing: Type.trackEyebrow }
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: head.verticalCenter
        text: (root.rows.length + (root.rows.length === 1 ? " row" : " rows")).toUpperCase()
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.label
        font.letterSpacing: Type.trackLabel
      }
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.line }
    }

    Repeater {
      model: root.rows
      Item {
        id: row
        required property var modelData
        required property int index
        // The control goes under its name when beside it the name would be
        // too narrow to read.
        readonly property bool stacked: seg.width + Type.px(120) > width
        width: column.width
        height: stacked
          ? texts.height + seg.height + Type.px(6) + 2 * Type.px(9)
          : Math.max(Type.px(44), texts.height + Type.px(12), seg.height + Type.px(12))

        Rectangle {
          visible: row.index < root.rows.length - 1
          anchors.bottom: parent.bottom
          width: parent.width
          height: 1
          color: Ink.lineSoft
        }
        Column {
          id: texts
          y: row.stacked ? Type.px(9) : (parent.height - height) / 2
          width: row.stacked ? parent.width : parent.width - seg.width - Type.px(10)
          Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.modelData.name
            color: Ink.ink
            font.family: Type.text
            font.pixelSize: Type.row
          }
          Text {
            visible: text !== ""
            width: parent.width
            wrapMode: Text.Wrap
            text: row.modelData.detail
            color: Ink.inkMuted
            font.family: Type.text
            font.pixelSize: Type.note
          }
        }
        Segmented {
          id: seg
          x: row.stacked ? 0 : parent.width - width
          y: row.stacked ? texts.y + texts.height + Type.px(6) : (parent.height - height) / 2
          options: Settings.optionsFor(row.modelData.key, root.options)
          labels: ({})
          selected: row.modelData.key.indexOf("show:") === 0
            ? (S.shows(root.style, row.modelData.key.slice(5)) ? "shown" : "hidden")
            : Settings.selected(row.modelData.key, root.style, root.style.sealGlyph)
          onPicked: function(value) { root.picked(row.modelData.key, value) }
        }
      }
    }
  }
}
