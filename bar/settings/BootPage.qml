pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Oin.js" as Oin
import "../../core/Settings.js" as Settings
import "../../core/Themes.js" as Th

// Settings › Boot 押印 (docs/kaze §4.1): the boot and disk-unlock screen.
// Left, the screen itself, from the pictures `hanko boot on` would install
// (services/Kaze.qml draws them into the state folder for the theme as it
// is): hold a moment, play one boot, or click it and type, a nick a key,
// Enter to cut, Esc for a wrong one. Right, the switch: On installs it and
// rebuilds the boot image (your password, once, and a minute), Off puts
// back the screen it replaced. Under that, the screen's two choices
// (kaze.json, kept at once, Undo puts them back; an installed screen needs
// Redraw to take them), what to do if a boot ever shows nothing, and the
// commands.
Column {
  id: root

  property var kaze: ({})
  property bool boot: false
  property var drawn: ({})
  property string error: ""
  property string busy: ""
  // The preview's pictures ("" until the first drawing) and whether one is
  // being drawn.
  property string preview: ""
  property bool previewBusy: false
  property string themeName: ""
  property string glyph: "鑑"
  property string name: ""
  property bool compact: false
  // The moment held when the page opens (the harness picks one).
  property string firstMoment: "asked"

  signal bootPicked(bool on)
  signal refreshPicked()
  signal kazePicked(string key, string value)
  // Ask for the preview to be drawn (again): on opening, and when what it
  // is drawn from changes.
  signal previewWanted()
  // Esc on an empty field: the window's keys again (the rail, the cursor).
  signal keysWanted()

  readonly property bool working: busy === "boot"
  readonly property string bootName: Settings.kazeValue(kaze, "bootName")
  readonly property string bootPress: Settings.kazeValue(kaze, "bootPress")
  readonly property string stale: boot ? Oin.stale(drawn, { theme: themeName, glyph: glyph, name: bootName, press: bootPress }, Th.themeName) : ""
  // On, but drawn before `hanko boot on` kept what it drew for.
  readonly property bool unrecorded: boot && !(drawn && drawn.theme)
  readonly property real gap: Type.px(16)
  readonly property real screenWidth: compact ? width : Math.round(width * 0.62)
  readonly property real sideWidth: compact ? width : width - screenWidth - gap

  Component.onCompleted: previewWanted()
  onBootNameChanged: previewWanted()
  onBootPressChanged: previewWanted()
  onGlyphChanged: previewWanted()
  onThemeNameChanged: previewWanted()

  // ------------------------------------------------ what the screen shows
  // A moment held still, one boot played, or what you type.
  property string held: firstMoment
  property real playT: -1
  property string tryPhase: ""
  property int tryFailed: 0
  property real tryProgress: 0
  property real tryFade: 0
  readonly property bool playing: playT >= 0
  readonly property bool trying: tryPhase !== ""
  readonly property var shown: {
    if (playing) return Oin.story(playT)
    if (trying) return { state: tryPhase, count: tryInput.text.length, progress: tryProgress, press: 1, paper: 1, failed: tryFailed, fade: tryFade }
    return Object.assign({ paper: 1, fade: 0 }, Oin.moment(held))
  }

  function hold(key) { stopAll(); held = key }
  function play() {
    stopAll()
    if (!Motion.live) { held = "booting"; return }
    playAnim.restart()
  }
  function stopAll() {
    playAnim.stop(); playT = -1
    cutAnim.stop(); wrongAnim.stop()
    tryPhase = ""; tryFailed = 0; tryProgress = 0; tryFade = 0
    tryInput.text = ""
  }
  function startTrying() {
    if (playing) { playAnim.stop(); playT = -1 }
    if (!trying) tryPhase = "password"
    tryInput.forceActiveFocus()
  }

  NumberAnimation {
    id: playAnim
    target: root; property: "playT"
    from: 0; to: Oin.STORY_MS; duration: Oin.STORY_MS
    onFinished: { root.playT = -1; root.held = "booting" }
  }
  // Enter: checked, then the hairline runs as the boot's progress.
  SequentialAnimation {
    id: cutAnim
    ScriptAction { script: { root.tryPhase = "checking" } }
    PauseAnimation { duration: 700 }
    ScriptAction { script: { root.tryPhase = "booting"; root.tryProgress = 0 } }
    NumberAnimation { target: root; property: "tryProgress"; to: 0.7; duration: 2600; easing.type: Easing.OutQuad }
  }
  // Esc: deflected; the spark and the old nicks go, the field is empty.
  SequentialAnimation {
    id: wrongAnim
    ScriptAction { script: { root.tryFailed++; root.tryFade = 0; root.tryPhase = "wrong" } }
    NumberAnimation { target: root; property: "tryFade"; from: 0; to: 1; duration: 320 }
    ScriptAction { script: { tryInput.text = ""; root.tryPhase = "password" } }
  }

  width: parent ? parent.width : 0
  spacing: 0
  topPadding: Type.px(22)

  SectionLabel {
    jp: "押印"
    text: "The boot screen · " + (root.boot ? "on" : "off, Omarchy's is in use") + (root.compact ? "" : " · nothing here touches your disk")
  }
  Item { width: 1; height: Type.px(12) }

  Flow {
    width: parent.width
    spacing: root.gap

    // ------------------------------------------------ the screen
    Column {
      width: root.screenWidth
      spacing: Type.px(10)

      Rectangle {
        id: frame
        width: parent.width
        height: Math.round((width - 2) * 9 / 16) + 2
        radius: 3
        color: "transparent"
        border.width: 1
        border.color: tryInput.activeFocus ? Ink.lineStrong : Ink.line
        clip: true

        BootScreen {
          x: 1; y: 1
          scale: (frame.width - 2) / 1920
          transformOrigin: Item.TopLeft
          dir: root.preview
          phase: root.shown.state
          count: root.shown.count
          progress: root.shown.progress
          press: root.shown.press
          paper: root.shown.paper === undefined ? 1 : root.shown.paper
          failed: root.shown.failed
          fade: root.shown.fade || 0
          showName: root.bootName === "name"
          pressInk: root.bootPress === "ink"
          glyph: root.glyph
          name: root.name
        }

        // Click and type: the field is not drawn, the blade is its picture.
        TextInput {
          id: tryInput
          width: 1; height: 1
          opacity: 0
          echoMode: TextInput.Password
          maximumLength: 64
          readOnly: root.tryPhase === "checking" || root.tryPhase === "booting"
          onTextChanged: {
            if (text.length > 0 && root.tryPhase === "wrong") { wrongAnim.stop(); root.tryFade = 0; root.tryPhase = "password" }
            if (text.length > 0 && root.tryPhase === "") root.tryPhase = "password"
          }
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              if (text.length > 0) cutAnim.restart()
              event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
              if (text.length > 0) wrongAnim.restart()
              else { root.stopAll(); root.keysWanted() }
              event.accepted = true
            }
          }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.IBeamCursor
          // Te 手 (bar/parts/KeyCursor.qml): Enter on the screen starts typing.
          readonly property bool keyStop: true
          function keyPress() { root.startTrying() }
          onClicked: {
            if (root.tryPhase === "booting" || root.tryPhase === "checking") root.stopAll()
            root.startTrying()
          }
        }

        // The preview's state, small, in the corner of the frame.
        Text {
          x: Type.px(10); y: Type.px(8)
          text: root.previewBusy ? "DRAWING FOR YOUR THEME…"
            : root.preview === "" ? "DRAWN HERE · HANKO-BOOT NOT RUN YET"
            : tryInput.activeFocus ? "TYPING · ENTER CUTS · ESC, A WRONG ONE"
            : "AS IT WOULD BE INSTALLED"
          color: Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackEyebrow
        }
      }

      // The middle at its true size (as on a 1080p screen): the seal, the
      // hairline and the hint, which the whole screen above draws too small
      // to read.
      Rectangle {
        id: closeUp
        readonly property real k: Type.px(1)
        width: parent.width
        height: Math.round(290 * k) + 2
        radius: 3
        color: "transparent"
        border.width: 1
        border.color: Ink.line
        Item {
          x: 1; y: 1
          width: closeUp.width - 2; height: closeUp.height - 2
          clip: true
        BootScreen {
          x: Math.round(parent.width / 2 - 960 * closeUp.k)
          y: -Math.round(360 * closeUp.k)
          scale: closeUp.k
          transformOrigin: Item.TopLeft
          dir: root.preview
          phase: root.shown.state
          count: root.shown.count
          progress: root.shown.progress
          press: root.shown.press
          paper: root.shown.paper === undefined ? 1 : root.shown.paper
          failed: root.shown.failed
          fade: root.shown.fade || 0
          showName: false
          pressInk: root.bootPress === "ink"
          glyph: root.glyph
        }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.IBeamCursor
          onClicked: root.startTrying()
        }
        Text {
          x: Type.px(10); y: Type.px(8)
          text: "CLOSE UP · TRUE SIZE"
          color: Ink.inkFaint
          font.family: Type.mono
          font.pixelSize: Type.tag
          font.letterSpacing: Type.trackEyebrow
        }
      }

      Row {
        spacing: Type.px(8)
        Segmented {
          options: Oin.MOMENTS.map(function(m) { return m.key })
          labels: (function() { var o = {}; Oin.MOMENTS.forEach(function(m) { o[m.key] = m.label }); return o })()
          selected: root.playing || root.trying ? "" : root.held
          onPicked: function(v) { root.hold(v) }
        }
        SmallButton {
          anchors.verticalCenter: parent.verticalCenter
          height: Type.px(24)
          label: root.playing ? "Playing…" : "Play a boot"
          plate: !root.playing
          onClicked: root.playing ? root.stopAll() : root.play()
        }
      }
      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Click the screen and type: a nick for each key, as on the lock. Enter cuts and the hairline becomes the boot's progress; Esc shows a wrong passphrase."
        color: Ink.inkFaint
        font.family: Type.text
        font.pixelSize: Type.note
      }
    }

    // ------------------------------------------------ the switch
    Column {
      width: root.sideWidth
      spacing: Type.px(10)

      Rectangle {
        width: parent.width
        height: switchCol.implicitHeight + 2 * Type.px(14)
        radius: 3
        color: "transparent"
        border.width: 1
        border.color: Ink.line

        Column {
          id: switchCol
          x: Type.px(14); y: Type.px(14)
          width: parent.width - 2 * x
          spacing: Type.px(10)

          Row {
            spacing: Type.px(10)
            Text {
              id: stateWord
              text: root.working ? "…" : root.boot ? "On" : "Off"
              color: Ink.ink
              font.family: Type.display
              font.pixelSize: Type.px(34)
              font.variableAxes: Type.axes(Type.px(34), 340)
            }
            Text {
              anchors.baseline: stateWord.baseline
              text: root.boot ? "Hanko's screen" : "Omarchy's screen"
              color: Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.row
            }
          }
          Text {
            width: parent.width
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: root.working ? "Asks for your password, then rebuilds the boot image. A minute; this window can stay open."
              : root.error !== "" ? root.error
              : root.stale !== "" ? root.stale + ". Redraw to bring it along."
              : root.unrecorded ? "From the next boot. It was drawn before Hanko kept a note of what for; Redraw to be sure it has your theme and the choices below."
              : root.boot ? "From the next boot" + (root.drawn && root.drawn.theme ? ", drawn for " + Th.themeName(root.drawn.theme) + (Oin.day(root.drawn.at) ? " on " + Oin.day(root.drawn.at) : "") : "") + ". Off puts back the screen it replaced."
              : "On draws it for your theme, checks its script, then asks for your password once to install it and rebuild the boot image."
            color: root.error !== "" || root.stale !== "" ? Ink.seal : Ink.inkMuted
            font.family: Type.text
            font.pixelSize: Type.note
          }
          Segmented {
            fill: parent.width
            options: ["on", "off"]
            labels: ({ on: "On", off: "Off" })
            selected: root.boot ? "on" : "off"
            enabled: !root.working
            onPicked: function(v) { if ((v === "on") !== root.boot) root.bootPicked(v === "on") }
          }
          SmallButton {
            visible: root.boot && (root.stale !== "" || root.unrecorded) && !root.working
            label: "Redraw · asks for your password"
            plate: root.stale !== ""
            onClicked: root.refreshPicked()
          }
        }
      }

      // The screen's two choices.
      Repeater {
        model: Settings.BOOT_CHOICES
        Rectangle {
          id: choice
          required property var modelData
          width: parent.width
          height: choiceCol.implicitHeight + 2 * Type.px(12)
          radius: 3
          color: "transparent"
          border.width: 1
          border.color: Ink.line
          Column {
            id: choiceCol
            x: Type.px(14); y: Type.px(12)
            width: parent.width - 2 * x
            spacing: Type.px(6)
            Row {
              spacing: Type.px(6)
              Text {
                id: choiceName
                text: choice.modelData.name
                color: Ink.ink
                font.family: Type.text
                font.pixelSize: Type.px(14)
                font.weight: Font.Medium
                font.variableAxes: Type.valueAxes
              }
              Text { anchors.baseline: choiceName.baseline; text: choice.modelData.jp; color: Ink.inkMuted; font.family: Type.jp; font.pixelSize: Type.px(13) }
            }
            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              text: choice.modelData.line
              color: Ink.inkMuted
              font.family: Type.text
              font.pixelSize: Type.note
            }
            Segmented {
              fill: parent.width
              options: choice.modelData.options
              labels: choice.modelData.labels
              selected: Settings.kazeValue(root.kaze, choice.modelData.key)
              onPicked: function(v) { root.kazePicked(choice.modelData.key, v) }
            }
          }
        }
      }
      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "The seal is your bar's, " + root.glyph + " (Typesetting › Seal), and the inks are your theme's."
        color: Ink.inkFaint
        font.family: Type.text
        font.pixelSize: Type.note
      }
    }
  }

  Item { width: 1; height: Type.px(26) }

  // ------------------------------------------------ if it goes wrong
  SectionLabel { jp: "守"; text: "If a boot ever shows nothing" }
  Item { width: 1; height: Type.px(10) }
  Grid {
    width: parent.width
    columns: root.compact ? 1 : 3
    columnSpacing: root.gap
    rowSpacing: Type.px(10)
    Repeater {
      model: [
        { head: "Type it anyway", line: "The disk still listens: type your passphrase and press Enter, even on a blank screen." },
        { head: "Press Esc", line: "Plymouth's plain text prompt comes up in place of the picture." },
        { head: "Put Omarchy's back", line: "From your desk, Off here or hanko boot off. Omarchy's own unlock-screen picker sets its screen too; this page then reads Off." }
      ]
      Column {
        id: help
        required property var modelData
        width: root.compact ? root.width : (root.width - 2 * root.gap) / 3
        spacing: Type.px(4)
        Text { text: help.modelData.head; color: Ink.ink; font.family: Type.text; font.pixelSize: Type.row }
        Text { width: parent.width; wrapMode: Text.WordWrap; text: help.modelData.line; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
      }
    }
  }

  Item { width: 1; height: Type.px(26) }

  // ------------------------------------------------ the commands
  SectionLabel { jp: "令"; text: "The same from a terminal" }
  Item { width: 1; height: Type.px(10) }
  Repeater {
    model: [
      ["hanko boot on", "draw, check, install, rebuild"],
      ["hanko boot off", "back to the screen it replaced"],
      ["hanko boot refresh", "draw it again after a theme change"],
      ["hanko boot preview", "the four moments as one picture"]
    ]
    Row {
      id: cmd
      required property var modelData
      spacing: Type.px(14)
      bottomPadding: Type.px(4)
      Text { width: Type.px(170); text: cmd.modelData[0]; color: Ink.ink; font.family: Type.mono; font.pixelSize: Type.label }
      Text { text: cmd.modelData[1]; color: Ink.inkMuted; font.family: Type.text; font.pixelSize: Type.note }
    }
  }
}
