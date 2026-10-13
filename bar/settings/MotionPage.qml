pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Style.js" as S
import "../../core/Settings.js" as Settings

// Settings › Motion 動 (docs/settings-kosei). First the one switch, paper or
// still, as two pictures. Then the timesheet (タイムシート, the animator's
// exposure sheet): a row per move Hanko makes, ruled in frames against a
// 0–400 ms scale, each move a bar from its delay to its end with its curve
// drawn inside it (the stamp's overshoot rises out of its bar). Hover a row
// and a red playhead runs it at a quarter speed, so it can be seen; under
// still, every bar is cut to its last frame.
Column {
  id: root

  property var style: ({})
  property var draft: S.normalize({})
  property bool compact: false

  signal settingPicked(string key, string value)

  readonly property bool still: (draft.motion || "paper") === "still"
  // The scale: 400 ms across; the now-notch's 1.2 s runs off the end.
  readonly property real span: 400

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  // ------------------------------------------------------------ the switch
  Row {
    spacing: Type.px(10)
    Repeater {
      model: [
        { key: "paper", jp: "紙", name: "Paper", line: "Every move eases, with weight; ink after paper" },
        { key: "still", jp: "静", name: "Still", line: "Every move cut to its end frame, as Omarchy's own switch does" }
      ]
      Tile {
        id: way
        required property var modelData
        width: (root.width - Type.px(10)) / 2
        height: implicitHeight
        stageHeight: Type.px(110)
        on: (root.draft.motion || "paper") === modelData.key
        jp: modelData.jp
        name: modelData.name
        line: modelData.line
        onClicked: root.settingPicked("motion", way.modelData.key)

        // A sheet dropping: ghosts of where it was (paper), or none (still).
        Repeater {
          model: way.modelData.key === "paper" ? [0.12, 0.25, 0.45, 1] : [1]
          Rectangle {
            id: ghost
            required property var modelData
            required property int index
            x: way.stage.width / 2 - width / 2
            y: Type.px(14) + (way.modelData.key === "paper" ? ghost.index * Type.px(9) : Type.px(27))
            width: Type.px(120)
            height: Type.px(56)
            color: ghost.modelData === 1 ? Ink.paper : "transparent"
            border.width: 1
            border.color: Ink.alpha(Ink.ink, 0.15 + 0.7 * ghost.modelData)
            Column {
              visible: ghost.modelData === 1
              x: Type.px(10); y: Type.px(10)
              spacing: Type.px(5)
              Rectangle { width: Type.px(46); height: Type.px(6); color: Ink.inkDim }
              Repeater { model: 3; Rectangle { required property int index; width: Type.px(96) - index * Type.px(14); height: 1; color: Ink.line } }
            }
          }
        }
      }
    }
  }

  // Omarchy's own animation switch overrides this one.
  Text {
    visible: Motion.system
    topPadding: Type.px(10)
    text: "Omarchy's animations are off, so Hanko is still too, whatever is picked here."
    color: Ink.seal
    font.family: Type.text
    font.pixelSize: Type.note
  }

  Item { width: 1; height: Type.px(30) }

  // ------------------------------------------------------------ the timesheet
  SectionLabel { jp: "秒"; text: "Timesheet · every move, in milliseconds · hover a row to run it" }
  Item { width: 1; height: Type.px(12) }

  Rectangle {
    id: sheet
    width: parent.width
    height: ruler.height + rows.height + 2
    radius: 3
    color: "transparent"
    border.width: 1
    border.color: Ink.line

    readonly property real nameWidth: Type.px(root.compact ? 120 : 250)
    readonly property real figureWidth: Type.px(root.compact ? 70 : 120)
    readonly property real chartX: nameWidth
    readonly property real chartWidth: width - nameWidth - figureWidth
    function xAt(ms) { return chartX + Math.min(1, ms / root.span) * chartWidth }

    // Frame lines: one per 60 Hz frame, stronger every 100 ms.
    Canvas {
      id: frames
      x: sheet.chartX
      y: 1
      width: sheet.chartWidth
      height: sheet.height - 2
      onPaint: {
        var c = getContext("2d")
        c.reset()
        var fps = 1000 / 60
        for (var t = 0; t <= root.span + 0.1; t += fps) {
          var x = Math.round(t / root.span * width) + 0.5
          c.strokeStyle = Ink.lineSoft
          c.beginPath(); c.moveTo(x, ruler.height); c.lineTo(x, height); c.stroke()
        }
        for (var m = 0; m <= root.span; m += 100) {
          var xm = Math.round(m / root.span * width) + 0.5
          c.strokeStyle = Ink.line
          c.beginPath(); c.moveTo(xm, 0); c.lineTo(xm, height); c.stroke()
        }
      }
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
    }

    // The ruler.
    Item {
      id: ruler
      width: parent.width
      height: Type.px(30)
      Text {
        x: Type.px(14)
        anchors.verticalCenter: parent.verticalCenter
        text: "MOVE"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackLabel
      }
      Repeater {
        model: [0, 100, 200, 300, 400]
        Text {
          required property int modelData
          x: sheet.xAt(modelData) + Type.px(4)
          anchors.verticalCenter: parent.verticalCenter
          text: modelData + (modelData === 400 ? " MS" : "")
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: 1
        }
      }
      Text {
        anchors.right: parent.right
        anchors.rightMargin: Type.px(14)
        anchors.verticalCenter: parent.verticalCenter
        text: "LENGTH"
        color: Ink.inkMuted
        font.family: Type.mono
        font.pixelSize: Type.tag
        font.letterSpacing: Type.trackLabel
      }
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Ink.line }
    }

    Column {
      id: rows
      y: ruler.height
      width: parent.width

      Repeater {
        model: Settings.MOTION_SHEET
        Item {
          id: move
          required property var modelData
          required property int index
          readonly property int length: Motion[modelData.prop] || 0
          readonly property int delay: modelData.delayProp ? (Motion[modelData.delayProp] || 0) : (modelData.delay || 0)
          readonly property real x0: sheet.xAt(delay)
          readonly property real x1: sheet.xAt(delay + length)
          readonly property bool hot: moveHover.containsMouse
          width: rows.width
          height: Type.px(root.compact ? 46 : 52)
          Rectangle { anchors.fill: parent; color: move.hot ? Ink.lineSoft : "transparent" }
          Rectangle { visible: move.index > 0; width: parent.width; height: 1; color: Ink.lineSoft }

          Column {
            x: Type.px(14)
            anchors.verticalCenter: parent.verticalCenter
            width: sheet.nameWidth - Type.px(24)
            spacing: Type.px(1)
            Text {
              text: move.modelData.name
              color: Ink.ink
              font.family: Type.display
              font.pixelSize: Type.px(16)
              font.weight: Font.Normal
              font.variableAxes: Type.axes(Type.px(16))
            }
            Text {
              visible: !root.compact
              width: parent.width
              elide: Text.ElideRight
              text: move.modelData.line
              color: Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.note
            }
          }

          // The delay, dashed; the move, a bar with its curve inside.
          Row {
            visible: move.delay > 0 && !root.still
            x: sheet.xAt(0)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(3)
            Repeater {
              model: Math.max(0, Math.floor((move.x0 - sheet.xAt(0)) / Type.px(7)))
              Rectangle { width: Type.px(4); height: 1; color: Ink.inkFaint }
            }
          }
          Rectangle {
            id: bar
            visible: !root.still
            x: move.x0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(2, move.x1 - move.x0)
            height: Type.px(22)
            radius: 2
            color: Ink.alpha(Ink.ink, move.hot ? 0.16 : 0.09)
            border.width: 1
            border.color: move.hot ? Ink.inkMuted : Ink.line
            // Drawn 10 px taller than the bar, so an overshoot (the stamp)
            // rises out of it.
            Canvas {
              id: curve
              readonly property real lift: Type.px(10)
              x: 0
              y: -lift
              width: parent.width
              height: parent.height + lift
              onPaint: {
                var c = getContext("2d")
                c.reset()
                var p = move.modelData.curve
                var top = lift + 2, w = width, h = height - top - 2
                c.strokeStyle = Ink.ink
                c.lineWidth = 1.4
                c.beginPath()
                if (move.modelData.dip) {
                  // Down to a trace, then back: in quad, out quad.
                  c.moveTo(0, top)
                  c.quadraticCurveTo(w * 0.5, top, w * 0.5, top + h * 0.8)
                  c.quadraticCurveTo(w * 0.5, top, w, top)
                } else {
                  c.moveTo(0, top + h)
                  c.bezierCurveTo(p[0] * w, top + h - p[1] * h, p[2] * w, top + h - p[3] * h, w, top)
                }
                c.stroke()
              }
              onWidthChanged: requestPaint()
            }
            // Runs off the scale: the now-notch's 1.2 s.
            Text {
              visible: move.delay + move.length > root.span
              anchors.right: parent.right
              anchors.rightMargin: Type.px(6)
              anchors.verticalCenter: parent.verticalCenter
              text: "→"
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.px(11)
            }
          }
          // Still: one tick at the last frame.
          Rectangle {
            visible: root.still
            x: move.x1 - 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: Type.px(22)
            color: Ink.inkDim
          }

          // The playhead: red, as now is.
          Rectangle {
            id: head
            visible: move.hot && !root.still
            x: move.x0
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: Type.px(30)
            color: Ink.seal
            NumberAnimation on x {
              running: move.hot && !root.still
              loops: Animation.Infinite
              from: move.x0
              to: move.x1
              duration: Math.max(1, move.length * 4)
              easing.type: Easing.BezierSpline
              easing.bezierCurve: move.modelData.dip ? [0.5, 0.5, 0.5, 0.5, 1, 1] : move.modelData.curve.concat([1, 1])
            }
          }

          Column {
            anchors.right: parent.right
            anchors.rightMargin: Type.px(14)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(2)
            Text {
              anchors.right: parent.right
              text: root.still ? "cut" : move.length >= 1000 ? (move.length / 1000).toFixed(1) + " s" : move.length + " ms"
              color: Ink.ink
              font.family: Type.mono
              font.pixelSize: Type.px(11)
            }
            Text {
              anchors.right: parent.right
              visible: !root.compact
              text: move.hot && !root.still ? "¼ SPEED" : (move.delay ? "+" + move.delay + " · " : "") + move.modelData.ease
              color: move.hot ? Ink.seal : Ink.inkFaint
              font.family: Type.mono
              font.pixelSize: Type.tag
              font.letterSpacing: 0.5
            }
          }

          MouseArea {
            id: moveHover
            anchors.fill: parent
            hoverEnabled: true
          }
        }
      }
    }
  }

  Item { width: 1; height: Type.px(14) }
  Text {
    width: Math.min(parent.width, Type.px(820))
    wrapMode: Text.Wrap
    text: "Ruled at 60 frames a second. Nothing springs and nothing glows; only a new stamp overshoots, and only by a little."
    color: Ink.inkMuted
    font.family: Type.text
    font.pixelSize: Type.note
  }
}
