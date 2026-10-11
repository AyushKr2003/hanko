pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings

// Settings › Presets 型: every preset as a specimen, drawn live with your
// data, as one list: the bars, then the four right-side studies
// (Style.js PRESET_GROUPS gives the order and the numbering). A card is its number, name, kanji and blurb, the
// settings that tell it apart, and the bar itself.
// The one in use carries the red mark (red means you) and IN USE, with the
// edits you made on top of it; a click on any other puts it on your bar.
// Your seal glyph, type size and hidden parts show in every preview, as
// they would on your bar.
Item {
  id: root

  property var doc: S.normalize({})
  property var barData: ({})
  property string query: ""
  property bool compact: false

  signal presetPicked(string name)

  readonly property var current: S.resolve(doc)

  width: parent ? parent.width : 0
  implicitHeight: groups.y + groups.height

  Column {
    id: groups
    y: Type.px(22)
    width: parent.width
    spacing: Type.px(12)

    Repeater {
      model: S.PRESET_GROUPS

      Column {
        id: group
        required property var modelData
        required property int index
        // The cards a search leaves in this group.
        readonly property var shown: modelData.names.filter(function(n) { return Settings.presetMatches(n, root.query, S.PRESETS) })
        // Numbered through both groups: Hanko 01 … Inrō 11.
        readonly property int first: {
          var n = 0
          for (var g = 0; g < index; g++) n += S.PRESET_GROUPS[g].names.length
          return n
        }
        visible: shown.length > 0
        width: groups.width
        spacing: Type.px(12)

        // One label over the whole list: the studies follow the bars
        // without a head of their own.
        SectionLabel {
          visible: group.index === 0
          jp: group.modelData.jp
          text: group.modelData.title + " · " + S.PRESET_NAMES.filter(function(n) { return Settings.presetMatches(n, root.query, S.PRESETS) }).length
        }

        Repeater {
          model: group.shown

          Rectangle {
            id: card
            required property string modelData
            required property int index
            readonly property bool inUse: modelData === root.doc.preset
            readonly property var style: S.resolve(S.withPreset(root.doc, modelData))
            readonly property int number: group.first + group.modelData.names.indexOf(modelData) + 1
            readonly property int pad: Type.px(root.compact ? 12 : 16)

            width: group.width
            height: head.y + head.height + Type.px(10) + facts.height + Type.px(12) + box.height + pad
            radius: 3
            color: cardHover.containsMouse && !inUse ? Ink.alpha(Ink.bone, Ink.light ? 0.04 : 0.035) : "transparent"
            border.width: 1
            border.color: inUse ? Ink.lineStrong : cardHover.containsMouse ? Ink.line : Ink.lineSoft
            Behavior on color { enabled: Motion.live; ColorAnimation { duration: 120 } }

            // 01  Hanko 判  · the two together              ■ IN USE · 2 EDITS
            Item {
              id: head
              x: card.pad
              y: card.pad
              width: card.width - 2 * card.pad
              height: name.implicitHeight
              Row {
                id: title
                spacing: Type.px(12)
                Text {
                  anchors.baseline: name.baseline
                  text: (card.number < 10 ? "0" : "") + card.number
                  color: Ink.inkFaint
                  font.family: Type.mono
                  font.pixelSize: Type.tag
                  font.letterSpacing: Type.trackLabel
                }
                Text {
                  id: name
                  text: card.modelData
                  color: Ink.ink
                  font.family: Type.display
                  font.pixelSize: Type.px(root.compact ? 22 : 26)
                  font.weight: Font.Normal
                  font.variableAxes: Type.axes(Type.px(root.compact ? 22 : 26))
                  font.letterSpacing: -0.3
                }
                Text {
                  anchors.baseline: name.baseline
                  text: Settings.PRESET_KANJI[card.modelData] || ""
                  color: card.inUse ? Ink.seal : Ink.inkMuted
                  font.family: Type.jp
                  font.pixelSize: Type.px(root.compact ? 16 : 19)
                }
                Text {
                  visible: !root.compact
                  anchors.baseline: name.baseline
                  text: "· " + (Settings.PRESET_BLURBS[card.modelData] || "")
                  color: Ink.inkMuted
                  font.family: Type.text
                  font.pixelSize: Type.note
                }
              }
              // In use: the red mark and a bone tag; otherwise USE on reach.
              Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Type.px(8)
                Text {
                  visible: card.inUse && root.current.edited
                  anchors.verticalCenter: parent.verticalCenter
                  text: (Object.keys(root.doc.edits).length) + (Object.keys(root.doc.edits).length === 1 ? " EDIT" : " EDITS")
                  color: Ink.inkMuted
                  font.family: Type.mono
                  font.pixelSize: Type.tag
                  font.letterSpacing: Type.trackLabel
                }
                Rectangle {
                  visible: card.inUse
                  anchors.verticalCenter: parent.verticalCenter
                  width: Type.px(7)
                  height: width
                  color: Ink.seal
                }
                Rectangle {
                  visible: card.inUse || cardHover.containsMouse
                  anchors.verticalCenter: parent.verticalCenter
                  width: tag.implicitWidth + 2 * Type.px(9)
                  height: tag.implicitHeight + 2 * Type.px(4)
                  radius: 2
                  color: card.inUse ? Ink.bone : "transparent"
                  border.width: card.inUse ? 0 : 1
                  border.color: Ink.lineStrong
                  Text {
                    id: tag
                    anchors.centerIn: parent
                    text: card.inUse ? "IN USE" : "USE ›"
                    color: card.inUse ? Ink.boneInk : Ink.ink
                    font.family: Type.mono
                    font.pixelSize: Type.tag
                    font.letterSpacing: Type.trackLabel
                  }
                }
              }
            }

            // The settings that tell it apart.
            Text {
              id: facts
              x: card.pad
              y: head.y + head.height + Type.px(8)
              width: card.width - 2 * card.pad
              elide: Text.ElideRight
              text: (root.compact ? (Settings.PRESET_BLURBS[card.modelData] || "") + " · " : "") + Settings.presetFacts(card.style)
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackLabel
              font.capitalization: Font.AllUppercase
            }

            // The bar, on bare paper.
            Rectangle {
              id: box
              x: card.pad
              y: facts.y + facts.height + Type.px(12)
              width: card.width - 2 * card.pad
              readonly property int gap: card.style.float === "inset" ? Type.px(8) : 0
              height: preview.height + 2 + 2 * gap
              radius: 2
              color: "transparent"
              border.width: 1
              border.color: Ink.lineSoft
              clip: true
              PreviewBar {
                id: preview
                x: 1 + box.gap
                y: card.style.position === "bottom" ? box.height - 1 - box.gap - height : 1 + box.gap
                width: box.width - 2 - 2 * box.gap
                style: card.style
                barData: root.barData
                // A screen's width, so a full bar never runs into its clock.
                minDesign: Type.px(1600)
              }
            }

            MouseArea {
              id: cardHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: card.inUse ? Qt.ArrowCursor : Qt.PointingHandCursor
              // The one in use stays as it is; Reset to preset drops its edits.
              onClicked: if (!card.inUse) root.presetPicked(card.modelData)
            }
          }
        }
      }
    }

    // A search that leaves no preset.
    Text {
      visible: !S.PRESET_NAMES.some(function(n) { return Settings.presetMatches(n, root.query, S.PRESETS) })
      text: "No preset matches “" + root.query.trim() + "”."
      color: Ink.inkMuted
      font.family: Type.text
      font.pixelSize: Type.row
    }
  }
}
