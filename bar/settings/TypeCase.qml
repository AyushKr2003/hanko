pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings

// The case (活字ケース) for the part the galley has open (docs/settings-kosei):
// its number, name and kanji over one plain line; what you changed from the
// preset, each with a way back; then a specimen for every way the part can
// be set (Specimen.qml); then the few choices that are words, not looks.
Item {
  id: root

  // Settings.PROOF entry.
  property var part: Settings.PROOF[0]
  property var style: ({})
  property var doc: S.normalize({})
  property var barData: ({})
  property bool compact: false

  signal picked(string key, string value)
  signal tried(string key, string value)
  signal untried()
  // "…" on the glyph stones: a glyph of your own, under Advanced.
  signal glyphAsked()

  readonly property var preset: S.PRESETS[doc.preset] || {}
  readonly property var edits: Settings.proofEdits(part, doc)
  // Under Inkan the bar's own parts are set for when you go back to it.
  readonly property bool shelved: style.form === "inkan" && part.bar

  implicitHeight: column.height

  Column {
    id: column
    width: root.width
    spacing: Type.px(18)

    // ------------------------------------------------------------ heading
    Item {
      width: parent.width
      height: Math.max(headLeft.height, headRight.height)

      Row {
        id: headLeft
        spacing: Type.px(16)
        Text {
          text: root.part.no
          color: Ink.inkFaint
          font.family: Type.display
          font.pixelSize: Type.px(root.compact ? 30 : 40)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(root.compact ? 30 : 40))
          font.features: { "tnum": 1 }
        }
        Column {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Type.px(4)
          spacing: Type.px(2)
          Row {
            spacing: Type.px(10)
            Text {
              id: partName
              text: root.part.name
              color: Ink.ink
              font.family: Type.display
              font.pixelSize: Type.px(root.compact ? 24 : 28)
              font.weight: Font.Normal
              font.variableAxes: Type.axes(Type.px(root.compact ? 24 : 28))
            }
            Text {
              anchors.baseline: partName.baseline
              text: root.part.jp
              color: Ink.inkMuted
              font.family: Type.jp
              font.pixelSize: Type.px(20)
            }
          }
        }
      }

      // What you set apart from the preset, each with the way back.
      Column {
        id: headRight
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Type.px(6)
        visible: !root.compact
        spacing: Type.px(4)
        Repeater {
          model: root.edits
          Row {
            id: editRow
            required property string modelData
            readonly property string was: String(root.preset[modelData] !== undefined ? root.preset[modelData] : "")
            anchors.right: parent.right
            spacing: Type.px(8)
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(4); height: width; radius: width / 2; color: Ink.seal }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Settings.alsoOf(editRow.modelData).name.toUpperCase() + "  " + root.doc.preset.toUpperCase() + " " + editRow.was + "  →  YOURS " + String(root.style[editRow.modelData])
              color: Ink.inkDim
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackLabel
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "PUT BACK"
              color: back.containsMouse ? Ink.ink : Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackLabel
              font.underline: true
              MouseArea {
                id: back
                anchors.fill: parent
                anchors.margins: -Type.px(4)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(editRow.modelData, editRow.was)
              }
            }
          }
        }
      }
    }

    Text {
      width: Math.min(parent.width, Type.px(720))
      wrapMode: Text.Wrap
      text: root.part.line + (root.shelved ? "  Inkan has no bar: set it now, and it is ready when Form is Bar again." : "")
      color: Ink.inkMuted
      font.family: Type.text
      font.pixelSize: Type.row
      lineHeight: 1.15
    }

    // ---------------------------------------------------------- specimens
    Repeater {
      model: root.part.cast
      Column {
        id: group
        required property string modelData
        required property int index
        readonly property var ways: Settings.optionsFor(modelData, S.OPTIONS)
        // Wide parts get wide specimens; then the count is balanced across rows.
        readonly property real minTile: Type.px(["status", "title", "media", "edge", "indicators"].indexOf(root.part.key) >= 0 ? 290 : 200)
        readonly property int most: Math.max(1, Math.floor((width + grid.spacing) / (minTile + grid.spacing)))
        readonly property int across: Math.max(1, Math.ceil(ways.length / Math.ceil(ways.length / most)))
        width: column.width
        spacing: Type.px(10)
        opacity: root.shelved ? 0.55 : 1

        // A head only when the part has more than one cast setting.
        SectionLabel {
          visible: root.part.cast.length > 1
          text: Settings.nameOf(group.modelData) + " · " + group.ways.length + " ways"
          jp: ""
        }

        Grid {
          id: grid
          width: parent.width
          columns: group.across
          spacing: Type.px(10)
          readonly property real tileWidth: Math.floor((width - (columns - 1) * spacing) / columns)
          Repeater {
            model: group.ways
            Specimen {
              required property string modelData
              width: grid.tileWidth
              height: implicitHeight
              stageHeight: Type.px(root.part.key === "status" || root.part.key === "frame" ? 92 : 82)
              style: root.style
              barData: root.barData
              part: root.part.key
              key: group.modelData
              value: modelData
              presetValue: String(root.preset[group.modelData])
              presetName: root.doc.preset
              onPicked: function(k, v) { root.picked(k, v) }
              onTried: function(k, v) { root.tried(k, v) }
              onUntried: root.untried()
            }
          }
        }
      }
    }

    // ---------------------------------------------------------- also, in words
    Column {
      visible: root.part.also.length > 0
      width: parent.width
      spacing: 0

      SectionLabel { text: root.part.cast.length ? "Also" : "Set"; jp: "" }
      Item { width: 1; height: Type.px(4) }

      Repeater {
        model: root.part.also
        Item {
          id: row
          required property string modelData
          required property int index
          readonly property var words: Settings.alsoOf(modelData)
          readonly property bool narrow: root.compact || width < Type.px(620)
          readonly property bool edited: root.edits.indexOf(modelData) >= 0
          width: parent.width
          height: Math.max(Type.px(46), (narrow ? label.height + control.height + Type.px(8) : Math.max(label.height, control.height)) + Type.px(16))

          Rectangle { visible: row.index > 0; width: parent.width; height: 1; color: Ink.lineSoft }

          Column {
            id: label
            y: row.narrow ? Type.px(8) : (row.height - height) / 2
            width: row.narrow ? parent.width : parent.width - control.width - Type.px(24)
            spacing: Type.px(1)
            Row {
              spacing: Type.px(8)
              Text { text: row.words.name; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row }
              Rectangle { visible: row.edited; anchors.verticalCenter: parent.verticalCenter; width: Type.px(4); height: width; radius: width / 2; color: Ink.seal }
            }
            Text {
              width: parent.width
              elide: Text.ElideRight
              text: row.words.line
              color: Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.note
            }
          }

          Loader {
            id: control
            x: row.narrow ? 0 : parent.width - width
            y: row.narrow ? label.y + label.height + Type.px(8) : (row.height - height) / 2
            sourceComponent: row.modelData === "sealGlyph" ? stones : segmented
            Component {
              id: segmented
              Segmented {
                options: Settings.optionsFor(row.modelData, S.OPTIONS)
                selected: Settings.selected(row.modelData, root.style, root.doc.sealGlyph)
                onPicked: function(value) { root.picked(row.modelData, value) }
              }
            }
            Component {
              id: stones
              Row {
                spacing: Type.px(8)
                Repeater {
                  model: Settings.GLYPHS.concat(["…"])
                  Rectangle {
                    id: stone
                    required property string modelData
                    readonly property bool own: modelData === "…"
                    readonly property bool on: own ? Settings.GLYPHS.indexOf(root.doc.sealGlyph) < 0 : root.doc.sealGlyph === modelData
                    width: Type.px(34)
                    height: width
                    radius: 3
                    color: own ? "transparent" : Ink.seal
                    border.width: own ? 1 : 0
                    border.color: Ink.lineStrong
                    opacity: on || stoneHover.containsMouse ? 1 : 0.62
                    Text {
                      anchors.centerIn: parent
                      text: stone.own && stone.on ? root.doc.sealGlyph : stone.modelData
                      color: stone.own ? Ink.ink : Ink.paper
                      font.family: Type.jpSerif
                      font.pixelSize: Type.px(18)
                    }
                    // The one carved now is ringed in ink.
                    Rectangle {
                      visible: stone.on
                      anchors.fill: parent
                      anchors.margins: -Type.px(4)
                      radius: 4
                      color: "transparent"
                      border.width: 1
                      border.color: Ink.ink
                    }
                    MouseArea {
                      id: stoneHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: stone.own ? root.glyphAsked() : root.picked("sealGlyph", stone.modelData)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
