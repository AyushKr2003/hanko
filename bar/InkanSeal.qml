import QtQuick
import "../core"
import "../core/Inkan.js" as Inkan

// Inkan's seal (form: inkan; docs/shell-concepts/inkan): the bar's stamp
// grown to the only thing on screen, its carving the status. Pure: it draws
// a `carving` from core/Inkan.js carving():
//   wear     the battery, as specks of the plate's own red over the glyph,
//            in the same seeded places every time (Inkan.specks)
//   chips    letters waiting: one corner cut off, two for three or more,
//            deeper when one is urgent
//   outline  quiet: only an outline in ink, no plate
//   broken   offline: the inner rule breaks along the foot
//   live     recording or dictation: a thin red ring around it, breathing
// `hovered` straightens its slight rest tilt; `pressed` sinks it on the
// stamp curve; `bloom` (0..1) is the ink spreading under it as it presses.
Item {
  id: root

  property var carving: ({ glyph: "鑑", wear: 1, chips: 0, deep: false, outline: false, broken: false })
  property int size: Type.px(Inkan.SIZE)
  property bool hovered: false
  property bool pressed: false
  property real bloom: 0
  // A stamp is never pressed quite straight.
  property real restTilt: -1.5

  readonly property var specks: Inkan.specks()
  readonly property var shown: Inkan.worn(specks, carving.outline ? 1 : carving.wear)
  readonly property int chipCount: carving.outline ? 0 : carving.chips
  readonly property real chip: Inkan.chipSize(carving.deep) * size

  implicitWidth: size
  implicitHeight: size

  // The ink under the seal as it presses: a soft red pool, past its edges.
  Item {
    anchors.centerIn: parent
    width: root.size * 2.4
    height: width
    visible: root.bloom > 0
    opacity: root.bloom
    Canvas {
      id: pool
      anchors.fill: parent
      onPaint: {
        var g = getContext("2d")
        g.reset()
        var r = width / 2
        var grad = g.createRadialGradient(r, r, 0, r, r, r)
        grad.addColorStop(0, Ink.alpha(Ink.seal, 0.3))
        grad.addColorStop(0.7, Ink.alpha(Ink.seal, 0))
        g.fillStyle = grad
        g.fillRect(0, 0, width, height)
      }
      Connections {
        target: Ink
        function onSealChanged() { pool.requestPaint() }
      }
    }
  }

  // Recording or dictation: a ring a few pixels out, breathing slowly.
  Rectangle {
    id: ring
    visible: !!root.carving.live
    anchors.fill: parent
    anchors.margins: -Math.max(3, Math.round(root.size * 0.09))
    radius: Math.max(3, root.size * 0.12)
    color: "transparent"
    border.width: 1
    border.color: Ink.seal
    SequentialAnimation on opacity {
      running: ring.visible && Motion.live
      loops: Animation.Infinite
      NumberAnimation { from: 1; to: 0.35; duration: 900; easing.type: Easing.InOutSine }
      NumberAnimation { from: 0.35; to: 1; duration: 900; easing.type: Easing.InOutSine }
    }
  }

  Item {
    id: stamp
    anchors.fill: parent
    rotation: root.hovered || root.pressed ? 0 : root.restTilt
    scale: root.pressed ? 0.92 : 1
    antialiasing: true

    Behavior on rotation {
      enabled: Motion.live
      NumberAnimation { duration: Motion.slide; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
      enabled: Motion.live
      NumberAnimation { duration: Motion.stamp; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.stampCurve }
    }

    // The plate, chipped, and its inner rule.
    Canvas {
      id: plate
      anchors.fill: parent
      antialiasing: true
      readonly property var key: [root.size, root.chipCount, root.chip, root.carving.outline, root.carving.broken,
                                  String(Ink.seal), String(Ink.paper), String(Ink.inkDim)]
      onKeyChanged: requestPaint()
      onPaint: {
        var g = getContext("2d")
        g.reset()
        var s = root.size, rad = Math.max(2, s * 0.07), chip = root.chip, chips = root.chipCount
        g.beginPath()
        g.moveTo(rad, 0)
        if (chips >= 1) { g.lineTo(s - chip, 0); g.lineTo(s, chip) }
        else { g.lineTo(s - rad, 0); g.quadraticCurveTo(s, 0, s, rad) }
        g.lineTo(s, s - rad); g.quadraticCurveTo(s, s, s - rad, s)
        if (chips >= 2) { g.lineTo(chip, s); g.lineTo(0, s - chip) }
        else { g.lineTo(rad, s); g.quadraticCurveTo(0, s, 0, s - rad) }
        g.lineTo(0, rad); g.quadraticCurveTo(0, 0, rad, 0)
        g.closePath()
        if (root.carving.outline) {
          g.lineWidth = 1.5
          g.strokeStyle = String(Ink.inkDim)
          g.stroke()
          return
        }
        g.fillStyle = String(Ink.seal)
        g.fill()
        // The inner rule, cut where the corners are, broken along the
        // foot when offline.
        var m = Math.max(2, s * 0.08), a = m + 0.5, b = s - m - 0.5
        var cut = chips >= 1 ? chip - m * 0.2 : 0, cut2 = chips >= 2 ? chip - m * 0.2 : 0
        g.strokeStyle = String(Ink.alpha(Ink.paper, 0.5))
        g.lineWidth = 1
        g.beginPath()
        g.moveTo(a, a)
        g.lineTo(b - cut, a)
        if (cut) g.lineTo(b, a + cut)
        g.lineTo(b, b)
        if (root.carving.broken) {
          g.lineTo(s * 0.64, b)
          g.moveTo(s * 0.36, b)
          g.lineTo(a + cut2, b)
          if (cut2) g.lineTo(a, b - cut2)
          g.lineTo(a, a)
        } else {
          g.lineTo(a + cut2, b)
          if (cut2) g.lineTo(a, b - cut2)
          g.closePath()
        }
        g.stroke()
      }
    }

    Text {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: Math.round(root.size * 0.02)
      text: root.carving.glyph || "鑑"
      color: root.carving.outline ? Ink.inkDim : Ink.paper
      font.family: Type.jp
      font.pixelSize: Math.round(root.size * 0.66)
    }

    // The wear: specks of the plate's red over the carving.
    Canvas {
      id: wearing
      anchors.fill: parent
      visible: root.shown.length > 0
      readonly property var key: [root.size, root.shown.length, String(Ink.seal)]
      onKeyChanged: requestPaint()
      onPaint: {
        var g = getContext("2d")
        g.reset()
        g.fillStyle = String(Ink.seal)
        var s = root.size
        for (var i = 0; i < root.shown.length; i++) {
          var p = root.shown[i]
          g.beginPath()
          g.arc(p.x * s, p.y * s, p.r * s, 0, 2 * Math.PI)
          g.fill()
        }
      }
    }
  }
}
