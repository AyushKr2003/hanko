pragma ComponentBehavior: Bound
import QtQuick
import "../core"
import "../core/Edge.js" as E

// The bar's edge, on the side facing the desktop (docs/COMPONENTS.md, "Edge"):
//   hairline  one 1 px line
//   dayrule   a 24-hour ruler: hour ticks, the spent part of the day a shade
//             stronger, and a red now-notch that moves every minute
//   rod       the scroll roller: a rod with end caps and a grip; pull it
//   rodrule   the rod carrying the day: ticks, spent part and now-notch
//
// Everything is drawn as if the bar sat at the top (marks rise from the
// edge into the bar) and mirrored when it sits at the bottom. The edge never
// adds to the bar's height: it lives inside the bar's own strip.
Item {
  id: root

  property string mode: "rodrule"
  property date now: new Date()
  // Draw along the bar's top side (the bar sits at the bottom of the screen).
  property bool atBottom: false
  // Inside the inset frame: held 10 px in from each end, and no hairline
  // of its own (the frame already is one).
  property bool inset: false

  // Dragged away from the bar far enough to unroll the scroll; x is where
  // along the bar the pull started.
  signal pulled(real x)

  readonly property bool isRod: mode === "rod" || mode === "rodrule"
  readonly property bool isDay: mode === "dayrule" || mode === "rodrule"
  readonly property real dayFraction: E.dayFraction(now)
  readonly property var ticks: E.hourTicks()
  readonly property var span: E.span(mode, width, inset)

  // The rod sits 2 px up from the edge so its 6 px caps fit inside the bar.
  readonly property int rodY: height - 4

  implicitHeight: 12
  visible: !(inset && mode === "hairline")

  // Mirrored as a whole at the bottom, so every mark keeps its distance
  // from the edge it belongs to.
  Item {
    id: band
    anchors.fill: parent
    transform: Scale {
      origin.y: band.height / 2
      yScale: root.atBottom ? -1 : 1
    }

    // ------------------------------------------------ hairline, dayrule
    Rectangle {
      visible: !root.isRod
      x: root.span.left
      y: band.height - 1
      width: root.span.width
      height: 1
      color: Ink.line
    }

    Item {
      id: day
      visible: root.mode === "dayrule"
      x: root.span.left
      width: root.span.width
      height: band.height

      Rectangle {
        y: day.height - 1
        width: E.at(root.dayFraction, day.width, 0)
        height: 1
        color: Ink.lineStrong
      }

      Repeater {
        model: day.visible ? root.ticks : []
        Rectangle {
          id: dayTick
          required property var modelData
          x: E.at(dayTick.modelData.fraction, day.width, 1)
          y: day.height - height
          width: 1
          height: dayTick.modelData.major ? 5 : 3
          color: dayTick.modelData.major ? Ink.lineStrong : Ink.line
        }
      }

      Notch {
        x: E.at(root.dayFraction, day.width, 2)
        y: day.height - 7
        stem: 7
        head: true
        creeps: true
      }
    }

    // ------------------------------------------------ rod, rodrule
    Item {
      id: rod
      visible: root.isRod
      x: root.span.left
      y: root.rodY
      width: root.span.width
      height: 2

      Rectangle {
        anchors.fill: parent
        radius: 1
        color: drag.pressed ? Ink.ink : Ink.lineStrong
      }

      // The spent part of the day, wound onto the rod.
      Rectangle {
        visible: root.mode === "rodrule"
        width: E.at(root.dayFraction, rod.width, 0)
        height: rod.height
        radius: 1
        color: Ink.inkMuted
      }

      Repeater {
        model: root.mode === "rodrule" ? root.ticks : []
        Rectangle {
          id: rodTick
          required property var modelData
          x: E.at(rodTick.modelData.fraction, rod.width, 1)
          y: -height
          width: 1
          height: rodTick.modelData.major ? 5 : 3
          color: Ink.lineStrong
        }
      }

      // End caps.
      Repeater {
        model: 2
        Rectangle {
          id: cap
          required property int index
          x: cap.index === 0 ? -3 : rod.width - 3
          y: -2
          width: 6
          height: 6
          radius: 3
          color: Ink.inkMuted
        }
      }

      Notch {
        visible: root.mode === "rodrule"
        x: E.at(root.dayFraction, rod.width, 2)
        y: -6
        stem: 8
        creeps: true
      }

      // The grip: a small paper plate on the rod's centre that lifts when
      // the pointer comes near.
      Rectangle {
        x: Math.round((rod.width - width) / 2)
        y: drag.containsMouse || drag.pressed ? -3 : -1
        width: 34
        height: 4
        radius: 2
        color: Ink.paper
        border.width: 1
        border.color: drag.pressed ? Ink.ink : Ink.lineStrong
        Behavior on y { enabled: !Motion.still; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      }
    }
  }

  // A red mark standing up from the edge, with an optional arrow head.
  component Notch: Item {
    id: notch
    property int stem: 7
    property bool head: false
    // Each minute the notch creeps to the new hour mark instead of jumping.
    property bool creeps: false
    width: 2
    Behavior on x {
      enabled: notch.creeps && Motion.live
      NumberAnimation { duration: Motion.creep; easing.type: Easing.InOutSine }
    }
    height: stem

    Rectangle {
      anchors.fill: parent
      color: Ink.seal
    }

    // A 6 px wide, 3 px tall head pointing at the edge, drawn as three
    // pixel rows so it stays crisp.
    Repeater {
      model: notch.head ? 3 : 0
      Rectangle {
        id: row
        required property int index
        x: -2 + row.index
        y: -3 + row.index
        width: 6 - 2 * row.index
        height: 1
        color: Ink.seal
      }
    }
  }

  // The rod is a handle: hover lifts the grip, a drag away from the bar
  // pulls. Kept to a thin band along the edge so it never takes clicks
  // meant for the cells above it. Not mirrored, so drag deltas stay in
  // screen terms; Edge.js decides which way counts.
  MouseArea {
    id: drag
    enabled: root.isRod
    visible: enabled
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: root.atBottom ? undefined : parent.bottom
    anchors.top: root.atBottom ? parent.top : undefined
    height: 8
    hoverEnabled: true
    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    preventStealing: true

    property real startY: 0
    property real startX: 0
    property bool fired: false

    onPressed: function(mouse) { startY = mouse.y; startX = mouse.x; fired = false }
    onPositionChanged: function(mouse) {
      if (!pressed || fired) return
      if (E.pulled(mouse.y - startY, root.atBottom, Type.px(E.PULL_THRESHOLD))) {
        fired = true
        root.pulled(startX)
      }
    }
  }
}
