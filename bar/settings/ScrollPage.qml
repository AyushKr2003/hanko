pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings
import "../../core/Leaf.js" as LeafJs
import ".."
import "../scroll"

// Settings › Scroll 巻 (docs/settings-kosei): first how a click on the bar
// opens a panel (a sheet drops, or the scroll unrolls), each drawn in
// small; then what sits between the scroll's sections, each divider drawn
// between two stub sections; then what follows Inbox, each end leaf drawn
// with a sample reading; then the scroll's sides and guides in words.
Column {
  id: root

  property var style: ({})
  property var draft: S.normalize({})
  property string query: ""
  property bool compact: false

  signal settingPicked(string key, string value)

  readonly property int across: width >= Type.px(760) ? 3 : 2
  readonly property real tileWidth: Math.floor((width - (across - 1) * Type.px(10)) / across)

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  // ------------------------------------------------------- how panels open
  SectionLabel { jp: "開"; text: "A click on the bar opens · 2 ways" }
  Item { width: 1; height: Type.px(12) }
  Row {
    spacing: Type.px(10)
    Repeater {
      model: [
        { key: "sheets", jp: "紙", name: "A sheet", line: "One sheet drops flush from the cell you click" },
        { key: "scroll", jp: "巻", name: "The scroll", line: "Every panel on one long paper, unrolled from the bar" }
      ]
      Tile {
        id: way
        required property var modelData
        width: (root.width - Type.px(10)) / 2
        height: implicitHeight
        stageHeight: Type.px(130)
        on: root.style.panels === modelData.key
        jp: modelData.jp
        name: modelData.name
        line: modelData.line
        onClicked: root.settingPicked("panels", way.modelData.key)

        // The bar, and what drops from it, in small.
        Rectangle {
          x: Type.px(24); y: Type.px(16)
          width: way.stage.width - 2 * x
          height: Type.px(12)
          color: Ink.alpha(Ink.ink, 0.12)
          Rectangle { x: Type.px(4); anchors.verticalCenter: parent.verticalCenter; width: Type.px(7); height: width; color: Ink.seal }
          Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; width: Type.px(26); height: Type.px(4); color: Ink.inkDim }
          Rectangle { id: cell; anchors.right: parent.right; anchors.rightMargin: Type.px(40); anchors.verticalCenter: parent.verticalCenter; width: Type.px(22); height: Type.px(6); color: way.modelData.key === "sheets" ? Ink.ink : Ink.inkFaint }
        }
        // A sheet under one cell...
        Rectangle {
          visible: way.modelData.key === "sheets"
          x: way.stage.width - Type.px(24) - Type.px(40) - Type.px(110) + Type.px(30)
          y: Type.px(28)
          width: Type.px(110)
          height: Type.px(88)
          color: "transparent"
          border.width: 1
          border.color: Ink.lineStrong
          Column {
            x: Type.px(10); y: Type.px(10)
            spacing: Type.px(6)
            Rectangle { width: Type.px(44); height: Type.px(7); color: Ink.inkDim }
            Repeater { model: 4; Rectangle { id: rule; required property int index; width: Type.px(88) - rule.index * Type.px(10); height: 1; color: Ink.line } }
          }
        }
        // ...or the whole scroll across.
        Rectangle {
          visible: way.modelData.key === "scroll"
          x: Type.px(36); y: Type.px(30)
          width: way.stage.width - 2 * x
          height: Type.px(86)
          color: "transparent"
          border.width: 1
          border.color: Ink.lineStrong
          Row {
            x: Type.px(10); y: Type.px(10)
            spacing: Type.px(10)
            Repeater {
              model: 5
              Column {
                id: section
                required property int index
                spacing: Type.px(5)
                Rectangle { width: Type.px(10); height: Type.px(10); color: section.index === 1 ? Ink.seal : Ink.inkFaint }
                Rectangle { width: Type.px(40); height: Type.px(5); color: Ink.inkDim }
                Repeater { model: 3; Rectangle { width: Type.px(36); height: 1; color: Ink.line } }
              }
            }
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(30) }

  // ------------------------------------------------------- between sections
  SectionLabel { jp: "間"; text: "Between the scroll's sections · " + Settings.INTERLUDES.length + " ways" }
  Item { width: 1; height: Type.px(12) }
  Grid {
    width: parent.width
    columns: root.across
    spacing: Type.px(10)
    Repeater {
      model: Settings.INTERLUDES
      Tile {
        id: tile
        required property var modelData
        width: root.tileWidth
        height: implicitHeight
        stageHeight: Type.px(140)
        on: modelData.key === root.style.interlude
        jp: modelData.jp
        name: modelData.name
        line: modelData.detail
        onClicked: root.settingPicked("interlude", tile.modelData.key)

        // Two stub sections either side of the divider.
        Repeater {
          model: [{ jp: "時", no: "01", left: true }, { jp: "音", no: "02", left: false }]
          Column {
            id: stub
            required property var modelData
            x: stub.modelData.left ? Type.px(14) : tile.stage.width / 2 + Type.px(30)
            y: Type.px(18)
            width: tile.stage.width / 2 - Type.px(46)
            spacing: Type.px(6)
            Text { text: stub.modelData.jp + "  " + stub.modelData.no; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.px(9) }
            Rectangle { width: parent.width * 0.8; height: Type.px(7); radius: 1; color: Ink.inkDim; opacity: 0.55 }
            Rectangle { width: parent.width * 0.55; height: Type.px(3); color: Ink.inkFaint; opacity: 0.6 }
            Item { width: 1; height: Type.px(6) }
            Repeater {
              model: 4
              Rectangle { required property int index; width: stub.width * (0.9 - index * 0.12); height: 1; color: Ink.line }
            }
          }
        }
        Interlude {
          x: tile.stage.width / 2 - width / 2
          y: Type.px(8)
          width: Type.px(46)
          height: tile.stage.height - Type.px(16)
          s: Type.scale * 0.62
          seed: 0
          style: tile.modelData.key
        }
      }
    }
  }

  Item { width: 1; height: Type.px(30) }

  // ------------------------------------------------------- after Inbox
  SectionLabel { jp: "跋"; text: "After Inbox, the scroll's end · " + Settings.ENDLEAVES.length + " leaves" }
  Item { width: 1; height: Type.px(12) }
  Grid {
    id: endleaves
    width: parent.width
    columns: root.across
    spacing: Type.px(10)
    readonly property var reading: LeafJs.sample(new Date())
    Repeater {
      model: Settings.ENDLEAVES
      Tile {
        id: leafTile
        required property var modelData
        width: root.tileWidth
        height: implicitHeight
        stageHeight: Math.round(root.tileWidth * 0.78)
        on: modelData.key === root.style.endleaf
        jp: modelData.jp
        name: modelData.name
        line: modelData.detail
        onClicked: root.settingPicked("endleaf", leafTile.modelData.key)
        EndLeaf {
          width: Type.px(400)
          height: Type.px(460)
          x: (leafTile.stage.width - width * scale) / 2
          y: -Type.px(36) * scale
          transformOrigin: Item.TopLeft
          scale: leafTile.stage.height / Type.px(390)
          kind: leafTile.modelData.key
          reading: endleaves.reading
          version: "0.1.0"
          preset: root.style.preset
          sealGlyph: root.style.sealGlyph
          enabled: false
        }
      }
    }
  }

  Item { width: 1; height: Type.px(30) }

  // ------------------------------------------------------- also, in words
  SectionLabel { jp: ""; text: "Also" }
  Item { width: 1; height: Type.px(4) }
  Repeater {
    model: [
      { key: "sides", name: "Sides", line: "Bare paper, or paper curling under at each end" },
      { key: "guides", name: "Guides", line: "The tabs on top, the position bar along the foot, both, or none" }
    ]
    Item {
      id: row
      required property var modelData
      required property int index
      width: root.width
      height: Type.px(52)
      Rectangle { visible: row.index > 0; width: parent.width; height: 1; color: Ink.lineSoft }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(1)
        Text { text: row.modelData.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row }
        Text { text: row.modelData.line; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
      }
      Segmented {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        options: Settings.optionsFor(row.modelData.key, S.OPTIONS)
        selected: String(root.style[row.modelData.key])
        onPicked: function(value) { root.settingPicked(row.modelData.key, value) }
      }
    }
  }
}
