pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// OrbitMap 軌道: Bluetooth devices arranged in tilted celestial orbits.
// Connected devices glide on the inner orbit (ringed in Ink.seal cinnabar red),
// paired/known devices on the middle orbit, and nearby found devices on the
// outer dashed orbit. Devices are spaced around orbits by the golden angle
// (137.5°), ensuring harmonious celestial distribution without overlap.
Item {
  id: root

  property var connected: []
  property var known: []
  property var found: []
  property bool powered: true
  property string hoverAddress: ""
  property real size: Type.px(280)

  signal picked(string address, string action)

  implicitWidth: size
  implicitHeight: Math.round(size * 0.72)

  readonly property real cx: width / 2
  readonly property real cy: height / 2 + Type.px(2)
  readonly property real tilt: 0.44

  readonly property real r1: width * 0.22
  readonly property real r2: width * 0.35
  readonly property real r3: width * 0.46

  readonly property real goldenAngle: Math.PI * (3 - Math.sqrt(5))

  readonly property var points: {
    var out = []
    var conn = root.connected || []
    var kn = root.known || []
    var fd = root.found || []

    var angle = 0.45

    // 1. Inner orbit: Connected
    for (var i = 0; i < conn.length; i++) {
      var d1 = conn[i]
      out.push({
        address: d1.address,
        name: d1.name,
        orbit: 1,
        radius: root.r1,
        angle: angle,
        status: "connected",
        battery: d1.level !== undefined ? d1.level : (d1.battery !== undefined ? d1.battery : -1),
        x: root.cx + root.r1 * Math.cos(angle),
        y: root.cy + root.r1 * root.tilt * Math.sin(angle)
      })
      angle += root.goldenAngle
    }

    // 2. Middle orbit: Known
    for (var j = 0; j < kn.length; j++) {
      var d2 = kn[j]
      out.push({
        address: d2.address,
        name: d2.name,
        orbit: 2,
        radius: root.r2,
        angle: angle,
        status: "known",
        battery: -1,
        x: root.cx + root.r2 * Math.cos(angle),
        y: root.cy + root.r2 * root.tilt * Math.sin(angle)
      })
      angle += root.goldenAngle
    }

    // 3. Outer orbit: Found
    for (var k = 0; k < fd.length; k++) {
      var d3 = fd[k]
      out.push({
        address: d3.address,
        name: d3.name,
        orbit: 3,
        radius: root.r3,
        angle: angle,
        status: "found",
        battery: -1,
        x: root.cx + root.r3 * Math.cos(angle),
        y: root.cy + root.r3 * root.tilt * Math.sin(angle)
      })
      angle += root.goldenAngle
    }

    return out
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    readonly property var pts: root.points
    readonly property string hAddr: root.hoverAddress
    readonly property bool pwr: root.powered
    readonly property color lineCol: Ink.line
    readonly property color lineSoft: Ink.lineSoft
    readonly property color inkCol: Ink.ink
    readonly property color inkDim: Ink.inkDim
    readonly property color sealCol: Ink.seal

    onPtsChanged: requestPaint()
    onHAddrChanged: requestPaint()
    onPwrChanged: requestPaint()

    onPaint: {
      var g = getContext("2d")
      g.reset()
      var cx = root.cx
      var cy = root.cy

      function drawEllipse(rx, ry, dash) {
        g.beginPath()
        if (dash) {
          // Approximate dashed ellipse with segments
          var steps = 48
          for (var s = 0; s < steps; s++) {
            if (s % 2 === 0) {
              var a0 = s * Math.PI * 2 / steps
              var a1 = (s + 0.7) * Math.PI * 2 / steps
              g.moveTo(cx + rx * Math.cos(a0), cy + ry * Math.sin(a0))
              g.lineTo(cx + rx * Math.cos(a1), cy + ry * Math.sin(a1))
            }
          }
        } else {
          // Standard ellipse
          for (var t = 0; t <= Math.PI * 2; t += 0.05) {
            var x = cx + rx * Math.cos(t)
            var y = cy + ry * Math.sin(t)
            if (t === 0) g.moveTo(x, y); else g.lineTo(x, y)
          }
          g.closePath()
        }
        g.stroke()
      }

      // Draw celestial elliptical orbit rings
      g.lineWidth = 1

      // Orbit 1: Inner (connected)
      g.strokeStyle = canvas.pts.some(function(p) { return p.orbit === 1 }) ? canvas.lineCol : canvas.lineSoft
      drawEllipse(root.r1, root.r1 * root.tilt, false)

      // Orbit 2: Middle (known)
      g.strokeStyle = canvas.lineSoft
      drawEllipse(root.r2, root.r2 * root.tilt, false)

      // Orbit 3: Outer (found/discovery) - dashed
      g.strokeStyle = canvas.lineSoft
      drawEllipse(root.r3, root.r3 * root.tilt, true)

      // Center host node
      g.beginPath()
      g.arc(cx, cy, Type.px(3), 0, Math.PI * 2)
      g.fillStyle = canvas.pwr ? canvas.inkCol : canvas.lineCol
      g.fill()

      // Plot device celestial bodies
      for (var i = 0; i < pts.length; i++) {
        var p = pts[i]
        var isHov = p.address === hAddr
        var isConn = p.status === "connected"
        var nodeR = isConn ? Type.px(4.5) : (isHov ? Type.px(4) : Type.px(3))

        // Tether line to host for connected devices
        if (isConn) {
          g.strokeStyle = canvas.sealCol
          g.lineWidth = 1
          g.beginPath()
          g.moveTo(cx, cy)
          g.lineTo(p.x, p.y)
          g.stroke()
        }

        // Body node
        g.beginPath()
        g.arc(p.x, p.y, nodeR, 0, Math.PI * 2)

        if (isConn) {
          g.fillStyle = canvas.sealCol
          g.fill()
        } else if (p.status === "known") {
          g.fillStyle = canvas.inkCol
          g.fill()
        } else {
          g.fillStyle = Ink.paper
          g.fill()
          g.strokeStyle = isHov ? canvas.inkCol : canvas.inkDim
          g.lineWidth = 1
          g.stroke()
        }

        // Hover halo
        if (isHov) {
          g.beginPath()
          g.arc(p.x, p.y, nodeR + Type.px(2.5), 0, Math.PI * 2)
          g.strokeStyle = isConn ? canvas.sealCol : canvas.inkCol
          g.lineWidth = 1
          g.stroke()
        }
      }
    }
  }

  // Active / hovered device readout
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
        if (root.hoverAddress !== "") {
          var h = root.points.find(function(p) { return p.address === root.hoverAddress })
          return h ? h.name + " (" + h.status + ")" : root.hoverAddress
        }
        var c = root.points.find(function(p) { return p.status === "connected" })
        return c ? c.name + (c.battery >= 0 ? " · " + c.battery + "%" : "") : ""
      }
      color: root.hoverAddress !== "" ? Ink.ink : Ink.seal
      font.family: Type.mono
      font.pixelSize: Type.tag
      font.weight: Font.Medium
    }
  }

  // Center mark
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Type.px(1)
    text: "藍 · 軌道"
    color: Ink.inkFaint
    font.family: Type.jp
    font.pixelSize: Type.tag
  }

  // Mouse interaction
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true

    function findClosest(mx, my) {
      var pts = root.points
      var best = null
      var minD = Type.px(18)
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
      root.hoverAddress = hit ? hit.address : ""
    }

    onExited: root.hoverAddress = ""

    onClicked: function(mouse) {
      var hit = findClosest(mouse.x, mouse.y)
      if (hit) {
        var action = hit.status === "connected" ? "disconnect" : (hit.status === "known" ? "connect" : "pair")
        root.picked(hit.address, action)
      }
    }
  }
}
