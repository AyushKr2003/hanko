pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// One tanzaku 短冊: the tall paper slip a poem is written on and hung up,
// here one choice on a sheet. It hangs from the rail by a short cord; its
// mark (a kanji) stands at the head, its name runs down it sideways (Latin
// turned, as vertical Japanese sets it), and a short figure sits upright at
// its foot (tate-chū-yoko). How far it hangs is its level (volume, signal,
// charge); a slip with no level hangs at rest. The one in use is inked, with
// a small red seal pressed at its foot. Under the pointer it swings a little
// on its cord, as paper does.
Item {
  id: root

  property string mark: ""
  property string name: ""
  property string foot: ""
  property real level: -1
  property bool selected: false
  property bool urgent: false
  property bool dashed: false
  property bool interactive: true
  // The longest a slip hangs; the rail sets it for all.
  property real reach: Type.px(220)

  signal clicked()

  // Te 手 (core/Cursor.js): the keyboard lands on a slip you can pick.
  readonly property bool keyStop: interactive
  readonly property bool keyChosen: selected
  function keyPress() { root.clicked() }

  readonly property real cord: Type.px(12)
  readonly property real shortest: reach * 0.5
  readonly property real paperLength: level >= 0 ? shortest + (reach - shortest) * Math.max(0, Math.min(1, level)) : reach * 0.8
  readonly property color ink: selected ? Ink.boneInk : Ink.ink
  readonly property color soft: selected ? Ink.alpha(Ink.boneInk, 0.65) : Ink.inkMuted

  width: Type.px(40)
  height: cord + reach + Type.px(8)

  Item {
    id: slip
    width: root.width
    height: root.cord + root.paperLength
    transformOrigin: Item.Top
    rotation: hover.containsMouse && root.interactive && !root.selected ? 1.8 : 0
    Behavior on rotation { enabled: Motion.live; NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
    Behavior on height { enabled: Motion.live; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // The cord.
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: root.cord; color: Ink.lineStrong }

    Rectangle {
      id: paper
      y: root.cord
      width: parent.width
      height: root.paperLength
      radius: 1
      color: root.selected ? Ink.bone : Ink.alpha(Ink.bone, hover.containsMouse && root.interactive ? 0.07 : 0.035)
      border.width: 1
      border.color: root.selected ? Ink.bone : root.dashed ? "transparent" : Ink.line

      // A muted slip is drawn dashed, like a crease.
      Repeater {
        model: root.dashed ? Math.floor(paper.height / Type.px(8)) : 0
        Rectangle { required property int index; y: index * Type.px(8); width: 1; height: Type.px(4); color: Ink.lineStrong }
      }
      Repeater {
        model: root.dashed ? Math.floor(paper.height / Type.px(8)) : 0
        Rectangle { required property int index; x: paper.width - 1; y: index * Type.px(8); width: 1; height: Type.px(4); color: Ink.lineStrong }
      }

      Text {
        id: markText
        visible: root.mark !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        y: Type.px(8)
        text: root.mark
        color: root.urgent && !root.selected ? Ink.seal : root.soft
        font.family: Type.brush
        font.pixelSize: Type.px(16)
      }

      // The name, down the slip.
      Item {
        id: nameBox
        anchors.horizontalCenter: parent.horizontalCenter
        y: (root.mark !== "" ? markText.y + markText.height + Type.px(6) : Type.px(10))
        width: nameText.implicitHeight
        height: Math.max(0, paper.height - y - (root.foot !== "" ? Type.px(34) : Type.px(10)))
        clip: true
        Text {
          id: nameText
          width: nameBox.height
          height: implicitHeight
          x: (nameBox.width - width) / 2
          y: (nameBox.height - height) / 2
          rotation: 90
          elide: Text.ElideRight
          text: root.name
          color: root.ink
          font.family: Type.text
          font.pixelSize: Type.note
          font.weight: Type.valueWeight
          font.variableAxes: Type.valueAxes
        }
      }

      // The figure, upright at the foot.
      Text {
        visible: root.foot !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.selected ? Type.px(20) : Type.px(9)
        width: parent.width - Type.px(4)
        horizontalAlignment: Text.AlignHCenter
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: Type.px(8)
        text: root.foot
        color: root.soft
        font.family: Type.mono
        font.pixelSize: Type.tag
      }

      // The seal on the one in use (red means you, now).
      Rectangle {
        visible: root.selected || root.urgent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.selected ? Type.px(6) : -Type.px(5)
        width: Type.px(10)
        height: width
        radius: 1
        rotation: -6
        color: Ink.seal
      }
    }
  }

  MouseArea {
    id: hover
    x: 0
    y: root.cord
    width: root.width
    height: root.paperLength
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
