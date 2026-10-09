pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Sound 音, Prose (文): "Playing at 62% through Studio Monitors. Spotify at
// 80, Firefox at 45. The mic is live." The underlined words are the
// controls (the level mutes, the output moves to the next, the mic toggles),
// a ruler under it sets the master, and the outputs are an index below.
Item {
  id: root

  property var sound: null
  signal request(string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var outputs: sound ? sound.outputs : []
  readonly property var streams: sound ? sound.streams : []
  readonly property var current: {
    for (var i = 0; i < outputs.length; i++) if (outputs[i].current) return outputs[i]
    return null
  }

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + Type.px(22)

  Column {
    id: column
    x: Type.px(26)
    y: Type.px(22)
    width: root.width - 2 * x

    SheetHead { sheet: "sound"; jp: "音"; label: "Sound · Pipewire"; compact: true }
    Item { width: 1; height: Type.px(16) }

    ProseText {
      id: line
      text: {
        if (!root.master) return "Listening for Pipewire…"
        var s = (root.master.muted ? "Silent, " + line.word("mute", line.red("muted")) + " at " + root.master.percent + "%"
                                    : "Playing at " + line.word("mute", root.master.percent + "%"))
        s += " through " + line.word("next", root.current ? root.current.label : "nothing") + ". "
        var parts = root.streams.map(function(st) { return line.em(st.label) + (st.muted ? " muted" : " at " + st.percent) })
        s += parts.length ? parts.join(", ") + ". " : "Nothing else is playing. "
        s += "The mic is " + line.word("mic", root.sound.inputMuted ? "off" : "live") + "."
        return s
      }
      onPicked: function(a) {
        if (a === "mute") root.request("mute", null)
        else if (a === "next") root.request("nextOutput", null)
        else if (a === "mic") root.request("inputMute", null)
      }
    }

    Item { width: 1; height: Type.px(14) }
    Ruler {
      width: parent.width
      value: root.master ? root.master.level : 0
      red: true
      muted: !!(root.master && root.master.muted)
      onMoved: function(v) { root.request("master", v) }
    }

    ProseIndex {
      label: "Outputs"
      summary: root.outputs.length + (root.outputs.length === 1 ? " device" : " devices")
      Repeater {
        model: root.outputs
        IndexRow {
          required property var modelData
          required property int index
          number: index + 1
          name: modelData.label
          note: modelData.note
          selected: modelData.current
          interactive: !modelData.current
          onClicked: root.request("output", { id: modelData.id, name: modelData.name })
        }
      }
    }
  }

  Keys.onUpPressed: if (root.master) root.request("master", Math.min(1, root.master.level + 0.05))
  Keys.onDownPressed: if (root.master) root.request("master", Math.max(0, root.master.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_M) { root.request("mute", null); event.accepted = true }
  }
}
