import QtQuick
import "../core"

// A reading that counts to its new value, the way a game's counters run up
// instead of snapping (volume 40 → 62 runs through the numbers in the time
// a fade takes). Whole numbers roll; anything else (a network's name)
// fades through like FadeText.
Text {
  id: root

  // What to show; set this, not `text`.
  property string figure: ""
  readonly property bool _whole: /^-?\d+$/.test(figure)
  property real _n: 0
  property string _shown: figure

  text: _whole && roll.running ? String(Math.round(_n)) : _shown

  onFigureChanged: {
    var was = _shown
    // Tested here, not through _whole: that binding may not have caught up
    // with the new figure yet when this handler runs.
    var whole = /^-?\d+$/
    if (Motion.live && whole.test(figure) && whole.test(was) && was !== figure) {
      roll.stop()
      roll.from = Number(was)
      roll.to = Number(figure)
      // A small step is quick, a long run a little longer; never past 320 ms.
      roll.duration = Math.min(320, 120 + 6 * Math.abs(Number(figure) - Number(was)))
      _shown = figure
      roll.start()
    } else if (Motion.live && was !== figure && was !== "") {
      fade.restart()
    } else {
      _shown = figure
    }
  }

  NumberAnimation { id: roll; target: root; property: "_n"; easing.type: Easing.OutCubic }

  SequentialAnimation {
    id: fade
    NumberAnimation { target: root; property: "opacity"; to: 0.2; duration: Motion.fade / 2; easing.type: Easing.InQuad }
    ScriptAction { script: root._shown = root.figure }
    NumberAnimation { target: root; property: "opacity"; to: 1; duration: Motion.fade / 2; easing.type: Easing.OutQuad }
  }
}
