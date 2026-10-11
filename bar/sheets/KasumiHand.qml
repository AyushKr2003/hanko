pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Kasumi 霞, mist bands. In Yamato-e picture scrolls and on gold screens,
// long flat bands of stylised mist (suyari-gasumi) laid in gold leaf part
// one scene from the next, and Rinpa screens leave much of the gold ground
// empty as sky. Here the sheet's reading heads the page with its kanji set
// large at the right like a title slip, its band the fullest gilt beneath
// it; every other level is a band drawn as far as its level, drifting in
// from alternate sides as mist does across an emaki. A choice in use is
// gilded the whole width and sealed red; the others are short, thin mist,
// as is anything muted. A week is a row of gold squares (shikishi), today
// sealed. Click or drag along a band you can set to draw it there.
HandSheet {
  id: root
  setHint: "Draw a band to set it"

  // The scene: the figure, and the kanji as a title slip at the right.
  Item {
    width: root.inner
    height: Type.px(96)
    Text {
      anchors.right: parent.right
      anchors.rightMargin: Type.px(6)
      y: Type.px(4)
      text: root.hero.mark
      color: root.hero.red ? Ink.seal : Ink.alpha(Ink.bone, 0.9)
      font.family: Type.brush
      font.pixelSize: Type.px(64)
    }
    Column {
      y: Type.px(8)
      width: parent.width - Type.px(96)
      spacing: Type.px(2)
      Row {
        spacing: Type.px(4)
        Text {
          text: root.hero.figure
          color: root.hero.red ? Ink.seal : Ink.ink
          font.family: Type.display
          font.pixelSize: Type.px(44)
          font.weight: Font.Normal
          font.variableAxes: Type.axes(Type.px(44), 380)
          font.features: { "tnum": 1 }
        }
        Text {
          visible: text !== ""
          y: Type.px(8)
          text: root.hero.unit
          color: Ink.inkMuted
          font.family: Type.display
          font.pixelSize: Type.px(16)
        }
      }
      Text {
        width: parent.width
        elide: Text.ElideRight
        text: root.hero.line
        color: Ink.ink
        font.family: Type.display
        font.italic: true
        font.pixelSize: Type.px(16)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(16), 360)
      }
    }
  }
  Item { width: 1; height: Type.px(4); visible: !lead.visible }
  Text {
    visible: !lead.visible && text !== ""
    text: root.hero.caption.toUpperCase()
    color: Ink.inkMuted
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }
  MistBand {
    id: lead
    visible: root.hero.rank && root.hero.level >= 0
    width: root.inner
    level: Math.max(0, root.hero.level)
    lead: true
    sealed: !root.hero.red
    gilt: !(root.hero.red && !!root.hero.set)
    name: root.hero.name
    note: root.hero.caption !== root.hero.name ? root.hero.caption : ""
    noteColor: root.hero.red ? Ink.seal : Ink.inkMuted
    settable: !!root.hero.set
    onPicked: function(v) { root.request(root.hero.set.what, Math.max(root.hero.min, v)) }
  }
  Item { width: 1; height: Type.px(14) }

  // Every other level, drifting in from alternate sides.
  Repeater {
    model: root.model.levels
    MistBand {
      required property var modelData
      required property int index
      width: root.inner
      fromRight: index % 2 === 0
      level: Math.max(0, modelData.level)
      gilt: !modelData.muted && !modelData.dashed
      sealed: modelData.selected || modelData.urgent
      name: modelData.name
      note: modelData.muted ? "muted" : modelData.figure
      noteColor: modelData.selected || modelData.urgent ? Ink.seal : Ink.inkMuted
      settable: !!modelData.set
      clickable: !!modelData.click
      onPicked: function(v) { root.pick(modelData, v) }
      onClicked: root.act(modelData.click)
    }
  }

  // The choices.
  Item { width: 1; height: Type.px(8); visible: root.model.choices.length > 0 }
  Row {
    visible: root.model.choices.length > 0
    spacing: Type.px(8)
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.model.choicesMark; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(12) }
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.model.choicesLabel.toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
  }
  Item { width: 1; height: Type.px(8); visible: root.model.choices.length > 0 }

  // A week: a row of gold squares, the days gone dimmer, today sealed.
  Row {
    id: week
    visible: root.model.inline && root.model.choices.length > 0
    readonly property real side: Math.min(Type.px(52), (root.inner - 6 * spacing) / Math.max(1, root.model.choices.length))
    spacing: Type.px(8)
    Repeater {
      model: root.model.inline ? root.model.choices : []
      Item {
        id: day
        required property var modelData
        width: week.side
        height: week.side + Type.px(18)
        Rectangle {
          width: week.side
          height: week.side
          radius: 2
          readonly property bool gone: day.modelData.dashed
          color: day.modelData.selected ? Ink.alpha(Ink.bone, 0.9) : gone ? Ink.alpha(Ink.bone, 0.28) : "transparent"
          border.width: 1
          border.color: day.modelData.selected || gone ? "transparent" : Ink.lineStrong
          Text {
            anchors.centerIn: parent
            text: day.modelData.mark
            color: day.modelData.selected ? Ink.boneInk : Ink.inkDim
            font.family: Type.brush
            font.pixelSize: Type.px(20)
          }
          Rectangle {
            visible: day.modelData.selected
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Type.px(4)
            width: Type.px(10); height: width; radius: 1
            color: Ink.seal
          }
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: week.side + Type.px(4)
          text: day.modelData.name
          color: day.modelData.selected ? Ink.seal : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
        MouseArea {
          anchors.fill: parent
          enabled: !!day.modelData.click
          cursorShape: Qt.PointingHandCursor
          onClicked: root.act(day.modelData.click)
        }
      }
    }
  }

  // Other choices: the one in use gilded whole and sealed, the rest thin mist.
  Repeater {
    model: root.model.inline ? [] : root.model.choices
    MistBand {
      required property var modelData
      required property int index
      width: root.inner
      fromRight: (index + root.model.levels.length) % 2 === 0
      level: modelData.selected ? 1 : 0.34
      gilt: modelData.selected
      sealed: modelData.selected
      name: modelData.name
      note: modelData.note
      noteColor: modelData.selected ? Ink.seal : Ink.inkMuted
      clickable: !!modelData.click
      onClicked: root.act(modelData.click)
    }
  }
}
