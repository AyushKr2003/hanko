pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs
import "../../core/Time.js" as T

// 06 // INBOX: your notifications as letters, each stamped by the app that
// sent it (solid red when urgent, grey under do not disturb).
ScrollSection {
  id: root

  property var letters: []
  property bool dnd: false
  property date now: new Date()

  signal request(string what, var arg)

  readonly property var shown: letters.slice(0, 4)

  title: T.counted(letters.length, "letter", "letters")
  caption: dnd ? "Quiet · do not disturb is on" : "Stamped by the app that sent them"

  Column {
    width: parent.width
    topPadding: Type.px(18)

    Repeater {
      model: root.shown
      ListRow {
        id: letter
        required property var modelData
        required property int index
        position: letter.index
        ruled: letter.index > 0
        name: modelData.app || modelData.summary
        detail: (modelData.app ? modelData.summary : "") + (modelData.body ? (modelData.app ? " · " : "") + modelData.body.replace(/\s+/g, " ") : "")
        note: StatusJs.age(modelData.timestamp, root.now.getTime())
        upperNote: false
        leading: Component {
          Rectangle {
            width: Type.px(22)
            height: Type.px(22)
            rotation: letter.modelData.tilt
            radius: 2
            color: letter.modelData.urgent ? Ink.seal : "transparent"
            border.width: 1
            border.color: root.dnd ? Ink.inkFaint : Ink.seal
            Text {
              anchors.centerIn: parent
              text: letter.modelData.glyph
              color: letter.modelData.urgent ? Ink.paper : root.dnd ? Ink.inkFaint : Ink.seal
              font.family: /[　-鿿]/.test(letter.modelData.glyph) ? Type.jpSerif : Type.display
              font.pixelSize: Type.px(12)
            }
          }
        }
      }
    }
  }
}
