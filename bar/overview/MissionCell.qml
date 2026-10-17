pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Spaces.js" as Spaces

// One cell of the mission overview's strip: a workspace in small, its
// windows where they sit as hairline frames with their snapshots, and its
// folio under it (the number, its kanji, how many windows; the live one on
// a bone plate with a `//` lead, as the bar's folio is). The keyboard's pick
// wears the seal-red notch over it, a cell a window is carried onto a red
// frame. The trailing cell is the new space: a + in a hairline frame.
// A click switches there and keeps the overview open; a double click goes.
Item {
  id: cell

  property var view: null
  // "ws:<id>" or "new", and the workspace row (Hypr.workspaces) for ws.
  property string key: "new"
  property var space: null
  property bool live: false
  property bool selected: false
  property Component snapshot: null

  readonly property bool add: key === "new"
  readonly property int spaceId: add ? -1 : Number(key.slice(3))
  readonly property var windows: space ? (space.all || space.windows || []) : []
  readonly property bool hot: !!view && view.dragging && view.dragKey === cell.key
  property bool hovered: false
  readonly property real folioH: view ? view.folioH : Type.px(22)

  // The notch: the keyboard's pick (red means you).
  Rectangle {
    visible: cell.selected
    anchors.horizontalCenter: page.horizontalCenter
    anchors.bottom: page.top
    anchors.bottomMargin: Type.px(5)
    width: Type.px(18)
    height: Type.px(2)
    color: Ink.seal
  }

  Rectangle {
    id: page
    width: parent.width
    height: parent.height - cell.folioH
    color: cell.add ? "transparent" : Qt.tint(Ink.paper, Ink.alpha(Ink.ink, cell.live ? 0.06 : 0.03))
    clip: true

    Repeater {
      model: cell.windows.length
      Rectangle {
        id: mini
        required property int index
        readonly property var w: cell.windows[mini.index] || ({ x: 0, y: 0, w: 0, h: 0, address: "" })
        x: Math.round(mini.w.x * page.width) + 1
        y: Math.round(mini.w.y * page.height) + 1
        width: Math.max(2, Math.round(mini.w.w * page.width) - 2)
        height: Math.max(2, Math.round(mini.w.h * page.height) - 2)
        color: Qt.tint(Ink.paper, Ink.alpha(Ink.ink, 0.08))
        border.width: 1
        border.color: mini.w.focused ? Ink.lineStrong : Ink.line
        clip: true
        Loader {
          id: snap
          anchors.fill: parent
          anchors.margins: 1
          active: cell.snapshot !== null
          sourceComponent: cell.snapshot
        }
        Binding {
          when: snap.item !== null
          target: snap.item
          property: "address"
          value: mini.w.address
        }
      }
    }

    // A bare space: its kanji, faint, like an unprinted leaf.
    Text {
      visible: !cell.add && cell.windows.length === 0
      anchors.centerIn: parent
      text: Spaces.numeral(cell.spaceId)
      color: Ink.alpha(Ink.ink, cell.live ? 0.18 : 0.08)
      font.family: Type.jpSerif
      font.pixelSize: Math.min(page.height * 0.5, Type.px(34))
    }

    // The new space: a + in hairlines, NEW SPACE when a window is held here.
    Item {
      visible: cell.add
      anchors.fill: parent
      readonly property color mark: cell.hot || cell.hovered || cell.selected ? Ink.ink : Ink.inkFaint
      Rectangle { anchors.centerIn: parent; width: Type.px(18); height: 1; color: parent.mark; visible: !cell.hot }
      Rectangle { anchors.centerIn: parent; width: 1; height: Type.px(18); color: parent.mark; visible: !cell.hot }
      Rectangle {
        visible: cell.hot
        anchors.centerIn: parent
        width: newText.implicitWidth + Type.px(14)
        height: newText.implicitHeight + Type.px(6)
        color: Ink.bone
        Text {
          id: newText
          anchors.centerIn: parent
          text: "NEW SPACE"
          color: Ink.boneInk
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
      }
    }
  }

  // The frame, over the snapshots.
  Rectangle {
    anchors.fill: page
    color: "transparent"
    border.width: cell.hot || cell.live ? 2 : 1
    border.color: cell.hot ? Ink.seal : cell.live ? Ink.ink : cell.hovered || cell.selected ? Ink.lineStrong : Ink.line
  }

  // The folio.
  Item {
    y: page.height
    width: parent.width
    height: cell.folioH
    Rectangle {
      id: folio
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: Type.px(2)
      width: folioRow.width + Type.px(cell.live ? 12 : 0)
      height: cell.folioH - Type.px(6)
      color: cell.live ? Ink.bone : "transparent"
      Row {
        id: folioRow
        anchors.centerIn: parent
        spacing: Type.px(5)
        Text {
          visible: cell.live
          anchors.verticalCenter: parent.verticalCenter
          text: "//"
          color: Ink.boneInk
          opacity: 0.55
          font.family: Type.mono
          font.pixelSize: Type.tag
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: cell.add ? "NEW" : Spaces.folio(cell.spaceId)
          color: cell.live ? Ink.boneInk : cell.add ? Ink.inkFaint : cell.windows.length > 0 ? Ink.ink : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.label
          font.weight: Font.Medium
          font.letterSpacing: Type.trackFigure
        }
      }
    }
    Text {
      visible: !cell.add
      anchors.left: folio.right
      anchors.leftMargin: Type.px(6)
      anchors.verticalCenter: folio.verticalCenter
      text: Spaces.numeral(cell.spaceId)
      color: Ink.inkMuted
      font.family: Type.jpSerif
      font.pixelSize: Type.label
    }
    Row {
      anchors.right: parent.right
      anchors.verticalCenter: folio.verticalCenter
      spacing: Type.px(4)
      Rectangle {
        visible: !!cell.space && !!cell.space.urgent
        anchors.verticalCenter: parent.verticalCenter
        width: Type.px(5); height: width; radius: width / 2
        color: Ink.seal
      }
      Text {
        visible: cell.windows.length > 0
        anchors.verticalCenter: parent.verticalCenter
        text: String(cell.windows.length)
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: cell.hovered = true
    onExited: cell.hovered = false
    onClicked: if (cell.view) cell.view.cellPicked(cell.key, false)
    onDoubleClicked: if (cell.view) cell.view.cellPicked(cell.key, true)
  }
}
