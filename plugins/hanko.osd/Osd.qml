import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import "core"
import "core/Iai.js" as Iai
import "core/Taikan.js" as Taikan
import "OsdModel.js" as OsdModel

// Taikan 体幹, posture (docs/kaze, mockup 06): Omarchy's on-screen display,
// redrawn. A clone of omarchy.osd, so volume and brightness keys, the
// microphone switch and every `omarchy-osd` call land here unchanged (same
// IPC target and payloads, Omarchy's OsdModel.js). What it shows is one
// hairline at the foot of the screen that fills from the centre outward,
// with its label and figure above, or a crest and a word for a switch. It
// draws in on Iai's draw and sheathes back into its centre.
Item {
  id: root

  // Host injection (Omarchy's plugin contract); unused.
  property var shell
  property var manifest
  property string omarchyPath

  property var st: ({})
  readonly property var v: Taikan.view(root.st)
  property bool opened: false
  // 0 → 1 as it draws in, back to 0 as it sheathes.
  property real shown: 0
  property bool still: false

  FileView {
    path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/hanko/style.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.still = /"motion"\s*:\s*"still"/.test(text())
    onLoadFailed: root.still = false
  }

  function show(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration) {
    var next = OsdModel.stateForShow(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration)
    var wasOpen = root.opened
    root.st = next
    root.opened = true
    if (!wasOpen) {
      // A fresh OSD starts at its new value; only changes while open move.
      root.fill = root.v.fill
      root.figure = root.v.figure
      drawIn.restart()
    } else if (sheathe.running) {
      sheathe.stop()
      drawIn.restart()
    }
    if (root.v.full && !wasOpen) cut.restart()
    var d = root.v.duration
    if (d > 0) { hideTimer.interval = d; hideTimer.restart() } else hideTimer.stop()
  }

  function open(payloadJson) {
    try {
      var p = JSON.parse(payloadJson || "{}")
      show(p.icon || "", p.message || "", p.value === undefined ? "" : String(p.value), p.max === undefined ? "100" : String(p.max), p.progressText || "", p.duration === undefined ? "1200" : String(p.duration))
    } catch (e) {}
  }

  function close() {
    if (!root.opened) return
    root.opened = false
    drawIn.stop()
    if (root.still) root.shown = 0
    else sheathe.restart()
  }

  Timer { id: hideTimer; onTriggered: root.close() }

  // ── Motion ──
  SequentialAnimation {
    id: drawIn
    PauseAnimation { duration: root.still ? 0 : Iai.BEATS.nuki.hold }
    NumberAnimation { target: root; property: "shown"; to: 1; duration: root.still ? 0 : Iai.BEATS.nuki.ms; easing.type: Easing.BezierSpline; easing.bezierCurve: Iai.qml("nuki") }
  }
  NumberAnimation { id: sheathe; target: root; property: "shown"; to: 0; duration: Iai.BEATS.noto.ms; easing.type: Easing.BezierSpline; easing.bezierCurve: Iai.qml("noto") }

  // The level follows the value on the draw curve; the figure counts with it.
  property real fill: 0
  property real figure: 0
  Connections {
    target: root
    function onVChanged() {
      if (!root.opened) return
      fillAnim.to = root.v.fill; fillAnim.restart()
      figAnim.to = Math.max(0, root.v.figure); figAnim.restart()
      if (root.v.full) cut.restart()
    }
  }
  NumberAnimation { id: fillAnim; target: root; property: "fill"; duration: root.still ? 0 : Iai.BEATS.nuki.ms; easing.type: Easing.BezierSpline; easing.bezierCurve: Iai.qml("nuki") }
  NumberAnimation { id: figAnim; target: root; property: "figure"; duration: root.still ? 0 : Iai.BEATS.nuki.ms; easing.type: Easing.OutQuad }

  // The posture break at 100%: the whole line inks and the caps grow, for
  // one frame and 70 ms (the cut).
  property real broken: 0
  SequentialAnimation {
    id: cut
    PropertyAction { target: root; property: "broken"; value: 1 }
    PauseAnimation { duration: 16 }
    NumberAnimation { target: root; property: "broken"; to: 0; duration: root.still ? 0 : Iai.BEATS.kiri.ms }
  }

  // Registered a moment after start: on a reload the new instance exists
  // before the old one lets go of the target.
  IpcHandler {
    id: ipc
    enabled: false
    target: "osd"
    function show(payloadJson: string): string {
      root.open(payloadJson)
      return "ok"
    }
    function close(): string { root.close(); return "ok" }
    function state(): string { return root.opened ? "open" : "closed" }
    function ping(): string { return "ok" }
  }

  Timer { interval: 500; running: true; onTriggered: ipc.enabled = true }

  PanelWindow {
    id: panel
    visible: root.shown > 0 || root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "hanko-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Visual only: clicks pass through to the desktop.
    mask: Region {}

    // 1 at 1080 px tall.
    readonly property real k: Math.max(0.75, height / 1080)

    // A sheet of paper under it, so it reads over any window: square, a
    // hairline edge, no blur, no shadow (mockup 06's "not this" is the pill).
    Rectangle {
      readonly property real pad: Math.round(22 * panel.k)
      x: stage.x - pad
      y: stage.y + (root.v.kind === "level" ? reading.y : stage.height - Math.round(64 * panel.k)) - pad
      width: stage.width + 2 * pad
      height: stage.y + stage.height - y + pad
      color: Ink.paper
      border.width: 1
      border.color: Ink.lineSoft
      opacity: root.shown
    }

    Item {
      id: stage
      width: Math.round(panel.width * 0.3)
      height: Math.round(110 * panel.k)
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.round(58 * panel.k)

      // ── A level: the reading over the line ──
      Row {
        id: reading
        visible: root.v.kind === "level"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: line.top
        anchors.bottomMargin: Math.round(14 * panel.k)
        spacing: Math.round(12 * panel.k)
        opacity: Math.max(0, (root.shown - 0.4) / 0.6)
        Text {
          anchors.baseline: figureText.baseline
          text: root.v.label
          color: root.v.red ? Ink.seal : Ink.inkMuted
          font.family: Type.mono
          font.pixelSize: Math.round(12 * panel.k)
          font.letterSpacing: 2.4 * panel.k
        }
        Text {
          anchors.baseline: figureText.baseline
          text: root.v.kanji
          color: root.v.red ? Ink.seal : Ink.inkDim
          font.family: "Noto Serif CJK JP"
          font.pixelSize: Math.round(14 * panel.k)
        }
        Text {
          id: figureText
          text: root.v.muted ? root.v.word : Math.round(root.figure)
          color: root.v.red ? Ink.seal : Ink.ink
          font.family: Type.display
          font.pixelSize: Math.round(34 * panel.k)
          font.features: { "tnum": 1 }
        }
        Text {
          visible: !root.v.muted
          anchors.baseline: figureText.baseline
          text: "%"
          color: Ink.inkFaint
          font.family: Type.text
          font.pixelSize: Math.round(14 * panel.k)
        }
      }

      // The line: drawn from its centre as it opens.
      Item {
        id: line
        visible: root.v.kind === "level"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: Math.max(1, stage.width * root.shown)
        height: Math.round(14 * panel.k)
        readonly property color lineInk: root.broken > 0 ? Ink.ink : Ink.lineStrong

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: line.lineInk }
        // The caps at the ends, and the centre mark.
        Rectangle { x: 0; anchors.verticalCenter: parent.verticalCenter; width: root.broken > 0 ? 2 : 1; height: Math.round((9 + 4 * root.broken) * panel.k); color: root.broken > 0 ? Ink.ink : Ink.inkMuted }
        Rectangle { x: parent.width - width; anchors.verticalCenter: parent.verticalCenter; width: root.broken > 0 ? 2 : 1; height: Math.round((9 + 4 * root.broken) * panel.k); color: root.broken > 0 ? Ink.ink : Ink.inkMuted }
        Rectangle { x: Math.round(parent.width / 2); anchors.verticalCenter: parent.verticalCenter; width: 1; height: Math.round(7 * panel.k); color: Ink.inkFaint }
        // Ticks every tenth.
        Repeater {
          model: 11
          Rectangle { required property int index; x: Math.round(index * (line.width - 1) / 10); y: Math.round(line.height / 2 + 4 * panel.k); width: 1; height: Math.round(3 * panel.k); color: Ink.lineStrong }
        }
        // The fill, from the centre both ways; muted, a red mark at the centre.
        Rectangle {
          readonly property var h: Taikan.halves(root.fill)
          visible: !root.v.muted
          x: Math.round(line.width * h.left)
          width: Math.round(line.width * h.width)
          height: 3
          anchors.verticalCenter: parent.verticalCenter
          color: Ink.ink
        }
        Rectangle {
          visible: root.v.muted
          x: Math.round(line.width / 2 - 3)
          width: 6
          height: 3
          anchors.verticalCenter: parent.verticalCenter
          color: Ink.seal
        }
      }

      // ── A switch (or an end): a crest and its word, where the line would be ──
      Row {
        visible: root.v.kind !== "level"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: Math.round(18 * panel.k)
        opacity: root.shown
        scale: 0.96 + 0.04 * root.shown

        Item {
          width: Math.round(64 * panel.k)
          height: width
          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.v.red ? Ink.seal : "transparent"
            border.width: Math.max(2, Math.round(2.4 * panel.k))
            border.color: root.v.red ? Ink.seal : Ink.ink
          }
          Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.77
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: root.v.red ? Ink.paper : Ink.ink
            opacity: 0.6
          }
          Text {
            anchors.centerIn: parent
            text: root.v.crest
            color: root.v.red ? Ink.paper : Ink.ink
            font.family: "Noto Serif CJK JP"
            font.weight: Font.DemiBold
            font.pixelSize: Math.round(27 * panel.k)
          }
        }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Math.round(4 * panel.k)
          Text {
            visible: text !== ""
            text: root.v.label
            color: root.v.red ? Ink.seal : Ink.inkMuted
            font.family: Type.mono
            font.pixelSize: Math.round(12 * panel.k)
            font.letterSpacing: 2.4 * panel.k
          }
          Text {
            text: root.v.word
            color: Ink.ink
            font.family: Type.display
            font.pixelSize: Math.round(30 * panel.k)
          }
        }
      }
    }
  }
}
