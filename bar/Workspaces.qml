pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Spaces.js" as SpacesJs

// Workspaces 頁, in four styles (docs/COMPONENTS.md):
//   folio   page numbers; the live one inverts with a // lead; dots count windows
//           (one bone plate slides to whichever page is live)
//   layout  each workspace drawn as its real tiling, focused window filled
//   kanji   壱 弐 参 with window dots; the live one inverts
//   dots    one dot each; the live one a short bar
// `spaces` is Hypr.spacesFor(): [{ id, active, urgent, count, windows }].
Item {
  id: root

  property string mode: "layout"
  property var spaces: []
  property int barHeight: 40

  signal activated(int id)
  signal stepped(int delta)
  // Right-click: the workspace overview 一覧.
  signal overviewRequested()

  readonly property bool compact: barHeight <= Type.px(32)
  // The live workspace's cell; folio and kanji invert it with one plate
  // that slides from page to page (Motion.slide), like Ryoku's rail.
  // Reported by the cells themselves (see Segmented.qml for why).
  property Item liveCell: null
  function note(item: Item, on: bool) {
    if (on) liveCell = item
    else if (liveCell === item) liveCell = null
  }
  readonly property bool plated: mode === "folio" || mode === "kanji"

  visible: mode !== "none"
  implicitWidth: row.implicitWidth
  implicitHeight: barHeight

  Rectangle {
    id: plate
    visible: root.plated && root.liveCell !== null
    x: row.x + (root.liveCell ? root.liveCell.x : 0)
    y: row.y + (root.liveCell ? root.liveCell.y : 0)
    width: root.liveCell ? root.liveCell.width : 0
    height: root.liveCell ? root.liveCell.height : 0
    radius: root.mode === "kanji" ? 3 : 2
    color: Ink.bone
    Behavior on x { enabled: Motion.live; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: Motion.live; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.mode === "folio" ? Type.px(2) : root.mode === "kanji" ? Type.px(3) : Type.px(7)

    Repeater {
      model: root.spaces

      Item {
        id: cell
        required property var modelData
        readonly property bool on: modelData.active
        onOnChanged: root.note(cell, cell.on)
        Component.onCompleted: root.note(cell, cell.on)
        Component.onDestruction: if (root.liveCell === cell) root.liveCell = null
        readonly property bool occupied: modelData.count > 0

        implicitWidth: loader.implicitWidth
        implicitHeight: loader.implicitHeight
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Loader {
          id: loader
          sourceComponent: root.mode === "folio" ? folioCell
            : root.mode === "kanji" ? kanjiCell
            : root.mode === "dots" ? dotCell
            : glyphCell
          onLoaded: item.ws = Qt.binding(function() { return cell.modelData })
        }

        MouseArea {
          anchors.fill: parent
          anchors.margins: -2
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.overviewRequested()
            else root.activated(cell.modelData.id)
          }
        }
      }
    }
  }

  // Scroll anywhere on the workspaces to walk them.
  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function(event) { root.stepped(event.angleDelta.y > 0 ? -1 : 1) }
  }

  // ------------------------------------------------------------ folio
  Component {
    id: folioCell

    Rectangle {
      id: fc
      property var ws: null
      readonly property bool on: !!(ws && ws.active)
      readonly property bool occupied: !!(ws && ws.count > 0)
      implicitWidth: Math.max(Type.px(30), label.implicitWidth + Type.px(on ? 18 : 12))
      implicitHeight: Type.px(root.compact ? 20 : 22)
      radius: 2
      color: "transparent"

      Row {
        id: label
        anchors.centerIn: parent
        spacing: Type.px(5)
        Text {
          visible: fc.on
          text: "//"
          color: Ink.boneInk
          opacity: 0.55
          font.family: Type.mono
          font.pixelSize: Type.px(11)
        }
        Text {
          text: fc.ws ? SpacesJs.folio(fc.ws.id) : ""
          color: fc.on ? Ink.boneInk : fc.occupied ? Ink.inkDim : Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.px(11)
          font.weight: fc.on ? Font.DemiBold : Font.Normal
          font.letterSpacing: 1.2
        }
      }

      WindowDots {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        count: fc.on || !fc.ws ? 0 : fc.ws.count
        color: fc.occupied ? Ink.inkDim : Ink.inkFaint
      }

      UrgentDot { visible: !!(fc.ws && fc.ws.urgent); x: fc.width - width - 3; y: 3 }
    }
  }

  // ------------------------------------------------------------ layout
  Component {
    id: glyphCell

    Item {
      id: lc
      property var ws: null
      readonly property bool on: !!(ws && ws.active)
      readonly property bool empty: !ws || ws.windows.length === 0
      implicitWidth: empty ? Type.px(10) : Type.px(24)
      implicitHeight: Type.px(15)

      // An empty workspace is a faint point.
      Rectangle {
        visible: lc.empty
        anchors.centerIn: parent
        width: Type.px(3); height: width; radius: width / 2
        color: lc.on ? Ink.ink : Ink.inkFaint
      }

      Rectangle {
        id: frame
        visible: !lc.empty
        anchors.fill: parent
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: lc.on ? Ink.ink : Ink.line

        Repeater {
          model: lc.ws ? lc.ws.windows : []
          Rectangle {
            required property var modelData
            readonly property bool live: lc.on
            x: 1 + Math.round(modelData.x * (frame.width - 2)) + 1
            y: 1 + Math.round(modelData.y * (frame.height - 2)) + 1
            width: Math.max(1, Math.round(modelData.w * (frame.width - 2)) - 2)
            height: Math.max(1, Math.round(modelData.h * (frame.height - 2)) - 2)
            radius: 1
            color: live && modelData.focused ? Ink.ink : live ? Ink.alpha(Ink.ink, 0.22) : Ink.lineSoft
            border.width: 1
            border.color: live && modelData.focused ? Ink.ink : live ? Ink.inkMuted : Ink.line
          }
        }
      }

      UrgentDot { visible: !!(lc.ws && lc.ws.urgent); x: lc.width - width / 2 - 1; y: -height / 2 + 1; ring: true }
    }
  }

  // ------------------------------------------------------------ kanji
  Component {
    id: kanjiCell

    Rectangle {
      id: kc
      property var ws: null
      readonly property bool on: !!(ws && ws.active)
      implicitWidth: Type.px(root.compact ? 22 : 24)
      implicitHeight: implicitWidth
      radius: 3
      color: "transparent"

      Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: kc.ws ? SpacesJs.numeral(kc.ws.id) : ""
        color: kc.on ? Ink.boneInk : kc.ws && kc.ws.count > 0 ? Ink.inkDim : Ink.inkFaint
        font.family: Type.jpSerif
        font.pixelSize: Type.px(13.5)
      }

      WindowDots {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        count: kc.on || !kc.ws ? 0 : kc.ws.count
        color: Ink.inkDim
      }

      UrgentDot { visible: !!(kc.ws && kc.ws.urgent); x: kc.width - width - 2; y: 2 }
    }
  }

  // ------------------------------------------------------------ dots
  Component {
    id: dotCell

    Item {
      id: dc
      property var ws: null
      readonly property bool on: !!(ws && ws.active)
      readonly property bool occupied: !!(ws && ws.count > 0)
      implicitWidth: on ? Type.px(18) : Type.px(5)
      implicitHeight: Type.px(5)
      Behavior on implicitWidth { enabled: Motion.live; NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.fill: parent
        radius: dc.on ? 3 : width / 2
        color: dc.on ? Ink.ink : dc.occupied ? Ink.inkDim : "transparent"
        border.width: 1
        border.color: dc.on ? Ink.ink : dc.occupied ? Ink.inkDim : Ink.inkFaint
      }

      UrgentDot { visible: !!(dc.ws && dc.ws.urgent); x: dc.width; y: -height }
    }
  }

  component WindowDots: Row {
    id: dots
    property int count: 0
    property color color: Ink.inkDim
    spacing: 2
    Repeater {
      model: Math.min(dots.count, 5)
      Rectangle { width: 2; height: 2; color: dots.color; opacity: 0.7 }
    }
  }

  component UrgentDot: Rectangle {
    property bool ring: false
    width: Type.px(ring ? 5 : 4)
    height: width
    radius: width / 2
    color: Ink.seal
    border.width: ring ? 2 : 0
    border.color: Ink.paper
  }
}
