pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// 02 // SOUND: a fader bank (the master in seal red, then each app playing,
// then the mic; muted channels go faint) beside the outputs, the live one
// on a plate.
ScrollSection {
  id: root

  // core/Sound.js sheet() shape.
  property var sound: null

  signal request(string what, var arg)

  readonly property var outputs: sound ? sound.outputs : []
  readonly property var live: outputs.length && outputs[0].current ? outputs[0] : null
  // Four app faders at most, so the bank fits its section.
  readonly property var streams: sound ? sound.streams.slice(0, 3) : []

  title: "Sound"
  caption: (live ? live.label + (live.detail ? " · " + live.detail : "") : "No output") + " · Pipewire"

  Row {
    width: parent.width
    topPadding: Type.px(22)
    spacing: Type.px(34)

    Row {
      id: bank
      spacing: Type.px(26)

      Fader {
        visible: !!(root.sound && root.sound.master)
        name: "Master"
        master: true
        value: root.sound && root.sound.master ? root.sound.master.level : 0
        muted: !!(root.sound && root.sound.master && root.sound.master.muted)
        onMoved: function(v) { root.request("master", v) }
      }
      Repeater {
        model: root.streams
        Fader {
          id: app
          required property var modelData
          name: modelData.label
          value: modelData.level
          muted: modelData.muted
          onMoved: function(v) { root.request("stream", { id: app.modelData.id, name: app.modelData.name, value: v }) }
        }
      }
      Fader {
        visible: !!(root.sound && root.sound.inputLevel >= 0)
        name: "Mic"
        value: root.sound ? Math.max(0, root.sound.inputLevel) : 0
        muted: !!(root.sound && root.sound.inputMuted)
        onMoved: function(v) { root.request("input", v) }
      }
    }

    Column {
      anchors.bottom: bank.bottom
      anchors.bottomMargin: Type.px(26)
      width: Math.max(Type.px(200), parent.width - bank.width - parent.spacing)
      Repeater {
        model: root.outputs.slice(0, 4)
        ListRow {
          id: out
          required property var modelData
          required property int index
          position: out.index
          name: modelData.label
          note: modelData.current ? "Live" : (modelData.bus || "")
          on: modelData.current
          ruled: out.index > 0 && !root.outputs[out.index - 1].current
          interactive: !modelData.current
          onClicked: root.request("output", { id: out.modelData.id, name: out.modelData.name })
        }
      }
    }
  }
}
