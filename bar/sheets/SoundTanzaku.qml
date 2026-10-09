pragma ComponentBehavior: Bound
import QtQuick
import "../../core"

// Sound 音, Tanzaku (短冊): the master on the first slip (pull it to set the
// level; red, and the wash pale, when muted), then a slip for each output
// (the one playing inked and sealed; a click moves there) and one for each
// app playing, hung as far as its level (a click mutes it). Up/Down step
// the master, M mutes.
Item {
  id: root

  property var sound: null
  signal request(string what, var arg)

  readonly property var master: sound ? sound.master : null
  readonly property var outputs: sound ? sound.outputs.slice(0, 3) : []
  readonly property var streams: sound ? sound.streams.slice(0, 3) : []

  width: parent ? parent.width : 0
  implicitHeight: column.y + column.implicitHeight + foot.implicitHeight

  Column {
    id: column
    x: Type.px(24)
    y: Type.px(22)
    width: root.width - 2 * x
    bottomPadding: Type.px(18)

    SheetHead { sheet: "sound"; jp: "音"; label: "Sound · Pipewire"; compact: true }
    Item { width: 1; height: Type.px(18) }

    TanzakuRail {
      LeadStrip {
        mark: "音"
        figure: root.master ? String(root.master.percent) : "—"
        unit: root.master ? "%" : ""
        caption: root.master && root.master.muted ? "muted" : "master"
        level: root.master ? root.master.level : -1
        red: true
        muted: !!(root.master && root.master.muted)
        settable: !!root.master
        onMoved: function(v) { root.request("master", v) }
      }
      Repeater {
        model: root.outputs
        Tanzaku {
          required property var modelData
          mark: "出"
          name: modelData.label
          foot: modelData.note
          selected: modelData.current
          interactive: !modelData.current
          onClicked: root.request("output", { id: modelData.id, name: modelData.name })
        }
      }
      Item { width: Type.px(4); height: 1; visible: root.streams.length > 0 }
      Repeater {
        model: root.streams
        Tanzaku {
          required property var modelData
          name: modelData.label
          foot: modelData.muted ? "—" : String(modelData.percent)
          level: modelData.level
          dashed: modelData.muted
          onClicked: root.request("streamMute", { id: modelData.id, name: modelData.name })
        }
      }
    }
    TanzakuFoot { text: "Pull the first slip to set · click a slip to choose" }
  }

  ActionBar {
    id: foot
    anchors.top: column.bottom
    note: root.sound ? root.sound.input : ""
    SheetButton { text: "Mute"; on: !!(root.master && root.master.muted); onClicked: root.request("mute", null) }
    SheetButton { ghost: true; text: root.sound && root.sound.inputMuted ? "Unmute mic" : "Mute mic"; onClicked: root.request("inputMute", null) }
  }

  Keys.onUpPressed: if (root.master) root.request("master", Math.min(1, root.master.level + 0.05))
  Keys.onDownPressed: if (root.master) root.request("master", Math.max(0, root.master.level - 0.05))
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_M) { root.request("mute", null); event.accepted = true }
  }
}
