import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import "core"
import "core/Taiji.js" as Taiji
import "core/Leaf.js" as Leaf
import "core/Wind.js" as Wind

// Taiji 対峙, the standoff (docs/kaze, mockup 09). The lock screen in
// Hanko's grammar: your wallpaper in ink, grass at its foot, the time large
// in the serif with the day and the microseason, and under it a blade that
// grows a nick for each key you type. A wrong password is deflected: a red
// spark at the blade's tip, a shudder, the nicks fade.
//
// Only this view is Hanko's. Service.qml beside it is Omarchy's, byte for
// byte (tests/unit.mjs checks): the session lock, both PAM flows (password
// and fingerprint), the attempt count and the preview. This file keeps the
// stock LockView's whole interface (the properties and signals below) and
// its password field's handling as it was; only what is drawn changed.
Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  // 1 at 1080 px tall.
  readonly property real k: Math.max(0.6, height / 1080)

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=` (as the stock view).
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
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
  readonly property var ko: Leaf.almanac(root.now).ko

  Rectangle {
    anchors.fill: parent
    color: Color.background

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
        GradientStop { position: 0.7; color: Color.background }
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

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
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
      width: Taiji.bladeWidth(passwordInput.text.length, Math.round(640 * root.k))
      height: 1
      Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

      Rectangle { anchors.fill: parent; color: Ink.ink; visible: blade.width > 0 }
      // The hilt.
      Rectangle { x: -1; y: -9; width: 2; height: 19; color: Ink.ink; visible: blade.width > 0 }
      Repeater {
        model: Taiji.nicks(passwordInput.text.length, Math.round(640 * root.k))
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
      visible: root.fingerprintConfigured
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
      readonly property var h: Taiji.hint({ authenticating: root.authenticatingPassword, failure: root.failureMessage,
        attempts: root.failedAttempts, count: passwordInput.text.length, fingerprint: root.fingerprintConfigured })
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

    // The password field, as the stock view has it, but not drawn: the blade
    // is its picture. It keeps the keyboard and does all the work.
    TextInput {
      id: passwordInput
      x: blade.x
      y: blade.y - Math.round(20 * root.k)
      width: Math.round(640 * root.k)
      height: Math.round(40 * root.k)
      opacity: 0
      activeFocusOnPress: true
      clip: true
      enabled: root.inputEnabled && !root.authenticatingPassword
      readOnly: root.authenticatingPassword
      echoMode: TextInput.Password
      passwordCharacter: "●"
      passwordMaskDelay: 0
      color: Ink.ink
      font.family: Style.font.family
      font.pixelSize: Math.round(16 * root.k)
      cursorVisible: false

      onTextChanged: {
        if (!root.syncingPasswordText) root.passwordTextEdited(text)
        if (text.length > 0) {
          root.wakeRequested()
        }
        if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
      }

      onAccepted: {
        var submitted = root.passwordText
        root.passwordTextEdited("")
        if (submitted.length > 0) root.submitPassword(submitted)
      }

      Keys.onPressed: function(event) {
        root.wakeRequested()
        if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
          root.passwordTextEdited("")
          event.accepted = true
        }
      }
    }
  }
}
