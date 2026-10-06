import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"
import "../services"

// One layer-shell bar per screen. It reserves its own height and, when the
// bar is hidden, parks just past the screen edge instead of unmapping, the
// same trick Omarchy's bar uses so showing it again is only a margin change.
PanelWindow {
  id: win

  required property var bar          // the Bar.qml root
  property var style: Typeset.styleFor(screen ? screen.name : "")

  readonly property int barHeight: Type.px(style.height)
  readonly property bool atBottom: bar.position === "bottom"

  color: "transparent"
  implicitHeight: barHeight
  exclusionMode: bar.barHidden ? ExclusionMode.Ignore : ExclusionMode.Auto

  WlrLayershell.namespace: "hanko-bar"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: !win.atBottom
    bottom: win.atBottom
    left: true
    right: true
  }

  margins {
    top: bar.barHidden && !win.atBottom ? -win.barHeight : 0
    bottom: bar.barHidden && win.atBottom ? -win.barHeight : 0
  }

  BarSurface {
    anchors.fill: parent
    style: {
      var s = Object.assign({}, win.style)
      s.position = win.bar.position
      return s
    }
    now: win.bar.now
    spaces: Hypr.spacesFor(win.screen ? win.screen.name : "")
    activeWindow: Hypr.activeWindow
    home: Hypr.home
    media: Media.now
    timeFormat: win.bar.timeFormat

    onSealClicked: function(button) {
      if (button === Qt.RightButton) Hypr.openTerminal()
      else Hypr.openMenu()
    }
    onWorkspaceActivated: function(id) { Hypr.focusWorkspace(id) }
    onWorkspaceStepped: function(delta) { Hypr.stepWorkspace(delta) }
    onMediaAction: function(name) { Media.act(name) }
  }
}
