pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings

// Settings › Presets 型 as a pattern book (docs/settings-kosei): the dyers'
// stencil sample books from which a pattern was chosen. A row of swatches
// (a kanji and a name each; the one on your bar marked red), and the one
// you open set as your bar, at proof size, with only what it would change
// listed under it. Use puts it on. Your seal glyph, type size, set-aside
// parts and motion stay yours.
Column {
  id: root

  property var doc: S.normalize({})
  property var barData: ({})
  property string query: ""
  property bool compact: false
  // The preset open in the book ("" = the one in use).
  property string viewed: ""

  signal presetPicked(string name)

  readonly property var names: S.PRESET_NAMES.filter(function(n) { return Settings.presetMatches(n, root.query, S.PRESETS) })
  readonly property string open: {
    var want = viewed !== "" ? viewed : doc.preset
    if (names.indexOf(want) >= 0) return want
    return names.length ? names[0] : doc.preset
  }
  readonly property bool inUse: open === doc.preset
  readonly property var openStyle: S.resolve(S.withPreset(doc, open))
  readonly property var diff: Settings.presetDiff(doc, open, S)
  readonly property int edits: Object.keys(doc.edits || {}).length
  readonly property int number: S.PRESET_NAMES.indexOf(open) + 1

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  // ------------------------------------------------------------ the swatches
  Flow {
    id: book
    width: parent.width
    spacing: Type.px(18)

    Repeater {
      model: S.PRESET_GROUPS
      Column {
        id: group
        required property var modelData
        required property int index
        readonly property var shown: modelData.names.filter(function(n) { return root.names.indexOf(n) >= 0 })
        // All nine in one row when there is room: three group gaps of 18,
        // the rest 8 apart.
        readonly property real cardWidth: Math.max(Type.px(92), Math.min(Type.px(130), Math.floor(
          (book.width - (S.PRESET_GROUPS.length - 1) * book.spacing - (S.PRESET_NAMES.length - S.PRESET_GROUPS.length) * Type.px(8)) / S.PRESET_NAMES.length) - 1))
        visible: shown.length > 0
        spacing: Type.px(8)

        Text {
          text: group.modelData.jp + "  " + (group.shown.length === 1 ? group.modelData.title.replace(/^The /, "") : group.modelData.title).toUpperCase()
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackLabel
          // Never wider than its cards: "The seal only" sits over one.
          width: Math.min(implicitWidth, cards.width)
          elide: Text.ElideRight
        }
        Row {
          id: cards
          spacing: Type.px(8)
          Repeater {
            model: group.shown
            Rectangle {
              id: swatch
              required property string modelData
              readonly property bool open: modelData === root.open
              readonly property bool used: modelData === root.doc.preset
              width: group.cardWidth
              height: Type.px(118)
              radius: 3
              color: open ? Ink.bone : swatchHover.containsMouse ? Ink.lineSoft : "transparent"
              border.width: 1
              border.color: open ? Ink.bone : used ? Ink.lineStrong : Ink.line

              Text {
                x: Type.px(8)
                y: Type.px(7)
                text: String(S.PRESET_NAMES.indexOf(swatch.modelData) + 1).padStart(2, "0")
                color: swatch.open ? Ink.boneInk : Ink.inkFaint
                opacity: swatch.open ? 0.6 : 1
                font.family: Type.mono
                font.pixelSize: Type.tag
                font.letterSpacing: 1
              }
              // On your bar: red, as everything that is you.
              Rectangle {
                visible: swatch.used
                anchors.right: parent.right
                anchors.rightMargin: Type.px(8)
                y: Type.px(10)
                width: Type.px(6)
                height: width
                radius: width / 2
                color: Ink.seal
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Type.px(26)
                text: Settings.PRESET_KANJI[swatch.modelData] || ""
                color: swatch.open ? Ink.boneInk : swatch.used ? Ink.seal : Ink.ink
                font.family: Type.jp
                font.pixelSize: Type.px(Settings.PRESET_KANJI[swatch.modelData] && Settings.PRESET_KANJI[swatch.modelData].length > 1 ? 26 : 32)
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Type.px(12)
                text: swatch.modelData
                color: swatch.open ? Ink.boneInk : Ink.inkDim
                font.family: Type.display
                font.pixelSize: Type.px(16)
                font.weight: Font.Normal
                font.variableAxes: Type.axes(Type.px(16))
              }
              MouseArea {
                id: swatchHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                readonly property bool keyStop: enabled
                readonly property bool keyChosen: swatch.open
                function keyPress() { root.viewed = swatch.modelData }
                onClicked: root.viewed = swatch.modelData
                onDoubleClicked: root.presetPicked(swatch.modelData)
              }
            }
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(30) }

  // ------------------------------------------------------------ the pattern
  Item {
    width: parent.width
    height: Math.max(patternHead.height, useBox.height)
    Column {
      id: patternHead
      width: parent.width - useBox.width - Type.px(24)
      spacing: Type.px(4)
      Row {
        spacing: Type.px(14)
        Text {
          id: patternNo
          text: String(root.number).padStart(2, "0")
          color: Ink.inkFaint
          font.family: Type.display
          font.pixelSize: Type.px(root.compact ? 30 : 40)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(root.compact ? 30 : 40))
        }
        Text {
          anchors.baseline: patternNo.baseline
          text: root.open
          color: Ink.ink
          font.family: Type.display
          font.pixelSize: Type.px(root.compact ? 24 : 30)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(root.compact ? 24 : 30))
        }
        Text {
          anchors.baseline: patternNo.baseline
          text: Settings.PRESET_KANJI[root.open] || ""
          color: Ink.inkMuted
          font.family: Type.jp
          font.pixelSize: Type.px(20)
        }
      }
      Text {
        width: parent.width
        wrapMode: Text.Wrap
        text: (Settings.PRESET_BLURBS[root.open] || "").replace(/^./, function(c) { return c.toUpperCase() }) + ". " + Settings.presetFacts(root.openStyle) + "."
        color: Ink.inkMuted
        font.family: Type.text
        font.pixelSize: Type.row
      }
    }
    Column {
      id: useBox
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Type.px(4)
      spacing: Type.px(6)
      SmallButton {
        anchors.right: parent.right
        visible: !root.inUse
        plate: true
        label: "Use " + root.open
        onClicked: root.presetPicked(root.open)
      }
      Row {
        anchors.right: parent.right
        visible: root.inUse
        spacing: Type.px(8)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(6); height: width; radius: width / 2; color: Ink.seal }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "ON YOUR BAR" + (root.edits ? " · " + root.edits + (root.edits === 1 ? " EDIT" : " EDITS") + " ON TOP" : "")
          color: Ink.ink
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackLabel
        }
      }
    }
  }

  Item { width: 1; height: Type.px(16) }

  Galley {
    width: parent.width
    height: implicitHeight
    marks: false
    label: "PATTERN · " + root.open.toUpperCase() + ", SET AS YOUR BAR"
    style: root.openStyle
    barData: root.barData
    compact: root.compact
  }

  Item { width: 1; height: Type.px(26) }

  // ------------------------------------------------------- what would change
  SectionLabel {
    jp: "差"
    text: root.inUse && root.diff.length === 0
      ? "What changes · nothing, this is your bar"
      : root.inUse ? "Use it again and your edits go · " + root.diff.length
      : "What changes from your bar · " + root.diff.length
  }
  Item { width: 1; height: Type.px(6) }

  Grid {
    id: changes
    width: parent.width
    columns: width >= Type.px(820) ? 2 : 1
    columnSpacing: Type.px(28)
    readonly property real cellWidth: (width - (columns - 1) * columnSpacing) / columns
    Repeater {
      model: root.diff
      Item {
        id: change
        required property var modelData
        width: changes.cellWidth
        height: Type.px(34)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.lineSoft }
        Text {
          id: changeNo
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(26)
          text: change.modelData.no
          color: Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: 1
        }
        Text {
          id: changeName
          x: changeNo.width
          anchors.verticalCenter: parent.verticalCenter
          text: change.modelData.name
          color: Ink.inkDim
          font.family: Type.text
          font.pixelSize: Type.px(13)
        }
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Type.px(10)
          Text {
            text: change.modelData.from
            color: Ink.inkFaint
            font.family: Type.mono
            font.pixelSize: Type.px(11)
            font.strikeout: true
          }
          Text { text: "→"; color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.px(11) }
          Text {
            text: change.modelData.to
            color: Ink.ink
            font.family: Type.mono
            font.pixelSize: Type.px(11)
            font.letterSpacing: 0.5
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(16) }
  Text {
    width: Math.min(parent.width, Type.px(820))
    wrapMode: Text.Wrap
    text: "Stays yours: the seal " + root.doc.sealGlyph + ", type size, motion, the parts you set aside, and each screen's own settings"
      + (root.open === "Shōji" ? ". Shōji also puts every sheet in its washi hand and frames the overview." : ", and your sheet hands.")
      + " Double-click a swatch to use it at once."
    color: Ink.inkMuted
    font.family: Type.text
    font.pixelSize: Type.note
  }
}
