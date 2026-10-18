import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import "core"

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
  property string videoPosterPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintUnavailable: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property bool displaysBlank: false
  property bool powerSaverActive: false
  property string passwordText: ""
  property bool syncingPasswordText: false

  // A video wallpaper is drawn from the still the service cut from it.
  readonly property string picturePath: Util.isVideoPath(backgroundPath) ? videoPosterPath : backgroundPath
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  // 1 at 1080 px tall.
  readonly property real k: picture.k

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

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

  // The cut (docs/kaze, mockup 09): when a password goes to be checked, a
  // note tells hanko.desk to lay this same picture under the lock, so that
  // the moment the session unlocks it is cut in two and parts onto the
  // desk; a wrong password takes the note back. The note holds the time and
  // the wallpaper's path only: the field is already empty while checking.
  FileView {
    id: cutNote
    path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/hanko/cut.json"
    printErrors: false
    atomicWrites: true
  }
  onSubmitPassword: function(password) {
    if (root.inputEnabled)
      cutNote.setText(JSON.stringify({ at: Date.now(), backgroundPath: root.picturePath, backgroundVersion: root.backgroundVersion,
        fingerprint: root.fingerprintConfigured }))
  }
  onErrorStateChanged: if (errorState) cutNote.setText("{}")

  // The picture: core/Standoff.qml, shared with the desk's unlock cut.
  Standoff {
    id: picture
    anchors.fill: parent
    backgroundPath: root.picturePath
    backgroundVersion: root.backgroundVersion
    loadBackground: root.loadBackground
    count: passwordInput.text.length
    authenticating: root.authenticatingPassword
    failureMessage: root.failureMessage
    failedAttempts: root.failedAttempts
    fingerprint: root.fingerprintConfigured

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }
    // The password field, as the stock view has it, but not drawn: the blade
    // is its picture. It keeps the keyboard and does all the work.
    TextInput {
      id: passwordInput
      x: picture.bladeX
      y: picture.bladeY - Math.round(20 * root.k)
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
