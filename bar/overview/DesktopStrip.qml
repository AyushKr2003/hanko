pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// The desktop strip along the top of the dynamic overview (Ryoku's): one
// card per desktop that holds workspaces (a block of ten ids), its number
// and a dot per workspace (filled when it has windows), then one NEW card
// with a + to start a desktop. The live desktop and the viewed one wear
// the seal red; every card has a small hard shadow. Dragging a
// window onto a card moves it to that desktop (DynamicView does the hit
// test; the card only shows `dropHot`).
Row {
  id: strip
  property var view: null
  spacing: Type.px(14)

  Repeater {
    model: strip.view ? strip.view.desks : []
    Item {
      id: card
      required property var modelData
      required property int index
      readonly property int desk: card.modelData
      readonly property var dots: strip.view ? strip.view.dotsOf(card.desk) : []
      readonly property bool isNew: card.dots.length === 0 && card.desk !== (strip.view ? strip.view.activeDesk : -1)
      readonly property bool viewed: !!strip.view && strip.view.viewedDesk === card.desk
      readonly property bool live: !!strip.view && strip.view.activeDesk === card.desk
      readonly property bool dropHot: !!strip.view && strip.view.dragging && strip.view.dragDesk === card.desk
      property bool hovered: false
      readonly property bool lit: card.viewed || card.live || card.hovered || card.dropHot

      width: strip.view ? strip.view.deskW : Type.px(122)
      height: strip.view ? strip.view.deskH : Type.px(58)

      Rectangle {
        x: Type.px(3); y: Type.px(3)
        width: face.width; height: face.height
        color: "#000000"
        opacity: card.live ? 0.5 : 0.32
        antialiasing: false
      }

      Rectangle {
        id: face
        anchors.fill: parent
        color: Qt.tint(strip.view ? strip.view.cardColor : Ink.paper, card.dropHot || card.viewed || card.live ? Ink.alpha(Ink.seal, 0.09) : "transparent")
        border.width: card.viewed || card.live || card.dropHot ? 2 : 1
        border.color: card.dropHot || card.live || card.viewed ? Ink.seal
          : card.hovered ? Ink.lineStrong
          : Ink.line
        Behavior on border.color { enabled: !Motion.still; ColorAnimation { duration: 90 } }

        Column {
          anchors.centerIn: parent
          spacing: Type.px(7)
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.isNew ? "NEW" : ("0" + (card.desk + 1)).slice(-2)
            color: card.live ? Ink.seal : card.isNew ? Ink.inkFaint : Ink.ink
            font.family: Type.mono
            font.pixelSize: Type.px(13)
            font.letterSpacing: Type.px(2)
            font.weight: Font.DemiBold
          }
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Type.px(4)
            visible: !card.isNew
            Repeater {
              model: card.dots
              Rectangle {
                required property var modelData
                width: Type.px(6); height: width; radius: width / 2
                color: modelData ? (card.live ? Ink.seal : Ink.ink) : Ink.inkFaint
              }
            }
          }
          Item {
            visible: card.isNew
            anchors.horizontalCenter: parent.horizontalCenter
            width: Type.px(14); height: width
            Rectangle { anchors.centerIn: parent; width: Type.px(13); height: Type.px(2); radius: 1; color: card.lit ? Ink.seal : Ink.inkFaint }
            Rectangle { anchors.centerIn: parent; width: Type.px(2); height: Type.px(13); radius: 1; color: card.lit ? Ink.seal : Ink.inkFaint }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: card.hovered = true
          onExited: card.hovered = false
          onClicked: {
            if (!strip.view) return
            if (card.isNew) strip.view.newDesktop(card.desk)
            else strip.view.showDesk(card.desk)
          }
        }
      }
    }
  }
}
