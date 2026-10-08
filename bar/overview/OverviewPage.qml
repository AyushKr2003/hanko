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
  // A Kata design's skin (docs/kata); empty for Classic. Its `overview` part
  // prints the page: miniatures (Margin: soft paper, the number in
  // Fraunces), contact (Leaf: a contact sheet's frame, numbered 03A, with
  // sprocket holes and crop marks), framed (Shōji: washi in a lattice frame,
  // the kanji numeral over the figure).
  property var skin: ({})
  readonly property string variant: skin.overview || ""

  readonly property bool live: page.active
  readonly property var windows: O.visibleWindows(page.windows)
  property bool hovered: false

  // The sheet's shadow on the desk, matched to style.lua's "paper" as
  // Hyprland draws it (range 14 at render_power 3 reads as a dense band,
  // then a short fade): offset 3, 5, a tight blur. Cast in the theme's ink
  // so it reads on the dark desk: 55% under the live page, 25% under the
  // rest, the shadow's color and color_inactive.
  RectangularShadow {
    visible: root.variant !== "framed" && root.variant !== "contact"
    anchors.fill: parent
    radius: sheet.radius
    offset.x: Type.px(3)
    offset.y: Type.px(5)
    blur: Type.px(4)
    spread: Type.px(2)
    color: Ink.alpha(Ink.ink, root.live ? 0.55 : 0.25)
    Behavior on color { ColorAnimation { duration: Motion.ink } }
  }

  // contact: a card's hard shadow
  Rectangle {
    visible: root.variant === "contact"
    x: Type.px(3); y: Type.px(3); width: parent.width; height: parent.height
    color: root.live ? Ink.shade : Ink.alpha(Ink.shade, 0.6)
  }

  Rectangle {
    id: sheet
    anchors.fill: parent
    radius: root.variant === "miniatures" ? (root.skin.radiusRow || 0) : 0
    color: root.variant === "framed" ? Ink.alpha(Ink.paper, root.skin.opacity || 0.86) : root.variant === "contact" ? Ink.paper2 : Ink.paper
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
        visible: root.variant === ""
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
      // Kata folios
      Row {
        visible: root.variant !== ""
        x: Type.px(root.variant === "contact" ? 22 : 10)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Type.px(6)
        Text {
          visible: root.variant === "framed"
          anchors.verticalCenter: parent.verticalCenter
          text: Spaces.numeral(root.page.id)
          color: root.live ? Ink.ink : Ink.ink2
          font.family: Type.jpSerif; font.pixelSize: Type.px(18)
        }
        Text {
          readonly property int size: root.variant === "contact" ? Type.px(12) : root.variant === "framed" ? Type.px(12) : Type.px(17)
          anchors.verticalCenter: parent.verticalCenter
          text: root.variant === "contact" ? (root.live ? "▸ " : "") + Spaces.folio(root.page.id) + "A" : String(root.page.id)
          color: root.live ? Ink.ink : root.page.count > 0 ? Ink.ink2 : Ink.ink3
          font.family: root.variant === "contact" ? Type.mono : Type.display
          font.pixelSize: size
          font.weight: root.variant === "contact" ? Font.Medium : Font.Normal
          font.variableAxes: root.variant === "contact" ? ({}) : Type.axes(size, 380, root.skin.soft || 0)
          font.features: { "tnum": 1, "lnum": 1 }
        }
      }
      Text {
        visible: root.variant === ""
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
          text: root.variant === "" || root.variant === "contact"
            ? (root.page.count > 0 ? root.page.count + (root.page.count === 1 ? " WINDOW" : " WINDOWS") : root.live ? "HERE" : "")
            : (root.page.count > 0 ? root.page.count + (root.page.count === 1 ? " window" : " windows") : root.live ? "here" : "")
          color: Ink.inkMuted
          font.family: root.variant === "" || root.variant === "contact" ? Type.mono : Type.text
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackTag
        }
      }
      Rectangle { visible: root.variant !== "framed"; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.variant === "" ? Ink.line : Ink.kLine }
    }
    // contact: sprocket holes down the left edge of the frame
    Column {
      visible: root.variant === "contact"
      x: Type.px(6); y: Type.px(6)
      spacing: Type.px(7)
      Repeater {
        model: Math.max(0, Math.floor((root.height - Type.px(12)) / Type.px(15)))
        Rectangle { width: Type.px(7); height: Type.px(8); radius: 1; color: Ink.alpha(Ink.ink, 0.12) }
      }
    }

    // ---------------------------------------------- the screen
    Item {
      id: screen
      readonly property int inset: root.variant === "contact" ? Type.px(20) : root.variant === "framed" ? Type.px(8) : 0
      x: 1 + inset
      y: root.headH
      width: parent.width - 2 - inset - (root.variant === "framed" ? inset : 0)
      height: parent.height - root.headH - 1 - (root.variant === "framed" ? inset : 0)

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

      Repeater {
        model: root.windows
        Rectangle {
          id: tile
          required property var modelData
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

          // Ink fallback: the app's name large and faint until a snapshot lands.
          Text {
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
            anchors.fill: parent
            anchors.margins: 1
            active: root.snapshot !== null
            sourceComponent: root.snapshot
            onLoaded: item.address = tile.modelData.address
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

    // framed: the lattice frame of a shōji, a hairline inside the edge with its joints
    Rectangle {
      visible: root.variant === "framed"
      x: Type.px(4); y: Type.px(4); width: parent.width - 2 * x; height: parent.height - 2 * y
      color: "transparent"; border.width: 1; border.color: Ink.kLine
    }
    Rectangle { visible: root.variant === "framed"; x: Type.px(4); y: root.headH; width: parent.width - Type.px(8); height: 1; color: Ink.kLine }
    // contact: crop marks at the live frame's corners
    Repeater {
      model: root.variant === "contact" && root.live ? 4 : 0
      Item {
        required property int index
        x: index % 2 ? sheet.width - Type.px(12) : Type.px(2)
        y: index < 2 ? Type.px(2) : sheet.height - Type.px(12)
        width: Type.px(10); height: Type.px(10)
        Rectangle { x: parent.index % 2 ? parent.width - 1 : 0; width: 1; height: parent.height; color: Ink.ink }
        Rectangle { y: parent.index < 2 ? 0 : parent.height - 1; width: parent.width; height: 1; color: Ink.ink }
      }
    }
  }
}
