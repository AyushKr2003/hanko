pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../../core"
import "../../core/Spaces.js" as Spaces
import "../../core/Overview.js" as O

// One workspace in the overview, printed as a page: a folio band (the
// number, its kanji, how many windows; the live page's number inverted on
// a bone plate with a // lead, as the bar's folio does), then the screen
// with every window where it really sits, framed in hairlines, its live
// snapshot inside and its name on a paper tab. Every page lies on the desk
// like a sheet, with the short soft shadow style.lua gives Hyprland's windows
// ("paper"), cast in ink (light on a dark theme), stronger under the live page. Pure: OverviewView passes the data and takes
// the gestures.
Item {
  id: root

  // core/Overview.js pages() entry.
  property var page: ({ id: 1, active: false, urgent: false, count: 0, windows: [] })
  property real headH: Type.px(30)
  // The view, for dragging a window to another page.
  property var view: null
  // Builds a window's snapshot: a Component taking `address` (null in the
  // harness, which draws the ink fallback).
  property Component snapshot: null
  property bool hot: false

  readonly property bool live: page.active
  readonly property var windows: O.visibleWindows(page.windows)
  property bool hovered: false

  // The sheet's shadow on the desk, matched to style.lua's "paper" as
  // Hyprland draws it (range 14 at render_power 3 reads as a dense band,
  // then a short fade): offset 3, 5, a tight blur. Cast in the theme's ink
  // so it reads on the dark desk: 55% under the live page, 25% under the
  // rest, the shadow's color and color_inactive.
  RectangularShadow {
    anchors.fill: parent
    radius: sheet.radius
    offset.x: Type.px(3)
    offset.y: Type.px(5)
    blur: Type.px(4)
    spread: Type.px(2)
    color: Ink.alpha(Ink.ink, root.live ? 0.55 : 0.25)
    Behavior on color { ColorAnimation { duration: Motion.ink } }
  }

  Rectangle {
    id: sheet
    anchors.fill: parent
    color: Ink.paper
    border.width: root.hot || root.live ? 2 : 1
    border.color: root.hot ? Ink.seal : root.live ? Ink.ink : root.hovered ? Ink.lineStrong : Ink.line
    clip: true

    // ---------------------------------------------- the folio band
    Item {
      id: band
      width: parent.width
      height: root.headH

      Rectangle {
        id: folio
        x: Type.px(8)
        anchors.verticalCenter: parent.verticalCenter
        width: folioRow.width + Type.px(root.live ? 14 : 4)
        height: root.headH - Type.px(10)
        radius: 2
        color: root.live ? Ink.bone : "transparent"
        Row {
          id: folioRow
          anchors.centerIn: parent
          spacing: Type.px(5)
          Text {
            visible: root.live
            anchors.verticalCenter: parent.verticalCenter
            text: "//"
            color: Ink.boneInk
            opacity: 0.55
            font.family: Type.mono
            font.pixelSize: Type.label
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Spaces.folio(root.page.id)
            color: root.live ? Ink.boneInk : root.page.count > 0 ? Ink.ink : Ink.inkFaint
            font.family: Type.mono
            font.pixelSize: Type.value
            font.weight: Font.Medium
            font.letterSpacing: Type.trackFigure
          }
        }
      }
      Text {
        anchors.left: folio.right
        anchors.leftMargin: Type.px(8)
        anchors.verticalCenter: parent.verticalCenter
        text: Spaces.numeral(root.page.id)
        color: root.page.count > 0 || root.live ? Ink.inkDim : Ink.inkFaint
        font.family: Type.jpSerif
        font.pixelSize: Type.value
      }
      Row {
        anchors.right: parent.right
        anchors.rightMargin: Type.px(10)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(6)
        Rectangle {
          visible: root.page.urgent
          anchors.verticalCenter: parent.verticalCenter
          width: Type.px(5); height: width; radius: width / 2
          color: Ink.seal
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.page.count > 0 ? root.page.count + (root.page.count === 1 ? " WINDOW" : " WINDOWS") : root.live ? "HERE" : ""
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
      }
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.line }
    }

    // ---------------------------------------------- the screen
    Item {
      id: screen
      x: 1
      y: root.headH
      width: parent.width - 2
      height: parent.height - root.headH - 1

      // Bare page: its kanji, large and faint, like an unprinted leaf.
      Text {
        visible: root.page.count === 0
        anchors.centerIn: parent
        text: Spaces.numeral(root.page.id)
        color: Ink.alpha(Ink.ink, root.live ? 0.16 : 0.07)
        font.family: Type.jpSerif
        font.pixelSize: Math.min(screen.height * 0.5, Type.px(64))
      }

      // A click on the page (not on a window) goes there.
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: if (root.view) root.view.pagePicked(root.page.id)
      }

      // Counted, not the array: a new array (every workspace switch) would
      // rebuild each tile, and its snapshot blinked while it captured again.
      Repeater {
        model: root.windows.length
        Rectangle {
          id: tile
          required property int index
          readonly property var modelData: root.windows[tile.index] || ({ x: 0, y: 0, w: 0, h: 0, name: "", address: "", focused: false, floating: false })
          readonly property bool lifted: tileArea.containsMouse
          readonly property bool carried: !!root.view && root.view.dragging && root.view.dragAddress === tile.modelData.address
          x: Math.round(tile.modelData.x * screen.width) + 2
          y: Math.round(tile.modelData.y * screen.height) + 2
          width: Math.max(Type.px(14), Math.round(tile.modelData.w * screen.width) - 4)
          height: Math.max(Type.px(10), Math.round(tile.modelData.h * screen.height) - 4)
          // Opaque, so a floating window covers the tiling under it.
          color: Qt.tint(Ink.paper, Ink.alpha(Ink.ink, 0.05))
          border.width: 1
          border.color: tile.lifted ? Ink.seal : tile.modelData.focused ? Ink.ink : Ink.lineStrong
          opacity: tile.carried ? 0.25 : 1
          clip: true

          // Ink fallback: the app's name large and faint, only where there
          // are no snapshots (Settings, the harness). Live, it flashed on
          // every workspace switch while the snapshots came back.
          Text {
            visible: root.snapshot === null
            anchors.centerIn: parent
            width: parent.width - Type.px(8)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tile.modelData.name
            color: Ink.inkFaint
            readonly property int size: Math.round(Math.max(Type.px(10), Math.min(Type.px(22), tile.height * 0.22)))
            font.family: Type.display
            font.italic: true
            font.pixelSize: size
            font.variableAxes: Type.axes(size)
          }

          Loader {
            id: snap
            anchors.fill: parent
            anchors.margins: 1
            active: root.snapshot !== null
            sourceComponent: root.snapshot
          }
          Binding {
            when: snap.item !== null
            target: snap.item
            property: "address"
            value: tile.modelData.address
          }

          // The name tab, paper on the snapshot.
          Rectangle {
            visible: tile.height >= Type.px(26) && tile.width >= Type.px(46)
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Type.px(4)
            width: Math.min(tabText.implicitWidth + Type.px(10), parent.width - Type.px(8))
            height: tabText.implicitHeight + Type.px(4)
            radius: 2
            color: tile.modelData.focused ? Ink.bone : Ink.paper
            border.width: 1
            border.color: tile.modelData.focused ? Ink.bone : Ink.line
            Text {
              id: tabText
              anchors.centerIn: parent
              width: parent.width - Type.px(10)
              elide: Text.ElideRight
              text: (tile.modelData.floating ? "◇ " : "") + tile.modelData.name.toUpperCase()
              color: tile.modelData.focused ? Ink.boneInk : Ink.inkDim
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: Type.trackTag
            }
          }

          MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            property real downX: 0
            property real downY: 0
            onPressed: function(mouse) { downX = mouse.x; downY = mouse.y }
            onPositionChanged: function(mouse) {
              if (!(mouse.buttons & Qt.LeftButton) || !root.view) return
              if (!root.view.dragging) {
                if (Math.abs(mouse.x - downX) + Math.abs(mouse.y - downY) < Type.px(7)) return
                root.view.beginDrag(tile.modelData.address, tile.modelData.name, root.page.id)
              }
              var p = tileArea.mapToItem(root.view, mouse.x, mouse.y)
              root.view.dragTo(p.x, p.y)
            }
            onReleased: function(mouse) {
              if (!root.view) return
              if (root.view.dragging) { root.view.drop(); return }
              if (mouse.button === Qt.MiddleButton) root.view.windowClosed(tile.modelData.address)
              else root.view.windowPicked(tile.modelData.address)
            }
          }
        }
      }
    }
  }
}
