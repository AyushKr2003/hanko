import QtQuick
import "../../../core"
import "../../../bar"

// Not a render: a probe the motion test drives (tests/motion.py). It wakes
// Motion, changes a reading and reports what the bar shows on the way.
Item {
  id: root
  width: 900; height: 60
  property var log: []
  property var vol: ({ percent: 40, level: 0.4, muted: false, needsYou: false })

  Component.onCompleted: { Motion.forceStill = false; Motion.awake = true }

  StatusRow {
    id: row
    mode: "cells"
    barHeight: 40
    volume: root.vol
    battery: ({ percent: 9, level: 0.09, charging: false, needsYou: true })
  }

  RollText { id: roll; figure: "40" }

  Timer { interval: 50; running: true; onTriggered: { roll.figure = "62"; root.vol = { percent: 62, level: 0.62, muted: false, needsYou: false } } }
  Timer { interval: 50 + 70; running: true; onTriggered: root.log.push("mid:" + roll.text) }
  Timer { interval: 50 + 400; running: true; onTriggered: root.log.push("end:" + roll.text) }
  Timer { interval: 50 + 450; running: true; onTriggered: { roll.figure = "Kumo"; } }
  Timer { interval: 50 + 520; running: true; onTriggered: root.log.push("fading:" + roll.opacity.toFixed(2) + ":" + roll.text) }
  Timer { interval: 50 + 800; running: true; onTriggered: { root.log.push("faded:" + roll.opacity.toFixed(2) + ":" + roll.text); console.log("PROBE " + root.log.join(" ")) ; Qt.quit() } }
}
