pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// WifiFan 扇: Wi-Fi networks in range drawn as a folding fan (sensu 扇子).
// The computer sits at the foot hub; concentric hairline arcs represent
// signal strength tiers (strongest innermost). 2.4 GHz occupies the left wing,
// 5 GHz / 6 GHz the right wing. The connected network is an ink node stamped
// in cinnabar seal red (Ink.seal), with a fine hairline tether to the hub.
Item {
  id: root

  property var networks: []
  property string hoverSsid: ""
  property real size: Type.px(280)

  signal picked(string ssid, bool secure, bool saved)

  implicitWidth: size
  implicitHeight: Math.round(size * 0.68)

  readonly property real cx: width / 2
  readonly property real cy: height - Type.px(14)
  readonly property real rMin: Type.px(34)
  readonly property real rMax: Math.max(rMin + Type.px(20), Math.min(cx - Type.px(16), cy - Type.px(10)))

  // Radian sweep from left (-170 deg) to right (-10 deg)
  readonly property real fromAngle: -Math.PI * 0.94
  readonly property real toAngle: -Math.PI * 0.06

  function radiusOf(sig) {
    var s = Math.max(0, Math.min(100, sig || 0))
    return rMin + (1 - s / 100) * (rMax - rMin)
  }

  // Split networks into 2.4GHz and 5GHz/other
  readonly property var points: {
    var list = root.networks || []
    var low = []
    var high = []
    for (var i = 0; i < list.length; i++) {
      var n = list[i]
      var isHigh = (n.freq && n.freq >= 4900) || (n.detail && n.detail.indexOf("5 GHz") >= 0)
      if (isHigh) high.push(n)
      else low.push(n)
    }
    // If all are on one side or no freq known, distribute half and half
    if (low.length === 0 && high.length > 0) {
      low = high.splice(0, Math.floor(high.length / 2))
    } else if (high.length === 0 && low.length > 1) {
      high = low.splice(Math.ceil(low.length / 2))
    }

    var midAngle = (root.fromAngle + root.toAngle) / 2
    var out = []

    function place(arr, a0, a1) {
      if (!arr || arr.length === 0) return
      var span = a1 - a0
      for (var j = 0; j < arr.length; j++) {
        var item = arr[j]
        var a = arr.length === 1 ? (a0 + a1) / 2 : a0 + (j + 0.5) * (span / arr.length)
        var r = root.radiusOf(item.signal)
        out.push({
          ssid: item.ssid,
          signal: item.signal,
          current: !!item.current,
          secure: !!item.secure,
          saved: !!item.saved,
          angle: a,
          radius: r,
          x: root.cx + r * Math.cos(a),
          y: root.cy + r * Math.sin(a)
        })
      }
    }

    place(low, root.fromAngle, midAngle - 0.08)
    place(high, midAngle + 0.08, root.toAngle)
    return out
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    readonly property var pts: root.points
    readonly property string hSsid: root.hoverSsid
    readonly property color lineCol: Ink.line
    readonly property color lineSoft: Ink.lineSoft
    readonly property color inkCol: Ink.ink
    readonly property color inkDim: Ink.inkDim
    readonly property color sealCol: Ink.seal

    onPtsChanged: requestPaint()
    onHSsidChanged: requestPaint()
    onLineColChanged: requestPaint()

    onPaint: {
      var g = getContext("2d")
      g.reset()
      var cx = root.cx
      var cy = root.cy
      var rMin = root.rMin
      var rMax = root.rMax

      // 1. Concentric hairline arcs for signal tiers: 25%, 50%, 75%, 100%
      g.lineWidth = 1
      for (var tier = 1; tier <= 4; tier++) {
        var rTier = rMin + (tier / 4) * (rMax - rMin)
        g.strokeStyle = tier === 4 ? canvas.lineCol : canvas.lineSoft
        g.beginPath()
        g.arc(cx, cy, rTier, root.fromAngle, root.toAngle)
        g.stroke()
      }

      // 2. Boundary ribs (the fan's frame ribs)
      g.strokeStyle = canvas.lineCol
      g.beginPath()
      g.moveTo(cx + rMin * Math.cos(root.fromAngle), cy + rMin * Math.sin(root.fromAngle))
      g.lineTo(cx + rMax * Math.cos(root.fromAngle), cy + rMax * Math.sin(root.fromAngle))
      g.moveTo(cx + rMin * Math.cos(root.toAngle), cy + rMin * Math.sin(root.toAngle))
      g.lineTo(cx + rMax * Math.cos(root.toAngle), cy + rMax * Math.sin(root.toAngle))
      // Center split rib
      var midAngle = (root.fromAngle + root.toAngle) / 2
      g.strokeStyle = canvas.lineSoft
      g.moveTo(cx + rMin * Math.cos(midAngle), cy + rMin * Math.sin(midAngle))
      g.lineTo(cx + rMax * Math.cos(midAngle), cy + rMax * Math.sin(midAngle))
      g.stroke()

      // 3. Hub arc
      g.strokeStyle = canvas.lineCol
      g.beginPath()
      g.arc(cx, cy, rMin, root.fromAngle, root.toAngle)
      g.stroke()

      // 4. Plot network points
      for (var i = 0; i < pts.length; i++) {
        var p = pts[i]
        var isHov = p.ssid === hSsid
        var isCur = p.current

        // Tether line for active connection
        if (isCur) {
          g.strokeStyle = canvas.sealCol
          g.lineWidth = 1
          g.beginPath()
          g.moveTo(cx + rMin * Math.cos(p.angle), cy + rMin * Math.sin(p.angle))
          g.lineTo(p.x, p.y)
          g.stroke()
        }

        // Draw node
        g.beginPath()
        var nodeR = isCur ? Type.px(4.5) : (isHov ? Type.px(4) : Type.px(3))
        g.arc(p.x, p.y, nodeR, 0, Math.PI * 2)

        if (isCur) {
          g.fillStyle = canvas.sealCol
          g.fill()
        } else if (p.saved) {
          g.fillStyle = canvas.inkCol
          g.fill()
        } else {
          g.fillStyle = Ink.paper
          g.fill()
          g.strokeStyle = isHov ? canvas.inkCol : canvas.inkDim
          g.lineWidth = 1
          g.stroke()
        }

        // Double ring for hovered item
        if (isHov) {
          g.beginPath()
          g.arc(p.x, p.y, nodeR + Type.px(2.5), 0, Math.PI * 2)
          g.strokeStyle = isCur ? canvas.sealCol : canvas.inkCol
          g.lineWidth = 1
          g.stroke()
        }
      }
    }
  }

  // Band labels at the wings
  Text {
    anchors.left: parent.left
    anchors.leftMargin: Type.px(6)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(2)
    text: "2.4 GHz"
    color: Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }

  Text {
    anchors.right: parent.right
    anchors.rightMargin: Type.px(6)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(2)
    text: "5 GHz"
    color: Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Type.tag
    font.letterSpacing: Type.trackTag
  }

  // Hub mark
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(1)
    text: "扇"
    color: Ink.inkFaint
    font.family: Type.jp
    font.pixelSize: Type.tag
  }

  // Active / hovered network readout
  Item {
    id: readout
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    height: Type.px(18)
    visible: activeInfo.text !== ""

    Text {
      id: activeInfo
      anchors.centerIn: parent
      text: {
        if (root.hoverSsid !== "") {
          var h = root.points.find(function(p) { return p.ssid === root.hoverSsid })
          return h ? h.ssid + " · " + h.signal + "%" : root.hoverSsid
        }
        var c = root.points.find(function(p) { return p.current })
        return c ? c.ssid + " · " + c.signal + "%" : ""
      }
      color: root.hoverSsid !== "" ? Ink.ink : Ink.seal
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.weight: Font.Medium
    }
  }

  // Interactive mouse/touch targeting
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true

    function findClosest(mx, my) {
      var pts = root.points
      var best = null
      var minD = Type.px(16)
      for (var i = 0; i < pts.length; i++) {
        var dx = pts[i].x - mx
        var dy = pts[i].y - my
        var d = Math.sqrt(dx * dx + dy * dy)
        if (d < minD) {
          minD = d
          best = pts[i]
        }
      }
      return best
    }

    onPositionChanged: function(mouse) {
      var hit = findClosest(mouse.x, mouse.y)
      root.hoverSsid = hit ? hit.ssid : ""
    }

    onExited: root.hoverSsid = ""

    onClicked: function(mouse) {
      var hit = findClosest(mouse.x, mouse.y)
      if (hit) root.picked(hit.ssid, hit.secure, hit.saved)
    }
  }
}
