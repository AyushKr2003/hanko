pragma ComponentBehavior: Bound
import QtQuick
import "../../core"
import "../../core/Mon.js" as Mon

// Sound 音, Mon (紋): a page of a crest book. The master is the sheet's own
// mon, a kuyō whose eight stars light with the level (red when muted;
// scroll on it, or click a star). Each output bears a crest, the one playing
// inked red as the banner you serve under (a click changes allegiance), and
// each app playing a kuyō of its own volume (a click mutes it). Up/Down
// step the master, M mutes.
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
    Item { width: 1; height: Type.px(18) }

    MonHero {
      kind: "kuyo"
      level: root.master ? (root.master.muted ? 0 : root.master.level) : -1
      red: !!(root.master && root.master.muted)
      settable: !!root.master
      figure: root.master ? String(root.master.percent) : "—"
      unit: root.master ? "%" : ""
      title: root.current ? "through " + root.current.label : "no output"
      lines: [root.master && root.master.muted ? "Muted" : "Scroll the crest · click a star"]
      onMoved: function(v) { root.request("master", v) }
      SheetButton { text: "Mute"; on: !!(root.master && root.master.muted); onClicked: root.request("mute", null) }
    }

    MonPage {
      id: outs
      jp: "出"
      label: "Output"
      summary: root.outputs.length + (root.outputs.length === 1 ? " device" : " devices")
      Repeater {
        model: root.outputs
        CrestCell {
          required property var modelData
          required property int index
          width: outs.cellWidth
          kind: Mon.at(index).kind
          count: Mon.at(index).count
          name: modelData.label
          note: modelData.note
          selected: modelData.current
          interactive: !modelData.current
          onClicked: root.request("output", { id: modelData.id, name: modelData.name })
        }
      }
    }

    MonPage {
      id: mix
      visible: root.streams.length > 0
      jp: "奏"
      label: "Playing"
      summary: root.streams.length + (root.streams.length === 1 ? " app" : " apps")
      Repeater {
        model: root.streams
        CrestCell {
          required property var modelData
          width: mix.cellWidth
          kind: "kuyo"
          level: modelData.muted ? 0 : modelData.level
          faint: modelData.muted
          name: modelData.label
          note: modelData.muted ? "muted" : modelData.percent + "%"
          onClicked: root.request("streamMute", { id: modelData.id, name: modelData.name })
        }
      }
    }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.sound ? root.sound.input : ""
    SheetButton { ghost: true; text: root.sound && root.sound.inputMuted ? "Unmute mic" : "Mute mic"; onClicked: root.request("inputMute", null) }
    SheetButton { plate: true; text: "Next output ›"; onClicked: root.request("nextOutput", null) }
  }

  Keys.onUpPressed: if (root.master) root.request("master", Math.min(1, root.master.level + 0.05))
  Keys.onDownPressed: if (root.master) root.request("master", Math.max(0, root.master.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_M) { root.request("mute", null); event.accepted = true }
  }
}
