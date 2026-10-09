pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Sound 音, Dial (盤): the master as an arc gauge you turn (red, dashed when
// muted), the output in use beside it with Mute and Next, then the outputs
// and the apps playing as tiles. A click on an output plays there; on an
// app, mutes it. Up/Down step the master, M mutes.
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
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(20)

    SheetHead { sheet: "sound"; jp: "音"; label: "Sound · Pipewire"; compact: true }
    Item { width: 1; height: Type.px(16) }

    DialHero {
      value: root.master ? root.master.level : -1
      red: true
      muted: !!(root.master && root.master.muted)
      figure: root.master ? String(root.master.percent) : "—"
      unit: root.master ? "%" : ""
      caption: root.master && root.master.muted ? "muted" : "master"
      title: root.current ? root.current.label : "No output"
      lines: root.current ? [root.current.detail, "Scroll on bar · ±5"] : []
      onMoved: function(v) { root.request("master", v) }
      SheetButton { text: "Mute"; on: !!(root.master && root.master.muted); onClicked: root.request("mute", null) }
      SheetButton { plate: true; text: "Next output ›"; onClicked: root.request("nextOutput", null) }
    }

    TileSection {
      id: outs
      label: "Output"
      summary: root.outputs.length + (root.outputs.length === 1 ? " device" : " devices")
      Repeater {
        model: root.outputs
        Tile {
          required property var modelData
          width: outs.tileWidth
          name: modelData.label
          detail: modelData.detail
          note: modelData.note
          selected: modelData.current
          interactive: !modelData.current
          onClicked: root.request("output", { id: modelData.id, name: modelData.name })
        }
      }
    }

    TileSection {
      id: mix
      label: "Mixer"
      summary: root.streams.length ? root.streams.length + (root.streams.length === 1 ? " stream" : " streams") : "nothing playing"
      columns: 3
      Repeater {
        model: root.streams
        Tile {
          required property var modelData
          width: mix.tileWidth
          name: modelData.label
          detail: modelData.muted ? "muted" : modelData.percent + "%"
          level: modelData.muted ? 0 : modelData.level
          onClicked: root.request("streamMute", { id: modelData.id, name: modelData.name })
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.sound ? root.sound.input : ""
    SheetButton {
      ghost: true
      text: root.sound && root.sound.inputMuted ? "Unmute mic" : "Mute mic"
      onClicked: root.request("inputMute", null)
    }
  }

  Keys.onUpPressed: if (root.master) root.request("master", Math.min(1, root.master.level + 0.05))
  Keys.onDownPressed: if (root.master) root.request("master", Math.max(0, root.master.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_M) { root.request("mute", null); event.accepted = true }
  }
}
