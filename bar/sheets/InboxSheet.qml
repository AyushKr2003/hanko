pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Status.js" as StatusJs

// Inbox 報: your notifications as stamped letters, newest first: what it
// says, who sent it, how long ago, and the app's seal tilted in the corner
// (solid red when urgent). A letter that runs past its row opens in place
// on a click; its × puts it away (Delete, for the open one). At the foot:
// do not disturb, replaying recent ones as toasts, and clearing them all.
Item {
  id: root

  // core/Status.js notifications() shapes, newest first.
  property var letters: []
  property bool dnd: false
  property date now: new Date()
  property int maxRows: 6

  // what: dnd | replay | clear | open (arg: a stem, "" to fold it) |
  // putAway (arg: the letter)
  signal request(string what, var arg)

  // The stem of the letter opened in place (SheetView keeps it).
  property string openStem: ""

  readonly property var shown: letters.slice(0, maxRows)

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead {
      sheet: "inbox"
      jp: "報"
      label: "Inbox · " + StatusJs.count2(root.letters.length)
      title: "Inbox"
      blurb: root.dnd ? "Quiet: do not disturb is on, letters still arrive."
        : root.letters.length === 0 ? "Nothing new. Enjoy it."
        : root.letters.length === 1 ? "One letter, waiting."
        : root.letters.length + " letters, newest first."
    }

    GroupHead {
      title: "Letters"
      summary: root.letters.length > root.maxRows ? root.maxRows + " of " + root.letters.length : root.letters.length + " in all"
    }

    SheetRow {
      visible: root.letters.length === 0
      name: "No letters"
      detail: "Notifications land here as they arrive."
      last: true
    }

    Repeater {
      model: root.shown
      SheetRow {
        id: letter
        required property var modelData
        required property int index
        readonly property bool open: modelData.stem === root.openStem
        name: modelData.summary || modelData.app
        detail: (modelData.app ? modelData.app : "") + (modelData.body ? " · " + (open ? modelData.body : modelData.body.replace(/\s+/g, " ")) : "")
        // The row less its margins and the seal, age and × on the right.
        nameWidth: column.width - Type.px(20) - Type.px(12) - Type.px(100)
        last: index === root.shown.length - 1
        wrap: open
        interactive: cut || open
        trailingOnTop: true
        onClicked: root.request("open", open ? "" : modelData.stem)

        // The app's seal, tilted like a stamp on an envelope, how long
        // ago, and the × that puts the letter away.
        Row {
          spacing: Type.px(10)
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
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
          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Type.px(28)
            horizontalAlignment: Text.AlignRight
            text: StatusJs.age(letter.modelData.timestamp, root.now.getTime())
            color: Ink.inkDim
            font.family: Type.mono
            font.pixelSize: Type.label
            font.weight: Type.labelWeight
            font.letterSpacing: Type.trackLabel
          }
          PutAway {
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.request("putAway", letter.modelData)
          }
        }
      }
    }
  }

  // Delete puts the open letter away.
  Keys.onPressed: function(event) {
    if (event.key !== Qt.Key_Delete || root.openStem === "") return
    var l = root.letters.filter(function(x) { return x.stem === root.openStem })[0]
    if (l) root.request("putAway", l)
    event.accepted = true
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom

    SheetButton {
      text: "Quiet"
      on: root.dnd
      onClicked: root.request("dnd", null)
    }
    SheetButton {
      ghost: true
      text: "Replay"
      onClicked: root.request("replay", null)
    }
    SheetButton {
      plate: true
      text: "Clear all"
      onClicked: root.request("clear", null)
    }
  }
}
