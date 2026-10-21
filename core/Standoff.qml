import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Commons as Commons
import "Taiji.js" as Taiji
import "Almanac.js" as Almanac
import "Wind.js" as Wind

// Taiji 対峙, the standoff (docs/kaze, mockup 09): the lock screen's picture,
// shared by plugins/hanko.lock (its LockView puts the password field on it)
// and plugins/hanko.desk (which draws it again over the desk at the moment
// you unlock, and cuts it in two). The wallpaper in ink, still grass, the
// time in the serif with the day and the microseason, and a blade with a
// nick for each key typed; a wrong password is deflected.
Rectangle {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool loadBackground: true
  property int count: 0
  property bool authenticating: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool fingerprint: false
  readonly property bool errorState: failureMessage.length > 0
  // 1 at 1080 px tall.
  readonly property real k: Math.max(0.6, height / 1080)
  // Where the blade is, for the password field that sits over it.
  readonly property real bladeX: blade.x
  readonly property real bladeY: blade.y

  color: Commons.Color.background

  // Cache-busts the lock background by appending `?v=` (as the stock view).
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  // A wrong password: the spark and the shudder.
  property real deflect: 0
  onErrorStateChanged: if (errorState) deflection.restart()
  SequentialAnimation {
    id: deflection
    PropertyAction { target: root; property: "deflect"; value: 1 }
    NumberAnimation { target: blade; property: "shudder"; from: 0; to: 2; duration: 40 }
    NumberAnimation { target: blade; property: "shudder"; to: -1; duration: 50 }
    NumberAnimation { target: blade; property: "shudder"; to: 0; duration: 60 }
    PauseAnimation { duration: 500 }
    NumberAnimation { target: root; property: "deflect"; to: 0; duration: 220 }
  }

  // The clock and the almanac, once a second.
  property var now: new Date()
  Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
  readonly property var ko: Almanac.almanac(root.now).ko

  // The wallpaper in ink: no colour, a little darker, never blurred.
  Image {
    id: wallpaper
    anchors.fill: parent
    source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: width
    sourceSize.height: height
    visible: false
  }
  MultiEffect {
    anchors.fill: wallpaper
    source: wallpaper
    visible: root.loadBackground && wallpaper.status === Image.Ready
    autoPaddingEnabled: false
    saturation: -1
    brightness: Ink.light ? 0.05 : -0.3
    contrast: 0.1
    opacity: 0.55
  }

  // The ground fades into paper; the grass stands in it, still.
  Rectangle {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: Math.round(300 * root.k)
    gradient: Gradient {
      GradientStop { position: 0; color: "transparent" }
      GradientStop { position: 0.7; color: Commons.Color.background }
    }
  }
  Canvas {
    id: grass
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: Math.round(200 * root.k)
    readonly property var blades: Wind.field(width, height, 13)
    onBladesChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var c = Ink.inkFaint
      for (var i = 0; i < blades.length; i++) {
        var g = Wind.blade(blades[i], height, width, 0.18, 0, null)
        ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, g.alpha * 0.85)
        ctx.beginPath()
        ctx.moveTo(g.root[0] - g.w, g.root[1])
        ctx.quadraticCurveTo(g.ctrl[0] - g.w * 0.45, g.ctrl[1], g.tip[0], g.tip[1])
        ctx.quadraticCurveTo(g.ctrl[0] + g.w * 0.35, g.ctrl[1], g.root[0] + g.w, g.root[1])
        ctx.closePath()
        ctx.fill()
      }
    }
  }

  // ── The time, the day, the microseason ──
  Column {
    id: head
    x: Math.round(parent.width * 0.12)
    y: Math.round(parent.height * 0.3)
    spacing: Math.round(18 * root.k)

    Row {
      Text {
        text: Qt.formatTime(root.now, "HH")
        color: Ink.ink
        font.family: Type.display
        font.weight: Font.Light
        font.variableAxes: { "wght": 340, "opsz": 144 }
        renderType: Text.CurveRendering
        font.pixelSize: Math.round(200 * root.k)
        font.features: { "tnum": 1 }
      }
      Text {
        text: ":"
        color: Ink.seal
        font.family: Type.display
        font.weight: Font.Light
        font.variableAxes: { "wght": 340, "opsz": 144 }
        renderType: Text.CurveRendering
        font.pixelSize: Math.round(200 * root.k)
      }
      Text {
        text: Qt.formatTime(root.now, "mm")
        color: Ink.ink
        font.family: Type.display
        font.weight: Font.Light
        font.variableAxes: { "wght": 340, "opsz": 144 }
        renderType: Text.CurveRendering
        font.pixelSize: Math.round(200 * root.k)
        font.features: { "tnum": 1 }
      }
    }
    Text {
      text: Taiji.dayLine(root.now).toUpperCase()
      color: Ink.inkMuted
      font.family: Type.mono
      font.pixelSize: Math.round(15 * root.k)
      font.letterSpacing: 4 * root.k
    }
    Row {
      spacing: Math.round(18 * root.k)
      Text {
        text: root.ko.jp
        color: Ink.inkDim
        font.family: "Noto Serif CJK JP"
        font.pixelSize: Math.round(30 * root.k)
        font.letterSpacing: 4 * root.k
      }
      Text {
        anchors.baseline: parent.children[0].baseline
        text: Taiji.sentence(root.ko.english)
        color: Ink.inkMuted
        font.family: Type.display
        font.variableAxes: { "wght": 400 }
        font.italic: true
        font.pixelSize: Math.round(24 * root.k)
      }
    }
  }

  // ── The blade: a nick for each key; the password is never drawn ──
  Item {
    id: blade
    property real shudder: 0
    x: head.x + shudder
    y: head.y + head.height + Math.round(46 * root.k)
    width: Taiji.bladeWidth(root.count, Math.round(640 * root.k))
    height: 1
    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    Rectangle { anchors.fill: parent; color: Ink.ink; visible: blade.width > 0 }
    // The hilt.
    Rectangle { x: -1; y: -9; width: 2; height: 19; color: Ink.ink; visible: blade.width > 0 }
    Repeater {
      model: Taiji.nicks(root.count, Math.round(640 * root.k))
      Rectangle { required property var modelData; x: modelData; y: -7; width: 1; height: 8; color: Ink.ink; opacity: 1 - 0.7 * root.deflect }
    }
    // The deflection: a red spark at the tip.
    Rectangle {
      x: Math.max(0, blade.width - 1)
      y: -10
      width: 2
      height: 21
      color: Ink.seal
      opacity: root.deflect
    }
  }

  // The fingerprint crest, inking while the reader waits.
  Item {
    visible: root.fingerprint
    x: head.x + Math.max(blade.width, 0) + Math.round(36 * root.k)
    y: blade.y - Math.round(27 * root.k)
    width: Math.round(54 * root.k)
    height: width
    Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: 1.6; border.color: Ink.ink }
    Text {
      anchors.centerIn: parent
      text: "指"
      color: Ink.ink
      font.family: "Noto Serif CJK JP"
      font.pixelSize: Math.round(22 * root.k)
    }
  }

  Text {
    readonly property var h: Taiji.hint({ authenticating: root.authenticating, failure: root.failureMessage,
      attempts: root.failedAttempts, count: root.count, fingerprint: root.fingerprint })
    x: head.x
    y: blade.y + Math.round(26 * root.k)
    text: h.text.toUpperCase()
    color: h.red ? Ink.seal : Ink.inkFaint
    font.family: Type.mono
    font.pixelSize: Math.round(13 * root.k)
    font.letterSpacing: 3 * root.k
  }

  // Who this is.
  Column {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: Math.round(120 * root.k)
    anchors.bottomMargin: Math.round(120 * root.k)
    spacing: Math.round(6 * root.k)
    Text {
      anchors.right: parent.right
      text: Taiji.nameOf(Quickshell.env("USER"))
      color: Ink.inkDim
      font.family: Type.display
      font.variableAxes: { "wght": 400 }
      font.pixelSize: Math.round(28 * root.k)
    }
    Text {
      anchors.right: parent.right
      text: "LOCKED · 鍵"
      color: Ink.inkFaint
      font.family: Type.mono
      font.pixelSize: Math.round(13 * root.k)
      font.letterSpacing: 3 * root.k
    }
  }

}
