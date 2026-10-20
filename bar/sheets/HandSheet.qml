pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Hands.js" as Hands

// The frame every craft hand (Shōgi, Soroban, Odoshi, Kasumi) sits in:
// the eyebrow, the hand's own body, the quiet lines (zones, details), the
// hint, and the foot's buttons, all from one Hands.js model. Keys: Up/Down
// step the sheet's level, Left/Right and letters as the model says.
Item {
  id: root

  property var model: Hands.model("", {})
  // What the hand draws between the eyebrow and the lines.
  default property alias body: content.data
  // The hand's own hint for a row you can set ("Click a square to move it").
  property string setHint: ""
  signal request(string what, var arg)

  readonly property var hero: model.hero
  readonly property bool settable: !!hero.set || model.levels.some(function(r) { return !!r.set })
  readonly property string hint: [settable ? setHint : "", model.hint].filter(function(s) { return s !== "" }).join(" · ")
  readonly property real inner: width - 2 * Type.px(24)

  // A row asked for something: its own request, or its level picked.
  function act(o) { if (o) root.request(o.what, o.arg) }
  function pick(r, v) {
    if (!r || !r.set) return
    if (r.key === "hero") v = Math.max(hero.min, v)
    root.request(r.set.what, Hands.setArg(r.set, v))
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + (foot.visible ? foot.implicitHeight : 0)

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.inner
    bottomPadding: Type.px(18)

    SheetHead { sheet: root.model.sheet; jp: root.model.jp; label: root.model.label; compact: true }
    Item { width: 1; height: Type.px(16) }

    Column {
      id: content
      width: parent.width
    }

    Item { width: 1; height: Type.px(10); visible: root.model.lines.length > 0 }
    Flow {
      width: parent.width
      spacing: Type.px(18)
      visible: root.model.lines.length > 0
      Repeater {
        model: root.model.lines
        Text {
          required property string modelData
          text: modelData.toUpperCase()
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
      }
    }
    // The hint: what a click, the wheel or a key does here.
    Text {
      visible: root.hint !== ""
      width: parent.width
      topPadding: Type.px(10)
      horizontalAlignment: Text.AlignRight
      wrapMode: Text.Wrap
      text: root.hint
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.letterSpacing: Type.trackTag
      font.capitalization: Font.AllUppercase
      lineHeight: 1.3
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    visible: root.model.buttons.length > 0 || root.model.note !== ""
    note: root.model.note
    Repeater {
      model: root.model.buttons
      SheetButton {
        required property var modelData
        visible: modelData.visible !== false
        text: modelData.text
        on: !!modelData.on
        ghost: !!modelData.ghost
        plate: !!modelData.plate
        onClicked: root.act(modelData)
      }
    }
  }
  Keys.onPressed: function(event) {
    var letters = root.model.keys.letters
    var k = event.text.toUpperCase()
    if (k && letters[k]) { root.act(letters[k]); event.accepted = true }
  }
}
