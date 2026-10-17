pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Overview.js" as O

// The workspace overview 一覧, laid on a sheet of the theme's paper over the
// desk: a register line and a serif title, the group's workspaces as pages
// in a fixed grid (core/Overview.js; rows with nothing on them folded
// away), and the keys along the foot. Pure QtQuick: bar/OverviewWindow.qml
// feeds it Hyprland's state and turns its signals into dispatches; the
// harness renders it still.
Item {
  id: root

  // core/Overview.js pages(), the grid's columns, the monitor's aspect
  // (height / width) and this screen's name.
  property var pages: []
  property int columns: O.COLUMNS
  property real aspect: 0.5625
  property string screenName: ""
  property date now: new Date()
  property string timeFormat: "HH:mm"
  // Room the bar keeps at the top (or bottom) of the screen.
  property int topInset: 0
  property int bottomInset: 0
  // Builds a window's live snapshot (OverviewWindow); null draws ink.
  property Component snapshot: null
  // 0..1: the sheet and the pages print in.
  property real reveal: 1

  signal pagePicked(int id)
  signal windowPicked(string address)
  signal windowClosed(string address)
  signal windowMoved(string address, int id)
  signal dismissed()

  // ------------------------------------------------ dragging a window
  property bool dragging: false
  property string dragAddress: ""
  property string dragName: ""
  property int dragFrom: -1
  property int dragOver: -1
  property real dragX: 0
  property real dragY: 0
  function beginDrag(address, name, fromId) {
    dragAddress = address; dragName = name; dragFrom = fromId; dragging = true
  }
  function dragTo(x, y) {
    dragX = x; dragY = y
    dragOver = pageAt(x, y)
  }
  function drop() {
    if (dragOver > 0 && dragOver !== dragFrom) windowMoved(dragAddress, dragOver)
    dragging = false; dragAddress = ""; dragOver = -1; dragFrom = -1
  }
  function pageAt(x, y) {
    for (var i = 0; i < pages.length; i++) {
      var b = boxOf(pages[i])
      if (x >= grid.x + b.x && x <= grid.x + b.x + b.w && y >= grid.y + b.y && y <= grid.y + b.y + b.h) return pages[i].id
    }
    return -1
  }

  // ------------------------------------------------ geometry
  readonly property int margin: Type.px(width < Type.px(900) ? 20 : 56)
  readonly property int gap: Type.px(22)
  readonly property int headH: Type.px(30)
  readonly property real roomTop: topInset + head.height + Type.px(44)
  readonly property real roomBottom: height - bottomInset - foot.height - Type.px(40)
  readonly property var layout: O.fit(O.rowsShown(pages), columns, width - 2 * margin, roomBottom - roomTop,
                                      aspect, gap, headH, Type.px(300))
  function boxOf(p) {
    return { x: p.col * (layout.pageW + gap), y: p.row * (layout.pageH + gap), w: layout.pageW, h: layout.pageH }
  }

  // The sheet over the desk; a click on it (not on a page) dismisses.
  Rectangle {
    y: root.topInset
    width: parent.width
    height: parent.height - root.topInset - root.bottomInset
    color: Ink.alpha(Ink.paper, 0.94)
    opacity: root.reveal
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: root.dismissed()
    }
  }

  // ------------------------------------------------ head
  Item {
    id: head
    x: root.margin
    y: root.topInset + Type.px(30)
    width: root.width - 2 * root.margin
    height: titleColumn.height
    opacity: root.reveal

    Column {
      id: titleColumn
      spacing: Type.px(8)
      Row {
        spacing: Type.px(8)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Type.px(18); height: 1; color: Ink.ink }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "一覧"; color: Ink.seal; font.family: Type.jp; font.pixelSize: Type.label }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "·"; color: Ink.inkFaint; font.family: Type.text; font.pixelSize: Type.label }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "OVERVIEW" + (root.screenName ? "  ·  " + root.screenName : "")
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.eyebrow
          font.letterSpacing: Type.trackEyebrow
        }
      }
      Text {
        text: "Your desk, laid out"
        color: Ink.ink
        font.family: Type.display
        font.pixelSize: Type.px(34)
        font.variableAxes: Type.axes(Type.px(34))
      }
    }
    Column {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      spacing: Type.px(4)
      Text {
        anchors.right: parent.right
        text: Qt.formatTime(root.now, root.timeFormat)
        color: Ink.inkDim
        font.family: Type.display
        font.pixelSize: Type.px(22)
        font.variableAxes: Type.axes(Type.px(22))
      }
      Text {
        anchors.right: parent.right
        text: O.summary(root.pages)
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackLabel
      }
    }
  }

  // ------------------------------------------------ the pages
  Item {
    id: grid
    x: (root.width - root.layout.width) / 2
    y: root.roomTop + Math.max(0, (root.roomBottom - root.roomTop - root.layout.height) / 2)
    width: root.layout.width
    height: root.layout.height

    Repeater {
      model: root.pages
      OverviewPage {
        id: pageItem
        required property var modelData
        required property int index
        readonly property var box: root.boxOf(pageItem.modelData)
        x: pageItem.box.x
        y: pageItem.box.y
        width: pageItem.box.w
        height: pageItem.box.h
        opacity: Math.max(0, Math.min(1, root.reveal * 1.6 - pageItem.index * 0.05))
        scale: 0.97 + 0.03 * root.reveal
        page: pageItem.modelData
        headH: root.headH
        view: root
        snapshot: root.snapshot
        hot: root.dragging && root.dragOver === pageItem.modelData.id && root.dragOver !== root.dragFrom
      }
    }
  }

  // The window being carried: its name on a paper tab with an ink print.
  Item {
    visible: root.dragging
    x: root.dragX - width / 2
    y: root.dragY - height / 2
    width: ghostText.implicitWidth + Type.px(20)
    height: Type.px(30)
    z: 10
    Rectangle { x: Type.px(4); y: Type.px(4); width: parent.width; height: parent.height; color: Ink.ink }
    Rectangle {
      anchors.fill: parent
      color: Ink.paper
      border.width: 1
      border.color: Ink.ink
      Text {
        id: ghostText
        anchors.centerIn: parent
        text: root.dragName.toUpperCase()
        color: Ink.ink
        font.family: Type.mono
        font.pixelSize: Type.label
        font.letterSpacing: Type.trackLabel
      }
    }
  }

  // ------------------------------------------------ foot: the keys
  Row {
    id: foot
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height - root.bottomInset - height - Type.px(28)
    spacing: Type.px(22)
    opacity: root.reveal
    Repeater {
      model: O.KEYS
      Row {
        id: key
        required property var modelData
        spacing: Type.px(7)
        Text { text: key.modelData[0]; color: Ink.inkDim; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
        Text { text: key.modelData[1].toUpperCase(); color: Ink.inkFaint; font.family: Type.mono; font.pixelSize: Type.tag; font.letterSpacing: Type.trackLabel }
      }
    }
  }
}
