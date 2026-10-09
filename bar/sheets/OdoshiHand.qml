pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Odoshi 縅, armour lacing. The sheet hangs like the shoulder guard (sode)
// of a great armour: a crown plate (kanmuri-ita) with a fine inner border
// carries the sheet's reading, and when that reading has a level its own
// lame is laced under it in scarlet (hi-odoshi, the lacing of rank). Every
// other level is a lame of small scales laced in ink as far as its level
// (kebiki) and sparsely beyond (sugake); urgent ones are laced scarlet.
// Choices are lames too: the one in use laced in full and cross-knotted
// red along its foot (hishinui), as an armour's last plate is; the rest
// bare. A click on a lame you can set laces it to that scale; a click on
// any other lame does what its row does.
HandSheet {
  id: root
  setHint: "Click a scale to lace to it"

  // The crown plate.
  Rectangle {
    width: root.inner
    height: Type.px(72)
    radius: Type.px(3)
    color: Ink.alpha(Ink.bone, 0.05)
    border.width: 1
    border.color: Ink.lineStrong
    // The plate's printed-leather border (egawa): a fine inner rule.
    Rectangle { anchors.fill: parent; anchors.margins: Type.px(4); color: "transparent"; border.width: 1; border.color: Ink.lineSoft; radius: 2 }
    Text {
      id: crest
      x: Type.px(16)
      anchors.verticalCenter: parent.verticalCenter
      text: root.hero.mark
      color: Ink.seal
      font.family: Type.brush
      font.pixelSize: Type.px(34)
    }
    Row {
      id: figure
      x: crest.x + crest.width + Type.px(12)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(2)
      Text {
        text: root.hero.figure
        color: root.hero.red ? Ink.seal : Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(38)
        font.weight: Font.Normal
        font.variableAxes: Type.axes(Type.px(38), 380)
        font.features: { "tnum": 1 }
      }
      Text {
        visible: text !== ""
        y: Type.px(7)
        text: root.hero.unit
        color: Ink.inkMuted
        font.family: Type.display
        font.pixelSize: Type.px(14)
      }
    }
    Column {
      x: figure.x + figure.width + Type.px(14)
      width: parent.width - x - Type.px(14)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Type.px(2)
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
      Text {
        width: parent.width
        elide: Text.ElideRight
        visible: text !== ""
        text: (root.hero.rank && root.hero.level >= 0 ? root.hero.name + " · laced to the level" : root.hero.caption).toUpperCase()
        color: root.hero.red ? Ink.seal : Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
    }
  }
  Lame {
    visible: root.hero.rank && root.hero.level >= 0
    width: root.inner
    level: Math.max(0, root.hero.level)
    count: root.hero.scales || 0
    tint: Ink.seal
    settable: !!root.hero.set
    onPicked: function(v) { root.request(root.hero.set.what, Math.max(root.hero.min, v)) }
  }
  Item { width: 1; height: Type.px(14) }

  // Every other level: a lame laced as far as it goes.
  Repeater {
    model: root.model.levels
    Plate {
      id: lv
      required property var modelData
      r: modelData
      Lame {
        width: root.inner
        level: Math.max(0, lv.r.level)
        tint: lv.r.urgent ? Ink.seal : Ink.ink
        stitched: lv.r.selected
        dashed: lv.r.dashed || lv.r.muted
        settable: !!lv.r.set
        onPicked: function(v) { root.pick(lv.r, v) }
        onScaleClicked: if (!lv.r.set) root.act(lv.r.click)
      }
    }
  }

  // The choices: inline ones on one lame of named scales (a week), the rest
  // a lame each, the one in use laced in full and knotted.
  Item { width: 1; height: Type.px(4); visible: root.model.choices.length > 0 && root.model.levels.length > 0 }
  Row {
    visible: root.model.choices.length > 0
    spacing: Type.px(8)
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.model.choicesMark; color: Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(12) }
    Text { anchors.verticalCenter: parent.verticalCenter; text: root.model.choicesLabel.toUpperCase(); color: Ink.inkMuted; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackTag }
  }
  Item { width: 1; height: Type.px(6); visible: root.model.choices.length > 0 }
  Item {
    visible: root.model.inline && root.model.choices.length > 0
    width: root.inner
    height: visible ? week.height + Type.px(22) + Type.px(8) : 0
    // The day's kanji over its scale.
    Repeater {
      model: root.model.inline ? root.model.choices : []
      Text {
        required property var modelData
        required property int index
        x: index * root.inner / root.model.choices.length
        width: root.inner / root.model.choices.length
        horizontalAlignment: Text.AlignHCenter
        text: modelData.mark
        color: modelData.selected ? Ink.seal : modelData.dashed ? Ink.inkMuted : Ink.ink
        font.family: Type.brush
        font.pixelSize: Type.px(14)
      }
    }
    Lame {
      id: week
      y: Type.px(22)
      width: root.inner
      marks: root.model.inline ? root.model.choices.map(function(c) {
        return { laced: c.dashed || c.selected, red: c.selected, label: c.name }
      }) : []
      tint: Ink.inkDim
      onScaleClicked: function(i) { root.act(root.model.choices[i].click) }
    }
  }
  Repeater {
    model: root.model.inline ? [] : root.model.choices
    Plate {
      id: ch
      required property var modelData
      r: modelData
      Lame {
        width: root.inner
        level: ch.r.selected ? 1 : 0
        tint: Ink.ink
        stitched: ch.r.selected
        dashed: ch.r.dashed
        onScaleClicked: root.act(ch.r.click)
      }
    }
  }

  // A lame's head: its mark and name, its figure or note at the right.
  component Plate: Column {
    id: plate
    property var r: null
    width: root.inner
    spacing: Type.px(4)
    bottomPadding: Type.px(8)
    Item {
      width: parent.width
      height: Type.px(16)
      Row {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - note.width - Type.px(12)
        spacing: Type.px(8)
        Text { anchors.verticalCenter: parent.verticalCenter; text: plate.r.mark; color: plate.r.urgent ? Ink.seal : Ink.inkMuted; font.family: Type.brush; font.pixelSize: Type.px(12) }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, parent.width - Type.px(24))
          elide: Text.ElideRight
          text: plate.r.name + (plate.r.detail !== "" && plate.r.level < 0 ? "  ·  " + plate.r.detail : "")
          color: plate.r.selected ? Ink.ink : Ink.inkDim
          font.family: Type.text
          font.pixelSize: Type.px(13)
        }
      }
      Text {
        id: note
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: String(plate.r.muted ? "muted" : plate.r.level >= 0 ? plate.r.figure : plate.r.note).toUpperCase()
        color: plate.r.selected || plate.r.urgent ? Ink.seal : Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackTag
      }
    }
  }
}
