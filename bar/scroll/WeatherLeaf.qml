pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Weather.js" as Wx

// 00 // WEATHER 天: a leaf on the bare paper left of 01 // TIME, so the
// scroll opens on the day and the sky together. Not a section of its own
// (the index plate and the keys skip it); it shows while Time is in the
// middle and slides away with it.
//
//   18°, rain                      the title, like Time's
//   TOKYO · FEELS 16° · NE 12 KM/H  the caption
//   today's curve                   the temperature by the hour across the
//                                   day, the spent part fainter, daylight
//                                   shaded, rain chances as faint bars,
//                                   the red now-notch, the day's high and low
//   SUN 05:47 → 17:21 · RAIN 16:00
//   WED 晴 ──━━━━── 12° 22°         the next three days on one shared span
ScrollSection {
  id: root

  // core/Weather.js leaf(), or null before the first answer.
  property var weather: null

  readonly property var w: weather
  readonly property var points: w ? Wx.curve(w.hours, w.lo, w.hi) : []
  readonly property string wet: {
    if (!w) return ""
    for (var i = 0; i < w.hours.length; i++)
      if (!w.hours[i].past && w.hours[i].p >= 50) return (w.hours[i].hour < 10 ? "0" : "") + w.hours[i].hour + ":00"
    return ""
  }

  info: ({ no: "00", jp: w ? w.jp : "天", label: "WEATHER" })
  title: w && w.temp !== null
    ? w.temp + "°" + (w.word ? ", <i><font color='" + Ink.inkMuted + "'>" + w.word + "</font></i>" : "")
    : "—"
  caption: w ? w.caption : "Looking for the sky · Omarchy's weather place"

  Column {
    visible: !!root.w
    width: parent.width
    topPadding: Type.px(18)
    spacing: Type.px(10)

    // ------------------------------------------------ today, by the hour
    Item {
      id: day
      width: parent.width
      height: Type.px(70)

      readonly property real air: Type.px(12)
      function px(p) { return p.x * width }
      function py(p) { return air + (1 - p.y) * (height - 2 * air) }

      Canvas {
        id: ink
        anchors.fill: parent
        antialiasing: true
        onPaint: {
          var c = getContext("2d")
          c.reset()
          var w = root.w
          if (!w) return
          var W = width, H = height
          // Daylight, as the faintest wash.
          if (w.sunrise >= 0 && w.sunset > w.sunrise) {
            c.fillStyle = Qt.rgba(Ink.ink.r, Ink.ink.g, Ink.ink.b, 0.045)
            c.fillRect(w.sunrise / 1440 * W, 0, (w.sunset - w.sunrise) / 1440 * W, H - 1)
          }
          // Rain chances: a faint bar per hour, rising from the foot.
          c.fillStyle = Qt.rgba(Ink.inkMuted.r, Ink.inkMuted.g, Ink.inkMuted.b, 0.55)
          for (var i = 0; i < w.hours.length; i++) {
            var p = w.hours[i].p
            if (p <= 0) continue
            var bh = Math.max(1, p / 100 * Type.px(22))
            c.fillRect(Math.round(w.hours[i].hour / 23 * (W - 2)), H - 1 - bh, 2, bh)
          }
          // The curve, whole in the faint ink; from now on in full ink.
          var pts = root.points
          if (!pts.length) return
          c.lineWidth = 1.4
          c.lineJoin = "round"
          c.beginPath()
          for (var k = 0; k < pts.length; k++) {
            if (k === 0) c.moveTo(day.px(pts[k]), day.py(pts[k])); else c.lineTo(day.px(pts[k]), day.py(pts[k]))
          }
          c.strokeStyle = Ink.inkFaint
          c.stroke()
          var n = notch.point
          c.beginPath()
          c.moveTo(n.x, n.y)
          for (var m = 0; m < pts.length; m++) if (pts[m].x * 23 > notch.at * 23) c.lineTo(day.px(pts[m]), day.py(pts[m]))
          c.strokeStyle = Ink.ink
          c.stroke()
        }
        Connections {
          target: root
          function onWeatherChanged() { ink.requestPaint() }
        }
        Connections {
          target: Ink
          function onInkChanged() { ink.requestPaint() }
        }
        onWidthChanged: requestPaint()
      }

      // The foot of the day: a hairline with a tick every three hours.
      Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.line }
      Repeater {
        model: 9
        Rectangle {
          required property int index
          x: Math.round(index / 8 * (day.width - 1))
          y: day.height - height
          width: 1
          height: index % 2 === 0 ? Type.px(5) : Type.px(3)
          color: index % 2 === 0 ? Ink.lineStrong : Ink.line
        }
      }

      // Now: the red notch, up to the curve.
      Item {
        id: notch
        readonly property real at: root.w ? Math.min(1, root.w.nowHour / 23) : 0
        // Where now meets the curve, between the two hours around it.
        readonly property var point: {
          var pts = root.points
          if (!pts.length) return { x: 0, y: day.height }
          var i = Math.max(0, Math.min(pts.length - 2, Math.floor(notch.at * 23)))
          var a = pts[i], b = pts[i + 1] || a
          var t = Math.max(0, Math.min(1, notch.at * 23 - i))
          return { x: day.px({ x: a.x + (b.x - a.x) * t }), y: day.py({ y: a.y + (b.y - a.y) * t }) }
        }
        readonly property real curveY: point.y
        x: Math.round(at * (day.width - 2))
        Rectangle { y: notch.curveY; width: 2; height: day.height - notch.curveY; color: Ink.seal }
        Rectangle {
          x: -Type.px(2) + 1
          y: notch.curveY - Type.px(2)
          width: Type.px(4)
          height: width
          radius: width / 2
          color: Ink.seal
        }
      }

      // The day's high and low, where they fall.
      Repeater {
        model: root.w ? [{ hi: true }, { hi: false }] : []
        Text {
          id: mark
          required property var modelData
          readonly property var p: {
            var best = null
            for (var i = 0; i < root.points.length; i++) {
              var q = root.points[i]
              if (!best || (mark.modelData.hi ? q.y > best.y : q.y < best.y)) best = q
            }
            return best
          }
          visible: !!p
          x: p ? Math.max(0, Math.min(day.width - width, day.px(p) - width / 2)) : 0
          y: p ? (modelData.hi ? day.py(p) - height - 1 : day.py(p) + 2) : 0
          text: (modelData.hi ? root.w.hi : root.w.lo) + "°"
          color: modelData.hi ? Ink.inkDim : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
        }
      }
    }

    // The hours under the day.
    Item {
      width: parent.width
      height: Type.px(10)
      Repeater {
        model: ["00", "06", "12", "18", "24"]
        Text {
          required property string modelData
          required property int index
          x: index === 0 ? 0 : index === 4 ? parent.width - width : Math.round(index / 4 * parent.width - width / 2)
          text: modelData
          color: Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: 1
        }
      }
    }

    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.w ? (root.w.sunLine + (root.wet ? " · rain " + root.wet : "")).toUpperCase() : ""
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Type.label
      font.letterSpacing: Type.trackLabel
    }

    // ------------------------------------------------ the next three days
    Column {
      width: parent.width
      Rectangle { width: parent.width; height: 1; color: Ink.line }
      Repeater {
        model: root.w ? root.w.days : []
        Item {
          id: row
          required property var modelData
          width: parent.width
          height: Type.px(24)
          readonly property var span: Wx.range(modelData.lo, modelData.hi, root.w.weekLo, root.w.weekHi)
          Row {
            id: lead
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(8)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Type.px(28)
              text: row.modelData.name
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.label
              font.letterSpacing: Type.trackLabel
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: row.modelData.jp
              color: Ink.inkDim
              font.family: Type.jp
              font.pixelSize: Type.px(12)
            }
          }
          Row {
            id: temps
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Type.px(8)
            Text {
              width: Type.px(26)
              horizontalAlignment: Text.AlignRight
              text: row.modelData.lo === null ? "—" : row.modelData.lo + "°"
              color: Ink.inkMuted
              font.family: Type.mono
              font.pixelSize: Type.label
            }
            Text {
              width: Type.px(26)
              horizontalAlignment: Text.AlignRight
              text: row.modelData.hi === null ? "—" : row.modelData.hi + "°"
              color: Ink.ink
              font.family: Type.mono
              font.pixelSize: Type.label
            }
          }
          // Low to high on the span all four days share.
          Item {
            x: lead.width + Type.px(14)
            width: temps.x - x - Type.px(12)
            height: parent.height
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Ink.line }
            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              x: Math.round(row.span.from * parent.width)
              width: Math.max(3, Math.round((row.span.to - row.span.from) * parent.width))
              height: 3
              radius: 1
              color: Ink.ink
            }
          }
          Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Ink.lineSoft }
        }
      }
    }
  }
}
